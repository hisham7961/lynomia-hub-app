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
