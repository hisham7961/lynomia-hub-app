/// تجريد الدفع (§73–§75) — صادق: بلا اعتماد مزود لا يُدَّعى نجاح.
///
/// المزوّد الحقيقي `FcmPushProvider` (firebase_messaging) لا يُفعَّل إلا حين
/// تُمرَّر خيارات Firebase عبر `--dart-define` (راجع `docs/OWNER_SETUP.md`)؛
/// وإلا يبقى [NotConfiguredPushProvider] فيقول التطبيق الحقيقة: NOT_CONFIGURED.
/// التسجيل الخادمي (`push/register`/`unregister`) هنا، والتنسيق مع دورة الجلسة
/// والملاحة في `PushCoordinator`.
library;

import '../api/api_client.dart';
import '../security/redacting_logger.dart';
import 'push_message.dart';

enum PushSetupStatus { notConfigured, permissionDenied, ready, registered }

/// مصدر رمز الدفع ورسائله من مزود المنصة.
abstract interface class PushTokenProvider {
  /// `null` = المزود غير مهيأ أو لا رمز بعد (لا اختلاق).
  Future<String?> currentToken();

  /// بث تدوير الرمز (يبقى صامتاً في المزود الصفري).
  Stream<String> get tokenRotations;

  String get providerName; // fcm | apns
  bool get configured;

  /// طلب إذن الإشعار (iOS، وAndroid 13+ `POST_NOTIFICATIONS`) — `true` إن مُنح.
  Future<bool> requestPermission();

  /// رسالة وصلت والتطبيق في المقدّمة (النظام لا يعرضها ⇒ شريطٌ داخلي).
  Stream<PushMessage> get foregroundMessages;

  /// نقرٌ على إشعار أعاد التطبيق من الخلفية.
  Stream<PushMessage> get openedMessages;

  /// الإشعار الذي أطلق التطبيق من حالة الإغلاق (مرة واحدة) أو null.
  Future<PushMessage?> initialMessage();
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

  @override
  Future<bool> requestPermission() async => false;

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;
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

  /// سطر سجلٍّ تقني لفشل التسجيل — نوع الخطأ وحده (لا رمز ولا رسالة خام).
  static String failureLog(Object e) =>
      'تعذر تسجيل الدفع لدى الخادم: ${e.runtimeType}';

  PushSetupStatus _status = PushSetupStatus.notConfigured;
  PushSetupStatus get status => _status;

  /// الرمز المسجَّل فعلاً لدى الخادم (للإلغاء والتدوير) — لا يُسجَّل في السجلات.
  String? _registeredToken;
  String? _platform;

  /// تسجيل رمز المزود لدى الخادم — للجلسة المصادقة فقط (§74).
  Future<PushSetupStatus> registerIfPossible({required String platform}) async {
    if (!provider.configured) {
      _status = PushSetupStatus.notConfigured;
      return _status;
    }
    _platform = platform;
    final token = await provider.currentToken();
    if (token == null) {
      _status = PushSetupStatus.ready;
      return _status;
    }
    await _register(token, platform);
    return _status;
  }

  /// رفض المستخدم الإذن — حالة صادقة، لا تسجيل رمزٍ لن يُعرض إشعاره.
  void markPermissionDenied() {
    if (provider.configured) _status = PushSetupStatus.permissionDenied;
  }

  /// تدوير الرمز من المزوّد (§74): يُسجَّل الجديد ثم يُلغى القديم بهدوء.
  /// لا أثر قبل تسجيلٍ ناجح أول (الجلسة لم تُسجِّل بعد أو رُفض الإذن).
  Future<void> onTokenRotated(String token) async {
    final platform = _platform;
    if (platform == null ||
        (_status != PushSetupStatus.registered &&
            _status != PushSetupStatus.ready) ||
        token == _registeredToken) {
      return;
    }
    final old = _registeredToken;
    await _register(token, platform);
    if (old != null) await _unregister(old);
  }

  Future<void> _register(String token, String platform) async {
    await api.sendData(
      'POST',
      'push/register',
      body: {
        'token': token,
        'platform': platform,
        'provider': provider.providerName,
      },
    );
    _registeredToken = token;
    _status = PushSetupStatus.registered;
    _log.info('سُجل رمز الدفع لدى الخادم');
  }

  /// إلغاء التسجيل عند الخروج (§74) — يتسامح مع الفشل (الخادم يبطل بالخروج أيضاً).
  Future<void> unregisterQuietly() async {
    if (_status != PushSetupStatus.registered) return;
    final token = _registeredToken ?? await provider.currentToken();
    if (token != null) await _unregister(token);
    _registeredToken = null;
    _status = PushSetupStatus.ready;
  }

  /// نسيانٌ محلي بلا شبكة — الجلسة أُبطلت خادمياً (والخادم أبطل رموزها معها).
  void forget() {
    _registeredToken = null;
    if (_status == PushSetupStatus.registered) _status = PushSetupStatus.ready;
  }

  Future<void> _unregister(String token) async {
    try {
      await api.sendData('POST', 'push/unregister', body: {'token': token});
    } on Object catch (e) {
      _log.warn('تعذر إلغاء تسجيل الدفع: ${e.runtimeType}');
    }
  }
}
