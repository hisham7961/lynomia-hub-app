// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Lynomia Hub';

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
}
