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
  /// **'Lynomia Hub'**
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
