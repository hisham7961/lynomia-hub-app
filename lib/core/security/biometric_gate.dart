/// فتح القفل البيومتري — **جانب العميل حصراً** (§40).
///
/// يفتح الوصول للجلسة المخزنة محلياً؛ لا قالب ولا صورة ولا أي معطى حيوي يغادر
/// الجهاز أو يبلغ Lynomia. اختياري، وبسقوط تلقائي لاعتماد الجهاز (PIN/نمط).
library;

import 'package:local_auth/local_auth.dart';

import '../storage/prefs_store.dart';

abstract interface class BiometricGate {
  Future<bool> get available;
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> get available async =>
      await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;

  @override
  Future<bool> authenticate(String reason) => _auth.authenticate(
    localizedReason: reason,
    options: const AuthenticationOptions(
      stickyAuth: true,
      // biometricOnly=false: سقوط لاعتماد الجهاز (PIN) — القفل يبقى محلياً
      biometricOnly: false,
    ),
  );
}

/// تفضيل تفعيل القفل المحلي (علم غير حساس — في PrefsStore).
class BiometricPreference {
  BiometricPreference(this._prefs);

  static const _key = 'biometric_unlock';
  final PrefsStore _prefs;

  Future<bool> get enabled async => await _prefs.get(_key) == true;
  Future<void> setEnabled(bool value) => _prefs.set(_key, value);
}
