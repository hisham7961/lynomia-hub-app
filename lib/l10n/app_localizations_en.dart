// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lynomia Hub';

  @override
  String get navHome => 'Home';

  @override
  String get navMyWork => 'My Work';

  @override
  String get navDomains => 'Domains';

  @override
  String get navSearch => 'Search';

  @override
  String get navAccount => 'Account';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionClose => 'Close';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionSend => 'Send';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionLogin => 'Sign in';

  @override
  String get actionLogout => 'Sign out';

  @override
  String get actionLogoutAll => 'Sign out of all sessions';

  @override
  String get actionApprove => 'Approve';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionShowAll => 'Show all';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateEmpty => 'Nothing to show';

  @override
  String get stateOffline => 'No internet connection';

  @override
  String get stateOfflineCached => 'You are offline — showing a cached copy';

  @override
  String get stateError => 'Something went wrong';

  @override
  String get stateSyncing => 'Syncing…';

  @override
  String stateLastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get requiresConnection => 'Requires an internet connection';

  @override
  String get loginTitle => 'Sign in to Lynomia';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginInvalidEmail => 'Enter a valid email';

  @override
  String get loginRequired => 'This field is required';

  @override
  String get mfaTitle => 'Two-step verification';

  @override
  String get mfaHint => 'Enter the code from your authenticator app';

  @override
  String get mfaCode => 'Verification code';

  @override
  String get mfaExpired => 'Challenge expired — sign in again';

  @override
  String get stepUpTitle => 'Confirm your identity';

  @override
  String get stepUpPassword => 'Enter your password to continue';

  @override
  String get stepUpTotp => 'Enter your current verification code to continue';

  @override
  String get biometricUnlockTitle => 'Unlock Lynomia Hub';

  @override
  String get biometricUnlockReason => 'Unlock to access your session';

  @override
  String get biometricPrefTitle => 'Unlock with biometrics';

  @override
  String get biometricPrefSubtitle =>
      'Local lock on this device — nothing is sent to the server';

  @override
  String get sessionExpired => 'Session expired — sign in again';

  @override
  String get sessionRevoked =>
      'Your session is no longer valid — it was revoked from another device or by an admin';

  @override
  String get accountRestricted =>
      'Account restricted — contact your administrator';

  @override
  String get maintenanceTitle => 'Scheduled maintenance';

  @override
  String get maintenanceBody =>
      'The server is under temporary maintenance. Try again later.';

  @override
  String get lockdownTitle => 'Security lockdown';

  @override
  String get lockdownBody =>
      'Sign-in is temporarily suspended by a security decision.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This app version is older than the minimum supported. Update to continue.';

  @override
  String get updateStoreButton => 'Open store';

  @override
  String get updateStoreNotConfigured =>
      'The store link is not configured yet — contact support for the latest version.';

  @override
  String get serverUnavailable => 'Could not reach the server';

  @override
  String get homeAttention => 'Needs your attention';

  @override
  String get homeDue => 'Due soon';

  @override
  String get homeMyTasks => 'My open tasks';

  @override
  String get homeProjects => 'My projects';

  @override
  String get homeRecent => 'Recent activity';

  @override
  String get homeApprovalsPending => 'Pending approvals';

  @override
  String get myWorkTitle => 'My Work';

  @override
  String get myWorkTasks => 'Tasks assigned to me';

  @override
  String get myWorkApprovals => 'Approvals';

  @override
  String get myWorkNotifications => 'Notifications';

  @override
  String get myWorkMessages => 'Messages';

  @override
  String get domainsTitle => 'Domains';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search everything you can see…';

  @override
  String get searchMinChars => 'Enter at least two characters';

  @override
  String get searchNoResults => 'No matching results';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSessions => 'Mobile sessions';

  @override
  String get accountSessionCurrent => 'Current session';

  @override
  String get accountSessionRevoke => 'Revoke session';

  @override
  String get accountContext => 'Viewing context';

  @override
  String get accountContextCompany => 'Company';

  @override
  String get accountContextClient => 'Client';

  @override
  String get accountContextAll => 'All (no narrowing)';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountTheme => 'Appearance';

  @override
  String get accountThemeSystem => 'System';

  @override
  String get accountThemeLight => 'Light';

  @override
  String get accountThemeDark => 'Dark';

  @override
  String get accountSecurity => 'Security';

  @override
  String get accountNotificationPrefs => 'Notification preferences';

  @override
  String get accountPushStatus => 'Push notifications';

  @override
  String get pushNotConfigured =>
      'Not configured — requires push provider setup';

  @override
  String get pushRegistered => 'Enabled on this device';

  @override
  String get diagnosticsTitle => 'Developer diagnostics';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsUnreadOnly => 'Unread only';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesEmpty => 'No conversations yet';

  @override
  String get messagesHint => 'Write a message…';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsEmpty => 'No comments yet';

  @override
  String get commentsHint => 'Add a comment…';

  @override
  String get commentInternal => 'Internal';

  @override
  String get commentPinned => 'Pinned';

  @override
  String get commentResolved => 'Resolved';

  @override
  String get approvalsTitle => 'Approvals';

  @override
  String get approvalsEmpty => 'No pending requests';

  @override
  String get approvalRejectReason => 'Rejection reason (optional)';

  @override
  String get approvalDecided => 'Your decision was recorded';

  @override
  String get approvalStale =>
      'The request is stale — the record changed after it was submitted. Refresh, then decide.';

  @override
  String get approvalQueued =>
      'This operation is approval-protected — your request was queued for approvers';

  @override
  String get approvalOpenTarget => 'Open target record';

  @override
  String get recordTitle => 'Record';

  @override
  String get recordOverview => 'Overview';

  @override
  String get recordFields => 'Fields';

  @override
  String get recordActions => 'Actions';

  @override
  String get recordComments => 'Comments';

  @override
  String get recordAttachments => 'Attachments';

  @override
  String get recordVersionConflictTitle => 'Version conflict';

  @override
  String recordVersionConflictBody(String server) {
    return 'Someone else edited this record after you opened it (server version $server). Refresh, then redo your edit.';
  }

  @override
  String get recordVersionConflictReload => 'Load server version';

  @override
  String get recordDeleteConfirm =>
      'Delete this record? It moves to the recycle bin.';

  @override
  String get recordDeleted => 'Moved to the recycle bin';

  @override
  String get recordSaved => 'Saved';

  @override
  String get recordCreated => 'Created';

  @override
  String get recordNotFound => 'Not found or outside your scope';

  @override
  String get recordNoAccess => 'You do not have access here';

  @override
  String get actionDestructiveConfirm =>
      'This action is hard to undo — continue?';

  @override
  String get actionNeedsApproval => 'An approval request will be queued';

  @override
  String get actionDone => 'Done';

  @override
  String get actionsEmpty =>
      'No actions available for the record\'s current state';

  @override
  String moduleSearchHint(String module) {
    return 'Search $module…';
  }

  @override
  String get moduleSort => 'Sort';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get fieldReadOnly => 'Read only';

  @override
  String get fieldSecretMasked => 'Secret value — not auto-copied';

  @override
  String get fieldNoValue => '—';

  @override
  String get fieldPickDate => 'Pick a date';

  @override
  String fieldPickReference(String module) {
    return 'Pick from $module';
  }

  @override
  String get fieldAttachmentViaTab =>
      'Files are managed from the attachments tab after saving';

  @override
  String get filesUpload => 'Upload file';

  @override
  String get filesCamera => 'Camera';

  @override
  String get filesGallery => 'Photo library';

  @override
  String get filesDocument => 'Documents';

  @override
  String filesUploading(String percent) {
    return 'Uploading $percent%';
  }

  @override
  String get filesUploadFailed => 'Upload failed';

  @override
  String get filesUploadDone => 'Uploaded and attached';

  @override
  String get filesDownload => 'Download';

  @override
  String get filesEmpty => 'No attachments';

  @override
  String get scannerTitle => 'Scanner';

  @override
  String get scannerHint => 'Point the camera at a QR code or barcode';

  @override
  String get scannerNotFound =>
      'No matching record for this code within your scope';

  @override
  String get trackingTitle => 'Field tracking';

  @override
  String get trackingStart => 'Start tracking';

  @override
  String get trackingEnd => 'End tracking';

  @override
  String get trackingActive => 'Active tracking session';

  @override
  String get trackingConsent =>
      'I agree to share my location during this visible session; it ends when I end it';

  @override
  String trackingPointsSent(int count) {
    return 'Points sent: $count';
  }

  @override
  String get trackingPermissionDenied =>
      'Location permission denied — enable it in system settings';

  @override
  String get errUnauthenticated => 'Incorrect sign-in credentials';

  @override
  String get errForbidden => 'You do not have permission for this operation';

  @override
  String get errNotFound => 'Not found or outside your scope';

  @override
  String get errValidation => 'Check the highlighted fields';

  @override
  String get errRateLimited => 'Too many attempts — wait a moment';

  @override
  String get errServer => 'Server error — try again later';

  @override
  String get errNetwork => 'Connection failed — check your network';

  @override
  String errRequestId(String id) {
    return 'Request ID: $id';
  }

  @override
  String unreadBadge(int count) {
    return '$count unread';
  }

  @override
  String get pinnedTitle => 'My pins';

  @override
  String get webOnlyDestination => 'Web destination — opens in the browser';

  @override
  String get confirmLogout => 'Sign out of this device?';

  @override
  String get confirmLogoutAll => 'Sign out of all devices and sessions?';
}
