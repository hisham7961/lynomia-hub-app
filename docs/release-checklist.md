# قائمة فحص الإطلاق (§145 — الإعداد الخارجي المتبقي)

كلها **مدخلاتٌ خارجية** — البنية مبنيّةٌ وقابلةٌ للضبط منذ v0.7.0، والتطبيق يُبنى ويعمل بدونها بحالات صادقة.
كل بندٍ يشير إلى خطواته الدقيقة في `docs/OWNER_SETUP.md` (§ بين القوسين).

## ما بُني في التطبيق (v0.7.0) — لا عمل شيفرة متبقٍّ لهذه البنود

- [x] الروابط العالمية: `intent-filter` بـ`autoVerify` (`/m/*`, `/app/*`) بنطاقٍ محقون من Gradle، و`Runner.entitlements`
      بـ`applinks:$(APP_LINK_HOST)` موصولٌ لإعدادات Runner الثلاثة؛ الرابط قبل الدخول يُحفظ ويُفتح بعده
- [x] الدفع FCM: `FcmPushProvider` خلف الواجهة القائمة، Firebase يُهيَّأ من `--dart-define` فقط؛ الإذن، التسجيل
      بعد الجاهزية وعند التدوير، الإلغاء عند الخروج، شريط المقدّمة، فتح الهدف، التجريبي بلا ملاحة، الشارة من `unread`
- [x] iOS: `aps-environment` (development/production آلياً) + `UIBackgroundModes: remote-notification`
- [x] المعرّفات قابلة للضبط بلا تحرير شيفرة (Gradle property/env، xcconfig محلي) — مركزها `lib/core/config/app_identifiers.dart`
- [x] توقيع الإصدار من `android/key.properties` (قالب `key.properties.example`)؛ الغياب ⇒ debug محلياً بتحذير، وفشلٌ مع `requireReleaseSigning`
- [x] `allowBackup=false` + `dataExtractionRules` + `fullBackupContent` تستثني كل النطاقات
- [x] أيقونة العلامة (كل مقاسات Android + تكيّفية/monochrome، وكل مقاسات iOS) وشاشة البداية (Android ≤11 و12+، iOS)
- [x] الاسم المعروض معرَّباً (ar/en) + `CFBundleLocalizations`
- [x] CI: `.github/workflows/app.yml` (بوابة + APK debug + AAB موقَّع عند توفر الأسرار + iOS بلا توقيع)

## معرّفات المتاجر (REPLACE_BEFORE_STORE_RELEASE)

- [ ] معرّف حزمة Android النهائي ⇒ `LYNOMIA_ANDROID_APP_ID` / `-P lynomia.applicationId` (§٤، §٦)
- [ ] Apple Team ID + Bundle ID ⇒ `ios/Flutter/AppIdentity.local.xcconfig` (§٣)؛ App ID بقدرتَي Push + Associated Domains
- [ ] keystore الرفع + `android/key.properties` محلياً + أسرار CI الأربعة (§٥، §٦)
- [ ] (اختياري) استبدال الأيقونة المولَّدة بتصميم المصمم النهائي بالمقاسات نفسها (§٧)
- [ ] App Store ID + روابط المتجرين ⇒ `mobile.store_url_*` (§٨، §٩)

## الدفع

- [ ] مشروع Firebase + تطبيقا Android/iOS بالمعرّفات النهائية ⇒ `firebase.defines.json` (§١) و`FIREBASE_DEFINES_JSON` في CI
- [ ] مفتاح APNs (`.p8`) مرفوعٌ إلى Firebase (§٢)
- [ ] الخادم: `mobile.push_driver=fcm` + `push_fcm_project_id` + `push_fcm_access_token` ⇒ `GET push/admin/status` = configured (§١-٦)
- [ ] ⚠️ تجديد رمز الوصول (ساعة واحدة) — طلب خلفي **#9**؛ مؤقتاً cron (§١-٦)
- [ ] إشعار تجريبي من مركز المنصة يصل للجهازين (المقدّمة: شريط؛ الخلفية: إشعار نظام) (§١-٧)

## الروابط العالمية

- [ ] النطاق النهائي ⇒ `LYNOMIA_APP_LINK_HOST` / `APP_LINK_HOST`، ويطابق `hub.mobile.deep_links.host` (أو `APP_URL`) (§٠)
- [ ] `mobile.dl_apple_team_id` + `dl_apple_bundle_id` (§٣)
- [ ] `mobile.dl_android_package` + `dl_android_fingerprints` (بصمة الرفع **و**بصمة Play App Signing) (§٤)
- [ ] `/.well-known/*` ⇒ `X-Deep-Links-Status: CONFIGURED`؛ و`adb shell pm get-app-links` ⇒ verified (§٣-٥، §٤-٤)

## بوابة الإصدار والدعم

- [ ] `mobile.min_version_*` / `latest_version_*` / `force_update` عند الحاجة (§٩)
- [ ] `mobile.support_url` (§٩)

## قرارات أمنية [م] (`docs/security.md` §قرارات المرحلة ٥.٥)

- [ ] سلامة الجهاز (Play Integrity / App Attest): الموصى به **رصدٌ لا فرض** في v1.0
- [ ] تثبيت الشهادات: الموصى به **لا تثبيت** في v1.0
- [ ] سياسة البصمة: الموصى به **اختيارية للمستخدم** (قائمة اليوم)

## القطع النهائي

- [ ] `dart format --set-exit-if-changed .` + `flutter analyze` + `flutter test` خضراء
- [ ] AAB موقَّع (CI أو محلياً بـ`requireReleaseSigning=true`) + IPA موقَّع من Xcode/`flutter build ipa`
- [ ] اختبار تكاملي على محاكي Android وجهاز iOS: دخول، رابط عالمي بارد/حي، إشعار تجريبي ونقرة إشعار بوجهة، بصمة
- [ ] مراجعة أذونات AndroidManifest النهائية (كاميرا/موقع/إشعارات فقط §88)
- [ ] `tool/update_contracts.sh` على HEAD الخلفية النهائي + اختبارات العقد خضراء
- [ ] صفحتا المتجرين: الوصف، اللقطات (iPhone + iPad)، الخصوصية/Data safety، حساب المراجِع (§٨)
