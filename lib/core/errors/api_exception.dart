/// نموذج خطأ API الواحد — التفريع على `code` الآلي حصراً، لا على نص الرسالة.
///
/// الغلاف الخادمي: `{error, code, message, details, request_id}` + ترويستا
/// `X-Error-Code` و`X-Request-Id` (عقد `Api::error`). `request_id` يُحفظ دائماً
/// للعرض التقني والدعم.
library;

/// الأكواد الآلية المعروفة لعقد `/api/mobile/v1` (سجل القدرات: error_codes).
enum ApiErrorCode {
  unauthenticated('UNAUTHENTICATED'),
  accountRestricted('ACCOUNT_RESTRICTED'),
  forbidden('FORBIDDEN'),
  insufficientScope('INSUFFICIENT_SCOPE'),
  resourceNotFound('RESOURCE_NOT_FOUND'),
  methodNotAllowed('METHOD_NOT_ALLOWED'),
  validationFailed('VALIDATION_FAILED'),
  conflict('CONFLICT'),
  versionConflict('VERSION_CONFLICT'),
  approvalRequired('APPROVAL_REQUIRED'),
  idempotencyInProgress('IDEMPOTENCY_IN_PROGRESS'),
  idempotencyKeyReused('IDEMPOTENCY_KEY_REUSED'),
  payloadTooLarge('PAYLOAD_TOO_LARGE'),
  locked('LOCKED'),
  stepUpRequired('STEP_UP_REQUIRED'),
  rateLimited('RATE_LIMITED'),
  businessRuleViolation('BUSINESS_RULE_VIOLATION'),
  integrationUnavailable('INTEGRATION_UNAVAILABLE'),
  maintenance('MAINTENANCE'),
  lockdown('LOCKDOWN'),
  serviceUnavailable('SERVICE_UNAVAILABLE'),
  internalError('INTERNAL_ERROR'),
  mfaRequired('MFA_REQUIRED'),
  refreshTokenInvalid('REFRESH_TOKEN_INVALID'),
  sessionRevoked('SESSION_REVOKED'),
  appUpdateRequired('APP_UPDATE_REQUIRED'),

  /// كود لم يعرفه هذا الإصدار — يُعامل معاملة خطأ عام دون انهيار.
  unknown('UNKNOWN');

  const ApiErrorCode(this.wire);

  /// القيمة كما تصل على السلك.
  final String wire;

  static ApiErrorCode parse(String? raw) {
    if (raw == null || raw.isEmpty) return ApiErrorCode.unknown;
    for (final c in ApiErrorCode.values) {
      if (c.wire == raw) return c;
    }
    return ApiErrorCode.unknown;
  }
}

class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.httpStatus,
    this.message = '',
    this.details = const {},
    this.requestId,
    this.rawCode,
  });

  final ApiErrorCode code;
  final int httpStatus;

  /// الرسالة العربية الخادمية — **للعرض فقط**، لا يُفرَّع عليها.
  final String message;
  final Map<String, dynamic> details;
  final String? requestId;

  /// الكود الخام كما ورد (يفيد حين يكون [code] == unknown).
  final String? rawCode;

  /// أخطاء 422 لكل حقل: `details.errors = {field: [msgs]}` (شكل Laravel).
  Map<String, List<String>> get fieldErrors {
    final errs = details['errors'];
    if (errs is! Map) return const {};
    return errs.map(
      (k, v) => MapEntry(
        k.toString(),
        v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
      ),
    );
  }

  /// تعارض النسخة: `details = {current_version, your_version}`.
  int? get serverVersion => switch (details['current_version']) {
    final int v => v,
    final String s => int.tryParse(s),
    _ => null,
  };

  /// تحدي MFA عند `MFA_REQUIRED`.
  String? get mfaChallengeId => details['challenge_id']?.toString();
  List<String> get mfaMethods => (details['methods'] as List? ?? const [])
      .map((e) => e.toString())
      .toList();

  /// وجهة الموافقة المصفوفة عند `APPROVAL_REQUIRED` (202): `details.approval`.
  Map<String, dynamic>? get approvalTarget => details['approval'] is Map
      ? (details['approval'] as Map).cast<String, dynamic>()
      : null;

  bool get isAuthError =>
      code == ApiErrorCode.unauthenticated ||
      code == ApiErrorCode.sessionRevoked ||
      code == ApiErrorCode.refreshTokenInvalid;

  @override
  String toString() =>
      'ApiException(${code.wire}${code == ApiErrorCode.unknown ? '/$rawCode' : ''} '
      'http=$httpStatus rid=$requestId)';
}

/// فشل نقل (شبكة/مهلة/انقطاع) — قابل لإعادة المحاولة حيث يكون ذلك آمناً.
class NetworkException implements Exception {
  NetworkException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'NetworkException: $message';
}
