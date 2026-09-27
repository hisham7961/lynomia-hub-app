# إعداد المالك — من البناء التطويري إلى المتاجر (خطوةً خطوة)

> **لمن؟** للمبرمجين الذين سيستلمون حسابات المالك وملفاته. التطبيق v0.7.0 **يُبنى ويعمل كاملاً بدون أيٍّ مما
> هنا** — كل مُدخلٍ غائب يُعرض حالةً صادقة (`NOT_CONFIGURED`) لا عطلاً. هذه الوثيقة تقول **أين يُوضع كل مُدخل
> بالضبط**، دون تحرير شيفرة، ودون إدخال أي سرٍّ إلى المستودع.
>
> **القاعدة الذهبية:** لا يُدفع إلى git أيٌّ من: `google-services.json`، `GoogleService-Info.plist`، مفتاح
> `.p8`، `*.jks`/`*.keystore`، `android/key.properties`، `firebase.defines.json`،
> `ios/Flutter/AppIdentity.local.xcconfig`. كلها في `.gitignore`، وحارس `test/governance_test.dart` يتحقق.

---

## ٠) خريطة المدخلات — ماذا، ومن أين، وإلى أين

| # | المُدخل | مصدره | يوضع في (التطبيق) | يوضع في (الخادم) | إن غاب |
|---|---|---|---|---|---|
| 1 | **معرّف حزمة Android** (مثل `com.lynomia.hub`) | قرار المالك (نهائي لا يتغيّر بعد النشر) | `-P lynomia.applicationId=…` أو `LYNOMIA_ANDROID_APP_ID` | `mobile.dl_android_package` | `dev.lynomia.lynomia_hub_app` (تطويري) |
| 2 | **معرّف حزمة iOS** (Bundle ID) | Apple Developer ← Identifiers | `APP_BUNDLE_ID` في `ios/Flutter/AppIdentity.local.xcconfig` | `mobile.dl_apple_bundle_id` | `dev.lynomia.lynomiaHubApp` |
| 3 | **Apple Team ID** (١٠ محارف) | Apple Developer ← Membership | `APP_TEAM_ID` (نفس الملف) | `mobile.dl_apple_team_id` | يختاره Xcode عند التوقيع |
| 4 | **نطاق الروابط العالمية** (مثل `hub.lynomia.com`) | نطاق خادم الويب (`APP_URL`) | Android: `-P lynomia.appLinkHost=…` · iOS: `APP_LINK_HOST` | `hub.mobile.deep_links.host` (فارغ ⇒ `APP_URL`) | `app-links.lynomia.invalid` (لا يُحلّ ⇒ لا ربط) |
| 5 | **بصمات SHA-256** لتوقيع Android | keystore الرفع + «App signing key» في Play Console | — | `mobile.dl_android_fingerprints` (مفصولة بفاصلة) | الروابط تفتح المتصفح لا التطبيق |
| 6 | **مفتاح توقيع Android** (keystore) | يُنشأ مرةً (§٥) ويُحفظ خارج المستودع | `android/key.properties` (محلي) / أسرار CI | — | إصدارٌ موقَّع بـdebug **محلياً فقط** مع تحذير؛ وفي CI يُتخطّى |
| 7 | **خيارات Firebase** (apiKey/appId/senderId/projectId…) | Firebase Console | `--dart-define-from-file=firebase.defines.json` | `mobile.push_driver=fcm` + `mobile.push_fcm_project_id` + `mobile.push_fcm_service_account` (JSON حساب الخدمة — الخادم يسكّ منه رمز الوصول ويجدّده) | الدفع «غير مهيأ» (المزوّد الصفري) |
| 8 | **مفتاح APNs** (`.p8` + Key ID) | Apple Developer ← Keys | يُرفع إلى Firebase (لا للتطبيق ولا للمستودع) | — | لا إشعارات على iOS |
| 9 | **روابط المتجرين + الدعم + الإصدارات** | بعد إنشاء صفحتي المتجرين | — | `mobile.store_url_ios/android`, `mobile.support_url`, `mobile.min/latest_version_*`, `mobile.force_update` | لا زرّ متجر/دعم (صادق) |
| 10 | **عنوان الخادم** | الإنتاج | `--dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://…` | — | شاشة «إعداد غير صالح» (الإنتاج يرفض غير HTTPS) |

