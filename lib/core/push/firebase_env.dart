/// خيارات Firebase من `--dart-define` — لا `google-services.json` ولا
/// `GoogleService-Info.plist` في المستودع (CLAUDE.md: لا أسرار/اعتمادات).
///
/// ```
/// --dart-define=FIREBASE_PROJECT_ID=…            (مشترك)
/// --dart-define=FIREBASE_MESSAGING_SENDER_ID=…   (مشترك — رقم المشروع)
/// --dart-define=FIREBASE_STORAGE_BUCKET=…        (اختياري)
/// --dart-define=FIREBASE_ANDROID_API_KEY=…  --dart-define=FIREBASE_ANDROID_APP_ID=…
/// --dart-define=FIREBASE_IOS_API_KEY=…      --dart-define=FIREBASE_IOS_APP_ID=…
/// --dart-define=FIREBASE_IOS_BUNDLE_ID=…    (يطابق APP_BUNDLE_ID في xcconfig)
/// ```
/// أو دفعةً واحدة: `--dart-define-from-file=firebase.defines.json` (مُتجاهَل في
/// git؛ القالب `firebase.defines.example.json`). أي حقلٍ إلزاميٍّ ناقص للمنصة
/// الجارية ⇒ غير مهيأ ⇒ `NotConfiguredPushProvider` (حالة صادقة، لا تعطّل).
library;

enum FirebasePlatform { android, ios }

class FirebaseEnv {
  const FirebaseEnv({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.storageBucket,
    this.iosBundleId,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? storageBucket;
  final String? iosBundleId;

  /// القيم المحقونة وقت البناء.
  static const Map<String, String> compiledDefines = {
    'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    'FIREBASE_STORAGE_BUCKET': String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    ),
    'FIREBASE_ANDROID_API_KEY': String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
    ),
    'FIREBASE_ANDROID_APP_ID': String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
    ),
    'FIREBASE_IOS_API_KEY': String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    'FIREBASE_IOS_APP_ID': String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    'FIREBASE_IOS_BUNDLE_ID': String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
  };

  /// الخيارات المكتملة للمنصة أو `null` (غير مهيأ). [defines] للاختبار.
  static FirebaseEnv? resolve(
    FirebasePlatform platform, {
    Map<String, String> defines = compiledDefines,
  }) {
    String? v(String k) {
      final s = defines[k]?.trim();
      // قيمة القالب (firebase.defines.example.json) ليست إعداداً.
      if (s == null ||
          s.isEmpty ||
          s.contains('REPLACE_BEFORE_STORE_RELEASE')) {
        return null;
      }
      return s;
    }

    final prefix = platform == FirebasePlatform.ios ? 'IOS' : 'ANDROID';
    final apiKey = v('FIREBASE_${prefix}_API_KEY');
    final appId = v('FIREBASE_${prefix}_APP_ID');
    final sender = v('FIREBASE_MESSAGING_SENDER_ID');
    final project = v('FIREBASE_PROJECT_ID');
    if (apiKey == null || appId == null || sender == null || project == null) {
      return null;
    }
    // معرّف التطبيق في Firebase يحمل المنصة (`1:<sender>:android:<hash>`) —
    // خلطُ المنصتين خطأ إعدادٍ يُرفض هنا لا فشلٌ غامض في SDK.
    final platformTag = platform == FirebasePlatform.ios
        ? ':ios:'
        : ':android:';
    if (!appId.contains(platformTag)) return null;
    return FirebaseEnv(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: sender,
      projectId: project,
      storageBucket: v('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: platform == FirebasePlatform.ios
          ? v('FIREBASE_IOS_BUNDLE_ID')
          : null,
    );
  }

  /// أسماء المفاتيح الإلزامية للمنصة — لرسائل التشخيص والوثائق.
  static List<String> requiredKeys(FirebasePlatform platform) {
    final prefix = platform == FirebasePlatform.ios ? 'IOS' : 'ANDROID';
    return [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_${prefix}_API_KEY',
      'FIREBASE_${prefix}_APP_ID',
    ];
  }
}
