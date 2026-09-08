/// تجريد الدفع (§73–§75) — صادق: بلا اعتماد مزود لا يُدَّعى نجاح.
///
/// لا حزمة FCM/APNs في المستودع عمداً: الاعتماد الخارجي غير متوفر بعد
/// (BLOCKED_EXTERNAL_CONFIG)، والتطبيق يترجم ويعمل بدونه. عند توفره يُضاف
/// منفذ [PushTokenProvider] حقيقي (firebase_messaging أو APNs مباشر) دون مساس
/// ببقية الشيفرة — التسجيل الخادمي (`push/register`/`unregister`) جاهز هنا.
library;

import '../api/api_client.dart';
import '../security/redacting_logger.dart';

enum PushSetupStatus { notConfigured, ready, registered }

/// مصدر رمز الدفع من مزود المنصة.
abstract interface class PushTokenProvider {
  /// `null` = المزود غير مهيأ (لا اختلاق).
  Future<String?> currentToken();

  /// بث تدوير الرمز (يبقى صامتاً في المزود الصفري).
  Stream<String> get tokenRotations;

  String get providerName; // fcm | apns
  bool get configured;
}

/// المزود الصفري — الحقيقة عند غياب الاعتماد: NOT_CONFIGURED.
class NotConfiguredPushProvider implements PushTokenProvider {
  const NotConfiguredPushProvider();

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get tokenRotations => const Stream.empty();

  @override
  String get providerName => 'fcm';

  @override
  bool get configured => false;
}

class PushRegistrar {
  PushRegistrar({
    required this.api,
    required this.provider,
    RedactingLogger? log,
  }) : _log = log ?? RedactingLogger();

  final ApiClient api;
  final PushTokenProvider provider;
  final RedactingLogger _log;

  PushSetupStatus _status = PushSetupStatus.notConfigured;
  PushSetupStatus get status => _status;

  /// تسجيل رمز المزود لدى الخادم — للجلسة المصادقة فقط (§74).
  Future<PushSetupStatus> registerIfPossible({required String platform}) async {
    if (!provider.configured) {
      _status = PushSetupStatus.notConfigured;
      return _status;
    }
    final token = await provider.currentToken();
    if (token == null) {
      _status = PushSetupStatus.ready;
      return _status;
    }
    await api.sendData(
      'POST',
      'push/register',
      body: {
        'token': token,
        'platform': platform,
        'provider': provider.providerName,
      },
    );
    _status = PushSetupStatus.registered;
    _log.info('سُجل رمز الدفع لدى الخادم');
    return _status;
  }

  /// إلغاء التسجيل عند الخروج (§74) — يتسامح مع الفشل (الخادم يبطل بالخروج أيضاً).
  Future<void> unregisterQuietly() async {
    if (_status != PushSetupStatus.registered) return;
    final token = await provider.currentToken();
    if (token == null) return;
    try {
      await api.sendData('POST', 'push/unregister', body: {'token': token});
    } on Object catch (e) {
      _log.warn('تعذر إلغاء تسجيل الدفع: ${e.runtimeType}');
    }
    _status = PushSetupStatus.ready;
  }
}
