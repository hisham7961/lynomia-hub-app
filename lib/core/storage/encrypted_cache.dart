/// خبيئة الأعمال المشفرة على القرص (§63) — AES-256-GCM بمفتاح في المخزن الآمن.
///
/// **قرار موثق (docs/offline-sync.md):** بدل قاعدة SQLCipher أصلية، تُخزن
/// اللقطات JSON مشفرةً ملفاً لكل نطاق (nonce عشوائي لكل كتابة + وسم GCM).
/// المفتاح لا يغادر Keychain/Keystore، والملفات غير قابلة للقراءة بدونه —
/// فلا قاعدة مؤسسية نصية على القرص إطلاقاً.
///
/// **حارس السياسة بنيوي:** الكتابة تتطلب تمرير `sync_class` الخادمي، و
/// `SENSITIVE_NO_PERSIST`/`ONLINE_ONLY` تُرفض برمية [CachePolicyViolation] —
/// دفاع في العمق فوق امتناع محرك المزامنة أصلاً (§61 §62).
library;

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import 'secure_store.dart';

class CachePolicyViolation implements Exception {
  CachePolicyViolation(this.message);
  final String message;

  @override
  String toString() => 'CachePolicyViolation: $message';
}

class EncryptedJsonCache {
  EncryptedJsonCache({required this.rootDir, required SecureStore keyStore})
    : _secureStore = keyStore;

  static const _keyName = 'lynomia.cache_key_v1';
  static const forbiddenClasses = {
    'SENSITIVE_NO_PERSIST',
    'ONLINE_ONLY',
    'NOT_APPLICABLE',
  };

  /// جذر الخبيئة (يُحقن: دليل دعم التطبيق حقيقةً، ودليل مؤقت اختباراً).
  final Directory rootDir;
  final SecureStore _secureStore;
  final AesGcm _cipher = AesGcm.with256bits();
  SecretKey? _key;

  Future<SecretKey> _ensureKey() async {
    if (_key != null) return _key!;
    final stored = await _secureStore.read(_keyName);
    if (stored != null && stored.isNotEmpty) {
      return _key = SecretKey(base64Decode(stored));
    }
    final fresh = await _cipher.newSecretKey();
    final bytes = await fresh.extractBytes();
    await _secureStore.write(_keyName, base64Encode(bytes));
    return _key = fresh;
  }

  File _fileFor(String namespace) {
    final safe = namespace.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return File('${rootDir.path}/cache/$safe.bin');
  }

  /// كتابة لقطة — [syncClass] إن مُرر يُفحص ضد الأصناف المحظورة.
  Future<void> write(
    String namespace,
    Map<String, dynamic> value, {
    String? syncClass,
  }) async {
    if (syncClass != null && forbiddenClasses.contains(syncClass)) {
      throw CachePolicyViolation(
        'الصنف $syncClass لا يُكتب على القرص ($namespace)',
      );
    }
    final key = await _ensureKey();
    final clear = utf8.encode(jsonEncode(value));
    final nonce = _cipher.newNonce();
    final box = await _cipher.encrypt(clear, secretKey: key, nonce: nonce);
    final file = _fileFor(namespace);
    await file.parent.create(recursive: true);
    await file.writeAsBytes([
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ], flush: true);
  }

  Future<Map<String, dynamic>?> read(String namespace) async {
    final file = _fileFor(namespace);
    if (!await file.exists()) return null;
    try {
      final raw = await file.readAsBytes();
      if (raw.length < 12 + 16) return null;
      final key = await _ensureKey();
      final clear = await _cipher.decrypt(
        SecretBox(
          raw.sublist(12, raw.length - 16),
          nonce: raw.sublist(0, 12),
          mac: Mac(raw.sublist(raw.length - 16)),
        ),
        secretKey: key,
      );
      return (jsonDecode(utf8.decode(clear)) as Map).cast<String, dynamic>();
    } on Object {
      // ملف تالف/مفتاح تغير ⇒ تجاهل آمن (يُعاد الجلب من الخادم)
      await file.delete().catchError((_) => file);
      return null;
    }
  }

  Future<void> delete(String namespace) async {
    final f = _fileFor(namespace);
    if (await f.exists()) await f.delete();
  }

  /// حذف كل ما يبدأ بالبادئة (تبديل مستخدم/سياق أو خروج).
  Future<void> deleteByPrefix(String prefix) async {
    final dir = Directory('${rootDir.path}/cache');
    if (!await dir.exists()) return;
    final safe = prefix.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    await for (final f in dir.list()) {
      if (f is File && f.uri.pathSegments.last.startsWith(safe)) {
        await f.delete();
      }
    }
  }

  /// مسح كامل (خروج §39).
  Future<void> wipeAll() async {
    final dir = Directory('${rootDir.path}/cache');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// هل للنطاق أثر على القرص؟ (تستعمله اختبارات إثبات عدم الهبوط)
  Future<bool> existsOnDisk(String namespace) => _fileFor(namespace).exists();
}
