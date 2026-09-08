/// مخزن اعتماد الجلسة — فوق [SecureStore] حصراً (§34 §35).
///
/// رمز الوصول قصير العمر يُحفظ هنا أيضاً لصحة دورة الحياة (إقلاع بارد داخل
/// مهلته) — تخزين نظام آمن فقط، ولا يُسجَّل ولا يوضع في رابط قط.
/// [replace] استبدال ذري منطقياً: يُكتب الزوج الجديد كاملاً قبل اعتبار التدوير
/// تاماً — الرمز القديم مات على الخادم أصلاً (تدوير لمرة).
library;

import 'dart:convert';

import '../storage/secure_store.dart';
import 'session_tokens.dart';

class SessionTokenStore {
  SessionTokenStore(this._store);

  static const _key = 'lynomia.session';
  final SecureStore _store;

  Future<void> replace(SessionTokens t) => _store.write(
    _key,
    jsonEncode({
      'access_token': t.accessToken,
      'refresh_token': t.refreshToken,
      'session_id': t.sessionId,
      'installation_id': t.installationId,
      'access_expires_at': t.accessExpiresAt?.toIso8601String(),
      'refresh_expires_at': t.refreshExpiresAt?.toIso8601String(),
    }),
  );

  Future<SessionTokens?> read() async {
    final raw = await _store.read(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SessionTokens.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _store.delete(_key);
}
