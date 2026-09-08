# المعمارية — Lynomia Hub (تطبيق الجوال)

## الطبقات (§13)

```text
UI (features/*)          Views + ViewModels (State/ChangeNotifier)
   │  لا HTTP في widget، ولا منطق أعمال في الواجهة
Data (features/*_repository + core/api)
   │  Repositories فوق ApiClient الواحد
Platform (core/*)        config · api · auth · storage · sync · security ·
                         push · telemetry · ui المشتركة
```

- **حقن التبعيات:** `AppContainer` (lib/app/di/app_scope.dart) — توصيل واحد صريح؛
  `AppContainer.custom` للاختبارات يستبدل الناقل والمخزن والدلائل والبيومترية.
- **تدفق أحادي الاتجاه:** الشاشات تستدعي مستودعات وتتلقى حالة؛ الحالة المشتركة
  (`AccountState`, `SessionManager`, `ViewContext`, `ConnectivityMonitor`)
  ChangeNotifier يستمع لها الموجه والغلاف.

## عميل API الواحد (§100)

`core/api/api_client.dart` يضمن بنيوياً: ترويسات العقد (§30)، غلاف
`{data|error, code, request_id}`، تدويراً واحداً متسلسلاً عند 401 (§36)،
`SESSION_REVOKED` ينهي الجلسة فوراً (§38)، إعادة محدودة بجذر أسي للعابر الآمن
فقط (§59)، ETag/304 (§44)، وغلاف الخطأ على 2xx (مثل `APPROVAL_REQUIRED` 202)
يرمى مكتوباً.

## محرك الوحدات العام (§19)

`features/modules/` — المخطط من `GET schema` (منطق بالصلاحية، ETag) يقود:
القوائم (بحث/فرز/ترقيم)، شاشة السجل (حقول/إجراءات/تعليقات/مرفقات)، النماذج
(كل أنواع الحقول الـ13 — docs/schema-field-coverage.md)، الإجراءات من
`GET actions` حصراً. وحدة خادمية جديدة تظهر بلا إصدار جوال.

## التخزين الثلاثي (§102)

| المخزن | المحتوى | التقنية |
|---|---|---|
| `SecureStore` | رموز الجلسة، مفتاح الخبيئة، معرف التنصيب | Keychain / Keystore |
| `EncryptedJsonCache` | لقطات المزامنة والأعمال | AES-256-GCM ملفياً، المفتاح في الآمن |
| `PrefsStore` | لغة/مظهر/أعلام غير حساسة | JSON بسيط |

## الملاحة (§15)

go_router بغلاف `StatefulShellRoute` (٥ فروع)، إعادة توجيه على حالة
`LaunchController`/الجلسة، روابط عميقة `/m/*` و`/app/*` تطوى إلى شاشة السجل
العامة `/r/:module/:id`، وشاشة تحديث إلزامي حاجبة.