> **ضبط إعدادات الخادم:** منذ خلفية v2.618.0 يحرّر مركز «منصّة تطبيق الهاتف» مفاتيح `mobile.*` كلها (الإصدارات
> والمتاجر والدعم، الروابط العميقة، الدفع) بتحقّقٍ صارم وقيد تدقيقٍ لكل تغيير (بند الخطة ٢.١ ✅)؛ والسرّ (حساب
> الخدمة) للكتابة فقط. و`php artisan hub:set` باقٍ بديلاً على الخادم (§٩):
> ```bash
> php artisan hub:set mobile.dl_android_package com.lynomia.hub
> ```
> (المفاتيح الحساسة تُخزَّن مشفّرةً تلقائياً.)

---

## ١) Firebase — مشروع + خيارات `--dart-define` (البند 2.3)

1. **console.firebase.google.com** ← *Add project* ← الاسم (مثل `lynomia-hub`) ← Analytics اختياري (التطبيق لا
   يستعمله).
2. **تطبيق Android:** *Project settings ← Your apps ← Add app ← Android*:
   - *Android package name* = **المُدخل 1 بالضبط** (لا يُغيَّر بعدها).
   - *SHA-1*: اختياري (غير لازم لـFCM).
   - نزّل `google-services.json` **ولا تضعه في المستودع** — نحتاج منه ٥ قيم فقط (الجدول أدناه). **لا تُطبَّق
     إضافة Gradle `com.google.gms.google-services`** — التطبيق يُهيّئ Firebase من Dart.
3. **تطبيق iOS:** *Add app ← iOS* ← *Bundle ID* = **المُدخل 2 بالضبط**. نزّل `GoogleService-Info.plist` **ولا
   تضعه في Xcode ولا المستودع**.
4. انقل القيم إلى ملفٍ محلي من القالب:
   ```bash
   cp firebase.defines.example.json firebase.defines.json   # مُتجاهَل في git
   ```

   | المفتاح في `firebase.defines.json` | من `google-services.json` | من `GoogleService-Info.plist` |
   |---|---|---|
   | `FIREBASE_PROJECT_ID` | `project_info.project_id` | `PROJECT_ID` |
   | `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` | `GCM_SENDER_ID` |
   | `FIREBASE_STORAGE_BUCKET` (اختياري) | `project_info.storage_bucket` | `STORAGE_BUCKET` |
   | `FIREBASE_ANDROID_API_KEY` | `client[0].api_key[0].current_key` | — |
   | `FIREBASE_ANDROID_APP_ID` (`1:…:android:…`) | `client[0].client_info.mobilesdk_app_id` | — |
   | `FIREBASE_IOS_API_KEY` | — | `API_KEY` |
   | `FIREBASE_IOS_APP_ID` (`1:…:ios:…`) | — | `GOOGLE_APP_ID` |
   | `FIREBASE_IOS_BUNDLE_ID` | — | `BUNDLE_ID` |

   احذف مفتاح `_comment` أو اتركه (غير ضار). **أي قيمة ناقصة أو فيها `REPLACE_BEFORE_STORE_RELEASE`** ⇒ التطبيق
   يعدّ الدفع غير مهيأ للمنصة المعنيّة (مختبر في `test/core/push_fcm_test.dart`) — ومعرّف تطبيقٍ لمنصةٍ خاطئة
   (`:ios:` في خانة Android) يُرفض أيضاً.
