# جرد الشاشات (§125)

| المسار | الغرض | اعتماد الخلفية | الصلاحية/القدرة | دون اتصال | الرابط العميق |
|---|---|---|---|---|---|
| `/launch` | بوابة الإقلاع الحتمية | `app-config` (+`bootstrap` عند جلسة) | عامة | حالات صريحة: انقطاع/صيانة/قفل/تحديث | يُنتظر ثم يعاد التوجيه |
| `/login` | دخول + MFA | `auth/login`, `auth/mfa/verify` | عامة | رسالة شبكة صادقة | — |
| `/home` | الرئيسية (+ مثبتاتي من الخادم) | `home`, `prefs` | الجلسة | خطأ قابل للإعادة | عناصرها وجهات `{module,id}` |
| `/mywork` | مهامي (تجميع) | `home`, `dm/threads` | الجلسة | كالرئيسية | مداخل للاعتمادات/الإشعارات/الرسائل |
| `/domains`, `/domains/:key` | المجالات ← أقسام ← وجهات | `bootstrap.ia`/`navigation` | منطق خادمياً | من لقطة bootstrap | وجهات module ⇒ `/m/*` |
| `/search` | البحث الشامل | `search` | نتائج منطقية | يتطلب اتصالاً (لا بحث خبيئة كسلطة) | كل نتيجة ⇒ `/r/*` |
| `/account` | الهوية/السياق/الأمان/التفضيلات | `bootstrap`, `prefs` | الجلسة | يعرض اللقطة | — |
| `/account/prefs` | التفضيلات (كتم أنواع الإشعار · تثبيت الوجهات) — v0.6.0 | `prefs`, `PUT prefs`, `POST prefs/pin` | الجلسة (داخلي فقط) | يتطلب اتصالاً | — |
| `/account/sessions` | جلسات الجوال | `auth/sessions` | الجلسة | يتطلب اتصالاً | — |
| `/account/diagnostics` | تشخيص المطور | حالة محلية | **debug فقط** | يعمل | — |
| `/m/:module` | قائمة الوحدة العامة | `schema`, `{module}` | `can.v` (المحجوب 403/فارغ) | سقوط خبيئة بلافتة للوحدات القابلة | `/m/{module}` |
| `/m/:module/new` | إنشاء عام | `schema`, `POST {module}` | `can.a` (الزر يغيب بدونها) | يتطلب اتصالاً | — |
| `/r/:module/:id` | شاشة السجل العامة | `{module}/{id}`, `actions`, `comments` | خادمية لكل تبويب | يتطلب اتصالاً (404/403 صادقة) | **وجهة `/m/{module}/{id}` القانونية** |
| `/r/:module/:id/edit` | تعديل عام | `PUT/PATCH` + If-Match | `can.e` | يتطلب اتصالاً | — |
| `/notifications` | الإشعارات | `notifications*` | هوية خاصة | يتطلب اتصالاً | النقر يحل `target` ويلاحح |
| `/messages`, `/messages/:userId` | DM | `dm/*` | خصوصية الطرفين خادمياً | يتطلب اتصالاً | — |
| `/approvals`, `/approvals/:id` | الاعتمادات | `approvals*` | طابور المعتمد خادمياً | يتطلب اتصالاً | وجهة السجل الهدف |
| `/scanner` | الماسح | `identity/resolve/{q}` | إذن كاميرا عند الفتح | يتطلب اتصالاً للحل | يلاحح للكيان المحلول |
| `/tracking` | التتبع الميداني | `tracking/*` | موافقة صريحة + إذن موقع | دفعات تبقى للمحاولة التالية | — |
| `/me/custody` | عهدتي + إقرار الاستلام — v0.9.0 | `me/custody`, `assets/{id}/actions/ack` | الجلسة (داخلي) | يتطلب اتصالاً | الأصل ⇒ `/r/assets/{id}` |
| `/inventory`, `/inventory/:id`, `/inventory/:id/scan` | جلسات الجرد: تجميد، تفصيل، مسح متتابع، مصالحة/إغلاق بالتصعيد — v0.9.0 | `inventory/sessions*` | `assets.can.v` للمدخل + `can` الخادمية للأفعال | يتطلب اتصالاً | الصنف ⇒ `/r/assets/{id}` |
| `/r/:module/:id/versions` | نسخ السجل + الاستعادة — v0.9.0 | `{module}/{id}/versions`, `actions/restore-version` | `restorable` خادمياً + التصعيد | يتطلب اتصالاً | — |
| `/portal/tickets`, `/portal/tickets/:id` | «تذاكري» في قشرة العميل — v0.9.0 | `portal/tickets*` | حساب العميل وحده | يتطلب اتصالاً | — |
| `/conversations/directory`, `/conversations/new-group`, `/conversations/:id/members` | دليل القنوات، مجموعة جديدة، الأعضاء — v0.9.0 | `conversations/*`, `groups` | العضوية/`can_manage` خادمياً | يتطلب اتصالاً | الانضمام ⇒ `/conversations/{id}` |
| `/messages/search` | بحث نصّ الرسائل — v0.9.0 | `search/messages` | ما يراه القارئ خادمياً | يتطلب اتصالاً | النتيجة ⇒ وجهتها القانونية |
| `/reports/daily` | مراجعة تقارير الفريق — v0.9.0 | `reports/daily*` | مراجِع بقبول الخادم (٤٠٣ ⇒ لا مدخل) | يتطلب اتصالاً | — |
| `/calendar`, `/alerts` | التقويم الموحّد والتنبيهات — v0.9.0 | `calendar`, `alerts` | خادمية (hub_can/scope/field_mode) | يتطلب اتصالاً | العنصر ⇒ `/r/*` أو وثائقي |
