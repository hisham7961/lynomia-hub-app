# الدفع والروابط العميقة (§73–§77)

## معمارية الدفع — صادقة NOT_CONFIGURED

```text
PushTokenProvider (واجهة)
 ├─ NotConfiguredPushProvider   ← الحالي: لا اعتماد FCM/APNs في المستودع
 └─ (لاحقاً) FcmPushProvider    ← يضاف مع firebase_messaging عند توفر الاعتماد
PushRegistrar → POST push/register / push/unregister (للجلسة المصادقة فقط)
```

- التطبيق يترجم ويعمل كاملاً بلا اعتماد؛ حسابي/التشخيص يظهران «غير مهيأة» —
  لا نجاح مزيف (§73).
- عند توفر الاعتماد: يضاف مزود حقيقي + `google-services.json`/إعداد APNs
  (لا يلتزمان بالمستودع)، ويضبط الخادم `mobile.push_driver=fcm` +
  `project_id` + `access_token` ويُتحقق عبر `GET push/admin/status`.
- تدوير الرمز عبر `tokenRotations`؛ الخروج يلغي التسجيل (§74) والخادم يبطل
  رموز التنصيب أيضاً.
- **خصوصية (§75):** الحمولة الخادمية عنوان عام + `{module,id,action}` + عدّ —
  التطبيق يعامل الدفع إشارة: بعد النقر يصادق ويجلب من الخادم؛ لا محتوى حساس
  في سجل محلي.

## الروابط العميقة (§76)

الوجهة القانونية `{module, id, action}` من: الإشعارات، البحث، البيت،
الاعتمادات، حمولة الدفع. الترميز العالمي `/m/{module}/{id}[/{action}]`
و`/app/*`. `app_links` يلتقط البارد والحي، والموجه يطويها إلى
`/r/:module/:id` — الملاحة العامة تحل أي وحدة مسموحة بلا خريطة شاشات صلبة.

## Universal / App Links (§77)

سقالة الشيفرة جاهزة (الالتقاط + الطي). **الربط المنصي NOT_CONFIGURED** حتى
تصدر: Apple Team ID + Bundle ID النهائي، وAndroid package + بصمات SHA-256
للتوقيع — تدخل في إعدادات الخادم (`mobile.dl_*`) فيخدم `/.well-known/*`
تلقائياً، ويضاف الـintent-filter/associated domains النهائيان مع معرفات
الإنتاج (REPLACE_BEFORE_STORE_RELEASE — `lib/core/config/app_identifiers.dart`).
لا قيم توقيع مخترعة.
