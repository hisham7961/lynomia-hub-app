/// إقلاع الدفع الحقيقي — الملف الوحيد الذي يستورد Firebase.
///
/// Firebase يُهيَّأ **فقط** حين تكتمل خياراته في `--dart-define`
/// ([FirebaseEnv]) — لا ملفات `google-services`، ولا إضافة Gradle لها. وأي فشلٍ
/// في التهيئة يعيد [NotConfiguredPushProvider]: التطبيق يعمل، والحالة صادقة.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../security/redacting_logger.dart';
import 'fcm_push_provider.dart';
import 'firebase_env.dart';
import 'messaging_adapter.dart';
import 'push_message.dart';
import 'push_registrar.dart';

Future<PushTokenProvider> bootPushProvider(RedactingLogger log) async {
  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.android => FirebasePlatform.android,
    TargetPlatform.iOS => FirebasePlatform.ios,
    _ => null,
  };
  if (kIsWeb || platform == null) return const NotConfiguredPushProvider();
  final env = FirebaseEnv.resolve(platform);
  if (env == null) {
    log.info('الدفع غير مهيأ — خيارات Firebase غائبة (NOT_CONFIGURED)');
    return const NotConfiguredPushProvider();
  }
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: env.apiKey,
        appId: env.appId,
        messagingSenderId: env.messagingSenderId,
        projectId: env.projectId,
        storageBucket: env.storageBucket,
        iosBundleId: env.iosBundleId,
      ),
    );
    final messaging = FirebaseMessaging.instance;
    // المقدّمة: لا تنبيه نظامي — الشريط الداخلي يعرضها (والشارة تُحدَّث).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
    return FcmPushProvider(FirebaseMessagingAdapter(messaging), log: log);
  } on Object catch (e) {
    log.warn('تعذرت تهيئة Firebase — الدفع NOT_CONFIGURED: ${e.runtimeType}');
    return const NotConfiguredPushProvider();
  }
}

class FirebaseMessagingAdapter implements MessagingAdapter {
  FirebaseMessagingAdapter(this._m);

  final FirebaseMessaging _m;

  @override
  Future<bool> requestPermission() async {
    final s = await _m.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _m.getToken();

  @override
  Stream<String> get onTokenRefresh => _m.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_convert);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_convert);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final m = await _m.getInitialMessage();
    return m == null ? null : _convert(m);
  }

  static PushMessage _convert(RemoteMessage m) => PushMessage(
    title: m.notification?.title,
    body: m.notification?.body,
    data: {
      for (final e in m.data.entries)
        if (e.value != null) e.key: e.value.toString(),
    },
  );
}
