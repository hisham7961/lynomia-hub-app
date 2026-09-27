/// معرفات التطبيق — المركز الوحيد للمعرفات الخارجية وخريطة مواضعها الأصلية.
///
/// كل ما هنا معرف **تطوير** يكفي للترجمة والتشغيل، وليس جاهزاً للمتاجر:
/// REPLACE_BEFORE_STORE_RELEASE — تُمرَّر القيم النهائية من خارج المستودع
/// (لا تحرير لهذه الثوابت) كما في `docs/OWNER_SETUP.md`:
///
/// | المعرّف | Android | iOS | الخادم |
/// |---|---|---|---|
/// | الحزمة | `-P lynomia.applicationId` / `LYNOMIA_ANDROID_APP_ID` (`android/app/build.gradle.kts`) | `APP_BUNDLE_ID` (`ios/Flutter/AppIdentity.local.xcconfig`) | `mobile.dl_android_package` · `mobile.dl_apple_bundle_id` |
/// | نطاق الروابط | `-P lynomia.appLinkHost` / `LYNOMIA_APP_LINK_HOST` | `APP_LINK_HOST` | `hub.mobile.deep_links.host` (أو `app.url`) |
/// | Team ID | — | `APP_TEAM_ID` | `mobile.dl_apple_team_id` |
/// | بصمة التوقيع | `android/key.properties` (keystore) | — | `mobile.dl_android_fingerprints` |
/// | Firebase | `--dart-define=FIREBASE_*` (`lib/core/push/firebase_env.dart`) | ← نفسه | `mobile.push_*` |
///
/// هذه الثوابت هي **القيم الافتراضية** نفسها في ملفات المنصة — حارس
/// `test/governance_test.dart` يُسقط الحزمة إن تباعدت.
library;

abstract final class AppIdentifiers {
  /// REPLACE_BEFORE_STORE_RELEASE — معرف حزمة Android التطويري (الافتراضي).
  static const androidApplicationId = 'dev.lynomia.lynomia_hub_app';

  /// REPLACE_BEFORE_STORE_RELEASE — معرف حزمة iOS التطويري (الافتراضي).
  static const iosBundleId = 'dev.lynomia.lynomiaHubApp';

  /// REPLACE_BEFORE_STORE_RELEASE — لا Apple Team ID بعد (لا يُختلق).
  static const appleTeamId = 'NOT_CONFIGURED';

  /// REPLACE_BEFORE_STORE_RELEASE — نطاق الروابط العالمية الافتراضي: `.invalid`
  /// محجوزٌ لا يُحلّ أبداً، فالبناء الافتراضي لا يدّعي ربطاً بنطاقٍ حقيقي.
  static const defaultAppLinkHost = 'app-links.lynomia.invalid';

  /// أنماط الروابط العميقة التي يلتقطها التطبيق (عقد الخلفية §08 —
  /// `hub.mobile.deep_links.paths`)، وهي `pathPrefix` في intent-filter.
  static const deepLinkPathPrefixes = ['/m/', '/app/'];

  /// اسم العرض (الإنجليزي/الافتراضي) والعربي — يطابقان `app_name` في
  /// `res/values*/strings.xml` و`InfoPlist.strings` و`appTitle` في ARB.
  static const displayName = 'Lynomia Hub';
  static const displayNameAr = 'لينوميا هب';

  /// قناة إشعار Android التي يسمّيها الخادم (`PushService::ANDROID_CHANNEL`) —
  /// تُنشأ أصلياً في `MainActivity` (`NotificationChannels.DEFAULT_ID`) عند كل
  /// إقلاع، وتسمّيها الـmeta-data الافتراضية لـFCM في المانيفست. iOS بلا قنوات.
  static const androidNotificationChannelId = 'lynomia_default';
}