5. البناء:
   ```bash
   flutter build appbundle --release \
     --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://hub.lynomia.com \
     --dart-define-from-file=firebase.defines.json \
     -P lynomia.applicationId=com.lynomia.hub -P lynomia.appLinkHost=hub.lynomia.com
   flutter build ipa --release \
     --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://hub.lynomia.com \
     --dart-define-from-file=firebase.defines.json
   ```
   (`-P` يمرَّر إلى Gradle؛ بديلُه متغيرا البيئة `LYNOMIA_ANDROID_APP_ID` و`LYNOMIA_APP_LINK_HOST`، أو السطران
   `lynomia.applicationId=…` و`lynomia.appLinkHost=…` في `android/local.properties`.)
6. **الخادم — الإرسال:** *Project settings ← Service accounts ← Generate new private key* (JSON لحساب خدمة
   بدور *Firebase Cloud Messaging API Admin*)، ثم على الخادم:
   ```bash
   php artisan hub:set mobile.push_driver fcm
   php artisan hub:set mobile.push_fcm_project_id lynomia-hub
   php artisan hub:set mobile.push_fcm_service_account "$(cat service-account.json)"
   ```
   أو من مركز المنصة ← الإعدادات ← «الدفع» (الصق JSON حساب الخدمة — لا يُعاد عرضه). الخادم يسكّ رمز الوصول من
   حساب الخدمة ويجدّده بنفسه (طلب #9 محلول في v2.618) — **احذف ملف JSON من جهازك بعدها**.
   **قناة Android:** الخادم يرسل `channel_id = lynomia_default`، والتطبيق ينشئ هذه القناة (أهمية عالية، اسمٌ
   معرَّب) عند كل إقلاع منذ v1.0.0 — لا شيء عليك فيها.
7. **التحقق:** سجّل الدخول على جهاز حقيقي ⇒ حسابي ← «الإشعارات: مفعلة على هذا الجهاز» ⇒ من مركز المنصة
   (تبويب الإشعارات) «إشعار تجريبي» ⇒ يظهر شريط «وصل إشعارٌ تجريبي…» في التطبيق (المقدّمة) أو إشعار نظام (الخلفية)
   بلا ملاحة. و`GET /api/mobile/v1/push/admin/status` (للمالك) ⇒ `configured: true`.

## ٢) مفتاح APNs إلى Firebase (شرط إشعارات iOS)

1. **developer.apple.com ← Certificates, IDs & Profiles ← Keys ← +** ← الاسم `Lynomia APNs` ← فعّل *Apple Push
   Notifications service (APNs)* ← *Continue ← Register*.
2. نزّل ملف `AuthKey_XXXXXXXXXX.p8` (**يُنزَّل مرةً واحدة** — احفظه في خزنة الأسرار لا المستودع) وسجّل **Key ID**
   و**Team ID** (أعلى يمين الصفحة).
3. **Firebase ← Project settings ← Cloud Messaging ← Apple app configuration ← APNs Authentication Key ← Upload**:
   الملف + Key ID + Team ID. (مفتاح واحد يخدم التطوير والإنتاج.)
4. بيئة APNs في التطبيق آلية: `development` لبناء Debug و`production` لـRelease/TestFlight
   (`ios/Flutter/Debug.xcconfig` / `Release.xcconfig` ⇒ `aps-environment` في `Runner/Runner.entitlements`).

## ٣) Apple — Team ID وBundle ID والنطاقات المرتبطة (البندان 2.2 و5.1)

1. **Identifiers ← + ← App IDs ← App**: *Bundle ID (Explicit)* = المُدخل 2. في *Capabilities* فعّل:
   **Push Notifications** و**Associated Domains**. (لا غيرهما — التطبيق لا يطلب سواهما.)
2. أنشئ ملف الهوية المحلي (مُتجاهَل في git):
   ```bash
   cp ios/Flutter/AppIdentity.local.xcconfig.example ios/Flutter/AppIdentity.local.xcconfig
   ```
   وعدّل: `APP_BUNDLE_ID`، `APP_TEAM_ID`، `APP_LINK_HOST` (المُدخل 4 **بلا** `https://`). هذا الملف يُضمَّن من
   `ios/Flutter/AppIdentity.xcconfig` فيغلب القيم الافتراضية — ويقرؤه Xcode لـ`PRODUCT_BUNDLE_IDENTIFIER`
   و`DEVELOPMENT_TEAM` و`applinks:$(APP_LINK_HOST)`.
   *في CI:* أنشئه في خطوةٍ قبل البناء من متغيرات المستودع (`echo "APP_BUNDLE_ID = …" > …`).
3. افتح `ios/Runner.xcworkspace` ← هدف Runner ← *Signing & Capabilities* ← *Automatically manage signing* (أو
   بروفايلات يدوية تتضمن القدرتين). لا تغيّر `Bundle Identifier` من الواجهة — مصدره الـxcconfig.
4. **الخادم:**
   ```bash
   php artisan hub:set mobile.dl_apple_team_id ABCDE12345
   php artisan hub:set mobile.dl_apple_bundle_id com.lynomia.hub
   ```
5. **التحقق:** `curl -sI https://hub.lynomia.com/.well-known/apple-app-site-association` ⇒ الترويسة
   `X-Deep-Links-Status: CONFIGURED`، والجسم يحوي `ABCDE12345.com.lynomia.hub` والمسارين `/m/*` و`/app/*`. على
   الجهاز: افتح رابط `https://hub.lynomia.com/m/tasks/1` من «الملاحظات» ⇒ يفتح التطبيق على السجل (وقبل الدخول:
   يُحفظ الرابط ويُفتح بعده).

## ٤) Android — الحزمة والبصمات وassetlinks (البندان 2.2 و5.1)

1. **الحزمة:** المُدخل 1، يمرَّر كما في §١-٥. `namespace` في `android/app/build.gradle.kts` يبقى
   `dev.lynomia.lynomia_hub_app` عمداً — هو حزمة شيفرة Kotlin لا هوية المتجر، وتغييره يتطلب نقل `MainActivity.kt`
   بلا فائدة.
2. **البصمات — اثنتان عادةً:**
   - مفتاح الرفع (upload key) الذي تنشئه في §٥:
     ```bash
     keytool -list -v -keystore ~/keys/lynomia-upload.jks -alias upload | grep SHA256
     ```
   - مفتاح توقيع التطبيق لدى Google (**Play App Signing** — ما يصل للمستخدمين فعلاً): *Play Console ← التطبيق ←
     Test and release ← Setup ← App integrity ← App signing ← App signing key certificate ← SHA-256*.
3. **الخادم** (البصمتان مفصولتان بفاصلة، بصيغة `AA:BB:…`):
   ```bash
   php artisan hub:set mobile.dl_android_package com.lynomia.hub
   php artisan hub:set mobile.dl_android_fingerprints "AA:BB:…:01,CC:DD:…:02"
   ```
4. **التحقق:** `curl -sI https://hub.lynomia.com/.well-known/assetlinks.json` ⇒ `X-Deep-Links-Status: CONFIGURED`،
   ثم أداة Google *Statement List Generator and Tester*، وعلى الجهاز بعد التثبيت:
   ```bash
   adb shell pm verify-app-links --re-verify com.lynomia.hub
   adb shell pm get-app-links com.lynomia.hub     # hub.lynomia.com: verified
   ```
   ملاحظة: `intent-filter` يلتقط `https://<host>/m/*` و`/app/*` فقط (`AndroidManifest.xml`)، والنطاق من
   `lynomia.appLinkHost` — البناء بلا هذه الخاصية يربط النطاق المحجوز `.invalid` فلا يدّعي شيئاً.

## ٥) مفتاح التوقيع — keystore و`key.properties` (البند 5.2)

1. أنشئ keystore الرفع **مرة واحدة** وخزّنه (وكلمتي مروره) في خزنة أسرار المؤسسة — ضياعه يعني طلب إعادة ضبط
   من Google:
   ```bash
   keytool -genkeypair -v -keystore ~/keys/lynomia-upload.jks -alias upload \
     -keyalg RSA -keysize 4096 -validity 10000
   ```
2. محلياً: `cp android/key.properties.example android/key.properties` وعدّل الأربعة (`storeFile` مسار مطلق خارج
   المستودع). الملف مُتجاهَل في git.
3. سلوك البناء (`android/app/build.gradle.kts`):
   - `key.properties` كامل ⇒ الإصدار يوقَّع به.
   - غائب ⇒ الإصدار يوقَّع بمفتاح debug **مع تحذيرٍ صاخب** — للتجربة المحلية فقط، Google Play يرفضه.
   - `-P lynomia.requireReleaseSigning=true` (أو `LYNOMIA_REQUIRE_RELEASE_SIGNING=true`) ⇒ الغياب **فشل بناء**
     (يفعّله CI دائماً عند بناء الإصدار).
4. في Play Console فعّل **Play App Signing** (افتراضي للتطبيقات الجديدة) وارفع أول AAB — ثم خذ بصمته (§٤-٢).

## ٦) أسرار CI ومتغيراته (`.github/workflows/app.yml` — البند 5.4)

*GitHub ← Settings ← Secrets and variables ← Actions:*

| النوع | الاسم | القيمة |
|---|---|---|
| Secret | `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/keys/lynomia-upload.jks` |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | كلمة مرور المخزن |
| Secret | `ANDROID_KEY_ALIAS` | `upload` |
| Secret | `ANDROID_KEY_PASSWORD` | كلمة مرور المفتاح |
| Secret | `FIREBASE_DEFINES_JSON` | محتوى `firebase.defines.json` كاملاً (اختياري) |
| Variable | `LYNOMIA_ANDROID_APP_ID` | المُدخل 1 |
| Variable | `LYNOMIA_APP_LINK_HOST` | المُدخل 4 |
| Variable | `API_BASE_URL` | `https://hub.lynomia.com` |

بلا `ANDROID_KEYSTORE_BASE64`: البوابة (format/analyze/test) + APK debug + iOS بلا توقيع تعمل، وخطوة الـAAB
**تُتخطّى** لا تسقط. ومعه: `flutter build appbundle --release` موقَّعاً (يفشل إن نقص التوقيع) ويُرفع أثراً
(`app-release-aab`)، ثم تُحذف مادة التوقيع من العدّاء. بناء iOS الموقَّع ورفعه (TestFlight) يدويان على Mac حتى
تُضاف شهادات Apple للـCI (خارج نطاق v0.7.0).

## ٧) الأيقونة وشاشة البداية والاسم (البند 5.3)

- المولَّد الحالي: مونوغرام «L» أبيض على لون العلامة `#0F5E59` بنقطة كهرمانية — `python3
  tool/generate_brand_assets.py` (Pillow) يعيد إنتاج كل المقاسات: Android `mipmap-*/ic_launcher{,_round,_foreground}.png`
  + `mipmap-anydpi-v26` (تكيّفية + monochrome) + `drawable-*/splash_logo.png`، وiOS `AppIcon.appiconset` (كل مقاسات
  `Contents.json`، بلا قناة ألفا) و`LaunchImage`.
- **لاستبدالها بتصميم المصمم:** ضع ملفات PNG بالأسماء والمقاسات نفسها (أو حدّث الألوان/الرسم في السكربت وأعد
  تشغيله). حارس `governance_test` يتحقق من وجود كل ملفٍ يذكره `Contents.json`.
- **الاسم المعروض:** «لينوميا هب» (عربي) / «Lynomia Hub» (إنجليزي) — Android `res/values{,-ar}/strings.xml`، iOS
  `Runner/{ar,en}.lproj/InfoPlist.strings`، وداخل التطبيق `appTitle` في `lib/l10n/app_{ar,en}.arb`، ومرجعها
  `AppIdentifiers.displayName{,Ar}` (الحارس يُسقط التباعد).

## ٨) صفحتا المتجرين

**Google Play Console:** *Create app* (الاسم، لغة افتراضية العربية، تطبيق مجاني) ← *Store listing* (وصف قصير ≤80
وطويل ≤4000 بالعربية والإنجليزية، أيقونة 512×512 — `Icon-App-1024x1024@1x.png` مصغّرة، صورة مميزة 1024×500، لقطات
هاتف ٢–٨) ← *Privacy policy* (رابط) ← *Data safety*: الموقع (فقط أثناء جلسة تتبّع يبدؤها المستخدم)، الكاميرا
(مسح/مرفقات — لا تُجمع)، الصور/الملفات (مرفقات يرفعها المستخدم)، معلومات الحساب (بريد/اسم من الخادم)، معرّفات
الجهاز (معرّف تنصيب + رمز دفع) — «مُشفَّر أثناء النقل»، و«يمكن طلب الحذف» حسب سياسة المؤسسة ← *Content rating* ←
*Target audience* (18+ تطبيق أعمال) ← *App access*: **حساب تجريبي للمراجِع** (بريد/كلمة مرور على خادم الإنتاج
أو staging) ← *Internal testing* ← ارفع AAB ← بعد النجاح `mobile.store_url_android` =
`https://play.google.com/store/apps/details?id=com.lynomia.hub`.

**App Store Connect:** *My Apps ← +* (المنصة iOS، الاسم، اللغة الأساسية Arabic، Bundle ID = المُدخل 2، SKU) ←
*App Privacy* (نفس تصنيفات Play) ← لقطات **iPhone 6.9"/6.7"** و**iPad 13"** (المشروع يدعم iPad —
`TARGETED_DEVICE_FAMILY = 1,2`) ← *App Review Information*: حساب تجريبي + ملاحظة أن الموقع لا يُستعمل إلا في جلسة
تتبّع ظاهرة ← *Export compliance*: التطبيق يستعمل HTTPS والتشفير القياسي للنظام/المكتبات فقط (مُعفى) ← ارفع من
Xcode (*Product ← Archive*) أو `flutter build ipa` ثم Transporter ← TestFlight ← بعدها `mobile.store_url_ios`.

