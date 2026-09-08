# 16 · إصدار Android

> الحالة: **NOT_CONFIGURED** — لا مفتاح توقيع ولا حساب Play Console في
> المستودع.

قائمة ما يلزم قبل الإطلاق:

1. **معرفات:** `applicationId` حقيقي — تحديث
   `lib/core/config/app_identifiers.dart` و`android/app/build.gradle`
   بالمطابقة (موسومة `REPLACE_BEFORE_STORE_RELEASE`).
2. **التوقيع:** keystore إصدار (خارج المستودع) + `key.properties` محلي.
3. **الدفع:** مشروع Firebase/FCM (project id + حساب خدمة) — ثم إعدادات
   الخادم والتحقق عبر `GET push/admin/status`.
4. **App Links:** بصمة SHA-256 للتوقيع في إعدادات الخادم ليخدم
   `assetlinks.json` مضبوطة.
5. **بوابة الإصدار:** `mobile.min_version_android`/`latest` + رابط المتجر.
6. البناء: `flutter build appbundle --release --dart-define=LYNOMIA_API_BASE_URL=…`.
7. مراجعة `17-production-checklist.md` كاملة قبل الرفع.
