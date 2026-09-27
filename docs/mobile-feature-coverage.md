# مصفوفة تغطية القدرات (§124)

المصدر: `contracts/mobile-capabilities.json` (٩٥ نقطة · ٢٨ مجالاً · خلفية v2.617.0 @d02525c). الحالة:
`IMPLEMENTED` مبنية ومختبرة · `NOT_APPLICABLE` ليست شاشة جوال بطبيعتها ·
`BLOCKED_EXTERNAL_CONFIG` تنتظر اعتماداً خارجياً فقط · `BACKEND_GAP` فجوة عقد ·
`PENDING_APP` قدرةٌ خلفيّةٌ قائمةٌ لم تُبنَ في التطبيق بعد (لا زرَّ لها — لا واجهة ميتة) — لا شيء منها الآن.

**القدرات الجوالية غير المفسرة الغائبة = 0.**

| قدرة الخلفية | العقد | موضع التطبيق | مدخل الواجهة | سياسة الاتصال | الاختبارات | الحالة |
|---|---|---|---|---|---|---|
| دخول/MFA/تحديث/خروج/خروج شامل | `auth/login,mfa/verify,refresh,logout,logout-all` | `core/auth` | شاشة الدخول + حسابي | ONLINE | auth_flow + api_client | IMPLEMENTED |
| جلسات الجوال + إبطال | `auth/sessions[,/{id}]` | `AuthRepository.sessions/revoke` | حسابي ← الجلسات | ONLINE | auth_flow + screens_widget | IMPLEMENTED |
| التصعيد | `auth/step-up` | `runWithStepUp` | حوار عند 428 | ONLINE | auth_flow | IMPLEMENTED |
| app-config/health | `app-config`, `health` | `AppConfigRepository` + `ResumeCoordinator` + `LaunchController.applyHealth` | بوابة الإقلاع · فحص `health` عند العودة للمقدّمة (مقيّد بدقيقة) ⇒ شاشة صيانة/إغلاق/تحديث حاجب · تلميح `latest` الاختياري ورابط `support_url` في حسابي وبوابات الحجب | عامة | auth_flow + widget + resume_coordinator + phase1_app | IMPLEMENTED |
| bootstrap/context/navigation | `bootstrap,context,navigation` | `BootstrapRepository`/`AccountState` | الإقلاع + المجالات + مبدل السياق | ETag | widget + وحدات | IMPLEMENTED |
| المخطط | `schema[,/modules]` | `ModuleRepository.schema` | كل شاشات المحرك | ETag | module_engine | IMPLEMENTED |
| CRUD العام (٦) | `{module}…` | `ModuleRepository` | قائمة/سجل/نموذج عامة | ONLINE + خبيئة قراءة | module_engine + widget | IMPLEMENTED |
| الإجراءات (٢) | `{module}/{id}/actions…` | `ModuleRepository.actions/runAction` | تبويب الإجراءات | ONLINE | module_engine | IMPLEMENTED |
| المزامنة | `sync/{module}` | `SyncEngine` + `SyncScheduler` + `ResumeCoordinator` | تُشغَّل عند فتح قائمة الوحدة وعند الإقلاع/الاستئناف للوحدات `CACHEABLE_*` وحدها؛ قائمة الوحدة تسقط للخبيئة دون اتصال بلافتة ووقت آخر مزامنة | حسب `sync_class` — الحساس/الحي لا يُطلب ويُمحى أثره | sync_engine + sync_scheduler + phase1_app | IMPLEMENTED |
| البيت | `home` | `HomeRepository` | الرئيسية + مهامي | ONLINE | widget | IMPLEMENTED |
| البحث | `search` | `SearchRepository` | وجهة البحث | ONLINE | comm + widget | IMPLEMENTED |
| تفاعلات التعليقات وDM (٢) | `comments/{id}/react`, `dm/messages/{id}/react` | `CommentRepository.react` · `DmRepository.react` · `applyToggle` | زر «أضف تفاعلاً» وشرائح قابلة للنقر في لوحة التعليقات (السجل والقناة) · ضغطٌ مطوّل على رسالة DM | ONLINE (تبديلٌ ليس عديم الأثر ⇒ لا مفتاح ولا إعادة تلقائية) | collab_work_docs + collab_v2 + contract | IMPLEMENTED (ملخّص تفاعلات DM من القائمة وأحداث «منذ» — #6 محلول) |
| مؤشر الكتابة و«منذ» في DM والمحادثات (٥) | `dm/threads/{user}/typing,since`, `conversations`, `conversations/{id}/since,typing` | `DmRepository.thread/since/typing` · `CollabRepository.conversations/channelSince/channelTyping` · `SinceFeed.seed` · `VisiblePoller` · `TypingThrottle` | الرسائل ← «القنوات» ← القناة (تعليقات `module=channel` + نشر) · محادثة DM | ONLINE — «منذ» يبدأ من مؤشر الذيل الذي يعيده تحميل الخيط (`cursor` — #4 محلول)؛ استطلاع ٤–٥ ث لا يعمل إلا والشاشة ظاهرة والتطبيق في المقدّمة؛ الكتابة بعلم `feature_flags.collab_typing` (غيابه ⇒ تجربة وبديل ٤٠٤) | collab_work_docs + collab_v2 + contract | IMPLEMENTED (خادمٌ أقدم بلا مؤشر ⇒ لحاقٌ محدود بالصفحات) |
| الحضور (١) | `presence` | `CollabRepository.presence` (دفعات ≤١٠٠) | نقطة حضور في خيوط DM + حالة الطرف في رأس المحادثة | ONLINE — بعلم `feature_flags.collab_presence` (#8 محلول؛ غيابه ⇒ تجربة و٤٠٤ ⇒ بلا نقاط ولا خطأ) | collab_work_docs + collab_v2 + contract | IMPLEMENTED |
| المحفوظات (٣) | `saved` (GET · POST) · `saved/{id}` (DELETE) | `CollabRepository.saved/save/unsave` · `SavedTarget` · `saveWithUndo` | الرسائل ← أيقونة المحفوظات (فتح الوجهة · إزالة) · «احفظ» على التعليق وفي ضغط رسالة DM المطوّل بتراجعٍ فوري | ONLINE — POST «حفظٌ لا تبديل» ⇒ إعادة عابرة آمنة؛ DELETE بلا إعادة | collab_work_docs + collab_v2 + contract | IMPLEMENTED (#7 محلول؛ منشور `feed` بلا شاشة جوال ⇒ لا فتح) |
| عملي اليوم والتقرير اليومي (٢) | `work/today`, `work/daily-report` | `WorkRepository.today/dailyReport` · `isNoEmployeeProfile` | مهامي ← بطاقة «يومي» ← التقرير اليومي (تنقّل بالأيام) + زر تقديم بندٍ في وحدة `submit_hint` حين `can.a` في المخطط | ONLINE | collab_work_docs + collab_v2 + contract | IMPLEMENTED (الغلاف `data` مقروء، و«لا ملف موظف» بـ`BUSINESS_RULE_VIOLATION` + `details.reason` مع بديل الرمز الخام للخادم الأقدم — #5 محلول إضافياً) |
| وثائقي (٢) | `me/documents[,/{id}/file]` | `MyDocumentsRepository` | حسابي ← وثائقي ← معاينة | ONLINE — البايتات في الذاكرة فقط، لا قرص ولا خبيئة | collab_work_docs + contract | IMPLEMENTED (المعاينة للصور؛ غيرها يُذكر بصدق أنه يُفتح من الويب — لا عارض PDF بلا كتابة قرص) |
| «اسأل Hub» (سؤال · متابعة · محادثات · حذف) | `ask`, `ask/threads[,/{id}]` | `AskRepository` | بطاقة الرئيسية (بعلَم `can_ask`) ← المحادثة + محادثاتك | ONLINE (لا إعادة تلقائية — نداءٌ مدفوع) | ask_test + contract | IMPLEMENTED |
| الإشعارات (٥) | `notifications…` | `NotificationRepository` + `ResumeCoordinator` | شاشة الإشعارات: غير المقروء يُختم بـ`read` والمقروء يُحلّ بـ`GET target` ⇒ `/r/{module}/{id}`، وnull ⇒ البقاء في القائمة · الشارة حيّة من `unread-count` عند الجاهزية/الاستئناف وبعد القراءة | ONLINE (مؤشر) | comm + widget + phase1_app + resume_coordinator | IMPLEMENTED (فتح الهدف من حمولة الدفع ينتظر مزوّد FCM — المرحلة ٢) |
| التعليقات (٢) | `comments` | `CommentRepository` | تبويب تعليقات السجل | ONLINE | comm | IMPLEMENTED |
| DM (٤) | `dm/threads…` | `DmRepository` | الرسائل | ONLINE | comm | IMPLEMENTED |
| الاعتمادات (٤) | `approvals…` | `ApprovalRepository` | طابور/تفصيل/حسم · والكتابة المحمية (`202 APPROVAL_REQUIRED`) تُعرض «صُفَّ للمعتمدين» بوجهة الطلب في النموذج والتعديل والحذف والإجراءات | ONLINE | comm + screens_widget | IMPLEMENTED |
| التفضيلات (٣) | `prefs[,/pin]` | `PrefsRepository` + `PrefsScreen` | حسابي ← التفضيلات: كتم أنواع الإشعار (`notify.muteable` الخادمية — الكتم بالنوع لا بالوحدة، كالويب) وتثبيت/فكّ الوجهات بسقف الخادم · «مثبتاتي» على الرئيسية من `pins.pinned` | ONLINE — الكتم استبدال عديم الأثر؛ التثبيت بمفتاح idempotency للنقرة | phase1_app | IMPLEMENTED (داخلي فقط — `prefs` خارج قائمة العميل خادمياً) |
| الملفات (٦) | `files/…` | `FileRepository` + `AttachmentsPanel` + `AttachmentPreviewScreen` | تبويب المرفقات: رفع مقطّع، و«فتح» للمرفوع — الصورة تُنزَّل (`files/{id}/download`) وتُعرض **من الذاكرة** بلا قرص، وغيرها يُفتح بصدقٍ من صفحة السجل على الويب (لا ملف مؤقت) · حقول file/img تُفتح من الويب (قيمتها مسار تخزين لا معرّف مرفق) | ONLINE — لا بايت يهبط القرص | comm + widget + screens_widget | IMPLEMENTED (سرد المرفقات القائمة: BACKEND_GAP #1؛ `files/{id}/stream` غير مستعمل — التنزيل يكفي للصور؛ لا عارض PDF أصلي بلا كتابة قرص) |
| الماسح | `identity/resolve/{q}` | `IdentityRepository` + الماسح (`ScanViewBuilder` قابل للاستبدال) | أيقونة الرأس | ONLINE | comm + screens_widget | IMPLEMENTED |
| التتبع (٣) | `tracking/…` | `TrackingRepository` + `LocationSource` + شاشة التتبع | حسابي ← التتبع | ONLINE (دفعات) | comm + screens_widget | IMPLEMENTED |
| تسجيل الدفع (٢) | `push/register,unregister` | `PushRegistrar` | تلقائي عند الدخول/الخروج | ONLINE | push_biometric (بمزوّد مزيّف) | BLOCKED_EXTERNAL_CONFIG (لا اعتماد FCM/APNs — المزود الصفري صادق؛ المنطق مختبر بمزوّد مزيّف) |
| إدارة الدفع (٢) | `push/admin/status,test` | — | — | — | — | NOT_APPLICABLE (إدارة مالك — مركز المنصة ويب §98) |
| openapi.json | `openapi.json` | `contracts/mobile-openapi.json` | لقطة عقد + أداة تحديث | عامة | contract tests | IMPLEMENTED (لقطة) |
| تفعيل حساب العميل (٢) | `activation/{token}[,/complete]` | `ActivationRepository` + شاشة التفعيل | رابط عميق `/activate/{token}` (عام) | ONLINE (عامة) | client_experience | IMPLEMENTED |
| بوابة العميل (١٠) | `portal/home,engagements,projects[,/{id}],documents[,/{id}],invoices[,/{id}],conversations[,/{id}]` | `PortalRepository` + `ClientShell` وشاشات البوابة | قشرة حساب العميل كاملة | ONLINE (لا تخبئة — عالم حي) | client_experience + عزل القشرة + screens_widget (تفاصيل المشروع/الفاتورة/الوثيقة) | IMPLEMENTED |
| إدارة أعضاء العميل (٤) | `clients/{client}/members…` | `ClientMembersRepository` + شاشة الأعضاء | سجل وحدة clients ← «أعضاء العميل» | ONLINE (+ تصعيد بالغرض) | client_experience + screens_widget | IMPLEMENTED |

## الحصيلة

- قدرات الخلفية الجوالية: **95 نقطة / 28 مجالاً** (خلفية v2.617.0)
- IMPLEMENTED: **30 مجموعة** (منها ٦ مجموعات / ١٥ نقطة بُنيت في v0.4.0–v0.5.0)
- **v0.6.0 (المرحلة ١):** النقاط التي كانت «موصولة بلا واجهة» صارت مستعملةً من الواجهة فعلاً — `sync/{module}`
  (تُشغَّل في الإنتاج)، `prefs`/`prefs/pin` (شاشة التفضيلات + مثبتات الرئيسية)، `files/{id}/download` (معاينة الصور
  من الذاكرة)، `notifications/{id}/target` و`notifications/unread-count` (الهدف والشارة الحية)، و`health` (عند
  الاستئناف). يبقى بلا واجهة عن قصد: `GET navigation` (الشجرة من `bootstrap.ia`)، و`PATCH {module}/{id}` (PUT
  يكفي)، و`files/{id}/stream` (التنزيل يكفي للصور).
- NOT_APPLICABLE: **1** (إدارة الدفع للمالك — سطح ويب إداري)
- BLOCKED_EXTERNAL_CONFIG: **1** (تفعيل مزود الدفع الحقيقي)
- BACKEND_GAP: بندان فرعيان مفتوحان (سرد مرفقات سجل #1، ومعرّف مرفق الرسالة #2) — #4–#8 حُلّت في خلفية v2.617.0 وبُنيت في v0.5.0
- PENDING_APP: **0** (النقاط الثلاث عشرة التي أُضيفت في الخلفية بعد v2.447 مبنيّةٌ في v0.4.0)
- **غير مفسر: 0**
