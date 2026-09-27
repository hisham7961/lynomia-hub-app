# مصفوفة تغطية القدرات (§124)

المصدر: `contracts/mobile-capabilities.json` (٩٣ نقطة · ٢٨ مجالاً · خلفية v2.614.0). الحالة:
`IMPLEMENTED` مبنية ومختبرة · `NOT_APPLICABLE` ليست شاشة جوال بطبيعتها ·
`BLOCKED_EXTERNAL_CONFIG` تنتظر اعتماداً خارجياً فقط · `BACKEND_GAP` فجوة عقد ·
`PENDING_APP` قدرةٌ خلفيّةٌ قائمةٌ لم تُبنَ في التطبيق بعد (لا زرَّ لها — لا واجهة ميتة) — لا شيء منها الآن.

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
| تفاعلات التعليقات وDM (٢) | `comments/{id}/react`, `dm/messages/{id}/react` | `CommentRepository.react` · `DmRepository.react` | زر «أضف تفاعلاً» وشرائح قابلة للنقر في لوحة التعليقات (السجل والقناة) · ضغطٌ مطوّل على رسالة DM | ONLINE (تبديلٌ ليس عديم الأثر ⇒ لا مفتاح ولا إعادة تلقائية) | collab_work_docs + contract | IMPLEMENTED (قائمة رسائل DM لا تحمل التفاعلات: تُعرض ما أعاده الخادم في الجلسة — backend-change-requests.md#6) |
| مؤشر الكتابة و«منذ» في DM والمحادثات (٥) | `dm/threads/{user}/typing,since`, `conversations`, `conversations/{id}/since,typing` | `DmRepository.since/typing` · `CollabRepository.conversations/channelSince/channelTyping` · `SinceFeed` · `VisiblePoller` · `TypingThrottle` | الرسائل ← «القنوات» ← القناة (تعليقات `module=channel` + نشر) · محادثة DM | ONLINE — استطلاع ٤–٥ ث لا يعمل إلا والشاشة ظاهرة والتطبيق في المقدّمة؛ نبضة كتابة ≤١/٤ ث تتوقف عند ٤٠٤ (القدرة `collab.typing` مطفأة) | collab_work_docs + contract | IMPLEMENTED (لا مؤشر ابتدائي من الخادم ⇒ لحاقٌ بالصفحات حتى الذيل — backend-change-requests.md#4) |
| الحضور (١) | `presence` | `CollabRepository.presence` (دفعات ≤١٠٠) | نقطة حضور في خيوط DM + حالة الطرف في رأس المحادثة | ONLINE — ٤٠٤ (`collab.presence` مطفأة) ⇒ بلا نقاط ولا خطأ | collab_work_docs + contract | IMPLEMENTED |
| المحفوظات (١) | `saved` | `CollabRepository.saved` | الرسائل ← أيقونة المحفوظات | ONLINE (مُعادة التخويل خادمياً؛ غير المتاح بلا جسم) | collab_work_docs + contract | IMPLEMENTED (قراءة فقط — لا نقطة جوال للحفظ/الإزالة ولا وجهة للمحفوظة: backend-change-requests.md#7) |
| عملي اليوم والتقرير اليومي (٢) | `work/today`, `work/daily-report` | `WorkRepository.today/dailyReport` | مهامي ← بطاقة «يومي» ← التقرير اليومي (تنقّل بالأيام) + زر تقديم بندٍ في وحدة `submit_hint` حين `can.a` في المخطط | ONLINE | collab_work_docs + contract | IMPLEMENTED (`no_employee_profile` حالة صادقة لا خطأ؛ الرد بلا غلاف `data` — backend-change-requests.md#5) |
| وثائقي (٢) | `me/documents[,/{id}/file]` | `MyDocumentsRepository` | حسابي ← وثائقي ← معاينة | ONLINE — البايتات في الذاكرة فقط، لا قرص ولا خبيئة | collab_work_docs + contract | IMPLEMENTED (المعاينة للصور؛ غيرها يُذكر بصدق أنه يُفتح من الويب — لا عارض PDF بلا كتابة قرص) |
| «اسأل Hub» (سؤال · متابعة · محادثات · حذف) | `ask`, `ask/threads[,/{id}]` | `AskRepository` | بطاقة الرئيسية (بعلَم `can_ask`) ← المحادثة + محادثاتك | ONLINE (لا إعادة تلقائية — نداءٌ مدفوع) | ask_test + contract | IMPLEMENTED |
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

- قدرات الخلفية الجوالية: **93 نقطة / 28 مجالاً** (خلفية v2.614.0)
- IMPLEMENTED: **30 مجموعة** (منها ٦ مجموعات / ١٣ نقطة بُنيت في v0.4.0)
- NOT_APPLICABLE: **1** (إدارة الدفع للمالك — سطح ويب إداري)
- BLOCKED_EXTERNAL_CONFIG: **1** (تفعيل مزود الدفع الحقيقي)
- BACKEND_GAP: بنود فرعية موثقة لا تمنع أي قدرة (سرد مرفقات سجل · مؤشر «منذ» الابتدائي · تفاعلات قائمة DM · غلاف `work/today` · حفظ المحفوظات من الجوال) — راجع backend-change-requests.md
- PENDING_APP: **0** (النقاط الثلاث عشرة التي أُضيفت في الخلفية بعد v2.447 مبنيّةٌ في v0.4.0)
- **غير مفسر: 0**
