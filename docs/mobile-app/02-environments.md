# 02 · البيئات

`lib/core/config/app_env.dart` — بيئتان:

| | dev | prod |
|---|---|---|
| `apiBaseUrl` | يحدد وقت التشغيل (dart-define) | ثابت الإصدار |
| HTTP غير المشفر | مسموح للمضيف المحلي فقط | ممنوع (https إلزامي) |
| التشخيص | شاشة Diagnostics (kDebugMode) | مطفأة |

- القاعدة تمرر عبر `--dart-define=LYNOMIA_API_BASE_URL=…` — لا سر في الشيفرة.
- المعرفات المؤقتة (حِزم iOS/Android، معرف الفريق) مركزها
  `lib/core/config/app_identifiers.dart` موسومة `REPLACE_BEFORE_STORE_RELEASE`.
- `GET app-config` قبل الدخول تحمل الصيانة/القفل/بوابة الإصدار — الإقلاع
  يحترمها قبل أي شاشة (انظر `docs/environments.md` للطور الأول).
