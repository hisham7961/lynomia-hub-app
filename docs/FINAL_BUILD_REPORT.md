# FINAL BUILD REPORT — Lynomia Hub Mobile (البناء الأولي v0.1.0)

> **تحديث v0.2.0 — تجربة العميل (§10–§18):** هذا القسم يلخص دفعة الطور
> الثاني؛ ما بعده تقرير التأسيس v0.1.0 كما كان (بنوده لا تزال صحيحة إلا
> حيث ينص هذا القسم على غيره).

## v0.2.0 UPDATE VERDICT

```text
READY FOR DEVICE TESTING — DUAL AUDIENCE (INTERNAL + CLIENT)
```

- **الخلفية لم تعد مقروءة فقط في هذا الطور:** الطور الثاني خوّل تغييرها —
  دفعت `v2.447.0` على فرع `claude/new-session-6mm7zs` (سياج
  `MobilePortalGuard`، بوابة `portal/*` عشرة مسارات، تفعيل `activation/*`
  نقطتان عامتان، إدارة أعضاء `clients/{client}/members` أربعة مسارات —
  75 مساراً جوالاً كلياً؛ 25 اختباراً خلفياً جديداً/264 تأكيداً؛ الحزمتان
  خضراوان: SQLite 3433 اختباراً وMySQL(MariaDB محلياً) 3433 اختباراً).
- **التطبيق v0.2.0:** قشرتان بنمط الحساب الخادمي (`account_type`) —
  `ClientShell` وبيت بوابة العميل وقوائم/تفاصيل الوجهات الست وغرفة محادثة
  العميل؛ تفعيل الحساب برابط عميق عام؛ شاشة إدارة الأعضاء خلف التصعيد
  المربوط بالغرض؛ «حسابي» بنمط الحساب. 12 اختباراً جديداً (93 كلياً)،
  التحليل صفر ملاحظات، لقطات العقد على SHA الخلفية الجديد.
- **الحالات:** الدفع push لا يزال `BLOCKED_EXTERNAL_CONFIG`؛ معرفات المتاجر
  والتوقيع `NOT_CONFIGURED` (لا جاهزية إنتاج تُدَّعى بدونها)؛ التفاصيل في
  `docs/mobile-app/17-production-checklist.md` و`docs/mobile-feature-coverage.md`.
- **مرجع الخلفية المحدث:** `contracts/backend-source.json` —
  `claude/new-session-6mm7zs` @ `72891e8b…` · backend `2.447.0`.


## APP VERDICT

```text
READY FOR DEVICE TESTING
```

(جاهز لاختبار الأجهزة مقابل خادم Lynomia حي؛ إطلاق المتاجر ينتظر الإعداد
الخارجي فقط — `docs/release-checklist.md`.)

## REPOSITORY

- Mobile repo: `hisham7961/lynomia-hub-app`
- Branch: `claude/new-session-6mm7zs`
- Commit: `31c9526` (دفعة التأسيس v0.1.0)

## BACKEND REFERENCE

- Repo: `hisham7961/lynomia-hub` (**مقروء فقط — لم يُمس**)
- Branch/ref: `claude/lynomia-hub-enterprise-upgrade-xn4p2t` (قائم على origin؛
  وفرع `claude/new-session-6mm7zs` عند `111d2a6b…` دمجه — الشجرتان متطابقتان
  بـ`git diff` فارغ، فالمرجع المستعمل هو الفرع المحدد نفسه)
- Exact commit SHA: `791951d0e9e5a53b0832ecd3dd573271e03047d8`
- Mobile API version: `1` · Backend version: `2.446.0` · schema_version: `4a9f8b3a502e`
- Contract snapshot: `contracts/backend-source.json` +
  `contracts/mobile-capabilities.json` (٥٩ نقطة) +
  `contracts/mobile-openapi.json` (OpenAPI 3.1، ٥٣ مساراً — ولّدت من
  `MobileOpenApi::spec()` على نسخة العمل بقاعدة SQLite مؤقتة) — تحدث عمداً عبر
  `tool/update_contracts.sh` وتحرسها `test/contract/`

