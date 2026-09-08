/// حاوية التبعيات (§13) — توصيل واحد صريح، كل شيء قابل للحقن والاستبدال باختبار.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/connectivity_monitor.dart';
import '../../core/api/view_context.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/installation_id.dart';
import '../../core/auth/session_manager.dart';
import '../../core/auth/token_store.dart';
import '../../core/config/app_env.dart';
import '../../core/push/push_registrar.dart';
import '../../core/security/biometric_gate.dart';
import '../../core/security/redacting_logger.dart';
import '../../core/storage/encrypted_cache.dart';
import '../../core/storage/prefs_store.dart';
import '../../core/storage/secure_store.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/telemetry/app_info.dart';
import '../../features/approvals/approval_repository.dart';
import '../../features/comments/comment_repository.dart';
import '../../features/files/file_repository.dart';
import '../../features/home/home_repository.dart';
import '../../features/launch/app_config_repository.dart';
import '../../features/activation/activation_repository.dart';
import '../../features/launch/bootstrap_repository.dart';
import '../../features/members/client_members_repository.dart';
import '../../features/messages/dm_repository.dart';
import '../../features/modules/module_repository.dart';
import '../../features/notifications/notification_repository.dart';
import '../../features/portal/portal_repository.dart';
import '../../features/profile/prefs_repository.dart';
import '../../features/scanner/identity_repository.dart';
import '../../features/search/search_repository.dart';
import '../../features/tracking/tracking_repository.dart';
import '../bootstrap/account_state.dart';
import '../bootstrap/launch_controller.dart';

class AppContainer {
  AppContainer._({
    required this.env,
    required this.log,
    required this.secureStore,
    required this.prefs,
    required this.cache,
    required this.installation,
    required this.session,
    required this.viewContext,
    required this.api,
    required this.connectivity,
    required this.biometricGate,
    required this.biometricPref,
  }) {
    auth = AuthRepository(api: api, installation: installation);
    // كسر الدور: التدوير ينفذه AuthRepository عبر العميل نفسه بلا اعتراض مصادقة.
    session.refreshExecutor = auth.refreshCall;

    appConfig = AppConfigRepository(api);
    bootstrap = BootstrapRepository(api);
    modules = ModuleRepository(api);
    home = HomeRepository(api);
    search = SearchRepository(api);
    approvals = ApprovalRepository(api);
    notifications = NotificationRepository(api);
    dm = DmRepository(api);
    comments = CommentRepository(api);
    portal = PortalRepository(api);
    activation = ActivationRepository(api);
    clientMembers = ClientMembersRepository(api);
    files = FileRepository(api);
    identity = IdentityRepository(api);
    tracking = TrackingRepository(api);
    serverPrefs = PrefsRepository(api);
    push = PushRegistrar(api: api, provider: const NotConfiguredPushProvider());
    account = AccountState(
      bootstrapRepo: bootstrap,
      viewContext: viewContext,
      cache: cache,
    );
    sync = SyncEngine(
      api: api,
      cache: cache,
      viewContext: viewContext,
      userIdOf: () => account.user?.id ?? '-',
    );
    launch = LaunchController(
      env: env,
      appConfigRepo: appConfig,
      bootstrapRepo: bootstrap,
      session: session,
      account: account,
      viewContext: viewContext,
      biometricPref: biometricPref,
      biometricGate: biometricGate,
    );
  }

