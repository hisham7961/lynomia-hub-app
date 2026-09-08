/// بيئة التشغيل — تُحقن وقت البناء عبر:
/// `--dart-define=APP_ENV=dev|staging|prod --dart-define=API_BASE_URL=https://…`
///
/// الإنتاج يرفض الإعداد غير الآمن بنيوياً: مضيف غائب أو HTTP صريح ⇒ فشل إقلاع
/// مبكر واضح، لا سقوط صامت على نطاق مزيف. التطوير يجيز HTTP المحلي صراحةً.
library;

enum AppEnvKind { dev, staging, prod }

class AppEnvError implements Exception {
  AppEnvError(this.message);
  final String message;

  @override
  String toString() => 'AppEnvError: $message';
}

class AppEnv {
  const AppEnv({required this.kind, required this.apiBaseUrl});

  /// القيم المحقونة وقت البناء (تبقى ثابتة طوال عمر العملية).
  factory AppEnv.fromDefines() => AppEnv(
    kind: switch (const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    )) {
      'prod' || 'production' => AppEnvKind.prod,
      'staging' => AppEnvKind.staging,
      _ => AppEnvKind.dev,
    },
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: ''),
  );

  final AppEnvKind kind;

  /// أصل الخادم بلا مسار، مثل `https://hub.example.com` — يُلحق به `/api/mobile/v1`.
  final String apiBaseUrl;

  bool get isProd => kind == AppEnvKind.prod;

  Uri get apiRoot => Uri.parse(apiBaseUrl);

  Uri get mobileApiBase => apiRoot.replace(
    path: '${apiRoot.path.replaceAll(RegExp(r'/+$'), '')}/api/mobile/v1',
  );

  /// بوابة الأمان: تُستدعى قبل أي استخدام للشبكة.
  void validate() {
    if (apiBaseUrl.isEmpty) {
      throw AppEnvError('API_BASE_URL غائب — مرره عبر --dart-define');
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw AppEnvError('API_BASE_URL غير صالح: $apiBaseUrl');
    }
    if (isProd && uri.scheme != 'https') {
      throw AppEnvError('الإنتاج يتطلب HTTPS — رفض $apiBaseUrl');
    }
    if (!isProd && uri.scheme != 'https' && uri.scheme != 'http') {
      throw AppEnvError('مخطط غير مدعوم: ${uri.scheme}');
    }
  }
}
