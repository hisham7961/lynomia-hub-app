# البيئات (§9)

البيئة تحقن **وقت البناء**:

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000

flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://hub.example.com
```

| المتغير | القيم | ملاحظات |
|---|---|---|
| `APP_ENV` | `dev` (افتراض) · `staging` · `prod` | |
| `API_BASE_URL` | أصل الخادم بلا مسار | يُلحق به `/api/mobile/v1` تلقائياً |

**بوابة الأمان (`AppEnv.validate` — قبل أي شبكة):**

- الإنتاج: مضيف غائب أو `http://` ⇒ فشل إقلاع صريح (شاشة خطأ إعداد)، لا سقوط
  صامت. لا اسم مضيف إنتاجي مكتوب في الشيفرة — يمرر وقت البناء.
- التطوير: HTTP المحلي مجاز صراحة (محاكيات).

لا تعطيل TLS ولا «قبول كل الشهادات» في أي بيئة (§87). لا تثبيت شهادات
(pinning) بلا تصميم تدوير تشغيلي — غير مفعّل عمداً.

## خيارات الدفع وهوية المنصة (v0.7.0)

| المتغير | النوع | ملاحظات |
|---|---|---|
| `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_STORAGE_BUCKET` | `--dart-define` | مشتركة بين المنصتين |
| `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID` | `--dart-define` | Android — معرّف التطبيق يحمل `:android:` |
| `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID` | `--dart-define` | iOS — معرّف التطبيق يحمل `:ios:` |
| `lynomia.applicationId` / `LYNOMIA_ANDROID_APP_ID` | Gradle `-P` / بيئة | حزمة Android |
| `lynomia.appLinkHost` / `LYNOMIA_APP_LINK_HOST` | Gradle `-P` / بيئة | نطاق App Links |
| `APP_BUNDLE_ID`, `APP_TEAM_ID`, `APP_LINK_HOST` | `ios/Flutter/AppIdentity.local.xcconfig` | هوية iOS |

الأسهل: `--dart-define-from-file=firebase.defines.json` (القالب `firebase.defines.example.json`، والملف متجاهَل).
أي خيارٍ إلزاميٍّ ناقص ⇒ الدفع «غير مهيأ» ولا يتعطل شيء. التفاصيل: `docs/OWNER_SETUP.md`.
