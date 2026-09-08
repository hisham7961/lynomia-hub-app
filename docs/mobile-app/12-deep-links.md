# 12 · الروابط العميقة (§41)

- **الوجهة القانونية** `{module, id, action}` — المصدر `NotificationLink::target`
  الخادمي، لا اسم شاشة صلب.
- المسارات الملتقطة: `/m/{module}/{id}` و`/app/*` (يطوى على `/m/*`) —
  و`/activate/{token}` (وقشرته عامة تسبق الدخول §13).
- **التخويل على الفتح خادمي:** فتح رابط لسجل لا يملكه المستخدم يعرض 404
  الصادقة — الرابط ليس تخويلاً. ولحساب العميل يعيد الموجه أي مسار داخلي
  لبوابته (والخادم يصد النداء 404 على أي حال).
- Universal/App Links: الخادم يخدم `/.well-known/apple-app-site-association`
  و`assetlinks.json` — **NOT_CONFIGURED** حتى تدخل معرفات
  الفريق/الحزمة/البصمة (انظر `15-release-ios.md` و`16-release-android.md`).

التفصيل في `docs/push-deep-links.md`.
