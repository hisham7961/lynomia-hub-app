# مرجع الواجهة الخلفية (مقروء فقط)

| البند | القيمة |
|---|---|
| المستودع | `hisham7961/lynomia-hub` |
| الفرع المرجعي | `claude/lynomia-hub-enterprise-upgrade-xn4p2t` |
| SHA الدقيق | `791951d0e9e5a53b0832ecd3dd573271e03047d8` |
| ملاحظة المرجع | فرع `claude/new-session-6mm7zs` عند `111d2a6b…` هو دمج الفرع المرجعي، والشجرتان متطابقتان (`git diff` فارغ) |
| نسخة الخلفية | 2.446.0 |
| نسخة عقد الجوال | `1` (`X-API-Version: 1`) |
| نسخة المخطط وقت اللقطة | `4a9f8b3a502e` |
| السطح | `/api/mobile/v1` حصراً — ٥٩ مساراً (سجل القدرات) |

## الوثائق المقروءة بالكامل

- `docs/mobile-readiness/00…10 + FINAL_REPORT + mobile-capabilities.json`
- `docs/information-architecture/` (خاصة 03/05/06)
- `docs/mobile-platform-center/` (فهم تشغيلي — **ليس** شاشة في هذا التطبيق §98)
- المتحكمات الفعلية: `MobileAuthController`, `MobileContextController`,
  `MobileWorkController`, `MobileCommController`, `MobileResourceController`,
  `MobileSyncController`, `MobileFileController`, `MobilePushController`

## قواعد الاستهلاك الحاكمة

- الخادم يخوّل؛ التطبيق غير موثوق — لا قرار صلاحية على حالة محلية (§4).
- الترويسات سياق/تليمتري تضيّق ولا توسّع أبداً.
- التفريع على `code` الآلي لا نص الرسالة.
- `sync_class` خادمي يطاع ولا يتجاوز محلياً.
- النقص التعاقدي يوثق في `docs/backend-change-requests.md` — لا يُعدل Laravel من هنا.
