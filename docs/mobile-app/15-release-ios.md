# 15 · إصدار iOS

> الحالة: **NOT_CONFIGURED** — لا حساب Apple Developer ولا شهادات توقيع في
> المستودع (ولن تكون: لا أسرار في المستودع).

قائمة ما يلزم قبل TestFlight/App Store:

1. **معرفات:** Bundle ID حقيقي + Team ID — تحديث
   `lib/core/config/app_identifiers.dart` (موسومة `REPLACE_BEFORE_STORE_RELEASE`)
   و`ios/Runner` بالمطابقة.
2. **التوقيع:** شهادة توزيع + Provisioning Profile (خارج المستودع كلياً).
3. **الدفع:** مفتاح APNs (`.p8`) أو وساطة FCM — ثم ضبط إعدادات الخادم
   (`mobile.push_*`) والتحقق عبر `GET push/admin/status`.
4. **Universal Links:** إدخال Team+Bundle في إعدادات الخادم ليخدم
   `apple-app-site-association` مضبوطة + `Associated Domains` في القدرات.
5. **بوابة الإصدار:** ضبط `mobile.min_version_ios`/`latest` وروابط المتجر.
6. البناء: `flutter build ipa --release --dart-define=LYNOMIA_API_BASE_URL=…`.
7. مراجعة `17-production-checklist.md` كاملة قبل الرفع.

قيود المنصة تُوثق هنا عند ظهورها — لا ميزة iOS دون نظير Android إلا بقيد حقيقي.
