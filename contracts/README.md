# لقطات العقد — contracts/

الخادم (`hisham7961/lynomia-hub`) يبقى مصدر الحقيقة؛ هذه **لقطات** تُحدَّث عمداً:

| الملف | المصدر | الغرض |
|---|---|---|
| `backend-source.json` | يدوي عبر الأداة | مرجع الخلفية: المستودع/الفرع/SHA/نسخة العقد/تاريخ اللقطة |
| `mobile-capabilities.json` | `docs/mobile-readiness/mobile-capabilities.json` في الخلفية | سجل القدرات الآلي (٩٥ نقطة + أصناف المزامنة + NOT_CONFIGURED) |
| `mobile-openapi.json` | `GET /api/mobile/v1/openapi.json` (أو `App\Support\MobileOpenApi::spec()` عبر tinker على نسخة عمل بقاعدة SQLite مؤقتة) | مواصفة OpenAPI 3.1 الحية للجوال |

**التحديث:** `tool/update_contracts.sh /path/to/lynomia-hub [https://host]` — يسجل
الـSHA الجديد ويجلب اللقطات. **لا** تُجدَّد اللقطات ضمن بناء عادي؛ انحرافها يظهر في
`git diff` وتحرسه اختبارات `test/contract/`.
