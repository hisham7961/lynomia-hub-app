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

  @override
  String get portalTitle => 'Client portal';

  @override
  String get portalYourSpace => 'Your space';

  @override
  String get portalEngagements => 'Engagements';

  @override
  String get portalProjects => 'Projects';

  @override
  String get portalDocuments => 'Shared documents';

  @override
  String get portalInvoices => 'Invoices';

  @override
  String get portalConversations => 'Conversations';

  @override
  String get portalYourOrgs => 'Your organizations';

  @override
  String get portalEmptyWorld =>
      'Your account has no active access yet — contact your company representative';

  @override
  String get portalClientNote => 'Note for you';

  @override
  String get invoiceTotal => 'Total';

  @override
  String get invoicePaid => 'Paid';

  @override
  String get invoiceState => 'Status';

  @override
  String get invoiceDue => 'Due date';

  @override
  String get invoiceDate => 'Date';

  @override
  String get invoiceKind => 'Kind';

  @override
  String get projectProgress => 'Progress';

  @override
  String get projectStatus => 'Status';

  @override
  String get projectPriority => 'Priority';

  @override
  String get projectStart => 'Start date';

  @override
  String get projectLaunchExpected => 'Expected launch';

  @override
  String get projectLaunchActual => 'Actual launch';

  @override
  String get projectEngagement => 'Engagement';

  @override
  String get projectClient => 'Client';

  @override
  String get docCategory => 'Category';

  @override
  String get docNo => 'Document no.';

  @override
  String get docIssueDate => 'Issue date';

  @override
  String get docExpiry => 'Expiry date';

  @override
  String get docRenewal => 'Renewal';

  @override
  String get conversationWrite => 'Write a message…';

  @override
  String get conversationEmpty => 'No messages yet';

  @override
  String get activationTitle => 'Activate account';

  @override
  String activationIntro(String email) {
    return 'Create your password for $email';
  }

  @override
  String get activationOtp => 'Verification code (6 digits)';

  @override
  String get activationPassword => 'New password';

  @override
  String get activationPasswordConfirm => 'Confirm password';

  @override
  String get activationSubmit => 'Activate account';

  @override
  String get activationExpired =>
      'This activation link has expired — ask your company representative for a new invitation';

  @override
  String get activationDone =>
      'Your account is activated — sign in with your new password';

  @override
  String get activationPasswordMismatch => 'Passwords do not match';

  @override
  String get membersTitle => 'Client members';

  @override
  String get membersInvite => 'Invite member';

  @override
  String get membersEmail => 'Email';

  @override
  String get membersNameOptional => 'Name (optional)';

  @override
  String get membersRole => 'Role';

  @override
  String get membersRevoke => 'Revoke access';

  @override
  String get membersRevokeConfirm =>
      'Revoke this member\'s access? Suspension takes effect immediately.';

  @override
  String get membersChangeRole => 'Change role';

  @override
  String get membersInviteSent =>
      'Invitation sent as an activation message — no password is ever sent';

  @override
  String get membersStatusInvited => 'Invited';

  @override
  String get membersStatusActive => 'Active';

  @override
  String get membersStatusSuspended => 'Suspended';

  @override
  String get membersActivatedYes => 'Account activated';

  @override
  String get membersActivatedNo => 'Not activated yet';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleLead => 'Lead';

  @override
  String get roleTechnical => 'Technical';

  @override
  String get roleFinance => 'Finance';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get askTitle => 'Ask Hub';

  @override
  String get askHint => 'Ask about your projects and tasks…';

  @override
  String get askSend => 'Send';

  @override
  String get askWorking =>
      'Reading your data and answering — this may take a minute…';

  @override
  String get askEmpty =>
      'Ask a question about your data — answers come only from what you can see, with sources.';

  @override
  String get askSources => 'Sources';

  @override
  String askSourceRows(String label, int rows) {
    return '$label — $rows rows';
  }

  @override
  String get askPartial => 'Partial answer — not all data was read';

  @override
  String get askHiddenTurn =>
      'This answer is no longer available to you — your access or its data changed';

  @override
  String get askThreads => 'Your conversations';

  @override
  String get askNewThread => 'New conversation';

  @override
  String get askNoThreads => 'No saved conversations';

  @override
  String get askMemoryOff => 'Conversation saving is turned off on the server';

  @override
  String askRetention(int days) {
    return 'A conversation is deleted after $days days of inactivity';
  }

  @override
  String get askDeleteAll => 'Delete all conversations';

  @override
  String get askDeleteAllConfirm =>
      'Delete all your conversations? This cannot be undone.';

  @override
  String get askDeleteConfirm => 'Delete this conversation?';

  @override
  String get askErrUnavailable =>
      'The assistant is unavailable right now — try later';

  @override
  String get askErrLimit => 'You have reached the usage limit — try later';

  @override
  String get askErrDenied => 'You are not allowed to use the assistant';

  @override
  String get askErrNoData => 'No data available to you answers this question';

  @override
  String get askErrQuestion => 'Please phrase the question more clearly';

  @override
  String get askErrTooBig => 'The question is too broad — narrow it down';

  @override
  String get askErrGeneric => 'Could not answer';

  @override
  String get reactionsPick => 'Pick a reaction';

  @override
  String get reactionsAdd => 'Add reaction';

  @override
  String typingOne(String name) {
    return '$name is typing…';
  }

  @override
  String typingMany(String names) {
    return '$names are typing…';
  }

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceRecent => 'Recently active';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get messagesTabDirect => 'Direct';

  @override
  String get messagesTabChannels => 'Channels';

  @override
  String get conversationsChannels => 'Channels';

  @override
  String get conversationsRooms => 'Project rooms';

  @override
  String get conversationsGroups => 'Groups';

  @override
  String get conversationsEmpty =>
      'You are not a member of any channel or group';

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedEmpty => 'Nothing saved';

  @override
  String get savedUnavailable => 'This is no longer available to you';

  @override
  String get savedTypeComment => 'Comment';

  @override
  String get savedTypeDm => 'Direct message';

  @override
  String savedAt(String date) {
    return 'Saved $date';
  }

  @override
  String get workTodayTitle => 'My day';

  @override
  String get workDailyReport => 'Daily report';

  @override
  String get workNoProfile =>
      'No active employee profile is linked to your account — no workday to show';

  @override
  String get workAttendance => 'Attendance';

  @override
  String get workReport => 'Report';

  @override
  String workCheckIn(String time) {
    return 'In $time';
  }

  @override
  String workCheckOut(String time) {
    return 'Out $time';
  }

  @override
  String workReportedHours(String hours) {
    return 'Reported hours: $hours';
  }

  @override
  String workDeadline(String time) {
    return 'Submission deadline: $time';
  }

  @override
  String get workReportDue =>
      'Today\'s report is required and not yet submitted';

  @override
  String get workVerdictPending => 'It is too early to judge the day';

  @override
  String get workNeedsReview => 'Entries are pending review or revision';

  @override
  String workEntries(int count) {
    return 'Day entries ($count)';
  }

  @override
  String get workNoEntries => 'No entries submitted for this day';

  @override
  String get workSubmit => 'Submit a work entry';

  @override
  String workEntryHours(String hours) {
    return '$hours h';
  }

  @override
  String workEntryProgress(String progress) {
    return 'Progress $progress%';
  }

  @override
  String get workReviewPending => 'Pending review';

  @override
  String get workReviewAccepted => 'Accepted';

  @override
  String get workReviewNeedsRevision => 'Needs revision';

  @override
  String get workPrevDay => 'Previous day';

  @override
  String get workNextDay => 'Next day';

  @override
  String get myDocumentsTitle => 'My documents';

  @override
  String get myDocumentsEmpty => 'No documents on your file';

  @override
  String myDocumentsExpires(String date) {
    return 'Expires $date';
  }

  @override
  String myDocumentsExpired(String date) {
    return 'Expired $date';
  }

  @override
  String myDocumentsNo(String no) {
    return 'No. $no';
  }

  @override
  String get myDocumentsInfected => 'Blocked — flagged by the virus scan';

  @override
  String get myDocumentsNoPreview =>
      'In-app preview is for images only — open it from the web platform';

  @override
  String get myDocumentsRestricted =>
      'Access to this document is restricted by an explicit rule';

  @override
  String get myDocumentsNoPersist =>
      'Documents are shown from memory and never saved on the device';

  @override
  String get savedAction => 'Save';

  @override
  String get savedDone => 'Saved';

  @override
  String get savedAlready => 'Already saved';

  @override
  String get savedUndo => 'Undo';

  @override
  String get savedRemove => 'Remove from saved';

  @override
  String get savedRemoved => 'Removed from saved';

  @override
  String syncedAt(String date, String time) {
    return 'Last synced $date $time';
  }

  @override
  String get notificationNoTarget =>
      'This notification has no destination — staying in the list';

  @override
  String fileSizeBytes(int count) {
    return '$count B';
  }

  @override
  String fileSizeKb(String size) {
    return '$size KB';
  }

  @override
  String fileSizeMb(String size) {
    return '$size MB';
  }

  @override
  String get filesNoInAppPreview =>
      'In-app preview supports images only (from memory, never saved on the device) — open this file from the web platform';

  @override
  String get filesOpenOnWeb => 'Open on web';

  @override
  String get filesFieldOnWebOnly =>
      'This field\'s file opens from the record page on the web platform';

  @override
  String get filesInfected => 'Blocked — flagged as infected by the virus scan';

  @override
  String get prefsTitle => 'Preferences';

  @override
  String get prefsSubtitle =>
      'Mute notifications and pin favourites — saved on the server';

  @override
  String get prefsMuteHint =>
      'Muted kinds are never created for you — on web and mobile alike';

  @override
  String get prefsMuted => 'Muted';

  @override
  String get prefsNotifying => 'Notifying';

  @override
  String prefsPinsCount(int count, int max) {
    return '$count of $max pinned';
  }

  @override
  String get prefsPinsFilter => 'Filter destinations';

  @override
  String get prefsPin => 'Pin';

  @override
  String get prefsUnpin => 'Unpin';

  @override
  String get languageArabicShort => 'عربي';

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get unknownInitial => '?';

  @override
  String get appVersionTitle => 'App version';

  @override
  String get updateAvailableTitle => 'A newer version is available';

  @override
  String get updateAvailableBody =>
      'Updating is optional for now — open the store';

  @override
  String get supportTitle => 'Support';

  @override
  String get commentReply => 'Reply';

  @override
  String get listSeparator => ', ';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String diagnosticsSessionActive(String id) {
    return 'active (id: $id)';
  }

  @override
  String get diagnosticsPushReadyNoToken => 'ready (no token)';
}
