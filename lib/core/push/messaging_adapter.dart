/// منفذ المراسلة (FCM) مجرّداً عن الـSDK — ليُختبر المزوّد بمحوِّلٍ مزيّف
/// (`test/fakes/`) دون قناة منصة ولا Firebase.
library;

import 'push_message.dart';

abstract interface class MessagingAdapter {
  /// يطلب الإذن ويعيد `true` إن مُنح (أو مُنح مؤقتاً على iOS).
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onForegroundMessage;

  Stream<PushMessage> get onMessageOpenedApp;

  Future<PushMessage?> getInitialMessage();
}
