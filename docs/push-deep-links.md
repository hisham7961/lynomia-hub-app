# الدفع والروابط العميقة (§73–§77) — v0.7.0

## معمارية الدفع — FCM حين يُهيَّأ، وصادقة NOT_CONFIGURED حين لا

```text
bootPushProvider()                        lib/core/push/firebase_push_boot.dart (الوحيد الذي يستورد Firebase)
 ├─ FirebaseEnv.resolve(platform)          --dart-define FIREBASE_* (lib/core/push/firebase_env.dart)
 │   ├─ ناقص/قالب/منصة خاطئة ⇒ NotConfiguredPushProvider
 │   └─ مكتمل ⇒ Firebase.initializeApp(options) ⇒ FcmPushProvider(FirebaseMessagingAdapter)
 │                                                (فشل التهيئة ⇒ NotConfiguredPushProvider)
PushTokenProvider (واجهة) ── currentToken · tokenRotations · requestPermission
                             foregroundMessages · openedMessages · initialMessage
PushRegistrar      ── POST push/register {token, platform, provider:'fcm'} · push/unregister
PushCoordinator    ── دورة الجلسة + الملاحة + الشارة + الشريط (lib/app/bootstrap/push_coordinator.dart)
NavigationInbox    ── وجهةٌ واردة تنتظر LaunchReady (رابط عميق أو نقرة إشعار)
```

| الحدث | السلوك |
|---|---|
| الجاهزية (دخول، جلسة مستعادة، فتح القفل) | طلب الإذن مرة لكل تشغيل (iOS؛ Android 13+ `POST_NOTIFICATIONS`) ⇒ مُنح: `push/register` · رُفض: الحالة `permissionDenied` بلا تسجيل |
| رمز غير متاح بعد (iOS قبل رمز APNs) | الحالة `ready`؛ يصل عبر `onTokenRefresh` فيُسجَّل |
| تدوير الرمز | تسجيل الجديد ثم إلغاء القديم بهدوء |
| الخروج | `push/unregister` للرمز المسجَّل (يتسامح مع الفشل)؛ إبطال الجلسة ⇒ نسيانٌ محلي (الخادم أبطل الرموز) |
| رسالة في المقدّمة | شريطٌ داخلي (`SnackBar`) بعنوان الحمولة العام وزر «فتح» حين للإشعار وجهة؛ الشارة ⇐ `data.unread`؛ لا تنبيه نظام (iOS `alert:false`) |
| نقرة (خلفية) أو إشعار الإطلاق (إغلاق) | `data.module`+`data.id` ⇒ `/r/{module}/{id}`؛ وإلا `notification_id` ⇒ `GET notifications/{id}/target` (null/فشل ⇒ `/notifications`)؛ قبل الجاهزية يُحفظ ثم يُفتح |
| `category: 'test'` (إشعار تجريبي من المركز) | شريط «وصل إشعارٌ تجريبي…» بلا ملاحة ولا طلب |

- **خصوصية (§75):** الحمولة الخادمية عنوانٌ عام + `{module,id,action}` + عدّ — التطبيق يعاملها إشارة: الوجهة تُفتح
  عبر الموجّه والشاشة تجلب من الخادم الذي يعيد فحص النطاق والصلاحية؛ الرمز لا يُسجَّل في السجلات.
- **ما يلزم للتفعيل** (خيارات Firebase، مفتاح APNs، إعدادات الخادم): `docs/OWNER_SETUP.md` §١–§٢.
- **الاختبار:** `test/core/push_fcm_test.dart` بمحوِّل مراسلةٍ مزيّف (`test/fakes/fakes.dart`) — بلا Firebase ولا منصة.
- **حدود معروفة:** رمز وصول FCM الخادمي ثابتٌ ينتهي خلال ساعة (طلب خلفي #9)؛ لا `apns.badge` ولا قناة Android في
  الحمولة (#10) — شارة أيقونة التطبيق على iOS لا تُحدَّث من الخادم، والشارة داخل التطبيق حيّة. لا معالج رسائل
  خلفية (`onBackgroundMessage`): إشعارات `notification` يعرضها النظام، ولا حمولة data-only من الخادم.

## الروابط العميقة (§76)

الوجهة القانونية `{module, id, action}` من: الإشعارات، البحث، البيت، الاعتمادات، حمولة الدفع. الترميز العالمي
`/m/{module}/{id}[/{action}]` و`/app/*`. `app_links` يلتقط البارد والحي ⇒ `foldDeepLink` (`lib/core/links/deep_link.dart`):
يقبل `https`/`http` فقط، والبادئتين `/m/` و`/app/` فقط، ويرفض المقاطع الفارغة و`..`، ويحفظ الاستعلام، ويطوي
`/app/activate/*` ⇒ `/activate/*` و`/app/*` ⇒ `/m/*` ⇒ الموجّه ⇒ `/r/:module/:id`. الوجهة تمرّ بـ`NavigationInbox`: قبل
الجاهزية تُحفظ (الأحدث يغلب) وتُفتح بعد الدخول/فتح القفل دفعاً فوق الرئيسية.

## Universal / App Links (§77) — مبنية على المنصتين منذ v0.7.0

| | Android | iOS |
|---|---|---|
| الالتقاط | `intent-filter android:autoVerify="true"` (VIEW, DEFAULT, BROWSABLE, `https`, `pathPrefix` `/m/` و`/app/`) | `com.apple.developer.associated-domains` = `applinks:$(APP_LINK_HOST)` في `Runner/Runner.entitlements` (موصول بـ`CODE_SIGN_ENTITLEMENTS` لـDebug/Release/Profile) |
| النطاق | `manifestPlaceholders["appLinkHost"]` من `lynomia.appLinkHost` / `LYNOMIA_APP_LINK_HOST` | `APP_LINK_HOST` في `ios/Flutter/AppIdentity(.local).xcconfig` |
| الافتراضي | `app-links.lynomia.invalid` — نطاقٌ محجوز لا يُحلّ: لا ادعاء ربط | ← نفسه |
| التحقق الخادمي | `/.well-known/assetlinks.json` ⇐ `mobile.dl_android_package` + `dl_android_fingerprints` | `/.well-known/apple-app-site-association` ⇐ `mobile.dl_apple_team_id` + `dl_apple_bundle_id` |

الخطوات الدقيقة والتحقق (`X-Deep-Links-Status: CONFIGURED`، `adb shell pm get-app-links`): `docs/OWNER_SETUP.md` §٣–§٤.
لا قيم توقيع مخترعة.
