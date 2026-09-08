# مصفوفة تغطية القدرات (§124)

المصدر: `contracts/mobile-capabilities.json` (٧٥ نقطة · خلفية v2.447.0). الحالة:
`IMPLEMENTED` مبنية ومختبرة · `NOT_APPLICABLE` ليست شاشة جوال بطبيعتها ·
`BLOCKED_EXTERNAL_CONFIG` تنتظر اعتماداً خارجياً فقط · `BACKEND_GAP` فجوة عقد.

**القدرات الجوالية غير المفسرة الغائبة = 0.**

| قدرة الخلفية | العقد | موضع التطبيق | مدخل الواجهة | سياسة الاتصال | الاختبارات | الحالة |
|---|---|---|---|---|---|---|
| دخول/MFA/تحديث/خروج/خروج شامل | `auth/login,mfa/verify,refresh,logout,logout-all` | `core/auth` | شاشة الدخول + حسابي | ONLINE | auth_flow + api_client | IMPLEMENTED |
| جلسات الجوال + إبطال | `auth/sessions[,/{id}]` | `AuthRepository.sessions/revoke` | حسابي ← الجلسات | ONLINE | auth_flow | IMPLEMENTED |
| التصعيد | `auth/step-up` | `runWithStepUp` | حوار عند 428 | ONLINE | auth_flow | IMPLEMENTED |
| app-config/health | `app-config`, `health` | `AppConfigRepository` | بوابة الإقلاع | عامة | auth_flow + widget | IMPLEMENTED (health يُستدل به عند الحاجة عبر app-config نفسه) |
| bootstrap/context/navigation | `bootstrap,context,navigation` | `BootstrapRepository`/`AccountState` | الإقلاع + المجالات + مبدل السياق | ETag | widget + وحدات | IMPLEMENTED |
| المخطط | `schema[,/modules]` | `ModuleRepository.schema` | كل شاشات المحرك | ETag | module_engine | IMPLEMENTED |
| CRUD العام (٦) | `{module}…` | `ModuleRepository` | قائمة/سجل/نموذج عامة | ONLINE + خبيئة قراءة | module_engine + widget | IMPLEMENTED |
| الإجراءات (٢) | `{module}/{id}/actions…` | `ModuleRepository.actions/runAction` | تبويب الإجراءات | ONLINE | module_engine | IMPLEMENTED |
| المزامنة | `sync/{module}` | `SyncEngine` | سقوط خبيئة القوائم | حسب `sync_class` | sync_engine | IMPLEMENTED |
| البيت | `home` | `HomeRepository` | الرئيسية + مهامي | ONLINE | widget | IMPLEMENTED |
| البحث | `search` | `SearchRepository` | وجهة البحث | ONLINE | comm + widget | IMPLEMENTED |
| الإشعارات (٥) | `notifications…` | `NotificationRepository` | شاشة الإشعارات + شارات | ONLINE (مؤشر) | comm + widget | IMPLEMENTED |
| التعليقات (٢) | `comments` | `CommentRepository` | تبويب تعليقات السجل | ONLINE | comm | IMPLEMENTED |
| DM (٤) | `dm/threads…` | `DmRepository` | الرسائل | ONLINE | comm | IMPLEMENTED |
| الاعتمادات (٤) | `approvals…` | `ApprovalRepository` | طابور/تفصيل/حسم | ONLINE | comm | IMPLEMENTED |
| التفضيلات (٣) | `prefs[,/pin]` | `PrefsRepository` | حسابي (كتم/مثبتات) | ONLINE | مبني (مستودع) | IMPLEMENTED |
| الملفات (٦) | `files/…` | `FileRepository` + `AttachmentsPanel` | تبويب المرفقات | ONLINE | comm + widget | IMPLEMENTED (سرد المرفقات القائمة: BACKEND_GAP — راجع backend-change-requests.md#1) |
| الماسح | `identity/resolve/{q}` | `IdentityRepository` + الماسح | أيقونة الرأس | ONLINE | comm | IMPLEMENTED |
| التتبع (٣) | `tracking/…` | `TrackingRepository` + شاشة التتبع | حسابي ← التتبع | ONLINE (دفعات) | comm | IMPLEMENTED |
| تسجيل الدفع (٢) | `push/register,unregister` | `PushRegistrar` | تلقائي عند الدخول/الخروج | ONLINE | مبني (مستودع) | BLOCKED_EXTERNAL_CONFIG (لا اعتماد FCM/APNs — المزود الصفري صادق) |
| إدارة الدفع (٢) | `push/admin/status,test` | — | — | — | — | NOT_APPLICABLE (إدارة مالك — مركز المنصة ويب §98) |
| openapi.json | `openapi.json` | `contracts/mobile-openapi.json` | لقطة عقد + أداة تحديث | عامة | contract tests | IMPLEMENTED (لقطة) |
| تفعيل حساب العميل (٢) | `activation/{token}[,/complete]` | `ActivationRepository` + شاشة التفعيل | رابط عميق `/activate/{token}` (عام) | ONLINE (عامة) | client_experience | IMPLEMENTED |
| بوابة العميل (١٠) | `portal/home,engagements,projects[,/{id}],documents[,/{id}],invoices[,/{id}],conversations[,/{id}]` | `PortalRepository` + `ClientShell` وشاشات البوابة | قشرة حساب العميل كاملة | ONLINE (لا تخبئة — عالم حي) | client_experience + عزل القشرة | IMPLEMENTED |
| إدارة أعضاء العميل (٤) | `clients/{client}/members…` | `ClientMembersRepository` + شاشة الأعضاء | سجل وحدة clients ← «أعضاء العميل» | ONLINE (+ تصعيد بالغرض) | client_experience | IMPLEMENTED |

## الحصيلة

- قدرات الخلفية الجوالية: **75 نقطة / 25 مجموعة** (خلفية v2.447.0 — تجربة العميل §10–§18)
- IMPLEMENTED: **23 مجموعة**
- NOT_APPLICABLE: **1** (إدارة الدفع للمالك — سطح ويب إداري)
- BLOCKED_EXTERNAL_CONFIG: **1** (تفعيل مزود الدفع الحقيقي)
- BACKEND_GAP: بند فرعي واحد (سرد مرفقات سجل) — موثق
- **غير مفسر: 0**
