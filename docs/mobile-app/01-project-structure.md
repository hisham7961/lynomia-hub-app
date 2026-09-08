# 01 · بنية المشروع

```
lib/
  app/            التركيب: DI، الإقلاع، الموجه، الجذر
  core/
    api/          ApiClient (تجديد أحادي الرحلة، Idempotency، If-Match، ETag)
    auth/         المصادقة والجلسة ومخزن الرموز الآمن
    config/       بيئات + معرفات (REPLACE_BEFORE_STORE_RELEASE)
    errors/       ApiException — التفريع على `code` حصراً
    push/         مسجل الدفع (مزود صفري صادق حتى تُضبط الاعتمادات)
    security/     البوابة البيومترية + مسجل يحجب الأسرار
    storage/      خبيئة AES-256-GCM + مخزن آمن + تفضيلات
    sync/         محرك المزامنة (sync_class خادمية القيادة)
    ui/           حالات الشاشة + تدفق التصعيد
  features/
    activation/   تفعيل حساب العميل (§13)
    portal/       بوابة العميل: القشرة والبيت والوجهات (§12 §17 §18)
    members/      إدارة أعضاء العميل للمدير الداخلي (§15)
    …             (auth, home, my_work, modules, records, approvals,
                   comments, messages, files, scanner, tracking,
                   notifications, search, profile, shell, workspaces, launch)
  l10n/           ARB عربي/إنجليزي — لا نص واجهة صلباً
contracts/        لقطات العقد (تُحدَّث عمداً عبر tool/update_contracts.sh)
test/             fakes/ + core/ + features/ + widget/ + contract/ + governance
docs/             هذه الوثائق + وثائق الطور الأول
```

قاعدة الطبقات: الشاشة تستهلك مستودعاً، والمستودع يستهلك `ApiClient` فقط،
ولا يستورد `core/` شيئاً من `features/`.
