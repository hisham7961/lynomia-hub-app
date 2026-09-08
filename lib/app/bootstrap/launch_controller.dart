/// آلة الإقلاع الحتمية (§28) — لا شاشة انتظار لا نهائية، وكل فشل حالة صريحة.
///
/// ```
/// بدء ← بيئة ← معرف تنصيب ← app-config ← بوابة صيانة/إصدار ← جلسة مخزنة
///   ← (قفل بيومتري اختياري) ← تحديث إن لزم ← bootstrap ← غلاف مصادق | دخول
/// ```
library;

import 'package:flutter/foundation.dart';

import '../../core/api/view_context.dart';
import '../../core/auth/session_manager.dart';
import '../../core/config/app_env.dart';
import '../../core/errors/api_exception.dart';
import '../../core/security/biometric_gate.dart';
import '../../features/launch/app_config_repository.dart';
import '../../features/launch/bootstrap_repository.dart';
import 'account_state.dart';

sealed class LaunchState {
  const LaunchState();
}

class LaunchLoading extends LaunchState {
  const LaunchLoading();
}

/// فشل إعداد بيئة (إنتاج بلا HTTPS مثلاً) — حالة نهائية صريحة.
class LaunchConfigError extends LaunchState {
  const LaunchConfigError(this.message);
  final String message;
}

/// تعذر الوصول للخادم قبل الدخول — قابلة لإعادة المحاولة.
class LaunchOffline extends LaunchState {
  const LaunchOffline();
}

class LaunchMaintenance extends LaunchState {
  const LaunchMaintenance({this.message, this.lockdown = false});
  final String? message;
  final bool lockdown;
}

/// تحديث إلزامي (§46) — حاجبة.
class LaunchUpdateRequired extends LaunchState {
  const LaunchUpdateRequired(this.config);
  final AppConfig config;
}

/// قفل بيومتري بانتظار الفتح (§40).
class LaunchLocked extends LaunchState {
  const LaunchLocked();
}

class LaunchLoggedOut extends LaunchState {
  const LaunchLoggedOut();
}

class LaunchReady extends LaunchState {
  const LaunchReady();
}

class LaunchController extends ChangeNotifier {
  LaunchController({
    required this.env,
    required this.appConfigRepo,
    required this.bootstrapRepo,
    required this.session,
    required this.account,
    required this.viewContext,
    required this.biometricPref,
    required this.biometricGate,
  });

  final AppEnv env;
  final AppConfigRepository appConfigRepo;
  final BootstrapRepository bootstrapRepo;
  final SessionManager session;
  final AccountState account;
  final ViewContext viewContext;
  final BiometricPreference biometricPref;
  final BiometricGate biometricGate;

  LaunchState _state = const LaunchLoading();
  AppConfig? appConfig;

  LaunchState get state => _state;

  void _set(LaunchState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> start() async {
    _set(const LaunchLoading());

    // (١) البيئة — بوابة الأمان قبل أي شبكة.
    try {
      env.validate();
    } on AppEnvError catch (e) {
      _set(LaunchConfigError(e.message));
      return;
    }

    // (٢) app-config العامة — صيانة/قفل/بوابة إصدار (§45).
    try {
      appConfig = await appConfigRepo.fetch();
    } on NetworkException {
      _set(const LaunchOffline());
      return;
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.maintenance ||
          e.code == ApiErrorCode.lockdown) {
        _set(
          LaunchMaintenance(
            message: e.message,
            lockdown: e.code == ApiErrorCode.lockdown,
          ),
        );
        return;
      }
      _set(const LaunchOffline());
      return;
    }

    final cfg = appConfig!;
    if (cfg.lockdown || cfg.maintenance) {
      _set(
        LaunchMaintenance(
          message: cfg.maintenanceMessage,
          lockdown: cfg.lockdown,
        ),
      );
      return;
    }
    if (cfg.blocksUsage) {
      _set(LaunchUpdateRequired(cfg));
      return;
    }

    // (٣) الجلسة الآمنة المخزنة.
    final restored = await session.restore();
    if (!restored) {
      _set(const LaunchLoggedOut());
      return;
    }

    // (٤) القفل البيومتري المحلي الاختياري (§40).
    if (await biometricPref.enabled && await biometricGate.available) {
      _set(const LaunchLocked());
      return; // يستأنف عبر [unlock]
    }

    await _enterAuthenticated();
  }

  /// محاولة الفتح البيومتري من شاشة القفل.
  Future<void> unlock(String localizedReason) async {
    if (await biometricGate.authenticate(localizedReason)) {
      await _enterAuthenticated();
    }
  }

  /// (٥) bootstrap ثم الغلاف المصادق — يجدد الرمز ضمنياً إن لزم.
  Future<void> _enterAuthenticated() async {
    try {
      await account.loadBootstrap();
      _set(const LaunchReady());
    } on ApiException catch (e) {
      if (e.isAuthError) {
        await session.end(SessionEndReason.expired);
        _set(const LaunchLoggedOut());
        return;
      }
      if (e.code == ApiErrorCode.appUpdateRequired) {
        _set(LaunchUpdateRequired(appConfig!));
        return;
      }
      if (e.code == ApiErrorCode.accountRestricted) {
        await session.end(SessionEndReason.restricted);
        _set(const LaunchLoggedOut());
        return;
      }
      _set(const LaunchOffline());
    } on NetworkException {
      _set(const LaunchOffline());
    }
  }

  /// بعد دخول ناجح من شاشة المصادقة.
  Future<void> onSignedIn() => _enterAuthenticated();

  /// عودة لشاشة الدخول (خروج/إبطال).
  void onSignedOut() => _set(const LaunchLoggedOut());
}
