/// مزوّد FCM الحقيقي خلف [PushTokenProvider] — لا يستورد Firebase مباشرةً:
/// كل نداء SDK عبر [MessagingAdapter]، فالمنطق هنا مختبرٌ بمحوِّلٍ مزيّف.
library;

import '../security/redacting_logger.dart';
import 'messaging_adapter.dart';
import 'push_message.dart';
import 'push_registrar.dart';

class FcmPushProvider implements PushTokenProvider {
  FcmPushProvider(this._adapter, {RedactingLogger? log})
    : _log = log ?? RedactingLogger();

  final MessagingAdapter _adapter;
  final RedactingLogger _log;

  @override
  String get providerName => 'fcm';

  @override
  bool get configured => true;

  /// على iOS قد يعيد `getToken` خطأً قبل وصول رمز APNs — يُعامَل «لا رمز بعد»
  /// (يصل لاحقاً عبر [tokenRotations]) لا عطلاً.
  @override
  Future<String?> currentToken() async {
    try {
      final t = await _adapter.getToken();
      return (t == null || t.isEmpty) ? null : t;
    } on Object catch (e) {
      _log.warn('تعذر جلب رمز FCM: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Stream<String> get tokenRotations =>
      _adapter.onTokenRefresh.where((t) => t.isNotEmpty);

  @override
  Future<bool> requestPermission() async {
    try {
      return await _adapter.requestPermission();
    } on Object catch (e) {
      _log.warn('تعذر طلب إذن الإشعار: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Stream<PushMessage> get foregroundMessages => _adapter.onForegroundMessage;

  @override
  Stream<PushMessage> get openedMessages => _adapter.onMessageOpenedApp;

  @override
  Future<PushMessage?> initialMessage() async {
    try {
      return await _adapter.getInitialMessage();
    } on Object {
      return null;
    }
  }
}
