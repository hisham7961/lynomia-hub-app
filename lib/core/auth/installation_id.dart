/// معرف التنصيب (§29): UUID عشوائي يُولَّد عند أول تشغيل ويثبت في المخزن الآمن.
///
/// لا IMEI ولا معرف إعلانات ولا بصمة عتاد — عشوائية خالصة. يُرسل في الدخول
/// (`installation_uuid`) وترويسة `X-Lynomia-Installation-Id` (تليمتري لا تخويل).
library;

import 'package:uuid/uuid.dart';

import '../storage/secure_store.dart';

class InstallationId {
  InstallationId(this._store);

  static const _key = 'lynomia.installation_uuid';
  final SecureStore _store;
  String? _cached;

  Future<String> ensure() async {
    if (_cached != null) return _cached!;
    final existing = await _store.read(_key);
    if (existing != null && existing.isNotEmpty) return _cached = existing;
    final fresh = const Uuid().v4();
    await _store.write(_key, fresh);
    return _cached = fresh;
  }
}
