// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'لينوميا هب';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMyWork => 'مهامي';

  @override
  String get navDomains => 'المجالات';

  @override
  String get navSearch => 'البحث';

  @override
  String get navAccount => 'حسابي';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionCreate => 'إنشاء';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionOpen => 'فتح';

  @override
  String get actionSend => 'إرسال';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get actionLogin => 'تسجيل الدخول';

  @override
  String get actionLogout => 'تسجيل الخروج';

  @override
  String get actionLogoutAll => 'الخروج من كل الجلسات';

  @override
  String get actionApprove => 'اعتماد';

  @override
  String get actionReject => 'رفض';

  @override
  String get actionShowAll => 'عرض الكل';

  @override
  String get stateLoading => 'جارٍ التحميل…';

  @override
  String get stateEmpty => 'لا عناصر لعرضها';

  @override
  String get stateOffline => 'لا اتصال بالإنترنت';

  @override
  String get stateOfflineCached => 'أنت دون اتصال — تُعرض نسخة مخبأة';

  @override
  String get stateError => 'حدث خطأ';

  @override
  String get stateSyncing => 'جارٍ المزامنة…';

  @override
  String stateLastSynced(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get requiresConnection => 'يتطلب اتصالاً بالإنترنت';

  @override
  String get loginTitle => 'تسجيل الدخول إلى Lynomia';

  @override
  String get loginEmail => 'البريد الإلكتروني';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginInvalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get loginRequired => 'هذا الحقل مطلوب';

  @override
  String get mfaTitle => 'التحقق بخطوتين';

  @override
  String get mfaHint => 'أدخل رمز التحقق من تطبيق المصادقة';

  @override
  String get mfaCode => 'رمز التحقق';

  @override
  String get mfaExpired => 'انتهت مهلة التحدي — أعد تسجيل الدخول';

  @override
  String get stepUpTitle => 'تأكيد الهوية';

  @override
  String get stepUpPassword => 'أدخل كلمة المرور للمتابعة';

  @override
  String get stepUpTotp => 'أدخل رمز التحقق الحالي للمتابعة';

  @override
  String get biometricUnlockTitle => 'فتح Lynomia Hub';

  @override
  String get biometricUnlockReason => 'افتح القفل للوصول إلى جلستك';

  @override
  String get biometricPrefTitle => 'الفتح بالبصمة/الوجه';

  @override
  String get biometricPrefSubtitle =>
      'قفل محلي على هذا الجهاز — لا يُرسل شيء للخادم';

  @override
  String get sessionExpired => 'انتهت الجلسة — سجّل الدخول من جديد';

  @override
  String get sessionRevoked =>
      'جلستك لم تعد صالحة — أُبطلت من جهاز آخر أو من الإدارة';

  @override
  String get accountRestricted => 'الحساب مقيد — راجع الإدارة';

  @override
  String get maintenanceTitle => 'صيانة مجدولة';

  @override
  String get maintenanceBody => 'الخادم في صيانة مؤقتة. حاول لاحقاً.';

  @override
  String get lockdownTitle => 'قفل أمني';

  @override
  String get lockdownBody => 'الدخول موقوف مؤقتاً بقرار أمني.';

  @override
  String get updateRequiredTitle => 'تحديث مطلوب';

  @override
  String get updateRequiredBody =>
      'إصدار التطبيق أقدم من الحد الأدنى المدعوم. حدّث للمتابعة.';

  @override
  String get updateStoreButton => 'فتح المتجر';

  @override
  String get updateStoreNotConfigured =>
      'رابط المتجر غير مهيأ بعد — تواصل مع الدعم للحصول على الإصدار الأحدث.';

  @override
  String get serverUnavailable => 'تعذر الوصول إلى الخادم';

  @override
  String get homeAttention => 'يتطلب انتباهك';

  @override
  String get homeDue => 'تقترب مواعيدها';

  @override
  String get homeMyTasks => 'مهامي المفتوحة';

  @override
  String get homeProjects => 'مشاريعي';

  @override
  String get homeRecent => 'آخر النشاطات';

  @override
  String get homeApprovalsPending => 'اعتمادات معلقة';

  @override
  String get myWorkTitle => 'مهامي';

  @override
  String get myWorkTasks => 'المهام المسندة إليّ';

  @override
  String get myWorkApprovals => 'الاعتمادات';

  @override
  String get myWorkNotifications => 'الإشعارات';

  @override
  String get myWorkMessages => 'الرسائل';

  @override
  String get domainsTitle => 'المجالات';

  @override
  String get searchTitle => 'البحث';

  @override
  String get searchHint => 'ابحث في كل ما تراه…';

  @override
  String get searchMinChars => 'أدخل حرفين على الأقل';

  @override
  String get searchNoResults => 'لا نتائج مطابقة';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get accountSessions => 'جلسات الجوال';

  @override
  String get accountSessionCurrent => 'الجلسة الحالية';

  @override
  String get accountSessionRevoke => 'إبطال الجلسة';

  @override
  String get accountContext => 'سياق العرض';

  @override
  String get accountContextCompany => 'الشركة';

  @override
  String get accountContextClient => 'العميل';

  @override
  String get accountContextAll => 'الكل (بلا تضييق)';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get accountTheme => 'المظهر';

  @override
  String get accountThemeSystem => 'حسب النظام';

  @override
  String get accountThemeLight => 'فاتح';

  @override
  String get accountThemeDark => 'داكن';

  @override
  String get accountSecurity => 'الأمان';

  @override
  String get accountNotificationPrefs => 'تفضيلات الإشعار';

  @override
  String get accountPushStatus => 'الإشعارات الفورية';

  @override
  String get pushNotConfigured => 'غير مهيأة — تتطلب إعداد مزود الدفع';

  @override
  String get pushRegistered => 'مفعلة على هذا الجهاز';

  @override
  String get diagnosticsTitle => 'تشخيص المطور';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل مقروءاً';

  @override
  String get notificationsEmpty => 'لا إشعارات';

  @override
  String get notificationsUnreadOnly => 'غير المقروء فقط';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get messagesEmpty => 'لا محادثات بعد';

  @override
  String get messagesHint => 'اكتب رسالة…';

  @override
  String get messageDeleted => 'حُذفت رسالة';

  @override
  String get commentsTitle => 'التعليقات';

  @override
  String get commentsEmpty => 'لا تعليقات بعد';

  @override
  String get commentsHint => 'أضف تعليقاً…';

  @override
  String get commentInternal => 'داخلي';

  @override
  String get commentPinned => 'مثبت';

  @override
  String get commentResolved => 'محلول';

  @override
  String get approvalsTitle => 'الاعتمادات';

  @override
  String get approvalsEmpty => 'لا طلبات معلقة';

  @override
  String get approvalRejectReason => 'سبب الرفض (اختياري)';

  @override
  String get approvalDecided => 'قرارك سُجل';

  @override
  String get approvalStale =>
      'الطلب تقادم — تغير السجل بعد تقديمه. حدّث ثم قرر.';

  @override
  String get approvalQueued =>
      'العملية محمية بالموافقات — صُفَّ طلبك للمعتمدين';

  @override
  String get approvalOpenTarget => 'فتح السجل الهدف';

  @override
  String get recordTitle => 'السجل';

  @override
  String get recordOverview => 'نظرة';

  @override
  String get recordFields => 'الحقول';

  @override
  String get recordActions => 'الإجراءات';

  @override
  String get recordComments => 'التعليقات';

  @override
  String get recordAttachments => 'المرفقات';

  @override
  String get recordVersionConflictTitle => 'تعارض نسخة';

  @override
  String recordVersionConflictBody(String server) {
    return 'عدّل غيرك هذا السجل بعدما فتحته (نسخة الخادم $server). حدّث ثم أعد تعديلك.';
  }

  @override
  String get recordVersionConflictReload => 'تحميل نسخة الخادم';

  @override
  String get recordDeleteConfirm => 'حذف السجل؟ يُنقل إلى السلة.';

  @override
  String get recordDeleted => 'نُقل إلى السلة';

  @override
  String get recordSaved => 'حُفظ';

  @override
  String get recordCreated => 'أُنشئ';

  @override
  String get recordNotFound => 'السجل غير موجود أو خارج نطاقك';

  @override
  String get recordNoAccess => 'لا صلاحية لك هنا';

  @override
  String get actionDestructiveConfirm =>
      'إجراء لا يُتراجع عنه بسهولة — متابعة؟';

  @override
  String get actionNeedsApproval => 'سيُصفّ طلب موافقة';

  @override
  String get actionDone => 'نُفذ';

  @override
  String get actionsEmpty => 'لا إجراءات متاحة لحالة السجل الحالية';

  @override
  String moduleSearchHint(String module) {
    return 'بحث في $module…';
  }

  @override
  String get moduleSort => 'الفرز';

  @override
  String fieldRequired(String field) {
    return 'حقل $field مطلوب';
  }

  @override
  String get fieldReadOnly => 'قراءة فقط';

  @override
  String get fieldSecretMasked => 'قيمة سرية — لا تُنسخ تلقائياً';

  @override
  String get fieldNoValue => '—';

  @override
  String get fieldPickDate => 'اختر تاريخاً';

  @override
  String fieldPickReference(String module) {
    return 'اختر من $module';
  }

  @override
  String get fieldAttachmentViaTab =>
      'تُدار الملفات من تبويب المرفقات بعد الحفظ';

  @override
  String get filesUpload => 'رفع ملف';

  @override
  String get filesCamera => 'الكاميرا';

  @override
  String get filesGallery => 'مكتبة الصور';

  @override
  String get filesDocument => 'المستندات';

  @override
  String filesUploading(String percent) {
    return 'جارٍ الرفع $percent٪';
  }

  @override
  String get filesUploadFailed => 'تعذر الرفع';

  @override
  String get filesUploadDone => 'رُفع وأُرفق';

  @override
  String get filesDownload => 'تنزيل';

  @override
  String get filesEmpty => 'لا مرفقات';

  @override
  String get scannerTitle => 'الماسح';

  @override
  String get scannerHint => 'وجّه الكاميرا نحو رمز QR أو باركود';

  @override
  String get scannerNotFound => 'لا سجل مطابق لهذا الرمز ضمن نطاقك';

  @override
  String get trackingTitle => 'التتبع الميداني';

  @override
  String get trackingStart => 'بدء التتبع';

  @override
  String get trackingEnd => 'إنهاء التتبع';

  @override
  String get trackingActive => 'جلسة تتبع نشطة';

  @override
  String get trackingConsent =>
      'أوافق على مشاركة موقعي أثناء هذه الجلسة الظاهرة، وتنتهي بإنهائها';

  @override
  String trackingPointsSent(int count) {
    return 'نقاط مرسلة: $count';
  }

  @override
  String get trackingPermissionDenied =>
      'إذن الموقع مرفوض — فعّله من إعدادات النظام';

  @override
  String get errUnauthenticated => 'بيانات الدخول غير صحيحة';

  @override
  String get errForbidden => 'لا صلاحية لك على هذه العملية';

  @override
  String get errNotFound => 'غير موجود أو خارج نطاقك';

  @override
  String get errValidation => 'تحقق من الحقول المعلمة';

  @override
  String get errRateLimited => 'محاولات كثيرة — انتظر قليلاً';

  @override
  String get errServer => 'خطأ في الخادم — حاول لاحقاً';

  @override
  String get errNetwork => 'تعذر الاتصال — تحقق من الشبكة';

  @override
  String errRequestId(String id) {
    return 'معرف الطلب: $id';
  }

  @override
  String unreadBadge(int count) {
    return '$count غير مقروء';
  }

  @override
  String get pinnedTitle => 'مثبتاتي';

  @override
  String get webOnlyDestination => 'وجهة ويب — تُفتح في المتصفح';

  @override
  String get confirmLogout => 'تسجيل الخروج من هذا الجهاز؟';

  @override
  String get confirmLogoutAll => 'الخروج من كل الأجهزة والجلسات؟';

  @override
  String get portalTitle => 'بوابة العميل';

  @override
  String get portalYourSpace => 'مساحتك';

  @override
  String get portalEngagements => 'الارتباطات';

  @override
  String get portalProjects => 'المشاريع';

  @override
  String get portalDocuments => 'الوثائق المشتركة';

  @override
  String get portalInvoices => 'الفواتير';

  @override
  String get portalConversations => 'المحادثات';

  @override
  String get portalYourOrgs => 'منظماتك';

  @override
  String get portalEmptyWorld =>
      'لا وصول فعّالاً لحسابك بعد — تواصل مع مسؤولك لدى الشركة';

  @override
  String get portalClientNote => 'ملاحظة لك';

  @override
  String get invoiceTotal => 'الإجمالي';

  @override
  String get invoicePaid => 'المدفوع';

  @override
  String get invoiceState => 'الحالة';

  @override
  String get invoiceDue => 'تاريخ الاستحقاق';

  @override
  String get invoiceDate => 'التاريخ';

  @override
  String get invoiceKind => 'النوع';

  @override
  String get projectProgress => 'نسبة الإنجاز';

  @override
  String get projectStatus => 'الحالة';

  @override
  String get projectPriority => 'الأولوية';

  @override
  String get projectStart => 'تاريخ البدء';

  @override
  String get projectLaunchExpected => 'الإطلاق المتوقع';

  @override
  String get projectLaunchActual => 'الإطلاق الفعلي';

  @override
  String get projectEngagement => 'الارتباط';

  @override
  String get projectClient => 'العميل';

  @override
  String get docCategory => 'التصنيف';

  @override
  String get docNo => 'رقم الوثيقة';

  @override
  String get docIssueDate => 'تاريخ الإصدار';

  @override
  String get docExpiry => 'تاريخ الانتهاء';

  @override
  String get docRenewal => 'التجديد';

  @override
  String get conversationWrite => 'اكتب رسالة…';

  @override
  String get conversationEmpty => 'لا رسائل بعد';

  @override
  String get activationTitle => 'تفعيل الحساب';

  @override
  String activationIntro(String email) {
    return 'أنشئ كلمة مرورك لحساب $email';
  }

  @override
  String get activationOtp => 'رمز التحقق (٦ أرقام)';

  @override
  String get activationPassword => 'كلمة المرور الجديدة';

  @override
  String get activationPasswordConfirm => 'تأكيد كلمة المرور';

  @override
  String get activationSubmit => 'تفعيل الحساب';

  @override
  String get activationExpired =>
      'انتهت صلاحية رابط التفعيل — اطلب دعوة جديدة من مسؤولك لدى الشركة';

  @override
  String get activationDone =>
      'تم تفعيل حسابك — سجّل الدخول بكلمة مرورك الجديدة';

  @override
  String get activationPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get membersTitle => 'أعضاء العميل';

  @override
  String get membersInvite => 'دعوة عضو';

  @override
  String get membersEmail => 'البريد الإلكتروني';

  @override
  String get membersNameOptional => 'الاسم (اختياري)';

  @override
  String get membersRole => 'الدور';

  @override
  String get membersRevoke => 'سحب الوصول';

  @override
  String get membersRevokeConfirm =>
      'أتريد سحب وصول هذا العضو؟ يسري التعليق فوراً.';

  @override
  String get membersChangeRole => 'تغيير الدور';

  @override
  String get membersInviteSent =>
      'أُرسلت الدعوة برسالة تفعيل — لا كلمة سر تُرسل أبداً';

  @override
  String get membersStatusInvited => 'مدعو';

  @override
  String get membersStatusActive => 'فعّال';

  @override
  String get membersStatusSuspended => 'معلَّق';

  @override
  String get membersActivatedYes => 'فعّل حسابه';

  @override
  String get membersActivatedNo => 'لم يفعّل حسابه بعد';

  @override
  String get roleOwner => 'مالك';

  @override
  String get roleLead => 'مسؤول رئيسي';

  @override
  String get roleTechnical => 'تقني';

  @override
  String get roleFinance => 'مالي';

  @override
  String get roleViewer => 'مشاهد';

  @override
  String get askTitle => 'اسأل Hub';

  @override
  String get askHint => 'اسأل عن مشاريعك ومهامّك…';

  @override
  String get askSend => 'إرسال';

  @override
  String get askWorking => 'يقرأ بياناتك ويجيب — قد يستغرق دقيقة…';

  @override
  String get askEmpty =>
      'اسأل سؤالاً عن بياناتك — يجيب ممّا تراه أنت فقط، ويذكر مصادره.';

  @override
  String get askSources => 'المصادر';

  @override
  String askSourceRows(String label, int rows) {
    return '$label — $rows صفّاً';
  }

  @override
  String get askPartial => 'جوابٌ جزئيّ — لم تُقرأ كلُّ البيانات';

  @override
  String get askHiddenTurn =>
      'لم يعد هذا الجواب متاحاً لك — تغيّرت صلاحيّاتك أو البيانات التي بُني عليها';

  @override
  String get askThreads => 'محادثاتك';

  @override
  String get askNewThread => 'محادثة جديدة';

  @override
  String get askNoThreads => 'لا محادثات محفوظة';

  @override
  String get askMemoryOff => 'حفظُ المحادثات مطفأ على الخادم';

  @override
  String askRetention(int days) {
    return 'تُمحى المحادثة بعد $days يوماً بلا نشاط';
  }

  @override
  String get askDeleteAll => 'حذف كل المحادثات';

  @override
  String get askDeleteAllConfirm => 'حذف كل محادثاتك؟ لا يمكن التراجع.';

  @override
  String get askDeleteConfirm => 'حذف هذه المحادثة؟';

  @override
  String get askErrUnavailable => 'المساعد غير متاح الآن — حاول لاحقاً';

  @override
  String get askErrLimit => 'بلغتَ حدّ الاستخدام — حاول لاحقاً';

  @override
  String get askErrDenied => 'لا صلاحية لك لاستعمال المساعد';

  @override
  String get askErrNoData => 'لا بيانات متاحة لك للإجابة عن هذا السؤال';

  @override
  String get askErrQuestion => 'صِغ السؤال بشكلٍ أوضح';

  @override
  String get askErrTooBig => 'السؤال واسعٌ جداً — ضيّقه';

  @override
  String get askErrGeneric => 'تعذّر الجواب';

  @override
  String get reactionsPick => 'اختر تفاعلاً';

  @override
  String get reactionsAdd => 'أضف تفاعلاً';

  @override
  String typingOne(String name) {
    return '$name يكتب…';
  }

  @override
  String typingMany(String names) {
    return '$names يكتبون…';
  }

  @override
  String get presenceOnline => 'متصل الآن';

  @override
  String get presenceRecent => 'نشط مؤخراً';

  @override
  String get presenceAway => 'غير نشط';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get messagesTabDirect => 'المباشرة';

  @override
  String get messagesTabChannels => 'القنوات';

  @override
  String get conversationsChannels => 'القنوات';

  @override
  String get conversationsRooms => 'غرف المشاريع';

  @override
  String get conversationsGroups => 'المجموعات';

  @override
  String get conversationsEmpty => 'لست عضواً في أي قناة أو مجموعة';

  @override
  String get savedTitle => 'المحفوظات';

  @override
  String get savedEmpty => 'لا محفوظات';

  @override
  String get savedUnavailable => 'لم يعد هذا متاحاً لك';

  @override
  String get savedTypeComment => 'تعليق';

  @override
  String get savedTypeDm => 'رسالة مباشرة';

  @override
  String savedAt(String date) {
    return 'حُفظ $date';
  }

  @override
  String get workTodayTitle => 'يومي';

  @override
  String get workDailyReport => 'التقرير اليومي';

  @override
  String get workNoProfile =>
      'لا ملفَّ موظفٍ نشطاً مربوطاً بحسابك — لا حالَ يومٍ لعرضه';

  @override
  String get workAttendance => 'الحضور';

  @override
  String get workReport => 'التقرير';

  @override
  String workCheckIn(String time) {
    return 'دخول $time';
  }

  @override
  String workCheckOut(String time) {
    return 'خروج $time';
  }

  @override
  String workReportedHours(String hours) {
    return 'الساعات المُبلَّغة: $hours';
  }

  @override
  String workDeadline(String time) {
    return 'مهلة التقديم: $time';
  }

  @override
  String get workReportDue => 'تقرير اليوم مطلوب ولم يُقدَّم بعد';

  @override
  String get workVerdictPending => 'لم يحِن وقت الحكم على اليوم بعد';

  @override
  String get workNeedsReview => 'بنودٌ بانتظار المراجعة أو التعديل';

  @override
  String workEntries(int count) {
    return 'بنود اليوم ($count)';
  }

  @override
  String get workNoEntries => 'لا بنود مُقدَّمة لهذا اليوم';

  @override
  String get workSubmit => 'قدّم بند عمل';

  @override
  String workEntryHours(String hours) {
    return '$hours ساعة';
  }

  @override
  String workEntryProgress(String progress) {
    return 'التقدم $progress٪';
  }

  @override
  String get workReviewPending => 'بانتظار المراجعة';

  @override
  String get workReviewAccepted => 'مقبول';

  @override
  String get workReviewNeedsRevision => 'يحتاج تعديلاً';

  @override
  String get workPrevDay => 'اليوم السابق';

  @override
  String get workNextDay => 'اليوم التالي';

  @override
  String get myDocumentsTitle => 'وثائقي';

  @override
  String get myDocumentsEmpty => 'لا وثائق على ملفّك';

  @override
  String myDocumentsExpires(String date) {
    return 'تنتهي $date';
  }

  @override
  String myDocumentsExpired(String date) {
    return 'انتهت $date';
  }

  @override
  String myDocumentsNo(String no) {
    return 'رقم $no';
  }

  @override
  String get myDocumentsInfected => 'محجوبة — وُسمت مصابة بفحص الفيروسات';

  @override
  String get myDocumentsNoPreview =>
      'المعاينة داخل التطبيق للصور فقط — افتحها من المنصة على الويب';

  @override
  String get myDocumentsRestricted => 'وصول هذه الوثيقة مقيَّد بقاعدة صريحة';

  @override
  String get myDocumentsNoPersist =>
      'تُعرض الوثائق من الذاكرة ولا تُحفظ على الجهاز';

  @override
  String get savedAction => 'احفظ';

  @override
  String get savedDone => 'حُفظت في المحفوظات';

  @override
  String get savedAlready => 'محفوظة سلفاً';

  @override
  String get savedUndo => 'تراجع';

  @override
  String get savedRemove => 'إزالة من المحفوظات';

  @override
  String get savedRemoved => 'أُزيلت من المحفوظات';

  @override
  String syncedAt(String date, String time) {
    return 'آخر مزامنة $date $time';
  }

  @override
  String get notificationNoTarget => 'لا وجهة لهذا الإشعار — بقي في القائمة';

  @override
  String fileSizeBytes(int count) {
    return '$count بايت';
  }

  @override
  String fileSizeKb(String size) {
    return '$size ك.ب';
  }

  @override
  String fileSizeMb(String size) {
    return '$size م.ب';
  }

  @override
  String get filesNoInAppPreview =>
      'المعاينة داخل التطبيق للصور فقط (من الذاكرة، بلا حفظ على الجهاز) — افتح هذا الملف من المنصة على الويب';

  @override
  String get filesOpenOnWeb => 'افتح على الويب';

  @override
  String get filesFieldOnWebOnly =>
      'ملف هذا الحقل يُفتح من صفحة السجل على المنصة على الويب';

  @override
  String get filesInfected => 'محجوب — وُسم مصاباً بفحص الفيروسات';

  @override
  String get prefsTitle => 'التفضيلات';

  @override
  String get prefsSubtitle =>
      'كتم الإشعارات وتثبيت المفضّلة — تُحفظ على الخادم';

  @override
  String get prefsMuteHint =>
      'النوع المكتوم لا يُنشأ لك إشعاره أصلاً — على الويب والجوال معاً';

  @override
  String get prefsMuted => 'مكتوم';

  @override
  String get prefsNotifying => 'يُشعِرك';

  @override
  String prefsPinsCount(int count, int max) {
    return 'مثبّت $count من $max';
  }

  @override
  String get prefsPinsFilter => 'تصفية الوجهات';

  @override
  String get prefsPin => 'ثبّت';

  @override
  String get prefsUnpin => 'فكّ التثبيت';

  @override
  String get languageArabicShort => 'عربي';

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get unknownInitial => '؟';

  @override
  String get appVersionTitle => 'إصدار التطبيق';

  @override
  String get updateAvailableTitle => 'إصدار أحدث متاح';

  @override
  String get updateAvailableBody => 'التحديث اختياري الآن — افتح المتجر';

  @override
  String get supportTitle => 'الدعم';

  @override
  String get commentReply => 'رد';

  @override
  String get listSeparator => '، ';

  @override
  String percentValue(int value) {
    return '$value٪';
  }

  @override
  String diagnosticsSessionActive(String id) {
    return 'نشطة (id: $id)';
  }

  @override
  String get diagnosticsPushReadyNoToken => 'ready (لا رمز)';

  @override
  String get pushPermissionDenied =>
      'مرفوضة — فعّل إذن الإشعارات من إعدادات الجهاز';

  @override
  String get pushAwaitingToken => 'مهيأة — بانتظار رمز الجهاز';

  @override
  String get pushBannerDefaultTitle => 'إشعار جديد';

  @override
  String get pushBannerOpen => 'فتح';

  @override
  String get pushTestReceived => 'وصل إشعارٌ تجريبي من مركز منصة الجوال';

  @override
  String get diagnosticsPushPermissionDenied =>
      'permission denied (الإذن مرفوض)';

  @override
  String get fieldValueRequired => 'هذا الحقل مطلوب';

  @override
  String get attendanceTitle => 'الحضور والانصراف';

  @override
  String get attendanceAlreadyIn => 'سُجّل حضورك اليوم مسبقاً';

  @override
  String get attendanceOpenShift =>
      'لديك ورديةٌ مفتوحة من يومٍ سابق — سجّل انصرافك منها أولاً';

  @override
  String get attendanceNotIn => 'لم تسجّل حضوراً بعد';

  @override
  String get attendanceAlreadyOut => 'سُجّل انصرافك مسبقاً';

  @override
  String get attendanceConsentRequired => 'إرسال الموقع يتطلّب موافقتك الصريحة';

  @override
  String get attendanceNoProfile => 'لا ملف موظفٍ مربوطاً بحسابك';

  @override
  String get attendanceLocationUnavailable =>
      'تعذّر تحديد الموقع — يُسجَّل بلا موقع';

  @override
  String get attendanceCheckedIn => 'سُجّل الحضور';

  @override
  String get attendanceCheckedOut => 'سُجّل الانصراف';

  @override
  String get attendanceStateNotIn => 'لم تسجّل حضورك اليوم';

  @override
  String attendanceStateIn(String time) {
    return 'حاضر منذ $time';
  }

  @override
  String attendanceStateOut(String timeIn, String timeOut) {
    return 'حضور $timeIn · انصراف $timeOut';
  }

  @override
  String attendanceHours(String hours) {
    return '$hours ساعة';
  }

  @override
  String get attendanceOvernight => 'وردية ليلية ممتدة من اليوم السابق';

  @override
  String get attendanceMode => 'وضع العمل';

  @override
  String get attendanceShareLocation => 'إرفاق موقعي لهذه المرة';

  @override
  String get attendanceShareLocationHint =>
      'قراءةٌ واحدة لحظة الضغط بموافقتك — لا تتبّع';

  @override
  String get attendanceCheckIn => 'تسجيل الحضور';

  @override
  String get attendanceCheckOut => 'تسجيل الانصراف';

  @override
  String get leaveRejectReasonTitle => 'سبب الرفض';

  @override
  String get leaveRejectReasonHint => 'يقرؤه صاحب الطلب';

  @override
  String get leaveApproveConfirm =>
      'اعتماد طلب الإجازة؟ يحسم الخادم مرحلته (موافقة المدير أو الاعتماد النهائي).';

  @override
  String get leaveAlreadyDecided => 'هذا الطلب محسومٌ مسبقاً';

  @override
  String get leaveSelfRequest =>
      'لا تقرّر في طلبك أنت — يقرّر مديرك أو الموارد البشرية';

  @override
  String get leaveNotDecider =>
      'قرار هذا الطلب لمدير الموظف أو الموارد البشرية';

  @override
  String get leaveReasonRequired => 'سبب الرفض مطلوب';

  @override
  String get leaveDecisionTitle => 'قرار الطلب';

  @override
  String get custodyTitle => 'عهدتي';

  @override
  String get custodyEmpty => 'لا عهدة بيدك ولا حركات';

  @override
  String get custodyAcked => 'سُجّل إقرار الاستلام';

  @override
  String get custodyPendingReceipts => 'إقرارات استلام معلّقة';

  @override
  String get custodyAck => 'أُقرّ بالاستلام';

  @override
  String custodyAssets(int count) {
    return 'ما بيدي ($count)';
  }

  @override
  String get custodyNoAssets => 'لا أصول بيدك الآن';

  @override
  String get custodyReceiptPending => 'بانتظار إقرارك';

  @override
  String get custodyMoves => 'حركات عهدتي';

  @override
  String custodyHandoverTo(String name) {
    return 'تسليم العهدة إلى $name';
  }

  @override
  String get custodyNoteHint => 'ملاحظة (اختيارية)';

  @override
  String get custodyRecover => 'استرداد العهدة';

  @override
  String get custodyHandover => 'تسليم العهدة';

  @override
  String get custodyActionsTitle => 'العهدة';

  @override
  String get inventoryTitle => 'جلسات الجرد';

  @override
  String get inventoryFreezeConfirm =>
      'فتح جلسة جردٍ جديدة بتجميد لقطة أصولك الآن؟';

  @override
  String inventoryFrozen(int count) {
    return 'جُمِّد $count أصلاً في الجلسة';
  }

  @override
  String get inventoryFreeze => 'جلسة جديدة';

  @override
  String get inventoryEmpty => 'لا جلسات جرد';

  @override
  String inventorySessionMeta(int items, int scans, String by) {
    return '$items صنفاً · $scans مسحة · $by';
  }

  @override
  String get inventorySession => 'جلسة الجرد';

  @override
  String get inventoryReconcile => 'المصالحة';

  @override
  String get inventoryReconcileConfirm =>
      'مصالحة الجلسة كتابياً (موجود/مفقود/انتقل/غير متوقع)؟ يتطلّب تأكيد الهوية.';

  @override
  String get inventoryReconciled => 'تمت المصالحة';

  @override
  String get inventoryClose => 'إغلاق الجلسة';

  @override
  String get inventoryCloseConfirm =>
      'إغلاق الجلسة؟ لا مسح بعد الإغلاق. يتطلّب تأكيد الهوية.';

  @override
  String get inventoryClosed => 'أُغلقت الجلسة';

  @override
  String get inventoryScan => 'مسح';

  @override
  String inventoryItems(int count) {
    return 'الأصناف ($count)';
  }

  @override
  String get inventoryRecentScans => 'أحدث المسحات';

  @override
  String get inventoryUnknownCode => 'رمز غير معروف (لا يُخزَّن)';

  @override
  String get inventorySessionClosed => 'الجلسة مغلقة — لا مسح بعد الإغلاق';

  @override
  String get inventoryScanHint => 'وجّه الكاميرا إلى رمز الأصل';

  @override
  String inventoryScanKnown(String name) {
    return '✓ معروف: $name';
  }

  @override
  String inventoryScanUnexpected(String name) {
    return '⚠ غير متوقع: $name';
  }

  @override
  String get inventoryScanUnknown => '✗ رمز غير معروف في نطاقك';

  @override
  String inventoryScanCount(int count) {
    return 'المسح ($count)';
  }

  @override
  String pageOf(int page, int pages) {
    return '$page من $pages';
  }

  @override
  String filesDeleteConfirm(String name) {
    return 'حذف المرفق «$name»؟';
  }

  @override
  String get filesDeleted => 'حُذف المرفق';

  @override
  String filesExpires(String date) {
    return 'ينتهي $date';
  }

  @override
  String get filesMessageNoPreview =>
      'المعاينة داخل التطبيق للصور فقط (من الذاكرة) — افتح هذا المرفق من المنصة على الويب';

  @override
  String get inventoryUnknownCompany =>
      'الشركة المختارة في السياق غير معروفة — اختر شركةً أخرى أو ألغِ التضييق';

  @override
  String versionsRestoreConfirm(int version) {
    return 'استعادة السجل إلى النسخة $version؟ تُنشأ نسخةٌ جديدة بقيمها.';
  }

  @override
  String get versionsRestore => 'استعادة';

  @override
  String versionsRestored(int version) {
    return 'استُعيدت النسخة $version';
  }

  @override
  String get versionsTitle => 'نسخ السجل';

  @override
  String get versionsEmpty => 'لا نسخ محفوظة لهذا السجل';

  @override
  String get versionsCurrent => 'النسخة الحالية';

  @override
  String get versionsOldest => 'أقدم نسخة معروضة';

  @override
  String get versionsNoVisibleChange => 'لا تغيير في الحقول الظاهرة لك';

  @override
  String versionsChanged(String fields) {
    return 'تغيّر: $fields';
  }

  @override
  String get financeQueuedBlocked =>
      'الوحدة بانتظار اعتمادٍ معلّق — لا تنفيذ الآن';

  @override
  String financePaid(String amount) {
    return 'سُجّلت دفعة $amount';
  }

  @override
  String financePaidRemaining(
    String amount,
    String remaining,
    String currency,
  ) {
    return 'سُجّلت دفعة $amount — المتبقي $remaining $currency';
  }

  @override
  String get financeQuoteSendConfirm =>
      'إرسال عرض السعر؟ قد يُحال للمراجعة الداخلية بحسب عتبة الاعتماد.';

  @override
  String get financeQuoteEscalated =>
      'أُحيل العرض للمراجعة الداخلية قبل الإرسال';

  @override
  String get financeQuoteSent => 'أُرسل عرض السعر';

  @override
  String get financeQuoteAcceptConfirm => 'تسجيل قبول عرض السعر؟';

  @override
  String get financeQuoteAccepted => 'قُبل عرض السعر';

  @override
  String get financeQuoteAlreadyAccepted => 'العرض مقبولٌ مسبقاً — لا أثر جديد';

  @override
  String get financeReceiveConfirm => 'استلام أمر الشراء وإنشاء حركات المخزون؟';

  @override
  String get financeAlreadyReceived => 'الأمر مستلمٌ مسبقاً';

  @override
  String financeReceived(int moves, int skipped) {
    return 'اُستلم الأمر: $moves حركة مخزون · $skipped متخطّى';
  }

  @override
  String get financePay => 'تسجيل دفعة';

  @override
  String get financeQuoteSend => 'إرسال العرض';

  @override
  String get financeQuoteAccept => 'قبول العرض';

  @override
  String get financeReceive => 'استلام الأمر';

  @override
  String get financeAmountInvalid =>
      'اكتب مبلغاً موجباً بصيغة عشرية صريحة (مثل 2500.000) بلا فواصل آلاف';

  @override
  String get financeAmount => 'المبلغ';

  @override
  String get financePayRef => 'المرجع (اختياري)';

  @override
  String get financePayNote => 'ملاحظة (اختيارية)';

  @override
  String get commentEdit => 'تحرير';

  @override
  String get commentEdited => 'حُرِّر التعليق';

  @override
  String get commentDeleteConfirm => 'حذف هذا التعليق؟';

  @override
  String get commentDeleted => 'حُذف التعليق';

  @override
  String get commentPinnedDone => 'ثُبِّت التعليق';

  @override
  String get commentUnpinned => 'أُلغي التثبيت';

  @override
  String get commentResolvedDone => 'عُلِّم محلولاً';

  @override
  String get commentReopened => 'أُعيد فتحه';

  @override
  String get commentToTaskDone => 'حُوِّل التعليق إلى مهمة';

  @override
  String get commentUnpin => 'إلغاء التثبيت';

  @override
  String get commentPin => 'تثبيت';

  @override
  String get commentReopen => 'إعادة فتح';

  @override
  String get commentResolve => 'تعليم محلولاً';

  @override
  String get commentToTask => 'تحويل لمهمة';

  @override
  String get ticketsTitle => 'تذاكري';

  @override
  String get ticketsNew => 'بلاغ جديد';

  @override
  String get ticketsEmpty => 'لا تذاكر بعد';

  @override
  String get ticketsCreated => 'فُتح البلاغ';

  @override
  String get ticketsDuplicateTitle => 'بلاغ مشابه مفتوح';

  @override
  String ticketsDuplicateBody(String subject) {
    return 'لديك بلاغٌ مطابق ما زال مفتوحاً: «$subject». أضِف ردّك عليه، أو أرسل هذا إن كان بلاغاً مختلفاً.';
  }

  @override
  String get ticketsOpenExisting => 'فتح القائم';

  @override
  String get ticketsSubmitAnyway => 'إرسال كبلاغٍ مختلف';

  @override
  String get ticketsSubject => 'الموضوع';

  @override
  String get ticketsBody => 'الوصف';

  @override
  String get ticketsPriority => 'الأولوية';

  @override
  String get ticketsProject => 'المشروع';

  @override
  String get ticketsNone => '—';

  @override
  String get ticketsOrg => 'المنظمة';

  @override
  String get ticketsNoReplies => 'لا ردود بعد';

  @override
  String get ticketsYou => 'أنت';

  @override
  String get ticketsReplyHint => 'اكتب ردّك…';

  @override
  String get channelVisPrivate => 'خاصة';

  @override
  String get channelVisMembers => 'للأعضاء';

  @override
  String get channelVisCompany => 'للشركة';

  @override
  String get channelVisPublic => 'عامة';

  @override
  String get channelVisDefault => 'الافتراضي';

  @override
  String get channelRoleOwner => 'مالك';

  @override
  String get channelRoleModerator => 'مشرف';

  @override
  String get channelRoleMember => 'عضو';

  @override
  String get channelRoleGuest => 'ضيف';

  @override
  String get channelNotifyAll => 'كل الرسائل';

  @override
  String get channelNotifyMentions => 'الإشارات فقط';

  @override
  String get channelNotifyMuted => 'مكتومة';

  @override
  String get channelCreated => 'أُنشئت القناة';

  @override
  String get channelNew => 'قناة جديدة';

  @override
  String get channelName => 'اسم القناة';

  @override
  String get channelVisibility => 'الظهور';

  @override
  String get channelJoined => 'انضممت إلى القناة';

  @override
  String get channelAlreadyMember => 'أنت عضوٌ فيها مسبقاً';

  @override
  String get channelDirectory => 'دليل القنوات';

  @override
  String get channelDirectoryEmpty => 'لا قنوات متاحة للانضمام';

  @override
  String channelMembersCount(int count) {
    return '$count عضواً';
  }

  @override
  String get channelJoin => 'انضمام';

  @override
  String get groupCreated => 'أُنشئت المجموعة';

  @override
  String get groupNew => 'مجموعة جديدة';

  @override
  String get groupTitleOptional => 'اسم المجموعة (اختياري)';

  @override
  String get groupNoContacts =>
      'لا جهات في رسائلك المباشرة بعد — راسل زملاءك أولاً';

  @override
  String channelRemoveConfirm(String name) {
    return 'إزالة $name من الحاوية؟';
  }

  @override
  String get channelRemove => 'إزالة';

  @override
  String get channelMembers => 'الأعضاء';

  @override
  String get channelAddMember => 'إضافة عضو';

  @override
  String channelMakeRole(String role) {
    return 'اجعله $role';
  }

  @override
  String get messageSearchHint => 'ابحث في نص الرسائل…';

  @override
  String messageSearchMin(int count) {
    return 'اكتب $count أحرف على الأقل';
  }

  @override
  String get messageSearchNone => 'لا نتائج';

  @override
  String messageSearchTotal(int count) {
    return '$count نتيجة';
  }

  @override
  String get channelFavorited => 'أُضيفت للمفضّلة';

  @override
  String get channelUnfavorited => 'أُزيلت من المفضّلة';

  @override
  String channelNotifySaved(String pref) {
    return 'الإشعار: $pref';
  }

  @override
  String get channelArchived => 'أُرشفت القناة';

  @override
  String get channelUnarchived => 'أُعيدت القناة من الأرشيف';

  @override
  String get groupLeaveConfirm => 'مغادرة هذه المجموعة؟ لن تصلك رسائلها بعد.';

  @override
  String get groupLeave => 'مغادرة المجموعة';

  @override
  String get groupLeft => 'غادرت المجموعة';

  @override
  String get channelFavorite => 'المفضّلة (تبديل)';

  @override
  String get channelNotify => 'تفضيل الإشعار';

  @override
  String get channelArchive => 'أرشفة/إعادة';

  @override
  String get dmEdit => 'تحرير';

  @override
  String get dmDelete => 'سحب الرسالة';

  @override
  String get dmDeleteConfirm => 'سحب هذه الرسالة؟ يبقى أثرها «حُذفت».';

  @override
  String get dmEdited => '(معدّلة)';

  @override
  String get reviewAccepted => 'مقبول';

  @override
  String get reviewNeedsRevision => 'يحتاج تنقيحاً';

  @override
  String get reviewPending => 'بانتظار المراجعة';

  @override
  String get reviewFeedbackTitle => 'ملاحظة التنقيح';

  @override
  String get reviewFeedbackHint => 'ما المطلوب تحسينه؟ يقرؤها الموظف';

  @override
  String get teamReportsTitle => 'تقارير الفريق اليومية';

  @override
  String get previousDay => 'اليوم السابق';

  @override
  String get nextDay => 'اليوم التالي';

  @override
  String get reviewScopeTeam => 'فريقي';

  @override
  String get reviewScopeMine => 'مشاريعي';

  @override
  String get reviewAll => 'الكل';

  @override
  String reviewSummary(int total, int pending, int accepted, int revision) {
    return '$total بنداً · $pending بانتظار · $accepted مقبول · $revision للتنقيح';
  }

  @override
  String get reviewEmpty => 'لا بنود لهذا اليوم';

  @override
  String get reviewTruncated => 'عُرض أول ٢٠٠ بند — ضيّق التصفية';

  @override
  String reviewHours(String hours) {
    return '$hours ساعة';
  }

  @override
  String reviewProgress(String progress) {
    return 'تقدّم $progress٪';
  }

  @override
  String reviewProblems(String text) {
    return 'عوائق: $text';
  }

  @override
  String reviewNext(String text) {
    return 'التالي: $text';
  }

  @override
  String reviewFeedback(String text) {
    return 'ملاحظة المراجع: $text';
  }

  @override
  String get reviewAccept => 'قبول';

  @override
  String get reviewRequestRevision => 'طلب تنقيح';

  @override
  String get reviewReopen => 'إعادة فتح';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get calendarPrev => 'النافذة السابقة';

  @override
  String get calendarNext => 'النافذة التالية';

  @override
  String get calendarEmpty => 'لا مواعيد في هذه النافذة';

  @override
  String calendarOverflow(int count) {
    return '$count عنصراً إضافياً لم يُعرض — افتح التقويم على الويب للاطلاع عليها';
  }

  @override
  String get alertsTitle => 'التنبيهات';

  @override
  String get alertsEmpty => 'لا شيء ينتهي قريباً';

  @override
  String get alertsLate => 'متأخر';

  @override
  String get alertsWeek => 'خلال أسبوع';

  @override
  String alertsWindow(int days) {
    return 'خلال $days يوماً';
  }

  @override
  String alertsDaysLate(int days) {
    return 'متأخر $days يوماً';
  }

  @override
  String alertsDaysLeft(int days) {
    return 'بعد $days يوماً';
  }
}