## ٩) إعدادات الخادم دفعةً واحدة (بعد توفر كل شيء — أو من محرّر الإعدادات في مركز المنصة)

```bash
# الروابط العالمية
php artisan hub:set mobile.dl_apple_team_id        ABCDE12345
php artisan hub:set mobile.dl_apple_bundle_id      com.lynomia.hub
php artisan hub:set mobile.dl_android_package      com.lynomia.hub
php artisan hub:set mobile.dl_android_fingerprints "AA:…:01,CC:…:02"
# الدفع
php artisan hub:set mobile.push_driver             fcm
php artisan hub:set mobile.push_fcm_project_id     lynomia-hub
php artisan hub:set mobile.push_fcm_service_account "$(cat service-account.json)"
# المتجران والدعم والإصدارات
php artisan hub:set mobile.store_url_android       "https://play.google.com/store/apps/details?id=com.lynomia.hub"
php artisan hub:set mobile.store_url_ios           "https://apps.apple.com/app/id0000000000"
php artisan hub:set mobile.support_url             "https://hub.lynomia.com/support"
php artisan hub:set mobile.latest_version_android  1.0.0
php artisan hub:set mobile.latest_version_ios      1.0.0
```
ثم مركز المنصة ← «التطبيق والإصدار» ← قائمة الإطلاق: كل البنود خضراء.

## ١٠) قبول نهائي

راجع `docs/release-checklist.md` — كل بندٍ فيه يشير إلى القسم المعني هنا.
