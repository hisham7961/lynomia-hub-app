/// مستودع المصادقة — تدفقات `auth/*` كاملة على العقد الفعلي (§32–§41).
library;

import 'dart:io' show Platform;

import '../api/api_client.dart';
import '../errors/api_exception.dart';
import '../telemetry/app_info.dart';
import 'installation_id.dart';
import 'session_tokens.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.isOwner = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString(),
    isOwner: json['is_owner'] == true,
  );

  final String id;
  final String name;
  final String email;
  final String? role;

  /// **عرض فقط** — الخادم لا يثق به ويعيد فحص الملكية في كل نقطة.
  final bool isOwner;
}

/// نتيجة الدخول: جلسة، أو تحدي MFA.
sealed class LoginOutcome {
  const LoginOutcome();
}

class LoginSession extends LoginOutcome {
  const LoginSession(this.tokens, this.user);
  final SessionTokens tokens;
  final AuthUser user;
}

class LoginMfaChallenge extends LoginOutcome {
  const LoginMfaChallenge({
    required this.challengeId,
    required this.methods,
    this.expiresAt,
  });
  final String challengeId;
  final List<String> methods;
  final DateTime? expiresAt;
}

class MobileSessionInfo {
  const MobileSessionInfo({
    required this.id,
    this.platform,
    this.appVersion,
    this.createdAt,
    this.lastUsedAt,
    this.current = false,
  });

  factory MobileSessionInfo.fromJson(
    Map<String, dynamic> j, {
    String? currentId,
  }) => MobileSessionInfo(
    id: j['id']?.toString() ?? '',
    platform: j['platform']?.toString(),
    appVersion: j['app_version']?.toString(),
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    lastUsedAt: DateTime.tryParse(
      (j['last_used_at'] ?? j['last_seen_at'])?.toString() ?? '',
    ),
    current:
        j['current'] == true ||
        (currentId != null && j['id']?.toString() == currentId),
  );

  final String id;
  final String? platform;
  final String? appVersion;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final bool current;
}

class AuthRepository {
  AuthRepository({required this.api, required this.installation});

  final ApiClient api;
  final InstallationId installation;

  /// هوية العميل من عميل API الواحد — تبقى حية بعد تحميلها المتأخر.
  AppInfo? get _appInfo => api.appInfo;

  String get _platform =>
      _appInfo?.platform ?? (Platform.isIOS ? 'ios' : 'android');

  /// `POST auth/login` — نجاح ⇒ جلسة؛ `MFA_REQUIRED` ⇒ تحدٍ (ليس خطأ للمستدعي).
  Future<LoginOutcome> login({
    required String email,
    required String password,
    String? locale,
    String? timezone,
    String? deviceModel,
    String? osVersion,
  }) async {
    try {
      final data = await api.sendData(
        'POST',
        'auth/login',
        auth: AuthMode.none,
        body: {
          'email': email,
          'password': password,
          'installation_uuid': await installation.ensure(),
          'platform': _platform,
          'app_version': ?_appInfo?.version,
          'app_build': ?_appInfo?.build,
          'device_model': ?deviceModel,
          'os_version': ?osVersion,
          'locale': ?locale,
          'tz': ?timezone,
        },
      );
      return _session(data);
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.mfaRequired && e.mfaChallengeId != null) {
        return LoginMfaChallenge(
          challengeId: e.mfaChallengeId!,
          methods: e.mfaMethods,
          expiresAt: DateTime.tryParse(
            e.details['expires_at']?.toString() ?? '',
          ),
        );
      }
      rethrow;
    }
  }

  /// `POST auth/mfa/verify` — فشل الرمز يعود `MFA_REQUIRED` (التحدي حي ضمن مهلته).
  Future<LoginSession> mfaVerify({
    required String challengeId,
    required String code,
  }) async {
    final data = await api.sendData(
      'POST',
      'auth/mfa/verify',
      auth: AuthMode.none,
      body: {'challenge_id': challengeId, 'code': code},
    );
    return _session(data);
  }

  LoginSession _session(Map<String, dynamic> data) => LoginSession(
    SessionTokens.fromJson(data),
    AuthUser.fromJson(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  /// `POST auth/refresh` — يستدعيه [SessionManager] حصراً (تسلسل §36).
  Future<SessionTokens> refreshCall(String refreshToken) async {
    final data = await api.sendData(
      'POST',
      'auth/refresh',
      auth: AuthMode.none,
      body: {'refresh_token': refreshToken},
    );
    return SessionTokens.fromJson(data);
  }

  Future<void> logout() => api.sendData('POST', 'auth/logout');

  Future<void> logoutAll() => api.sendData('POST', 'auth/logout-all');

  Future<List<MobileSessionInfo>> sessions({String? currentId}) async {
    final resp = await api.send(ApiRequest('GET', 'auth/sessions'));
    final list = resp.dataMap['sessions'] as List? ?? resp.dataList;
    return list
        .whereType<Map>()
        .map(
          (e) => MobileSessionInfo.fromJson(
            e.cast<String, dynamic>(),
            currentId: currentId,
          ),
        )
        .toList();
  }

  Future<void> revokeSession(String id) =>
      api.sendData('DELETE', 'auth/sessions/$id');

  /// `POST auth/step-up` — منحة مربوطة بـ(الجلسة+الغرض+المهلة) (§41).
  Future<void> stepUp({required String purpose, required String credential}) =>
      api.sendData(
        'POST',
        'auth/step-up',
        body: {'purpose': purpose, 'credential': credential},
      );
}
