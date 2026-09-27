import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'لينوميا هب'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navMyWork.
  ///
  /// In ar, this message translates to:
  /// **'مهامي'**
  String get navMyWork;

  /// No description provided for @navDomains.
  ///
  /// In ar, this message translates to:
  /// **'المجالات'**
  String get navDomains;

  /// No description provided for @navSearch.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get navSearch;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navAccount;

  /// No description provided for @actionRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get actionConfirm;

  /// No description provided for @actionSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get actionSave;

  /// No description provided for @actionCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get actionCreate;

  /// No description provided for @actionEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get actionDelete;

  /// No description provided for @actionClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get actionClose;

  /// No description provided for @actionOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get actionOpen;

  /// No description provided for @actionSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get actionSend;

  /// No description provided for @actionRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get actionRefresh;

  /// No description provided for @actionLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get actionLogin;

  /// No description provided for @actionLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get actionLogout;

  /// No description provided for @actionLogoutAll.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من كل الجلسات'**
  String get actionLogoutAll;

  /// No description provided for @actionApprove.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get actionApprove;

  /// No description provided for @actionReject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get actionReject;

  /// No description provided for @actionShowAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get actionShowAll;

  /// No description provided for @stateLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get stateLoading;

  /// No description provided for @stateEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا عناصر لعرضها'**
  String get stateEmpty;

  /// No description provided for @stateOffline.
  ///
  /// In ar, this message translates to:
  /// **'لا اتصال بالإنترنت'**
  String get stateOffline;

  /// No description provided for @stateOfflineCached.
  ///
  /// In ar, this message translates to:
  /// **'أنت دون اتصال — تُعرض نسخة مخبأة'**
  String get stateOfflineCached;

  /// No description provided for @stateError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get stateError;

  /// No description provided for @stateSyncing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المزامنة…'**
  String get stateSyncing;

  /// No description provided for @stateLastSynced.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {time}'**
  String stateLastSynced(String time);

  /// No description provided for @requiresConnection.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب اتصالاً بالإنترنت'**
  String get requiresConnection;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول إلى Lynomia'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get loginPassword;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريداً إلكترونياً صحيحاً'**
  String get loginInvalidEmail;

  /// No description provided for @loginRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get loginRequired;

  /// No description provided for @mfaTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحقق بخطوتين'**
  String get mfaTitle;

  /// No description provided for @mfaHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق من تطبيق المصادقة'**
  String get mfaHint;

  /// No description provided for @mfaCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get mfaCode;

  /// No description provided for @mfaExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة التحدي — أعد تسجيل الدخول'**
  String get mfaExpired;

  /// No description provided for @stepUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الهوية'**
  String get stepUpTitle;

  /// No description provided for @stepUpPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور للمتابعة'**
  String get stepUpPassword;

  /// No description provided for @stepUpTotp.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق الحالي للمتابعة'**
  String get stepUpTotp;

  /// No description provided for @biometricUnlockTitle.
  ///
  /// In ar, this message translates to:
  /// **'فتح Lynomia Hub'**
  String get biometricUnlockTitle;

  /// No description provided for @biometricUnlockReason.
  ///
  /// In ar, this message translates to:
  /// **'افتح القفل للوصول إلى جلستك'**
  String get biometricUnlockReason;

  /// No description provided for @biometricPrefTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة/الوجه'**
  String get biometricPrefTitle;

  /// No description provided for @biometricPrefSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قفل محلي على هذا الجهاز — لا يُرسل شيء للخادم'**
  String get biometricPrefSubtitle;

  /// No description provided for @sessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة — سجّل الدخول من جديد'**
  String get sessionExpired;

  /// No description provided for @sessionRevoked.
  ///
  /// In ar, this message translates to:
  /// **'جلستك لم تعد صالحة — أُبطلت من جهاز آخر أو من الإدارة'**
  String get sessionRevoked;

  /// No description provided for @accountRestricted.
  ///
  /// In ar, this message translates to:
  /// **'الحساب مقيد — راجع الإدارة'**
  String get accountRestricted;

  /// No description provided for @maintenanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'صيانة مجدولة'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In ar, this message translates to:
  /// **'الخادم في صيانة مؤقتة. حاول لاحقاً.'**
  String get maintenanceBody;

  /// No description provided for @lockdownTitle.
  ///
  /// In ar, this message translates to:
  /// **'قفل أمني'**
  String get lockdownTitle;

  /// No description provided for @lockdownBody.
  ///
  /// In ar, this message translates to:
  /// **'الدخول موقوف مؤقتاً بقرار أمني.'**
  String get lockdownBody;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث مطلوب'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق أقدم من الحد الأدنى المدعوم. حدّث للمتابعة.'**
  String get updateRequiredBody;

  /// No description provided for @updateStoreButton.
  ///
  /// In ar, this message translates to:
  /// **'فتح المتجر'**
  String get updateStoreButton;

  /// No description provided for @updateStoreNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'رابط المتجر غير مهيأ بعد — تواصل مع الدعم للحصول على الإصدار الأحدث.'**
  String get updateStoreNotConfigured;

  /// No description provided for @serverUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الوصول إلى الخادم'**
  String get serverUnavailable;

  /// No description provided for @homeAttention.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب انتباهك'**
  String get homeAttention;

  /// No description provided for @homeDue.
  ///
  /// In ar, this message translates to:
  /// **'تقترب مواعيدها'**
  String get homeDue;

  /// No description provided for @homeMyTasks.
  ///
  /// In ar, this message translates to:
  /// **'مهامي المفتوحة'**
  String get homeMyTasks;

  /// No description provided for @homeProjects.
  ///
  /// In ar, this message translates to:
  /// **'مشاريعي'**
  String get homeProjects;

  /// No description provided for @homeRecent.
  ///
  /// In ar, this message translates to:
  /// **'آخر النشاطات'**
  String get homeRecent;

  /// No description provided for @homeApprovalsPending.
  ///
  /// In ar, this message translates to:
  /// **'اعتمادات معلقة'**
  String get homeApprovalsPending;

  /// No description provided for @myWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهامي'**
  String get myWorkTitle;

  /// No description provided for @myWorkTasks.
  ///
  /// In ar, this message translates to:
  /// **'المهام المسندة إليّ'**
  String get myWorkTasks;

  /// No description provided for @myWorkApprovals.
  ///
  /// In ar, this message translates to:
  /// **'الاعتمادات'**
  String get myWorkApprovals;

  /// No description provided for @myWorkNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get myWorkNotifications;

  /// No description provided for @myWorkMessages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get myWorkMessages;

  /// No description provided for @domainsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المجالات'**
  String get domainsTitle;

  /// No description provided for @searchTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في كل ما تراه…'**
  String get searchHint;

  /// No description provided for @searchMinChars.
  ///
  /// In ar, this message translates to:
  /// **'أدخل حرفين على الأقل'**
  String get searchMinChars;

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج مطابقة'**
  String get searchNoResults;

  /// No description provided for @accountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get accountTitle;

  /// No description provided for @accountSessions.
  ///
  /// In ar, this message translates to:
  /// **'جلسات الجوال'**
  String get accountSessions;

  /// No description provided for @accountSessionCurrent.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة الحالية'**
  String get accountSessionCurrent;

  /// No description provided for @accountSessionRevoke.
  ///
  /// In ar, this message translates to:
  /// **'إبطال الجلسة'**
  String get accountSessionRevoke;

  /// No description provided for @accountContext.
  ///
  /// In ar, this message translates to:
  /// **'سياق العرض'**
  String get accountContext;

  /// No description provided for @accountContextCompany.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get accountContextCompany;

  /// No description provided for @accountContextClient.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get accountContextClient;

  /// No description provided for @accountContextAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل (بلا تضييق)'**
  String get accountContextAll;

  /// No description provided for @accountLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get accountLanguage;

  /// No description provided for @accountTheme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get accountTheme;

  /// No description provided for @accountThemeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get accountThemeSystem;

  /// No description provided for @accountThemeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get accountThemeLight;

  /// No description provided for @accountThemeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get accountThemeDark;

  /// No description provided for @accountSecurity.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get accountSecurity;

  /// No description provided for @accountNotificationPrefs.
  ///
  /// In ar, this message translates to:
  /// **'تفضيلات الإشعار'**
  String get accountNotificationPrefs;

  /// No description provided for @accountPushStatus.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات الفورية'**
  String get accountPushStatus;

  /// No description provided for @pushNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'غير مهيأة — تتطلب إعداد مزود الدفع'**
  String get pushNotConfigured;

  /// No description provided for @pushRegistered.
  ///
  /// In ar, this message translates to:
  /// **'مفعلة على هذا الجهاز'**
  String get pushRegistered;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تشخيص المطور'**
  String get diagnosticsTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل مقروءاً'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا إشعارات'**
  String get notificationsEmpty;

  /// No description provided for @notificationsUnreadOnly.
  ///
  /// In ar, this message translates to:
  /// **'غير المقروء فقط'**
  String get notificationsUnreadOnly;

  /// No description provided for @messagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get messagesTitle;

  /// No description provided for @messagesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات بعد'**
  String get messagesEmpty;

  /// No description provided for @messagesHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get messagesHint;

  /// No description provided for @messageDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت رسالة'**
  String get messageDeleted;

  /// No description provided for @commentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا تعليقات بعد'**
  String get commentsEmpty;

  /// No description provided for @commentsHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف تعليقاً…'**
  String get commentsHint;

  /// No description provided for @commentInternal.
  ///
  /// In ar, this message translates to:
  /// **'داخلي'**
  String get commentInternal;

  /// No description provided for @commentPinned.
  ///
  /// In ar, this message translates to:
  /// **'مثبت'**
  String get commentPinned;

  /// No description provided for @commentResolved.
  ///
  /// In ar, this message translates to:
  /// **'محلول'**
  String get commentResolved;

  /// No description provided for @approvalsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاعتمادات'**
  String get approvalsTitle;

  /// No description provided for @approvalsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا طلبات معلقة'**
  String get approvalsEmpty;

  /// No description provided for @approvalRejectReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض (اختياري)'**
  String get approvalRejectReason;

  /// No description provided for @approvalDecided.
  ///
  /// In ar, this message translates to:
  /// **'قرارك سُجل'**
  String get approvalDecided;

  /// No description provided for @approvalStale.
  ///
  /// In ar, this message translates to:
  /// **'الطلب تقادم — تغير السجل بعد تقديمه. حدّث ثم قرر.'**
  String get approvalStale;

  /// No description provided for @approvalQueued.
  ///
  /// In ar, this message translates to:
  /// **'العملية محمية بالموافقات — صُفَّ طلبك للمعتمدين'**
  String get approvalQueued;

  /// No description provided for @approvalOpenTarget.
  ///
  /// In ar, this message translates to:
  /// **'فتح السجل الهدف'**
  String get approvalOpenTarget;

  /// No description provided for @recordTitle.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get recordTitle;

  /// No description provided for @recordOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة'**
  String get recordOverview;

  /// No description provided for @recordFields.
  ///
  /// In ar, this message translates to:
  /// **'الحقول'**
  String get recordFields;

  /// No description provided for @recordActions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get recordActions;

  /// No description provided for @recordComments.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get recordComments;

  /// No description provided for @recordAttachments.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get recordAttachments;

  /// No description provided for @recordVersionConflictTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعارض نسخة'**
  String get recordVersionConflictTitle;

  /// No description provided for @recordVersionConflictBody.
  ///
  /// In ar, this message translates to:
  /// **'عدّل غيرك هذا السجل بعدما فتحته (نسخة الخادم {server}). حدّث ثم أعد تعديلك.'**
  String recordVersionConflictBody(String server);

  /// No description provided for @recordVersionConflictReload.
  ///
  /// In ar, this message translates to:
  /// **'تحميل نسخة الخادم'**
  String get recordVersionConflictReload;

  /// No description provided for @recordDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف السجل؟ يُنقل إلى السلة.'**
  String get recordDeleteConfirm;

  /// No description provided for @recordDeleted.
  ///
  /// In ar, this message translates to:
  /// **'نُقل إلى السلة'**
  String get recordDeleted;

  /// No description provided for @recordSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ'**
  String get recordSaved;

  /// No description provided for @recordCreated.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئ'**
  String get recordCreated;

  /// No description provided for @recordNotFound.
  ///
  /// In ar, this message translates to:
  /// **'السجل غير موجود أو خارج نطاقك'**
  String get recordNotFound;

  /// No description provided for @recordNoAccess.
  ///
  /// In ar, this message translates to:
  /// **'لا صلاحية لك هنا'**
  String get recordNoAccess;

  /// No description provided for @actionDestructiveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إجراء لا يُتراجع عنه بسهولة — متابعة؟'**
  String get actionDestructiveConfirm;

  /// No description provided for @actionNeedsApproval.
  ///
  /// In ar, this message translates to:
  /// **'سيُصفّ طلب موافقة'**
  String get actionNeedsApproval;

  /// No description provided for @actionDone.
  ///
  /// In ar, this message translates to:
  /// **'نُفذ'**
  String get actionDone;

  /// No description provided for @actionsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا إجراءات متاحة لحالة السجل الحالية'**
  String get actionsEmpty;

  /// No description provided for @moduleSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في {module}…'**
  String moduleSearchHint(String module);

  /// No description provided for @moduleSort.
  ///
  /// In ar, this message translates to:
  /// **'الفرز'**
  String get moduleSort;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'حقل {field} مطلوب'**
  String fieldRequired(String field);

  /// No description provided for @fieldReadOnly.
  ///
  /// In ar, this message translates to:
  /// **'قراءة فقط'**
  String get fieldReadOnly;

  /// No description provided for @fieldSecretMasked.
  ///
  /// In ar, this message translates to:
  /// **'قيمة سرية — لا تُنسخ تلقائياً'**
  String get fieldSecretMasked;

  /// No description provided for @fieldNoValue.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get fieldNoValue;

  /// No description provided for @fieldPickDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخاً'**
  String get fieldPickDate;

  /// No description provided for @fieldPickReference.
  ///
  /// In ar, this message translates to:
  /// **'اختر من {module}'**
  String fieldPickReference(String module);

  /// No description provided for @fieldAttachmentViaTab.
  ///
  /// In ar, this message translates to:
  /// **'تُدار الملفات من تبويب المرفقات بعد الحفظ'**
  String get fieldAttachmentViaTab;

  /// No description provided for @filesUpload.
  ///
  /// In ar, this message translates to:
  /// **'رفع ملف'**
  String get filesUpload;

  /// No description provided for @filesCamera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get filesCamera;

  /// No description provided for @filesGallery.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الصور'**
  String get filesGallery;

  /// No description provided for @filesDocument.
  ///
  /// In ar, this message translates to:
  /// **'المستندات'**
  String get filesDocument;

  /// No description provided for @filesUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع {percent}٪'**
  String filesUploading(String percent);

  /// No description provided for @filesUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الرفع'**
  String get filesUploadFailed;

  /// No description provided for @filesUploadDone.
  ///
  /// In ar, this message translates to:
  /// **'رُفع وأُرفق'**
  String get filesUploadDone;

  /// No description provided for @filesDownload.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل'**
  String get filesDownload;

  /// No description provided for @filesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا مرفقات'**
  String get filesEmpty;

  /// No description provided for @scannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'الماسح'**
  String get scannerTitle;

  /// No description provided for @scannerHint.
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا نحو رمز QR أو باركود'**
  String get scannerHint;

  /// No description provided for @scannerNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا سجل مطابق لهذا الرمز ضمن نطاقك'**
  String get scannerNotFound;

  /// No description provided for @trackingTitle.
  ///
  /// In ar, this message translates to:
  /// **'التتبع الميداني'**
  String get trackingTitle;

  /// No description provided for @trackingStart.
  ///
  /// In ar, this message translates to:
  /// **'بدء التتبع'**
  String get trackingStart;

  /// No description provided for @trackingEnd.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التتبع'**
  String get trackingEnd;

  /// No description provided for @trackingActive.
  ///
  /// In ar, this message translates to:
  /// **'جلسة تتبع نشطة'**
  String get trackingActive;

  /// No description provided for @trackingConsent.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على مشاركة موقعي أثناء هذه الجلسة الظاهرة، وتنتهي بإنهائها'**
  String get trackingConsent;

  /// No description provided for @trackingPointsSent.
  ///
  /// In ar, this message translates to:
  /// **'نقاط مرسلة: {count}'**
  String trackingPointsSent(int count);

  /// No description provided for @trackingPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض — فعّله من إعدادات النظام'**
  String get trackingPermissionDenied;

  /// No description provided for @errUnauthenticated.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدخول غير صحيحة'**
  String get errUnauthenticated;

  /// No description provided for @errForbidden.
  ///
  /// In ar, this message translates to:
  /// **'لا صلاحية لك على هذه العملية'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In ar, this message translates to:
  /// **'غير موجود أو خارج نطاقك'**
  String get errNotFound;

  /// No description provided for @errValidation.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الحقول المعلمة'**
  String get errValidation;

  /// No description provided for @errRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة — انتظر قليلاً'**
  String get errRateLimited;

  /// No description provided for @errServer.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الخادم — حاول لاحقاً'**
  String get errServer;

  /// No description provided for @errNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال — تحقق من الشبكة'**
  String get errNetwork;

  /// No description provided for @errRequestId.
  ///
  /// In ar, this message translates to:
  /// **'معرف الطلب: {id}'**
  String errRequestId(String id);

  /// No description provided for @unreadBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} غير مقروء'**
  String unreadBadge(int count);

  /// No description provided for @pinnedTitle.
  ///
  /// In ar, this message translates to:
  /// **'مثبتاتي'**
  String get pinnedTitle;

  /// No description provided for @webOnlyDestination.
  ///
  /// In ar, this message translates to:
  /// **'وجهة ويب — تُفتح في المتصفح'**
  String get webOnlyDestination;

  /// No description provided for @confirmLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج من هذا الجهاز؟'**
  String get confirmLogout;

  /// No description provided for @confirmLogoutAll.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من كل الأجهزة والجلسات؟'**
  String get confirmLogoutAll;

  /// No description provided for @portalTitle.
  ///
  /// In ar, this message translates to:
  /// **'بوابة العميل'**
  String get portalTitle;

  /// No description provided for @portalYourSpace.
  ///
  /// In ar, this message translates to:
  /// **'مساحتك'**
  String get portalYourSpace;

  /// No description provided for @portalEngagements.
  ///
  /// In ar, this message translates to:
  /// **'الارتباطات'**
  String get portalEngagements;

  /// No description provided for @portalProjects.
  ///
  /// In ar, this message translates to:
  /// **'المشاريع'**
  String get portalProjects;

  /// No description provided for @portalDocuments.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق المشتركة'**
  String get portalDocuments;

  /// No description provided for @portalInvoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get portalInvoices;

  /// No description provided for @portalConversations.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get portalConversations;

  /// No description provided for @portalYourOrgs.
  ///
  /// In ar, this message translates to:
  /// **'منظماتك'**
  String get portalYourOrgs;

  /// No description provided for @portalEmptyWorld.
  ///
  /// In ar, this message translates to:
  /// **'لا وصول فعّالاً لحسابك بعد — تواصل مع مسؤولك لدى الشركة'**
  String get portalEmptyWorld;

  /// No description provided for @portalClientNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة لك'**
  String get portalClientNote;

  /// No description provided for @invoiceTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get invoiceTotal;

  /// No description provided for @invoicePaid.
  ///
  /// In ar, this message translates to:
  /// **'المدفوع'**
  String get invoicePaid;

  /// No description provided for @invoiceState.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get invoiceState;

  /// No description provided for @invoiceDue.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get invoiceDue;

  /// No description provided for @invoiceDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get invoiceDate;

  /// No description provided for @invoiceKind.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get invoiceKind;

  /// No description provided for @projectProgress.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإنجاز'**
  String get projectProgress;

  /// No description provided for @projectStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get projectStatus;

  /// No description provided for @projectPriority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get projectPriority;

  /// No description provided for @projectStart.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البدء'**
  String get projectStart;

  /// No description provided for @projectLaunchExpected.
  ///
  /// In ar, this message translates to:
  /// **'الإطلاق المتوقع'**
  String get projectLaunchExpected;

  /// No description provided for @projectLaunchActual.
  ///
  /// In ar, this message translates to:
  /// **'الإطلاق الفعلي'**
  String get projectLaunchActual;

  /// No description provided for @projectEngagement.
  ///
  /// In ar, this message translates to:
  /// **'الارتباط'**
  String get projectEngagement;

  /// No description provided for @projectClient.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get projectClient;

  /// No description provided for @docCategory.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get docCategory;

  /// No description provided for @docNo.
  ///
  /// In ar, this message translates to:
  /// **'رقم الوثيقة'**
  String get docNo;

  /// No description provided for @docIssueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإصدار'**
  String get docIssueDate;

  /// No description provided for @docExpiry.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get docExpiry;

  /// No description provided for @docRenewal.
  ///
  /// In ar, this message translates to:
  /// **'التجديد'**
  String get docRenewal;

  /// No description provided for @conversationWrite.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get conversationWrite;

  /// No description provided for @conversationEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا رسائل بعد'**
  String get conversationEmpty;

  /// No description provided for @activationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الحساب'**
  String get activationTitle;

  /// No description provided for @activationIntro.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ كلمة مرورك لحساب {email}'**
  String activationIntro(String email);

  /// No description provided for @activationOtp.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق (٦ أرقام)'**
  String get activationOtp;

  /// No description provided for @activationPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get activationPassword;

  /// No description provided for @activationPasswordConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get activationPasswordConfirm;

  /// No description provided for @activationSubmit.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الحساب'**
  String get activationSubmit;

  /// No description provided for @activationExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية رابط التفعيل — اطلب دعوة جديدة من مسؤولك لدى الشركة'**
  String get activationExpired;

  /// No description provided for @activationDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل حسابك — سجّل الدخول بكلمة مرورك الجديدة'**
  String get activationDone;

  /// No description provided for @activationPasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get activationPasswordMismatch;

  /// No description provided for @membersTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعضاء العميل'**
  String get membersTitle;

  /// No description provided for @membersInvite.
  ///
  /// In ar, this message translates to:
  /// **'دعوة عضو'**
  String get membersInvite;

  /// No description provided for @membersEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get membersEmail;

  /// No description provided for @membersNameOptional.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (اختياري)'**
  String get membersNameOptional;

  /// No description provided for @membersRole.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get membersRole;

  /// No description provided for @membersRevoke.
  ///
  /// In ar, this message translates to:
  /// **'سحب الوصول'**
  String get membersRevoke;

  /// No description provided for @membersRevokeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أتريد سحب وصول هذا العضو؟ يسري التعليق فوراً.'**
  String get membersRevokeConfirm;

  /// No description provided for @membersChangeRole.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدور'**
  String get membersChangeRole;

  /// No description provided for @membersInviteSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت الدعوة برسالة تفعيل — لا كلمة سر تُرسل أبداً'**
  String get membersInviteSent;

  /// No description provided for @membersStatusInvited.
  ///
  /// In ar, this message translates to:
  /// **'مدعو'**
  String get membersStatusInvited;

  /// No description provided for @membersStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'فعّال'**
  String get membersStatusActive;

  /// No description provided for @membersStatusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'معلَّق'**
  String get membersStatusSuspended;

  /// No description provided for @membersActivatedYes.
  ///
  /// In ar, this message translates to:
  /// **'فعّل حسابه'**
  String get membersActivatedYes;

  /// No description provided for @membersActivatedNo.
  ///
  /// In ar, this message translates to:
  /// **'لم يفعّل حسابه بعد'**
  String get membersActivatedNo;

  /// No description provided for @roleOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get roleOwner;

  /// No description provided for @roleLead.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول رئيسي'**
  String get roleLead;

  /// No description provided for @roleTechnical.
  ///
  /// In ar, this message translates to:
  /// **'تقني'**
  String get roleTechnical;

  /// No description provided for @roleFinance.
  ///
  /// In ar, this message translates to:
  /// **'مالي'**
  String get roleFinance;

  /// No description provided for @roleViewer.
  ///
  /// In ar, this message translates to:
  /// **'مشاهد'**
  String get roleViewer;

  /// No description provided for @askTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسأل Hub'**
  String get askTitle;

  /// No description provided for @askHint.
  ///
  /// In ar, this message translates to:
  /// **'اسأل عن مشاريعك ومهامّك…'**
  String get askHint;

  /// No description provided for @askSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get askSend;

  /// No description provided for @askWorking.
  ///
  /// In ar, this message translates to:
  /// **'يقرأ بياناتك ويجيب — قد يستغرق دقيقة…'**
  String get askWorking;

  /// No description provided for @askEmpty.
  ///
  /// In ar, this message translates to:
  /// **'اسأل سؤالاً عن بياناتك — يجيب ممّا تراه أنت فقط، ويذكر مصادره.'**
  String get askEmpty;

  /// No description provided for @askSources.
  ///
  /// In ar, this message translates to:
  /// **'المصادر'**
  String get askSources;

  /// No description provided for @askSourceRows.
  ///
  /// In ar, this message translates to:
  /// **'{label} — {rows} صفّاً'**
  String askSourceRows(String label, int rows);

  /// No description provided for @askPartial.
  ///
  /// In ar, this message translates to:
  /// **'جوابٌ جزئيّ — لم تُقرأ كلُّ البيانات'**
  String get askPartial;

  /// No description provided for @askHiddenTurn.
  ///
  /// In ar, this message translates to:
  /// **'لم يعد هذا الجواب متاحاً لك — تغيّرت صلاحيّاتك أو البيانات التي بُني عليها'**
  String get askHiddenTurn;

  /// No description provided for @askThreads.
  ///
  /// In ar, this message translates to:
  /// **'محادثاتك'**
  String get askThreads;

  /// No description provided for @askNewThread.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة'**
  String get askNewThread;

  /// No description provided for @askNoThreads.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات محفوظة'**
  String get askNoThreads;

  /// No description provided for @askMemoryOff.
  ///
  /// In ar, this message translates to:
  /// **'حفظُ المحادثات مطفأ على الخادم'**
  String get askMemoryOff;

  /// No description provided for @askRetention.
  ///
  /// In ar, this message translates to:
  /// **'تُمحى المحادثة بعد {days} يوماً بلا نشاط'**
  String askRetention(int days);

  /// No description provided for @askDeleteAll.
  ///
  /// In ar, this message translates to:
  /// **'حذف كل المحادثات'**
  String get askDeleteAll;

  /// No description provided for @askDeleteAllConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف كل محادثاتك؟ لا يمكن التراجع.'**
  String get askDeleteAllConfirm;

  /// No description provided for @askDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه المحادثة؟'**
  String get askDeleteConfirm;

  /// No description provided for @askErrUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المساعد غير متاح الآن — حاول لاحقاً'**
  String get askErrUnavailable;

  /// No description provided for @askErrLimit.
  ///
  /// In ar, this message translates to:
  /// **'بلغتَ حدّ الاستخدام — حاول لاحقاً'**
  String get askErrLimit;

  /// No description provided for @askErrDenied.
  ///
  /// In ar, this message translates to:
  /// **'لا صلاحية لك لاستعمال المساعد'**
  String get askErrDenied;

  /// No description provided for @askErrNoData.
  ///
  /// In ar, this message translates to:
  /// **'لا بيانات متاحة لك للإجابة عن هذا السؤال'**
  String get askErrNoData;

  /// No description provided for @askErrQuestion.
  ///
  /// In ar, this message translates to:
  /// **'صِغ السؤال بشكلٍ أوضح'**
  String get askErrQuestion;

  /// No description provided for @askErrTooBig.
  ///
  /// In ar, this message translates to:
  /// **'السؤال واسعٌ جداً — ضيّقه'**
  String get askErrTooBig;

  /// No description provided for @askErrGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الجواب'**
  String get askErrGeneric;

  /// No description provided for @reactionsPick.
  ///
  /// In ar, this message translates to:
  /// **'اختر تفاعلاً'**
  String get reactionsPick;

  /// No description provided for @reactionsAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف تفاعلاً'**
  String get reactionsAdd;

  /// No description provided for @typingOne.
  ///
  /// In ar, this message translates to:
  /// **'{name} يكتب…'**
  String typingOne(String name);

  /// No description provided for @typingMany.
  ///
  /// In ar, this message translates to:
  /// **'{names} يكتبون…'**
  String typingMany(String names);

  /// No description provided for @presenceOnline.
  ///
  /// In ar, this message translates to:
  /// **'متصل الآن'**
  String get presenceOnline;

  /// No description provided for @presenceRecent.
  ///
  /// In ar, this message translates to:
  /// **'نشط مؤخراً'**
  String get presenceRecent;

  /// No description provided for @presenceAway.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get presenceAway;

  /// No description provided for @presenceOffline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get presenceOffline;

  /// No description provided for @messagesTabDirect.
  ///
  /// In ar, this message translates to:
  /// **'المباشرة'**
  String get messagesTabDirect;

  /// No description provided for @messagesTabChannels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get messagesTabChannels;

  /// No description provided for @conversationsChannels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get conversationsChannels;

  /// No description provided for @conversationsRooms.
  ///
  /// In ar, this message translates to:
  /// **'غرف المشاريع'**
  String get conversationsRooms;

  /// No description provided for @conversationsGroups.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات'**
  String get conversationsGroups;

  /// No description provided for @conversationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لست عضواً في أي قناة أو مجموعة'**
  String get conversationsEmpty;

  /// No description provided for @savedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get savedTitle;

  /// No description provided for @savedEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا محفوظات'**
  String get savedEmpty;

  /// No description provided for @savedUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'لم يعد هذا متاحاً لك'**
  String get savedUnavailable;

  /// No description provided for @savedTypeComment.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get savedTypeComment;

  /// No description provided for @savedTypeDm.
  ///
  /// In ar, this message translates to:
  /// **'رسالة مباشرة'**
  String get savedTypeDm;

  /// No description provided for @savedAt.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ {date}'**
  String savedAt(String date);

  /// No description provided for @workTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'يومي'**
  String get workTodayTitle;

  /// No description provided for @workDailyReport.
  ///
  /// In ar, this message translates to:
  /// **'التقرير اليومي'**
  String get workDailyReport;

  /// No description provided for @workNoProfile.
  ///
  /// In ar, this message translates to:
  /// **'لا ملفَّ موظفٍ نشطاً مربوطاً بحسابك — لا حالَ يومٍ لعرضه'**
  String get workNoProfile;

  /// No description provided for @workAttendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get workAttendance;

  /// No description provided for @workReport.
  ///
  /// In ar, this message translates to:
  /// **'التقرير'**
  String get workReport;

  /// No description provided for @workCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول {time}'**
  String workCheckIn(String time);

  /// No description provided for @workCheckOut.
  ///
  /// In ar, this message translates to:
  /// **'خروج {time}'**
  String workCheckOut(String time);

  /// No description provided for @workReportedHours.
  ///
  /// In ar, this message translates to:
  /// **'الساعات المُبلَّغة: {hours}'**
  String workReportedHours(String hours);

  /// No description provided for @workDeadline.
  ///
  /// In ar, this message translates to:
  /// **'مهلة التقديم: {time}'**
  String workDeadline(String time);

  /// No description provided for @workReportDue.
  ///
  /// In ar, this message translates to:
  /// **'تقرير اليوم مطلوب ولم يُقدَّم بعد'**
  String get workReportDue;

  /// No description provided for @workVerdictPending.
  ///
  /// In ar, this message translates to:
  /// **'لم يحِن وقت الحكم على اليوم بعد'**
  String get workVerdictPending;

  /// No description provided for @workNeedsReview.
  ///
  /// In ar, this message translates to:
  /// **'بنودٌ بانتظار المراجعة أو التعديل'**
  String get workNeedsReview;

  /// No description provided for @workEntries.
  ///
  /// In ar, this message translates to:
  /// **'بنود اليوم ({count})'**
  String workEntries(int count);

  /// No description provided for @workNoEntries.
  ///
  /// In ar, this message translates to:
  /// **'لا بنود مُقدَّمة لهذا اليوم'**
  String get workNoEntries;

  /// No description provided for @workSubmit.
  ///
  /// In ar, this message translates to:
  /// **'قدّم بند عمل'**
  String get workSubmit;

  /// No description provided for @workEntryHours.
  ///
  /// In ar, this message translates to:
  /// **'{hours} ساعة'**
  String workEntryHours(String hours);

  /// No description provided for @workEntryProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم {progress}٪'**
  String workEntryProgress(String progress);

  /// No description provided for @workReviewPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المراجعة'**
  String get workReviewPending;

  /// No description provided for @workReviewAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get workReviewAccepted;

  /// No description provided for @workReviewNeedsRevision.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج تعديلاً'**
  String get workReviewNeedsRevision;

  /// No description provided for @workPrevDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم السابق'**
  String get workPrevDay;

  /// No description provided for @workNextDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم التالي'**
  String get workNextDay;

  /// No description provided for @myDocumentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'وثائقي'**
  String get myDocumentsTitle;

  /// No description provided for @myDocumentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا وثائق على ملفّك'**
  String get myDocumentsEmpty;

  /// No description provided for @myDocumentsExpires.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي {date}'**
  String myDocumentsExpires(String date);

  /// No description provided for @myDocumentsExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت {date}'**
  String myDocumentsExpired(String date);

  /// No description provided for @myDocumentsNo.
  ///
  /// In ar, this message translates to:
  /// **'رقم {no}'**
  String myDocumentsNo(String no);

  /// No description provided for @myDocumentsInfected.
  ///
  /// In ar, this message translates to:
  /// **'محجوبة — وُسمت مصابة بفحص الفيروسات'**
  String get myDocumentsInfected;

  /// No description provided for @myDocumentsNoPreview.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة داخل التطبيق للصور فقط — افتحها من المنصة على الويب'**
  String get myDocumentsNoPreview;

  /// No description provided for @myDocumentsRestricted.
  ///
  /// In ar, this message translates to:
  /// **'وصول هذه الوثيقة مقيَّد بقاعدة صريحة'**
  String get myDocumentsRestricted;

  /// No description provided for @myDocumentsNoPersist.
  ///
  /// In ar, this message translates to:
  /// **'تُعرض الوثائق من الذاكرة ولا تُحفظ على الجهاز'**
  String get myDocumentsNoPersist;

  /// No description provided for @savedAction.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get savedAction;

  /// No description provided for @savedDone.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت في المحفوظات'**
  String get savedDone;

  /// No description provided for @savedAlready.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة سلفاً'**
  String get savedAlready;

  /// No description provided for @savedUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get savedUndo;

  /// No description provided for @savedRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المحفوظات'**
  String get savedRemove;

  /// No description provided for @savedRemoved.
  ///
  /// In ar, this message translates to:
  /// **'أُزيلت من المحفوظات'**
  String get savedRemoved;

  /// No description provided for @syncedAt.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة {date} {time}'**
  String syncedAt(String date, String time);

  /// No description provided for @notificationNoTarget.
  ///
  /// In ar, this message translates to:
  /// **'لا وجهة لهذا الإشعار — بقي في القائمة'**
  String get notificationNoTarget;

  /// No description provided for @fileSizeBytes.
  ///
  /// In ar, this message translates to:
  /// **'{count} بايت'**
  String fileSizeBytes(int count);

  /// No description provided for @fileSizeKb.
  ///
  /// In ar, this message translates to:
  /// **'{size} ك.ب'**
  String fileSizeKb(String size);

  /// No description provided for @fileSizeMb.
  ///
  /// In ar, this message translates to:
  /// **'{size} م.ب'**
  String fileSizeMb(String size);

  /// No description provided for @filesNoInAppPreview.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة داخل التطبيق للصور فقط (من الذاكرة، بلا حفظ على الجهاز) — افتح هذا الملف من المنصة على الويب'**
  String get filesNoInAppPreview;

  /// No description provided for @filesOpenOnWeb.
  ///
  /// In ar, this message translates to:
  /// **'افتح على الويب'**
  String get filesOpenOnWeb;

  /// No description provided for @filesFieldOnWebOnly.
  ///
  /// In ar, this message translates to:
  /// **'ملف هذا الحقل يُفتح من صفحة السجل على المنصة على الويب'**
  String get filesFieldOnWebOnly;

  /// No description provided for @filesInfected.
  ///
  /// In ar, this message translates to:
  /// **'محجوب — وُسم مصاباً بفحص الفيروسات'**
  String get filesInfected;

  /// No description provided for @prefsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التفضيلات'**
  String get prefsTitle;

  /// No description provided for @prefsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كتم الإشعارات وتثبيت المفضّلة — تُحفظ على الخادم'**
  String get prefsSubtitle;

  /// No description provided for @prefsMuteHint.
  ///
  /// In ar, this message translates to:
  /// **'النوع المكتوم لا يُنشأ لك إشعاره أصلاً — على الويب والجوال معاً'**
  String get prefsMuteHint;

  /// No description provided for @prefsMuted.
  ///
  /// In ar, this message translates to:
  /// **'مكتوم'**
  String get prefsMuted;

  /// No description provided for @prefsNotifying.
  ///
  /// In ar, this message translates to:
  /// **'يُشعِرك'**
  String get prefsNotifying;

  /// No description provided for @prefsPinsCount.
  ///
  /// In ar, this message translates to:
  /// **'مثبّت {count} من {max}'**
  String prefsPinsCount(int count, int max);

  /// No description provided for @prefsPinsFilter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية الوجهات'**
  String get prefsPinsFilter;

  /// No description provided for @prefsPin.
  ///
  /// In ar, this message translates to:
  /// **'ثبّت'**
  String get prefsPin;

  /// No description provided for @prefsUnpin.
  ///
  /// In ar, this message translates to:
  /// **'فكّ التثبيت'**
  String get prefsUnpin;

  /// No description provided for @languageArabicShort.
  ///
  /// In ar, this message translates to:
  /// **'عربي'**
  String get languageArabicShort;

  /// No description provided for @languageEnglishShort.
  ///
  /// In ar, this message translates to:
  /// **'EN'**
  String get languageEnglishShort;

  /// No description provided for @unknownInitial.
  ///
  /// In ar, this message translates to:
  /// **'؟'**
  String get unknownInitial;

  /// No description provided for @appVersionTitle.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق'**
  String get appVersionTitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In ar, this message translates to:
  /// **'إصدار أحدث متاح'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In ar, this message translates to:
  /// **'التحديث اختياري الآن — افتح المتجر'**
  String get updateAvailableBody;

  /// No description provided for @supportTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعم'**
  String get supportTitle;

  /// No description provided for @commentReply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get commentReply;

  /// No description provided for @listSeparator.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get listSeparator;

  /// No description provided for @percentValue.
  ///
  /// In ar, this message translates to:
  /// **'{value}٪'**
  String percentValue(int value);

  /// No description provided for @diagnosticsSessionActive.
  ///
  /// In ar, this message translates to:
  /// **'نشطة (id: {id})'**
  String diagnosticsSessionActive(String id);

  /// No description provided for @diagnosticsPushReadyNoToken.
  ///
  /// In ar, this message translates to:
  /// **'ready (لا رمز)'**
  String get diagnosticsPushReadyNoToken;

  /// No description provided for @pushPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة — فعّل إذن الإشعارات من إعدادات الجهاز'**
  String get pushPermissionDenied;

  /// No description provided for @pushAwaitingToken.
  ///
  /// In ar, this message translates to:
  /// **'مهيأة — بانتظار رمز الجهاز'**
  String get pushAwaitingToken;

  /// No description provided for @pushBannerDefaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعار جديد'**
  String get pushBannerDefaultTitle;

  /// No description provided for @pushBannerOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get pushBannerOpen;

  /// No description provided for @pushTestReceived.
  ///
  /// In ar, this message translates to:
  /// **'وصل إشعارٌ تجريبي من مركز منصة الجوال'**
  String get pushTestReceived;

  /// No description provided for @diagnosticsPushPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'permission denied (الإذن مرفوض)'**
  String get diagnosticsPushPermissionDenied;

  /// No description provided for @fieldValueRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldValueRequired;

  /// No description provided for @attendanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحضور والانصراف'**
  String get attendanceTitle;

  /// No description provided for @attendanceAlreadyIn.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل حضورك اليوم مسبقاً'**
  String get attendanceAlreadyIn;

  /// No description provided for @attendanceOpenShift.
  ///
  /// In ar, this message translates to:
  /// **'لديك ورديةٌ مفتوحة من يومٍ سابق — سجّل انصرافك منها أولاً'**
  String get attendanceOpenShift;

  /// No description provided for @attendanceNotIn.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجّل حضوراً بعد'**
  String get attendanceNotIn;

  /// No description provided for @attendanceAlreadyOut.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل انصرافك مسبقاً'**
  String get attendanceAlreadyOut;

  /// No description provided for @attendanceConsentRequired.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الموقع يتطلّب موافقتك الصريحة'**
  String get attendanceConsentRequired;

  /// No description provided for @attendanceNoProfile.
  ///
  /// In ar, this message translates to:
  /// **'لا ملف موظفٍ مربوطاً بحسابك'**
  String get attendanceNoProfile;

  /// No description provided for @attendanceLocationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد الموقع — يُسجَّل بلا موقع'**
  String get attendanceLocationUnavailable;

  /// No description provided for @attendanceCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل الحضور'**
  String get attendanceCheckedIn;

  /// No description provided for @attendanceCheckedOut.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل الانصراف'**
  String get attendanceCheckedOut;

  /// No description provided for @attendanceStateNotIn.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجّل حضورك اليوم'**
  String get attendanceStateNotIn;

  /// No description provided for @attendanceStateIn.
  ///
  /// In ar, this message translates to:
  /// **'حاضر منذ {time}'**
  String attendanceStateIn(String time);

  /// No description provided for @attendanceStateOut.
  ///
  /// In ar, this message translates to:
  /// **'حضور {timeIn} · انصراف {timeOut}'**
  String attendanceStateOut(String timeIn, String timeOut);

  /// No description provided for @attendanceHours.
  ///
  /// In ar, this message translates to:
  /// **'{hours} ساعة'**
  String attendanceHours(String hours);

  /// No description provided for @attendanceOvernight.
  ///
  /// In ar, this message translates to:
  /// **'وردية ليلية ممتدة من اليوم السابق'**
  String get attendanceOvernight;

  /// No description provided for @attendanceMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع العمل'**
  String get attendanceMode;

  /// No description provided for @attendanceShareLocation.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق موقعي لهذه المرة'**
  String get attendanceShareLocation;

  /// No description provided for @attendanceShareLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'قراءةٌ واحدة لحظة الضغط بموافقتك — لا تتبّع'**
  String get attendanceShareLocationHint;

  /// No description provided for @attendanceCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحضور'**
  String get attendanceCheckIn;

  /// No description provided for @attendanceCheckOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الانصراف'**
  String get attendanceCheckOut;

  /// No description provided for @leaveRejectReasonTitle.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get leaveRejectReasonTitle;

  /// No description provided for @leaveRejectReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'يقرؤه صاحب الطلب'**
  String get leaveRejectReasonHint;

  /// No description provided for @leaveApproveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد طلب الإجازة؟ يحسم الخادم مرحلته (موافقة المدير أو الاعتماد النهائي).'**
  String get leaveApproveConfirm;

  /// No description provided for @leaveAlreadyDecided.
  ///
  /// In ar, this message translates to:
  /// **'هذا الطلب محسومٌ مسبقاً'**
  String get leaveAlreadyDecided;

  /// No description provided for @leaveSelfRequest.
  ///
  /// In ar, this message translates to:
  /// **'لا تقرّر في طلبك أنت — يقرّر مديرك أو الموارد البشرية'**
  String get leaveSelfRequest;

  /// No description provided for @leaveNotDecider.
  ///
  /// In ar, this message translates to:
  /// **'قرار هذا الطلب لمدير الموظف أو الموارد البشرية'**
  String get leaveNotDecider;

  /// No description provided for @leaveReasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض مطلوب'**
  String get leaveReasonRequired;

  /// No description provided for @leaveDecisionTitle.
  ///
  /// In ar, this message translates to:
  /// **'قرار الطلب'**
  String get leaveDecisionTitle;

  /// No description provided for @custodyTitle.
  ///
  /// In ar, this message translates to:
  /// **'عهدتي'**
  String get custodyTitle;

  /// No description provided for @custodyEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا عهدة بيدك ولا حركات'**
  String get custodyEmpty;

  /// No description provided for @custodyAcked.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل إقرار الاستلام'**
  String get custodyAcked;

  /// No description provided for @custodyPendingReceipts.
  ///
  /// In ar, this message translates to:
  /// **'إقرارات استلام معلّقة'**
  String get custodyPendingReceipts;

  /// No description provided for @custodyAck.
  ///
  /// In ar, this message translates to:
  /// **'أُقرّ بالاستلام'**
  String get custodyAck;

  /// No description provided for @custodyAssets.
  ///
  /// In ar, this message translates to:
  /// **'ما بيدي ({count})'**
  String custodyAssets(int count);

  /// No description provided for @custodyNoAssets.
  ///
  /// In ar, this message translates to:
  /// **'لا أصول بيدك الآن'**
  String get custodyNoAssets;

  /// No description provided for @custodyReceiptPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار إقرارك'**
  String get custodyReceiptPending;

  /// No description provided for @custodyMoves.
  ///
  /// In ar, this message translates to:
  /// **'حركات عهدتي'**
  String get custodyMoves;

  /// No description provided for @custodyHandoverTo.
  ///
  /// In ar, this message translates to:
  /// **'تسليم العهدة إلى {name}'**
  String custodyHandoverTo(String name);

  /// No description provided for @custodyNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختيارية)'**
  String get custodyNoteHint;

  /// No description provided for @custodyRecover.
  ///
  /// In ar, this message translates to:
  /// **'استرداد العهدة'**
  String get custodyRecover;

  /// No description provided for @custodyHandover.
  ///
  /// In ar, this message translates to:
  /// **'تسليم العهدة'**
  String get custodyHandover;

  /// No description provided for @custodyActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'العهدة'**
  String get custodyActionsTitle;

  /// No description provided for @inventoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'جلسات الجرد'**
  String get inventoryTitle;

  /// No description provided for @inventoryFreezeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'فتح جلسة جردٍ جديدة بتجميد لقطة أصولك الآن؟'**
  String get inventoryFreezeConfirm;

  /// No description provided for @inventoryFrozen.
  ///
  /// In ar, this message translates to:
  /// **'جُمِّد {count} أصلاً في الجلسة'**
  String inventoryFrozen(int count);

  /// No description provided for @inventoryFreeze.
  ///
  /// In ar, this message translates to:
  /// **'جلسة جديدة'**
  String get inventoryFreeze;

  /// No description provided for @inventoryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا جلسات جرد'**
  String get inventoryEmpty;

  /// No description provided for @inventorySessionMeta.
  ///
  /// In ar, this message translates to:
  /// **'{items} صنفاً · {scans} مسحة · {by}'**
  String inventorySessionMeta(int items, int scans, String by);

  /// No description provided for @inventorySession.
  ///
  /// In ar, this message translates to:
  /// **'جلسة الجرد'**
  String get inventorySession;

  /// No description provided for @inventoryReconcile.
  ///
  /// In ar, this message translates to:
  /// **'المصالحة'**
  String get inventoryReconcile;

  /// No description provided for @inventoryReconcileConfirm.
  ///
  /// In ar, this message translates to:
  /// **'مصالحة الجلسة كتابياً (موجود/مفقود/انتقل/غير متوقع)؟ يتطلّب تأكيد الهوية.'**
  String get inventoryReconcileConfirm;

  /// No description provided for @inventoryReconciled.
  ///
  /// In ar, this message translates to:
  /// **'تمت المصالحة'**
  String get inventoryReconciled;

  /// No description provided for @inventoryClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الجلسة'**
  String get inventoryClose;

  /// No description provided for @inventoryCloseConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الجلسة؟ لا مسح بعد الإغلاق. يتطلّب تأكيد الهوية.'**
  String get inventoryCloseConfirm;

  /// No description provided for @inventoryClosed.
  ///
  /// In ar, this message translates to:
  /// **'أُغلقت الجلسة'**
  String get inventoryClosed;

  /// No description provided for @inventoryScan.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get inventoryScan;

  /// No description provided for @inventoryItems.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف ({count})'**
  String inventoryItems(int count);

  /// No description provided for @inventoryRecentScans.
  ///
  /// In ar, this message translates to:
  /// **'أحدث المسحات'**
  String get inventoryRecentScans;

  /// No description provided for @inventoryUnknownCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير معروف (لا يُخزَّن)'**
  String get inventoryUnknownCode;

  /// No description provided for @inventorySessionClosed.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة مغلقة — لا مسح بعد الإغلاق'**
  String get inventorySessionClosed;

  /// No description provided for @inventoryScanHint.
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا إلى رمز الأصل'**
  String get inventoryScanHint;

  /// No description provided for @inventoryScanKnown.
  ///
  /// In ar, this message translates to:
  /// **'✓ معروف: {name}'**
  String inventoryScanKnown(String name);

  /// No description provided for @inventoryScanUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'⚠ غير متوقع: {name}'**
  String inventoryScanUnexpected(String name);

  /// No description provided for @inventoryScanUnknown.
  ///
  /// In ar, this message translates to:
  /// **'✗ رمز غير معروف في نطاقك'**
  String get inventoryScanUnknown;

  /// No description provided for @inventoryScanCount.
  ///
  /// In ar, this message translates to:
  /// **'المسح ({count})'**
  String inventoryScanCount(int count);

  /// No description provided for @pageOf.
  ///
  /// In ar, this message translates to:
  /// **'{page} من {pages}'**
  String pageOf(int page, int pages);

  /// No description provided for @filesDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف المرفق «{name}»؟'**
  String filesDeleteConfirm(String name);

  /// No description provided for @filesDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذف المرفق'**
  String get filesDeleted;

  /// No description provided for @filesExpires.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي {date}'**
  String filesExpires(String date);

  /// No description provided for @filesMessageNoPreview.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة داخل التطبيق للصور فقط (من الذاكرة) — افتح هذا المرفق من المنصة على الويب'**
  String get filesMessageNoPreview;

  /// No description provided for @inventoryUnknownCompany.
  ///
  /// In ar, this message translates to:
  /// **'الشركة المختارة في السياق غير معروفة — اختر شركةً أخرى أو ألغِ التضييق'**
  String get inventoryUnknownCompany;

  /// No description provided for @versionsRestoreConfirm.
  ///
  /// In ar, this message translates to:
  /// **'استعادة السجل إلى النسخة {version}؟ تُنشأ نسخةٌ جديدة بقيمها.'**
  String versionsRestoreConfirm(int version);

  /// No description provided for @versionsRestore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get versionsRestore;

  /// No description provided for @versionsRestored.
  ///
  /// In ar, this message translates to:
  /// **'استُعيدت النسخة {version}'**
  String versionsRestored(int version);

  /// No description provided for @versionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'نسخ السجل'**
  String get versionsTitle;

  /// No description provided for @versionsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا نسخ محفوظة لهذا السجل'**
  String get versionsEmpty;

  /// No description provided for @versionsCurrent.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الحالية'**
  String get versionsCurrent;

  /// No description provided for @versionsOldest.
  ///
  /// In ar, this message translates to:
  /// **'أقدم نسخة معروضة'**
  String get versionsOldest;

  /// No description provided for @versionsNoVisibleChange.
  ///
  /// In ar, this message translates to:
  /// **'لا تغيير في الحقول الظاهرة لك'**
  String get versionsNoVisibleChange;

  /// No description provided for @versionsChanged.
  ///
  /// In ar, this message translates to:
  /// **'تغيّر: {fields}'**
  String versionsChanged(String fields);

  /// No description provided for @financeQueuedBlocked.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة بانتظار اعتمادٍ معلّق — لا تنفيذ الآن'**
  String get financeQueuedBlocked;

  /// No description provided for @financePaid.
  ///
  /// In ar, this message translates to:
  /// **'سُجّلت دفعة {amount}'**
  String financePaid(String amount);

  /// No description provided for @financePaidRemaining.
  ///
  /// In ar, this message translates to:
  /// **'سُجّلت دفعة {amount} — المتبقي {remaining} {currency}'**
  String financePaidRemaining(String amount, String remaining, String currency);

  /// No description provided for @financeQuoteSendConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إرسال عرض السعر؟ قد يُحال للمراجعة الداخلية بحسب عتبة الاعتماد.'**
  String get financeQuoteSendConfirm;

  /// No description provided for @financeQuoteEscalated.
  ///
  /// In ar, this message translates to:
  /// **'أُحيل العرض للمراجعة الداخلية قبل الإرسال'**
  String get financeQuoteEscalated;

  /// No description provided for @financeQuoteSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل عرض السعر'**
  String get financeQuoteSent;

  /// No description provided for @financeQuoteAcceptConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل قبول عرض السعر؟'**
  String get financeQuoteAcceptConfirm;

  /// No description provided for @financeQuoteAccepted.
  ///
  /// In ar, this message translates to:
  /// **'قُبل عرض السعر'**
  String get financeQuoteAccepted;

  /// No description provided for @financeQuoteAlreadyAccepted.
  ///
  /// In ar, this message translates to:
  /// **'العرض مقبولٌ مسبقاً — لا أثر جديد'**
  String get financeQuoteAlreadyAccepted;

  /// No description provided for @financeReceiveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'استلام أمر الشراء وإنشاء حركات المخزون؟'**
  String get financeReceiveConfirm;

  /// No description provided for @financeAlreadyReceived.
  ///
  /// In ar, this message translates to:
  /// **'الأمر مستلمٌ مسبقاً'**
  String get financeAlreadyReceived;

  /// No description provided for @financeReceived.
  ///
  /// In ar, this message translates to:
  /// **'اُستلم الأمر: {moves} حركة مخزون · {skipped} متخطّى'**
  String financeReceived(int moves, int skipped);

  /// No description provided for @financePay.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دفعة'**
  String get financePay;

  /// No description provided for @financeQuoteSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال العرض'**
  String get financeQuoteSend;

  /// No description provided for @financeQuoteAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول العرض'**
  String get financeQuoteAccept;

  /// No description provided for @financeReceive.
  ///
  /// In ar, this message translates to:
  /// **'استلام الأمر'**
  String get financeReceive;

  /// No description provided for @financeAmountInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغاً موجباً بصيغة عشرية صريحة (مثل 2500.000) بلا فواصل آلاف'**
  String get financeAmountInvalid;

  /// No description provided for @financeAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get financeAmount;

  /// No description provided for @financePayRef.
  ///
  /// In ar, this message translates to:
  /// **'المرجع (اختياري)'**
  String get financePayRef;

  /// No description provided for @financePayNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختيارية)'**
  String get financePayNote;

  /// No description provided for @commentEdit.
  ///
  /// In ar, this message translates to:
  /// **'تحرير'**
  String get commentEdit;

  /// No description provided for @commentEdited.
  ///
  /// In ar, this message translates to:
  /// **'حُرِّر التعليق'**
  String get commentEdited;

  /// No description provided for @commentDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذا التعليق؟'**
  String get commentDeleteConfirm;

  /// No description provided for @commentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذف التعليق'**
  String get commentDeleted;

  /// No description provided for @commentPinnedDone.
  ///
  /// In ar, this message translates to:
  /// **'ثُبِّت التعليق'**
  String get commentPinnedDone;

  /// No description provided for @commentUnpinned.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي التثبيت'**
  String get commentUnpinned;

  /// No description provided for @commentResolvedDone.
  ///
  /// In ar, this message translates to:
  /// **'عُلِّم محلولاً'**
  String get commentResolvedDone;

  /// No description provided for @commentReopened.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد فتحه'**
  String get commentReopened;

  /// No description provided for @commentToTaskDone.
  ///
  /// In ar, this message translates to:
  /// **'حُوِّل التعليق إلى مهمة'**
  String get commentToTaskDone;

  /// No description provided for @commentUnpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get commentUnpin;

  /// No description provided for @commentPin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت'**
  String get commentPin;

  /// No description provided for @commentReopen.
  ///
  /// In ar, this message translates to:
  /// **'إعادة فتح'**
  String get commentReopen;

  /// No description provided for @commentResolve.
  ///
  /// In ar, this message translates to:
  /// **'تعليم محلولاً'**
  String get commentResolve;

  /// No description provided for @commentToTask.
  ///
  /// In ar, this message translates to:
  /// **'تحويل لمهمة'**
  String get commentToTask;

  /// No description provided for @ticketsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذاكري'**
  String get ticketsTitle;

  /// No description provided for @ticketsNew.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ جديد'**
  String get ticketsNew;

  /// No description provided for @ticketsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا تذاكر بعد'**
  String get ticketsEmpty;

  /// No description provided for @ticketsCreated.
  ///
  /// In ar, this message translates to:
  /// **'فُتح البلاغ'**
  String get ticketsCreated;

  /// No description provided for @ticketsDuplicateTitle.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ مشابه مفتوح'**
  String get ticketsDuplicateTitle;

  /// No description provided for @ticketsDuplicateBody.
  ///
  /// In ar, this message translates to:
  /// **'لديك بلاغٌ مطابق ما زال مفتوحاً: «{subject}». أضِف ردّك عليه، أو أرسل هذا إن كان بلاغاً مختلفاً.'**
  String ticketsDuplicateBody(String subject);

  /// No description provided for @ticketsOpenExisting.
  ///
  /// In ar, this message translates to:
  /// **'فتح القائم'**
  String get ticketsOpenExisting;

  /// No description provided for @ticketsSubmitAnyway.
  ///
  /// In ar, this message translates to:
  /// **'إرسال كبلاغٍ مختلف'**
  String get ticketsSubmitAnyway;

  /// No description provided for @ticketsSubject.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع'**
  String get ticketsSubject;

  /// No description provided for @ticketsBody.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get ticketsBody;

  /// No description provided for @ticketsPriority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get ticketsPriority;

  /// No description provided for @ticketsProject.
  ///
  /// In ar, this message translates to:
  /// **'المشروع'**
  String get ticketsProject;

  /// No description provided for @ticketsNone.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get ticketsNone;

  /// No description provided for @ticketsOrg.
  ///
  /// In ar, this message translates to:
  /// **'المنظمة'**
  String get ticketsOrg;

  /// No description provided for @ticketsNoReplies.
  ///
  /// In ar, this message translates to:
  /// **'لا ردود بعد'**
  String get ticketsNoReplies;

  /// No description provided for @ticketsYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get ticketsYou;

  /// No description provided for @ticketsReplyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردّك…'**
  String get ticketsReplyHint;

  /// No description provided for @channelVisPrivate.
  ///
  /// In ar, this message translates to:
  /// **'خاصة'**
  String get channelVisPrivate;

  /// No description provided for @channelVisMembers.
  ///
  /// In ar, this message translates to:
  /// **'للأعضاء'**
  String get channelVisMembers;

  /// No description provided for @channelVisCompany.
  ///
  /// In ar, this message translates to:
  /// **'للشركة'**
  String get channelVisCompany;

  /// No description provided for @channelVisPublic.
  ///
  /// In ar, this message translates to:
  /// **'عامة'**
  String get channelVisPublic;

  /// No description provided for @channelVisDefault.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get channelVisDefault;

  /// No description provided for @channelRoleOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get channelRoleOwner;

  /// No description provided for @channelRoleModerator.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get channelRoleModerator;

  /// No description provided for @channelRoleMember.
  ///
  /// In ar, this message translates to:
  /// **'عضو'**
  String get channelRoleMember;

  /// No description provided for @channelRoleGuest.
  ///
  /// In ar, this message translates to:
  /// **'ضيف'**
  String get channelRoleGuest;

  /// No description provided for @channelNotifyAll.
  ///
  /// In ar, this message translates to:
  /// **'كل الرسائل'**
  String get channelNotifyAll;

  /// No description provided for @channelNotifyMentions.
  ///
  /// In ar, this message translates to:
  /// **'الإشارات فقط'**
  String get channelNotifyMentions;

  /// No description provided for @channelNotifyMuted.
  ///
  /// In ar, this message translates to:
  /// **'مكتومة'**
  String get channelNotifyMuted;

  /// No description provided for @channelCreated.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئت القناة'**
  String get channelCreated;

  /// No description provided for @channelNew.
  ///
  /// In ar, this message translates to:
  /// **'قناة جديدة'**
  String get channelNew;

  /// No description provided for @channelName.
  ///
  /// In ar, this message translates to:
  /// **'اسم القناة'**
  String get channelName;

  /// No description provided for @channelVisibility.
  ///
  /// In ar, this message translates to:
  /// **'الظهور'**
  String get channelVisibility;

  /// No description provided for @channelJoined.
  ///
  /// In ar, this message translates to:
  /// **'انضممت إلى القناة'**
  String get channelJoined;

  /// No description provided for @channelAlreadyMember.
  ///
  /// In ar, this message translates to:
  /// **'أنت عضوٌ فيها مسبقاً'**
  String get channelAlreadyMember;

  /// No description provided for @channelDirectory.
  ///
  /// In ar, this message translates to:
  /// **'دليل القنوات'**
  String get channelDirectory;

  /// No description provided for @channelDirectoryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا قنوات متاحة للانضمام'**
  String get channelDirectoryEmpty;

  /// No description provided for @channelMembersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} عضواً'**
  String channelMembersCount(int count);

  /// No description provided for @channelJoin.
  ///
  /// In ar, this message translates to:
  /// **'انضمام'**
  String get channelJoin;

  /// No description provided for @groupCreated.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئت المجموعة'**
  String get groupCreated;

  /// No description provided for @groupNew.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة جديدة'**
  String get groupNew;

  /// No description provided for @groupTitleOptional.
  ///
  /// In ar, this message translates to:
  /// **'اسم المجموعة (اختياري)'**
  String get groupTitleOptional;

  /// No description provided for @groupNoContacts.
  ///
  /// In ar, this message translates to:
  /// **'لا جهات في رسائلك المباشرة بعد — راسل زملاءك أولاً'**
  String get groupNoContacts;

  /// No description provided for @channelRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إزالة {name} من الحاوية؟'**
  String channelRemoveConfirm(String name);

  /// No description provided for @channelRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get channelRemove;

  /// No description provided for @channelMembers.
  ///
  /// In ar, this message translates to:
  /// **'الأعضاء'**
  String get channelMembers;

  /// No description provided for @channelAddMember.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو'**
  String get channelAddMember;

  /// No description provided for @channelMakeRole.
  ///
  /// In ar, this message translates to:
  /// **'اجعله {role}'**
  String channelMakeRole(String role);

  /// No description provided for @messageSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في نص الرسائل…'**
  String get messageSearchHint;

  /// No description provided for @messageSearchMin.
  ///
  /// In ar, this message translates to:
  /// **'اكتب {count} أحرف على الأقل'**
  String messageSearchMin(int count);

  /// No description provided for @messageSearchNone.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج'**
  String get messageSearchNone;

  /// No description provided for @messageSearchTotal.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتيجة'**
  String messageSearchTotal(int count);

  /// No description provided for @channelFavorited.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت للمفضّلة'**
  String get channelFavorited;

  /// No description provided for @channelUnfavorited.
  ///
  /// In ar, this message translates to:
  /// **'أُزيلت من المفضّلة'**
  String get channelUnfavorited;

  /// No description provided for @channelNotifySaved.
  ///
  /// In ar, this message translates to:
  /// **'الإشعار: {pref}'**
  String channelNotifySaved(String pref);

  /// No description provided for @channelArchived.
  ///
  /// In ar, this message translates to:
  /// **'أُرشفت القناة'**
  String get channelArchived;

  /// No description provided for @channelUnarchived.
  ///
  /// In ar, this message translates to:
  /// **'أُعيدت القناة من الأرشيف'**
  String get channelUnarchived;

  /// No description provided for @groupLeaveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'مغادرة هذه المجموعة؟ لن تصلك رسائلها بعد.'**
  String get groupLeaveConfirm;

  /// No description provided for @groupLeave.
  ///
  /// In ar, this message translates to:
  /// **'مغادرة المجموعة'**
  String get groupLeave;

  /// No description provided for @groupLeft.
  ///
  /// In ar, this message translates to:
  /// **'غادرت المجموعة'**
  String get groupLeft;

  /// No description provided for @channelFavorite.
  ///
  /// In ar, this message translates to:
  /// **'المفضّلة (تبديل)'**
  String get channelFavorite;

  /// No description provided for @channelNotify.
  ///
  /// In ar, this message translates to:
  /// **'تفضيل الإشعار'**
  String get channelNotify;

  /// No description provided for @channelArchive.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة/إعادة'**
  String get channelArchive;

  /// No description provided for @dmEdit.
  ///
  /// In ar, this message translates to:
  /// **'تحرير'**
  String get dmEdit;

  /// No description provided for @dmDelete.
  ///
  /// In ar, this message translates to:
  /// **'سحب الرسالة'**
  String get dmDelete;

  /// No description provided for @dmDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سحب هذه الرسالة؟ يبقى أثرها «حُذفت».'**
  String get dmDeleteConfirm;

  /// No description provided for @dmEdited.
  ///
  /// In ar, this message translates to:
  /// **'(معدّلة)'**
  String get dmEdited;

  /// No description provided for @reviewAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get reviewAccepted;

  /// No description provided for @reviewNeedsRevision.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج تنقيحاً'**
  String get reviewNeedsRevision;

  /// No description provided for @reviewPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المراجعة'**
  String get reviewPending;

  /// No description provided for @reviewFeedbackTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة التنقيح'**
  String get reviewFeedbackTitle;

  /// No description provided for @reviewFeedbackHint.
  ///
  /// In ar, this message translates to:
  /// **'ما المطلوب تحسينه؟ يقرؤها الموظف'**
  String get reviewFeedbackHint;

  /// No description provided for @teamReportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقارير الفريق اليومية'**
  String get teamReportsTitle;

  /// No description provided for @previousDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم السابق'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم التالي'**
  String get nextDay;

  /// No description provided for @reviewScopeTeam.
  ///
  /// In ar, this message translates to:
  /// **'فريقي'**
  String get reviewScopeTeam;

  /// No description provided for @reviewScopeMine.
  ///
  /// In ar, this message translates to:
  /// **'مشاريعي'**
  String get reviewScopeMine;

  /// No description provided for @reviewAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get reviewAll;

  /// No description provided for @reviewSummary.
  ///
  /// In ar, this message translates to:
  /// **'{total} بنداً · {pending} بانتظار · {accepted} مقبول · {revision} للتنقيح'**
  String reviewSummary(int total, int pending, int accepted, int revision);

  /// No description provided for @reviewEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا بنود لهذا اليوم'**
  String get reviewEmpty;

  /// No description provided for @reviewTruncated.
  ///
  /// In ar, this message translates to:
  /// **'عُرض أول ٢٠٠ بند — ضيّق التصفية'**
  String get reviewTruncated;

  /// No description provided for @reviewHours.
  ///
  /// In ar, this message translates to:
  /// **'{hours} ساعة'**
  String reviewHours(String hours);

  /// No description provided for @reviewProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدّم {progress}٪'**
  String reviewProgress(String progress);

  /// No description provided for @reviewProblems.
  ///
  /// In ar, this message translates to:
  /// **'عوائق: {text}'**
  String reviewProblems(String text);

  /// No description provided for @reviewNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي: {text}'**
  String reviewNext(String text);

  /// No description provided for @reviewFeedback.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة المراجع: {text}'**
  String reviewFeedback(String text);

  /// No description provided for @reviewAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get reviewAccept;

  /// No description provided for @reviewRequestRevision.
  ///
  /// In ar, this message translates to:
  /// **'طلب تنقيح'**
  String get reviewRequestRevision;

  /// No description provided for @reviewReopen.
  ///
  /// In ar, this message translates to:
  /// **'إعادة فتح'**
  String get reviewReopen;

  /// No description provided for @calendarTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get calendarTitle;

  /// No description provided for @calendarPrev.
  ///
  /// In ar, this message translates to:
  /// **'النافذة السابقة'**
  String get calendarPrev;

  /// No description provided for @calendarNext.
  ///
  /// In ar, this message translates to:
  /// **'النافذة التالية'**
  String get calendarNext;

  /// No description provided for @calendarEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا مواعيد في هذه النافذة'**
  String get calendarEmpty;

  /// No description provided for @calendarOverflow.
  ///
  /// In ar, this message translates to:
  /// **'{count} عنصراً إضافياً لم يُعرض — افتح التقويم على الويب للاطلاع عليها'**
  String calendarOverflow(int count);

  /// No description provided for @alertsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get alertsTitle;

  /// No description provided for @alertsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء ينتهي قريباً'**
  String get alertsEmpty;

  /// No description provided for @alertsLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get alertsLate;

  /// No description provided for @alertsWeek.
  ///
  /// In ar, this message translates to:
  /// **'خلال أسبوع'**
  String get alertsWeek;

  /// No description provided for @alertsWindow.
  ///
  /// In ar, this message translates to:
  /// **'خلال {days} يوماً'**
  String alertsWindow(int days);

  /// No description provided for @alertsDaysLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخر {days} يوماً'**
  String alertsDaysLate(int days);

  /// No description provided for @alertsDaysLeft.
  ///
  /// In ar, this message translates to:
  /// **'بعد {days} يوماً'**
  String alertsDaysLeft(int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
