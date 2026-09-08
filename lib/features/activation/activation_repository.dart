/// تفعيل حساب العميل (§13) — سكّة `AccountActivation` الخادمية نفسها عبر
/// نقطتَي `/api/mobile/v1/activation/{token}` العامتين.
///
/// العقد: الفحص يعيد `{status: pending|expired, email_masked}` (لا بريد كامل
/// قبل الإثبات)، والإتمام ذرّي (رمز + كلمة يضعها العميل) يعيد
/// `{activated, email}` **بلا جلسة** — الدخول بعده عبر سكّة الدخول الواحدة.
/// لا كلمة سر تُرسل أو تُسجّل هنا أبداً.
library;

import '../../core/api/api_client.dart';

class ActivationStatus {
  const ActivationStatus({required this.status, required this.emailMasked});

  factory ActivationStatus.fromJson(Map<String, dynamic> j) => ActivationStatus(
    status: j['status']?.toString() ?? '',
    emailMasked: j['email_masked']?.toString() ?? '',
  );

  final String status;
  final String emailMasked;

  bool get pending => status == 'pending';
  bool get expired => status == 'expired';
}

class ActivationResult {
  const ActivationResult({required this.activated, required this.email});

  factory ActivationResult.fromJson(Map<String, dynamic> j) => ActivationResult(
    activated: j['activated'] == true,
    email: j['email']?.toString() ?? '',
  );

  final bool activated;

  /// البريد الكامل يُكشف بعد الإثبات فقط — لتعبئة شاشة الدخول.
  final String email;
}

class ActivationRepository {
  ActivationRepository(this.api);

  final ApiClient api;

  Future<ActivationStatus> check(String token) async =>
      ActivationStatus.fromJson(
        await api.getData('activation/$token', auth: AuthMode.none),
      );

  Future<ActivationResult> complete({
    required String token,
    required String otp,
    required String password,
  }) async => ActivationResult.fromJson(
    await api.sendData(
      'POST',
      'activation/$token/complete',
      auth: AuthMode.none,
      body: {
        'otp': otp,
        'password': password,
        'password_confirmation': password,
      },
    ),
  );
}