## TOOLCHAIN

- Flutter: 3.47.2 (stable) · Dart: 3.13.2
- Android: SDK Platform 36, Build-Tools 36.0.0, Gradle 9.3.1, Java 21 (بيئة البناء)
- iOS: مشروع Runner (xcodeproj/xcworkspace/RunnerTests) قائم وجاهز للبناء —
  لا بيئة macOS هنا فلم يُنفذ بناء iOS (لا ادعاء §138)؛ Podfile يتولد على أول
  بناء macOS كنمط Flutter القياسي، وخطوة CI معدة ومعطلة حتى توفر عداء macOS

## ARCHITECTURE

feature-first (§14) فوق نواة منصة: `lib/app` (DI صريح `AppContainer`، موجه
go_router، آلة إقلاع)، `lib/core` (api/auth/config/errors/storage/sync/
security/push/telemetry/ui)، `lib/features/*` (repository + شاشات).
تفصيل: `docs/architecture.md`.

## APPLICATION NAVIGATION

خمس وجهات سفلية: الرئيسية · مهامي · المجالات · البحث · حسابي؛ الإشعارات
والرسائل والماسح أيقونات رأس بشارات؛ فوقها الوجهات العامة `/m/:module`،
`/r/:module/:id(/edit)`، `/notifications`، `/messages(/:id)`،
`/approvals(/:id)`، `/scanner`، `/tracking`. الخريطة الكاملة:
`docs/navigation.md` و`docs/screen-inventory.md`.

## AUTH

- Login: عقد `auth/login` الكامل (بريد/كلمة/تنصيب/منصة/إصدار/جهاز/لغة/منطقة)
- MFA: تحدي TOTP (`challenge_id`) — لا سر ثانٍ ولا SMS مدعى
- Refresh: **تسلسل تدوير واحد** مثبت اختباراً؛ استبدال ذري؛ عائلة باطلة ⇒ دخول
- Step-Up: حوار `runWithStepUp` على 428 بغرض الخادم ثم إعادة واحدة
- Biometrics: قفل محلي اختياري (local_auth) بسقوط لاعتماد الجهاز — لا شيء يُرسل
- Sessions: قائمة/إبطال جلسة/خروج/خروج شامل + مسح كامل محلي

## CONTEXT

- Company/Client: مبدل في حسابي من `bootstrap.context`؛ الترويسات تضيق فقط؛
  التبديل يبطل ويعيد الجلب؛ خبيئة المزامنة معزولة بالمفتاح (مثبت اختباراً)

## HOME / MY WORK

`GET home` كاملة: انتباه/مواعيد/مهامي/مشاريعي/اعتمادات معلقة/آخر نشاط/غير
مقروء — كل عنصر وجهة `{module,id}`. مهامي تجمع فوقها الرسائل والإشعارات.

## WORKSPACES

شجرة IA الخادمية (`bootstrap.ia`/`GET navigation` بـETag): مجالات ← أقسام ←
وجهات بترتيب `importance` و`mobile` fit (`web-only` ⇒ متصفح) — لا 80 وحدة
مسطحة ولا بنية صلبة.

## GENERIC MODULE ENGINE

- Modules supported: كل ما يبثه `GET schema` لدور المستخدم (٨٥+ في السجل)
- Field types: 13/13 عارضاً ومحرراً (`docs/schema-field-coverage.md`) —
  المجهول المستقبلي نص آمن لا انهيار
- Actions: allowlist الخادم فقط + تمييز هدام/محمي بموافقة + تصعيد + idempotency
- CRUD: قائمة (بحث/فرز/ترقيم لانهائي) · إنشاء · عرض · PUT/PATCH بـIf-Match ·
  حذف بتأكيد · 422 بجانب الحقل · تعارض نسخة بمسار حل صريح ·
  `APPROVAL_REQUIRED` ⇒ إشعار تصفيف بوجهة الطلب

