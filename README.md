# Lynomia Hub — v0.3.0

تطبيقُ الجوال الأصيل (iOS + Android) لمنصّة **Lynomia Business Hub** — عربيٌّ أولاً،
RTL أولاً، مبنيٌّ بـFlutter فوق سطح `/api/mobile/v1` حصراً. الخادمُ مصدرُ الحقيقة
(المصادقة، الصلاحيات، النطاق، الأعمال)؛ والتطبيقُ عميلٌ غيرُ موثوقٍ يعرض ولا يُخوِّل.

## البنية

```text
lib/
├── app/          # الغلاف: التطبيق، الموجّه (go_router)، الإقلاع، حقن التبعيات
├── core/         # المنصة: api, auth, config, errors, storage, sync, security,
│                 # localization, telemetry, ui
├── features/     # ميزات feature-first: launch, auth, home, my_work, workspaces,
│                 # modules, records, search, approvals, notifications, messages,
│                 # comments, files, scanner, tracking, profile, settings
└── main.dart
```

- **العقد:** لقطاتُه في `contracts/` (المصدر `hisham7961/lynomia-hub` — مقروءٌ فقط)،
  تُحدَّث عمداً عبر `tool/update_contracts.sh`، ويحرسها `test/contract/`.
- **البيئات:** `--dart-define=API_BASE_URL=… --dart-define=APP_ENV=dev|staging|prod`
  — الإنتاج يرفض غيابَ المضيف وHTTP غير الآمن (راجع `docs/environments.md`).
- **الحوكمة:** قواعدُ النسخة والدفع في `CLAUDE.md`؛ السجلُّ في `CHANGELOG.md`.

## أوامر القطع

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## سجل الإصدارات

- **v0.1.0** — التأسيس الكامل: مشروع Flutter (منصّتا iOS/Android)، الحوكمة ولقطات
  العقد، نواة المنصة (عميل API بترويسات العقد وتسلسل تحديثٍ واحد وIdempotency
  وIf-Match وETag، أخطاء مكتوبة على `code`، تخزين آمن، خبيئة مشفرة، تسجيل محجوب)،
  آلة الإقلاع، المصادقة الكاملة (MFA، تدوير التحديث، تصعيد، بيومترية محلية)،
  غلاف التطبيق العربي RTL بخمس وجهات، محرك الوحدات العام (مخطط/قوائم/سجل/نماذج/
  إجراءات)، الاعتمادات والإشعارات والرسائل والتعليقات والبحث والملفات والماسح
  والتتبع، المزامنة التزايدية بأصناف `sync_class` وشواهد الحذف، تجريد الدفع
  والروابط العميقة (NOT_CONFIGURED صادقة)، الاختبارات والتوثيق وCI.
