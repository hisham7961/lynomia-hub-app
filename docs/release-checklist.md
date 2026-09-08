# قائمة فحص الإطلاق (§145 — الإعداد الخارجي المتبقي)

كلها **خارجية** — البنية جاهزة والتطبيق يترجم ويعمل بدونها بحالات صادقة.

## معرفات المتاجر (REPLACE_BEFORE_STORE_RELEASE — `lib/core/config/app_identifiers.dart`)

- [ ] Apple Bundle ID النهائي + Apple Team ID + شهادات/بروفايلات التوقيع
- [ ] Android applicationId النهائي + مفتاح توقيع الإصدار (keystore) — واستخراج
      بصمات SHA-256
- [ ] تحديث `android/app/build.gradle.kts` و`ios/Runner` بالمعرفات النهائية
- [ ] أيقونة/شعار Lynomia النهائيان (الحالي placeholder فلاتر افتراضي موثق §26)
- [ ] App Store ID + روابط المتجرين ⇒ `setting('mobile.store_url_*')`

## الدفع

- [ ] مشروع Firebase (`project_id`) + اعتماد حساب الخدمة ⇒ إعدادات الخادم
      (`mobile.push_driver=fcm`…) — تحقق `GET push/admin/status` = configured
- [ ] إضافة مزود عميل حقيقي (`firebase_messaging`) + `google-services.json` /
      إعداد APNs — **لا يلتزمان بالمستودع**
- [ ] (اختياري) منفذ APNs مباشر خادمياً — غير مبني بعد (موثق خادمياً)

## الروابط العالمية

- [ ] النطاق المصرح ⇒ `hub.mobile.deep_links.host`
- [ ] `mobile.dl_apple_team_id` + `dl_apple_bundle_id`
- [ ] `mobile.dl_android_package` + `dl_android_fingerprints`
- [ ] تحقق `/.well-known/*` ترويسة `X-Deep-Links-Status: CONFIGURED`
- [ ] associated domains (iOS) + intent-filter autoVerify (Android) بالمعرفات النهائية

## بوابة الإصدار والدعم

- [ ] `mobile.min_version_*` / `latest_version_*` / `force_update` عند الحاجة
- [ ] `mobile.support_url`

## قرارات نشر Android

- [ ] `allowBackup=false` أو `dataExtractionRules` تستثني دليل الدعم (docs/security.md)
- [ ] مراجعة أذونات AndroidManifest النهائية (كاميرا/موقع/إشعارات فقط §88)

## القطع النهائي

- [ ] `flutter analyze` + `flutter test` + بناء الإصدارين موقعين
- [ ] `tool/update_contracts.sh` على HEAD الخلفية النهائي + اختبارات العقد خضراء
