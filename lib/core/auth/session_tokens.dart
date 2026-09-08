/// زوج رموز جلسة الجوال كما تعيده `auth/login`/`auth/mfa/verify`/`auth/refresh`.
library;

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.installationId,
    this.accessExpiresAt,
    this.refreshExpiresAt,
  });

  factory SessionTokens.fromJson(Map<String, dynamic> json) => SessionTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    sessionId: json['session_id']?.toString() ?? '',
    installationId: json['installation_id']?.toString() ?? '',
    accessExpiresAt: DateTime.tryParse(
      json['access_expires_at']?.toString() ?? '',
    ),
    refreshExpiresAt: DateTime.tryParse(
      json['refresh_expires_at']?.toString() ?? '',
    ),
  );

  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final String installationId;
  final DateTime? accessExpiresAt;
  final DateTime? refreshExpiresAt;

  bool accessExpired({Duration slack = const Duration(seconds: 20)}) {
    final exp = accessExpiresAt;
    if (exp == null) return false;
    return DateTime.now().toUtc().add(slack).isAfter(exp.toUtc());
  }
}
