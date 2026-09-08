# 17 · قائمة الإنتاج (§56)

> مرآة بوابة الإتمام — تراجع بصدق قبل أي إعلان جاهزية. الحالة الراهنة
> مفصلة في `docs/FINAL_BUILD_REPORT.md`.

## قبل أي إصدار متجر (كلها حالياً ناقصة خارجياً — BLOCKED_EXTERNAL)

- [ ] معرفات الحزم الحقيقية بدل `REPLACE_BEFORE_STORE_RELEASE`
- [ ] توقيع iOS + Android (شهادات/keystore خارج المستودع)
- [ ] اعتمادات الدفع (FCM/APNs) + `GET push/admin/status` = configured
- [ ] Universal/App Links مضبوطة (`X-Deep-Links-Status: CONFIGURED`)
- [ ] بوابة الإصدار (min/latest) وروابط المتجر والدعم في إعدادات الخادم

## عند كل دفعة (مفروضة آلياً)

- [x] `dart format --set-exit-if-changed .` + `flutter analyze` + `flutter test`
- [x] الخلفية على المحركين إن تغيرت (`phpunit` + `phpunit.mysql.xml`)
- [x] النسخة في المواضع الأربعة (`governance_test.dart`)
- [x] لقطات العقد حديثة (`test/contract/`)

## أمن قبل الإصدار

- [x] لا أسرار في المستودع، والرموز لا تسجل (اختبارات المسجل الحاجب)
- [x] عزل العميل مثبت خادمياً بنداء مباشر (§47 — حزمة الخلفية) وفي القشرة
- [x] `SENSITIVE_NO_PERSIST` لا يهبط القرص (اختبار)
- [ ] مراجعة أذونات المنصة النهائية (كاميرا/موقع/إشعارات) بنصوص متجر حقيقية