## APPROVALS

طابور المعتمد، تفصيل ببطاقة آمنة، اعتماد/رفض بتعليل، تقادم
(`VERSION_CONFLICT`) صريح، تصعيد عند الطلب، idempotent، وجهة السجل الهدف.

## NOTIFICATIONS

قائمة بمؤشر keyset + غير المقروء فقط + قراءة/قراءة الكل + حل `target`
القانوني والملاحة العامة — لا اسم شاشة صلب.

## COMMENTS

قراءة خيط السجل بردود وتفاعلات (عدد + mine) وحضور مرفق، نشر برد/منشن/داخلي
خلف Idempotency. (تفاعل إضافة إيموجي: لا نقطة جوال له — القراءة كاملة.)

## DMS

خيوط بغير المقروء، رسائل الخيط، إرسال idempotent، ختم قراءة، محذوفة تعرض
كذلك — الخيط بمعرف الطرف الآخر حصراً (خصوصية خادمية).

## SEARCH

Debounce ٣٥٠م + إلغاء منطقي للبائت + نتائج بوجهات + حالات فارغة/قصر صادقة —
لا بحث خبيئة كسلطة.

## FILES

رفع مقطع (جلسة/قطع مفهرسة/إتمام idempotent) بتقدم وإلغاء وإعادة، مصادر
كاميرا/مكتبة/مستندات بأذونات عند الحاجة، تنزيل مصادق بلا روابط عامة.
سرد مرفقات سجل قائمة: BACKEND_GAP موثقة.

## SCANNER

mobile_scanner ⇒ `identity/resolve/{q}` الخادمي ⇒ ملاحة للكيان المخول؛
مجهول/خارج النطاق رسالة صادقة — لا تفسير محلي.

## TRACKING

بدء بموافقة صريحة (`consent=true`) وإذن نظام، جلسة ظاهرة بعداد نقاط، دفعات
idempotent كل ٣٠ث/٢٠ نقطة تبقى عند الفشل للمحاولة، إنهاء صريح، لا جمع خارج
الجلسة (الاشتراك يلغى بمغادرة الشاشة).

## OFFLINE / SYNC

- Cache: `EncryptedJsonCache` — AES-256-GCM، المفتاح في Keychain/Keystore
- Encryption: مثبت اختباراً أن البايتات ليست نصاً (قرار موثق
  `docs/offline-sync.md`)
- Sync classes: الخمسة تطاع؛ الافتراض ONLINE_ONLY؛ رفض بنيوي لتخبئة الممنوع
- Tombstones: تطبق على المؤشر نفسه؛ تغير sync_version ⇒ إعادة كاملة
- Sensitive no-persist: مثبت اختباراً (لا كتابة + محو بقايا + رمي مكتوب)

## PUSH

- Architecture: `PushTokenProvider`/`PushRegistrar` + تسجيل/إلغاء خادميان
- Provider status: **NOT_CONFIGURED** (مزود صفري صادق — لا اعتماد في المستودع)
- External config remaining: FCM/APNs (release-checklist)

## DEEP LINKS

- Implemented: `/m/*` و`/app/*` بارداً وحياً (app_links) ⇒ شاشة السجل العامة؛
  الوجهة القانونية من الإشعارات/البحث/البيت/الاعتمادات
- External config remaining: Universal/App Links association (معرفات + بصمات)

## SECURITY

- Token storage: مخزن النظام الآمن حصراً · Refresh serialization: واحد مشترك
  (اختبار) · Sensitive data: لا قرص (اختبار) · Logging: محجوب (اختبار) ·
  HTTPS: بوابة إنتاج رافضة (اختبار)
- Findings: لا معلقات؛ المراجعة البندية في `docs/security.md`؛ غير المبني
  عمداً (Attest/Integrity/WebAuthn جوال) موثق NOT_CONFIGURED لا مدعى

## RTL / LOCALIZATION

