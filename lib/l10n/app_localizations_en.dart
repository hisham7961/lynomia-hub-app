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

  @override
  String get pushPermissionDenied =>
      'Denied — enable notification permission in device settings';

  @override
  String get pushAwaitingToken => 'Configured — waiting for the device token';

  @override
  String get pushBannerDefaultTitle => 'New notification';

  @override
  String get pushBannerOpen => 'Open';

  @override
  String get pushTestReceived =>
      'Test notification received from the Mobile Platform center';

  @override
  String get diagnosticsPushPermissionDenied => 'permission denied';

  @override
  String get fieldValueRequired => 'This field is required';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceAlreadyIn => 'You have already checked in today';

  @override
  String get attendanceOpenShift =>
      'You have an open shift from a previous day — check out of it first';

  @override
  String get attendanceNotIn => 'You have not checked in yet';

  @override
  String get attendanceAlreadyOut => 'You have already checked out';

  @override
  String get attendanceConsentRequired =>
      'Sending your location requires your explicit consent';

  @override
  String get attendanceNoProfile =>
      'No employee profile is linked to your account';

  @override
  String get attendanceLocationUnavailable =>
      'Location unavailable — recording without location';

  @override
  String get attendanceCheckedIn => 'Checked in';

  @override
  String get attendanceCheckedOut => 'Checked out';

  @override
  String get attendanceStateNotIn => 'You haven\'t checked in today';

  @override
  String attendanceStateIn(String time) {
    return 'Checked in since $time';
  }

  @override
  String attendanceStateOut(String timeIn, String timeOut) {
    return 'In $timeIn · Out $timeOut';
  }

  @override
  String attendanceHours(String hours) {
    return '$hours h';
  }

  @override
  String get attendanceOvernight => 'Overnight shift from the previous day';

  @override
  String get attendanceMode => 'Work mode';

  @override
  String get attendanceShareLocation => 'Attach my location this time';

  @override
  String get attendanceShareLocationHint =>
      'One reading at the moment you tap, with your consent — no tracking';

  @override
  String get attendanceCheckIn => 'Check in';

  @override
  String get attendanceCheckOut => 'Check out';

  @override
  String get leaveRejectReasonTitle => 'Rejection reason';

  @override
  String get leaveRejectReasonHint => 'The requester will read it';

  @override
  String get leaveApproveConfirm =>
      'Approve this leave request? The server decides the stage (manager approval or final approval).';

  @override
  String get leaveAlreadyDecided => 'This request has already been decided';

  @override
  String get leaveSelfRequest =>
      'You can\'t decide your own request — your manager or HR decides';

  @override
  String get leaveNotDecider =>
      'This request is decided by the employee\'s manager or HR';

  @override
  String get leaveReasonRequired => 'A rejection reason is required';

  @override
  String get leaveDecisionTitle => 'Decision';

  @override
  String get custodyTitle => 'My custody';

  @override
  String get custodyEmpty => 'No assets in your custody and no movements';

  @override
  String get custodyAcked => 'Receipt acknowledged';

  @override
  String get custodyPendingReceipts => 'Pending receipt acknowledgements';

  @override
  String get custodyAck => 'Acknowledge';

  @override
  String custodyAssets(int count) {
    return 'In my hands ($count)';
  }

  @override
  String get custodyNoAssets => 'No assets in your hands now';

  @override
  String get custodyReceiptPending => 'Awaiting your acknowledgement';

  @override
  String get custodyMoves => 'My custody movements';

  @override
  String custodyHandoverTo(String name) {
    return 'Hand over to $name';
  }

  @override
  String get custodyNoteHint => 'Note (optional)';

  @override
  String get custodyRecover => 'Recover custody';

  @override
  String get custodyHandover => 'Hand over';

  @override
  String get custodyActionsTitle => 'Custody';

  @override
  String get inventoryTitle => 'Inventory sessions';

  @override
  String get inventoryFreezeConfirm =>
      'Open a new inventory session by freezing a snapshot of your assets now?';

  @override
  String inventoryFrozen(int count) {
    return '$count assets frozen into the session';
  }

  @override
  String get inventoryFreeze => 'New session';

  @override
  String get inventoryEmpty => 'No inventory sessions';

  @override
  String inventorySessionMeta(int items, int scans, String by) {
    return '$items items · $scans scans · $by';
  }

  @override
  String get inventorySession => 'Inventory session';

  @override
  String get inventoryReconcile => 'Reconcile';

  @override
  String get inventoryReconcileConfirm =>
      'Reconcile the session (present/missing/moved/unexpected)? Requires identity confirmation.';

  @override
  String get inventoryReconciled => 'Reconciled';

  @override
  String get inventoryClose => 'Close session';

  @override
  String get inventoryCloseConfirm =>
      'Close the session? No scanning after closing. Requires identity confirmation.';

  @override
  String get inventoryClosed => 'Session closed';

  @override
  String get inventoryScan => 'Scan';

  @override
  String inventoryItems(int count) {
    return 'Items ($count)';
  }

  @override
  String get inventoryRecentScans => 'Recent scans';

  @override
  String get inventoryUnknownCode => 'Unknown code (not stored)';

  @override
  String get inventorySessionClosed =>
      'The session is closed — no scanning after closing';

  @override
  String get inventoryScanHint => 'Point the camera at the asset code';

  @override
  String inventoryScanKnown(String name) {
    return '✓ Known: $name';
  }

  @override
  String inventoryScanUnexpected(String name) {
    return '⚠ Unexpected: $name';
  }

  @override
  String get inventoryScanUnknown => '✗ Code not known in your scope';

  @override
  String inventoryScanCount(int count) {
    return 'Scanning ($count)';
  }

  @override
  String pageOf(int page, int pages) {
    return '$page of $pages';
  }

  @override
  String filesDeleteConfirm(String name) {
    return 'Delete attachment “$name”?';
  }

  @override
  String get filesDeleted => 'Attachment deleted';

  @override
  String filesExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get filesMessageNoPreview =>
      'In-app preview is for images only (in memory) — open this attachment on the web platform';

  @override
  String get inventoryUnknownCompany =>
      'The company selected in context is unknown — choose another or clear the filter';

  @override
  String versionsRestoreConfirm(int version) {
    return 'Restore the record to version $version? A new version is created with its values.';
  }

  @override
  String get versionsRestore => 'Restore';

  @override
  String versionsRestored(int version) {
    return 'Version $version restored';
  }

  @override
  String get versionsTitle => 'Record versions';

  @override
  String get versionsEmpty => 'No saved versions for this record';

  @override
  String get versionsCurrent => 'Current version';

  @override
  String get versionsOldest => 'Oldest listed version';

  @override
  String get versionsNoVisibleChange => 'No change in fields visible to you';

  @override
  String versionsChanged(String fields) {
    return 'Changed: $fields';
  }

  @override
  String get financeQueuedBlocked =>
      'A pending approval is queued for this module — not executed now';

  @override
  String financePaid(String amount) {
    return 'Payment of $amount recorded';
  }

  @override
  String financePaidRemaining(
    String amount,
    String remaining,
    String currency,
  ) {
    return 'Payment of $amount recorded — remaining $remaining $currency';
  }

  @override
  String get financeQuoteSendConfirm =>
      'Send the quote? It may be escalated for internal review by the approval threshold.';

  @override
  String get financeQuoteEscalated =>
      'The quote was escalated for internal review before sending';

  @override
  String get financeQuoteSent => 'Quote sent';

  @override
  String get financeQuoteAcceptConfirm => 'Record acceptance of the quote?';

  @override
  String get financeQuoteAccepted => 'Quote accepted';

  @override
  String get financeQuoteAlreadyAccepted =>
      'The quote was already accepted — no new effect';

  @override
  String get financeReceiveConfirm =>
      'Receive the purchase order and create stock movements?';

  @override
  String get financeAlreadyReceived => 'The order was already received';

  @override
  String financeReceived(int moves, int skipped) {
    return 'Received: $moves stock movements · $skipped skipped';
  }

  @override
  String get financePay => 'Record payment';

  @override
  String get financeQuoteSend => 'Send quote';

  @override
  String get financeQuoteAccept => 'Accept quote';

  @override
  String get financeReceive => 'Receive order';

  @override
  String get financeAmountInvalid =>
      'Enter a positive decimal amount (e.g. 2500.000) without thousands separators';

  @override
  String get financeAmount => 'Amount';

  @override
  String get financePayRef => 'Reference (optional)';

  @override
  String get financePayNote => 'Note (optional)';

  @override
  String get commentEdit => 'Edit';

  @override
  String get commentEdited => 'Comment edited';

  @override
  String get commentDeleteConfirm => 'Delete this comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get commentPinnedDone => 'Comment pinned';

  @override
  String get commentUnpinned => 'Unpinned';

  @override
  String get commentResolvedDone => 'Marked resolved';

  @override
  String get commentReopened => 'Reopened';

  @override
  String get commentToTaskDone => 'Comment converted to a task';

  @override
  String get commentUnpin => 'Unpin';

  @override
  String get commentPin => 'Pin';

  @override
  String get commentReopen => 'Reopen';

  @override
  String get commentResolve => 'Resolve';

  @override
  String get commentToTask => 'Convert to task';

  @override
  String get ticketsTitle => 'My tickets';

  @override
  String get ticketsNew => 'New ticket';

  @override
  String get ticketsEmpty => 'No tickets yet';

  @override
  String get ticketsCreated => 'Ticket opened';

  @override
  String get ticketsDuplicateTitle => 'A similar ticket is open';

  @override
  String ticketsDuplicateBody(String subject) {
    return 'You have a matching ticket still open: “$subject”. Reply on it, or submit this one if it\'s a different issue.';
  }

  @override
  String get ticketsOpenExisting => 'Open existing';

  @override
  String get ticketsSubmitAnyway => 'Submit as a different ticket';

  @override
  String get ticketsSubject => 'Subject';

  @override
  String get ticketsBody => 'Description';

  @override
  String get ticketsPriority => 'Priority';

  @override
  String get ticketsProject => 'Project';

  @override
  String get ticketsNone => '—';

  @override
  String get ticketsOrg => 'Organization';

  @override
  String get ticketsNoReplies => 'No replies yet';

  @override
  String get ticketsYou => 'You';

  @override
  String get ticketsReplyHint => 'Write your reply…';

  @override
  String get channelVisPrivate => 'Private';

  @override
  String get channelVisMembers => 'Members only';

  @override
  String get channelVisCompany => 'Company';

  @override
  String get channelVisPublic => 'Public';

  @override
  String get channelVisDefault => 'Default';

  @override
  String get channelRoleOwner => 'Owner';

  @override
  String get channelRoleModerator => 'Moderator';

  @override
  String get channelRoleMember => 'Member';

  @override
  String get channelRoleGuest => 'Guest';

  @override
  String get channelNotifyAll => 'All messages';

  @override
  String get channelNotifyMentions => 'Mentions only';

  @override
  String get channelNotifyMuted => 'Muted';

  @override
  String get channelCreated => 'Channel created';

  @override
  String get channelNew => 'New channel';

  @override
  String get channelName => 'Channel name';

  @override
  String get channelVisibility => 'Visibility';

  @override
  String get channelJoined => 'You joined the channel';

  @override
  String get channelAlreadyMember => 'You\'re already a member';

  @override
  String get channelDirectory => 'Channel directory';

  @override
  String get channelDirectoryEmpty => 'No channels available to join';

  @override
  String channelMembersCount(int count) {
    return '$count members';
  }

  @override
  String get channelJoin => 'Join';

  @override
  String get groupCreated => 'Group created';

  @override
  String get groupNew => 'New group';

  @override
  String get groupTitleOptional => 'Group name (optional)';

  @override
  String get groupNoContacts =>
      'No direct-message contacts yet — message your colleagues first';

  @override
  String channelRemoveConfirm(String name) {
    return 'Remove $name from the conversation?';
  }

  @override
  String get channelRemove => 'Remove';

  @override
  String get channelMembers => 'Members';

  @override
  String get channelAddMember => 'Add member';

  @override
  String channelMakeRole(String role) {
    return 'Make $role';
  }

  @override
  String get messageSearchHint => 'Search message text…';

  @override
  String messageSearchMin(int count) {
    return 'Type at least $count characters';
  }

  @override
  String get messageSearchNone => 'No results';

  @override
  String messageSearchTotal(int count) {
    return '$count results';
  }

  @override
  String get channelFavorited => 'Added to favorites';

  @override
  String get channelUnfavorited => 'Removed from favorites';

  @override
  String channelNotifySaved(String pref) {
    return 'Notifications: $pref';
  }

  @override
  String get channelArchived => 'Channel archived';

  @override
  String get channelUnarchived => 'Channel unarchived';

  @override
  String get groupLeaveConfirm =>
      'Leave this group? You won\'t receive its messages anymore.';

  @override
  String get groupLeave => 'Leave group';

  @override
  String get groupLeft => 'You left the group';

  @override
  String get channelFavorite => 'Favorite (toggle)';

  @override
  String get channelNotify => 'Notification preference';

  @override
  String get channelArchive => 'Archive / unarchive';

  @override
  String get dmEdit => 'Edit';

  @override
  String get dmDelete => 'Delete message';

  @override
  String get dmDeleteConfirm =>
      'Delete this message? A “deleted” marker remains.';

  @override
  String get dmEdited => '(edited)';

  @override
  String get reviewAccepted => 'Accepted';

  @override
  String get reviewNeedsRevision => 'Needs revision';

  @override
  String get reviewPending => 'Pending review';

  @override
  String get reviewFeedbackTitle => 'Revision feedback';

  @override
  String get reviewFeedbackHint =>
      'What should be improved? The employee will read it';

  @override
  String get teamReportsTitle => 'Team daily reports';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get reviewScopeTeam => 'My team';

  @override
  String get reviewScopeMine => 'My projects';

  @override
  String get reviewAll => 'All';

  @override
  String reviewSummary(int total, int pending, int accepted, int revision) {
    return '$total entries · $pending pending · $accepted accepted · $revision to revise';
  }

  @override
  String get reviewEmpty => 'No entries for this day';

  @override
  String get reviewTruncated =>
      'Showing the first 200 entries — narrow the filter';

  @override
  String reviewHours(String hours) {
    return '$hours h';
  }

  @override
  String reviewProgress(String progress) {
    return 'Progress $progress%';
  }

  @override
  String reviewProblems(String text) {
    return 'Blockers: $text';
  }

  @override
  String reviewNext(String text) {
    return 'Next: $text';
  }

  @override
  String reviewFeedback(String text) {
    return 'Reviewer note: $text';
  }

  @override
  String get reviewAccept => 'Accept';

  @override
  String get reviewRequestRevision => 'Request revision';

  @override
  String get reviewReopen => 'Reopen';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarPrev => 'Previous window';

  @override
  String get calendarNext => 'Next window';

  @override
  String get calendarEmpty => 'Nothing scheduled in this window';

  @override
  String calendarOverflow(int count) {
    return '$count more items not shown — open the calendar on the web to see them';
  }

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsEmpty => 'Nothing expiring soon';

  @override
  String get alertsLate => 'Overdue';

  @override
  String get alertsWeek => 'Within a week';

  @override
  String alertsWindow(int days) {
    return 'Within $days days';
  }

  @override
  String alertsDaysLate(int days) {
    return '$days days overdue';
  }

  @override
  String alertsDaysLeft(int days) {
    return 'In $days days';
  }

  @override
  String get notificationChannelName => 'Lynomia Hub notifications';

  @override
  String get notificationChannelDescription =>
      'Messages, approvals and alerts from your workspace';

  @override
  String leaveApproveBecomes(String status) {
    return 'Approving sets the request to “$status”';
  }

  @override
  String get eligibilityLoadFailed => 'Could not check availability';

  @override
  String get custodyNotHeld =>
      'This asset is not held by anyone — nothing to recover';

  @override
  String financeRemaining(String remaining, String currency) {
    return 'Remaining: $remaining $currency';
  }

  @override
  String get financePayDeadState =>
      'The document is cancelled or a draft — payments can\'t be recorded';

  @override
  String get financePaySettled =>
      'The document is fully settled — nothing remaining';

  @override
  String get financeBank => 'Bank';

  @override
  String get financeNoBank => 'No bank';

  @override
  String get groupAddParticipants => 'Add participants';

  @override
  String get groupForkExplain =>
      'Adding participants creates a new group with current and new members and an empty history; this group stays as is for its members.';

  @override
  String get groupForked => 'A new group was created with the participants';

  @override
  String get groupForkNoCandidates =>
      'No new contacts in your direct messages to add';

  @override
  String complianceTitle(int count) {
    return 'Today\'s compliance ($count)';
  }

  @override
  String complianceSummary(int done, int pending, int missing) {
    return 'Submitted $done · Pending $pending · Missing $missing';
  }

  @override
  String get complianceCompliant => 'Submitted';

  @override
  String get compliancePending => 'Awaiting submission';

  @override
  String get complianceMissing => 'Not submitted';

  @override
  String get complianceLate => 'Submitted late';

  @override
  String get complianceNotRequired => 'Not required';

  @override
  String get complianceReported => 'Submitted (no attendance)';

  @override
  String get complianceVerdictPending => 'Not yet due';

  @override
  String get complianceOnLeave => 'On leave';

  @override
  String get complianceLateArrival => 'Arrived late';

  @override
  String complianceTimeIn(String time) {
    return 'In $time';
  }

  @override
  String complianceTimeOut(String time) {
    return 'Out $time';
  }
}
