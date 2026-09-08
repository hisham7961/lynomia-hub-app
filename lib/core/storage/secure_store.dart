/// المخزن الآمن — واجهة رقيقة فوق تخزين النظام المدعوم عتادياً
/// (iOS Keychain / Android Keystore عبر flutter_secure_storage).
///
/// هنا وحده تعيش الأسرار: رمز التحديث، رمز الوصول، مفتاح تشفير الخبيئة،
/// معرف التنصيب. **لا** SharedPreferences ولا SQLite ولا JSON صريح (§35).
/// النسخ الاحتياطي: iOS بلا ترحيل iCloud للمفاتيح (ThisDeviceOnly)،
/// وAndroid يستبعد التخزين عبر EncryptedSharedPreferences خارج allowBackup
/// (راجع docs/security.md — قرار النسخ الاحتياطي موثق).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll(Iterable<String> keys);
}

class PlatformSecureStore implements SecureStore {
  PlatformSecureStore()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          // لا ترحيل عبر iCloud/نسخ احتياطي — الجهاز الحالي فقط.
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final k in keys) {
      await _storage.delete(key: k);
    }
  }
}