- Arabic: أولاً — كل نصوص الواجهة ARB (١٥٠+ مفتاحاً)، لا نص صلب في widget
- English: ARB كامل مواز (بنية جاهزة)
- RTL: يقوده locale؛ اختبارات widget توكد الاتجاه على الدخول والغلاف؛
  الأيقونات الاتجاهية auto-mirror؛ حقول البريد/الأرقام/الروابط LTR مقصود

## ACCESSIBILITY

عناصر Material دلالية، tooltips على كل أزرار الأيقونات، مفاتيح تبديل
بعناوين، أخطاء نماذج نصية بجانب الحقل، لا حالة بلون فقط (أيقونة+نص)،
أهداف لمس قياسية M3 — واختبار widget يوكد الزر الدلالي للدخول.

## FEATURE COVERAGE

- Backend mobile capabilities: 59 نقطة / 22 مجموعة
- Implemented: 20 مجموعة · Not applicable: 1 (إدارة دفع المالك — ويب §98) ·
  Blocked external: 1 (مزود الدفع) · Backend gaps: 1 بند فرعي (سرد مرفقات) ·
  **Unexplained missing = 0** (`docs/mobile-feature-coverage.md`)

## TESTS

```bash
$ dart format --set-exit-if-changed .   # نظيف (0 تغيير بعد القطع الأخير)
$ flutter analyze                        # No issues found!
$ flutter test                           # 00:05 +81: All tests passed!
```

81 اختباراً: نواة (بيئة/عميل/تشفير/مزامنة/تسجيل محجوب)، تدفقات مصادقة، محرك
الوحدات، تعاون (إشعارات/DM/تعليقات/اعتمادات/بحث/ملفات/ماسح/تتبع)، عقود على
اللقطات، حوكمة، وwidget RTL (دخول/صيانة/تحديث إلزامي/غلاف/مجالات/سجل/
إشعارات/بحث). كلها على fakes — لا خدمة حقيقية.

## BUILDS

- Android: `flutter build apk --debug` ⇒
  `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (نفذ فعلاً في بيئة
  البناء هذه — Gradle 9.3.1 / AGP على Java 21 / Platform 36). تحقق بالحزمة:
  `aapt dump badging` ⇒ `dev.lynomia.lynomia_hub_app` v0.1.0 (minSdk 24،
  label «Lynomia Hub») والأذونات الدنيا المعلنة فقط (§88)
- iOS: لم يُبنَ (لا بيئة macOS/Xcode هنا — لا ادعاء §138)؛ المشروع قائم
  وInfo.plist بنصوص الأغراض، وخطوة CI معدة معطلة حتى توفر عداء macOS

## CI

`.github/workflows/app.yml` (كان `ci.yml` حتى v0.6.0): format + analyze + test + بناء APK تجريبي
(subosito/flutter-action@3.47.2) — لا سر إنتاجي مطلوب. (سيجري على أول دفعة
لهذا المستودع.)

## EXTERNAL CONFIG STILL REQUIRED

فقط الحقيقي (تفصيله `docs/release-checklist.md`): اعتماد FCM/APNs، معرفات
Apple/Google النهائية + توقيع، بصمات App Links + النطاق، روابط المتجر/الدعم،
بوابة الإصدار، شعار نهائي، App Attest/Play Integrity إن قررت.

## BACKEND CHANGE REQUESTS

ثلاثة بنود موثقة فقط (`docs/backend-change-requests.md`): سرد مرفقات سجل،
معرف مرفق DM/تعليق للتنزيل، وتدوين حالة فرض 426 — لا التفاف نفذ على أي منها.

## VERSION

`0.1.0+1` (أولي §11) ← → `0.1.0+1` (نهائي هذا البناء) — التطابق الرباعي
(VERSION/pubspec/README/CHANGELOG) يحرسه `test/governance_test.dart`.

## GIT COMMITS

دفعة تأسيس واحدة شاملة على `claude/new-session-6mm7zs` (المشروع وليد —
التاريخ يبدأ بها)؛ تفصيل المحتوى في `CHANGELOG.md` v0.1.0.