  /// التركيب الحقيقي (منصة) — الاختبارات تبني البدائل يدوياً.
  static Future<AppContainer> boot({AppEnv? env}) async {
    final resolvedEnv = env ?? AppEnv.fromDefines();
    final log = RedactingLogger();
    final secureStore = PlatformSecureStore();
    final supportDir = await getApplicationSupportDirectory();
    final prefs = PrefsStore(Directory(supportDir.path));
    final cache = EncryptedJsonCache(
      rootDir: Directory(supportDir.path),
      keyStore: secureStore,
    );
    final installation = InstallationId(secureStore);
    final session = SessionManager(
      tokenStore: SessionTokenStore(secureStore),
      log: log,
    );
    final viewContext = ViewContext();
    final api = ApiClient(
      env: resolvedEnv,
      httpClient: http.Client(),
      session: session,
      viewContext: viewContext,
      installation: installation,
      log: log,
    );
    final container = AppContainer._(
      env: resolvedEnv,
      log: log,
      secureStore: secureStore,
      prefs: prefs,
      cache: cache,
      installation: installation,
      session: session,
      viewContext: viewContext,
      api: api,
      connectivity: ConnectivityMonitor(),
      biometricGate: LocalAuthBiometricGate(),
      biometricPref: BiometricPreference(prefs),
    );
    try {
      api.appInfo = await AppInfo.load();
    } on Object {
      // بيئة اختبار/تشغيل بلا قناة منصة — الترويسات التليمترية تغيب بصدق.
    }
    return container;
  }

  /// تركيب مخصص للاختبارات — كل شيء محقون.
  factory AppContainer.custom({
    required AppEnv env,
    required http.Client transport,
    required SecureStore secureStore,
    required Directory rootDir,
    AppInfo? appInfo,
  }) {
    final log = RedactingLogger();
    final prefs = PrefsStore(rootDir);
    final cache = EncryptedJsonCache(rootDir: rootDir, keyStore: secureStore);
    final installation = InstallationId(secureStore);
    final session = SessionManager(
      tokenStore: SessionTokenStore(secureStore),
      log: log,
    );
    final viewContext = ViewContext();
    final api = ApiClient(
      env: env,
      httpClient: transport,
      session: session,
      viewContext: viewContext,
      installation: installation,
      clientInfo: appInfo,
      log: log,
      sleep: (_) async {},
    );
    return AppContainer._(
      env: env,
      log: log,
      secureStore: secureStore,
      prefs: prefs,
      cache: cache,
      installation: installation,
      session: session,
      viewContext: viewContext,
      api: api,
      connectivity: ConnectivityMonitor(source: const Stream.empty()),
      biometricGate: _NoBiometrics(),
      biometricPref: BiometricPreference(prefs),
    );
  }

  final AppEnv env;
  final RedactingLogger log;
  final SecureStore secureStore;
  final PrefsStore prefs;
  final EncryptedJsonCache cache;
  final InstallationId installation;
  final SessionManager session;
  final ViewContext viewContext;
  final ApiClient api;
  final ConnectivityMonitor connectivity;
  final BiometricGate biometricGate;
  final BiometricPreference biometricPref;

  late final AuthRepository auth;
  late final AppConfigRepository appConfig;
  late final BootstrapRepository bootstrap;
  late final ModuleRepository modules;
  late final HomeRepository home;
  late final SearchRepository search;
  late final ApprovalRepository approvals;
  late final NotificationRepository notifications;
  late final DmRepository dm;
  late final CommentRepository comments;
  late final PortalRepository portal;
  late final ActivationRepository activation;
  late final ClientMembersRepository clientMembers;
  late final FileRepository files;
  late final IdentityRepository identity;
  late final TrackingRepository tracking;
  late final PrefsRepository serverPrefs;
  late final PushRegistrar push;
  late final AccountState account;
  late final SyncEngine sync;
  late final LaunchController launch;

  /// خروج كامل (§39): خادمياً ثم محلياً — دفع، رموز، خبيئة، سياق.
  Future<void> signOut({bool everywhere = false}) async {
    await push.unregisterQuietly();
    try {
      everywhere ? await auth.logoutAll() : await auth.logout();
    } on Object {
      // الخروج المحلي لا يُحجب بفشل شبكة — الخادم يبطل بالمهلة.
    }
    await account.clearOnLogout();
    await session.end(SessionEndReason.loggedOut);
    launch.onSignedOut();
  }
}

class _NoBiometrics implements BiometricGate {
  @override
  Future<bool> get available async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

/// تمرير الحاوية في الشجرة.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.container, required super.child});

  final AppContainer container;

  /// الحاوية ثابتة لعمر التطبيق — قراءة بلا تسجيل تبعية، فتصح من initState.
  static AppContainer of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.container;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      container != oldWidget.container;
}
