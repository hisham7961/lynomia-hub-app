/// الموجّه (§15) — go_router: إعادة توجيه مصادقة، روابط عميقة `/m/*` و`/app/*`،
/// شاشة تحديث حاجبة، وقشرتان بحسب نمط الحساب الخادمي (§10 §12):
/// الداخلي خمس وجهات، والعميل قشرة بوابته — ولا يعبر أحدهما لقشرة الآخر.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/activation/activation_screen.dart';
import '../../features/approvals/approvals_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/launch/launch_gate_screen.dart';
import '../../features/members/client_members_screen.dart';
import '../../features/messages/messages_screens.dart';
import '../../features/modules/module_list_screen.dart';
import '../../features/my_work/my_work_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/portal/client_home_screen.dart';
import '../../features/portal/client_shell.dart';
import '../../features/portal/portal_screens.dart';
import '../../features/profile/account_screen.dart';
import '../../features/profile/diagnostics_screen.dart';
import '../../features/profile/sessions_screen.dart';
import '../../features/records/record_form_screen.dart';
import '../../features/records/record_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/ask/ask_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/workspaces/domains_screen.dart';
import '../bootstrap/launch_controller.dart';
import '../di/app_scope.dart';

GoRouter buildRouter(AppContainer c) => GoRouter(
  initialLocation: '/launch',
  refreshListenable: Listenable.merge([c.launch, c.session, c.account]),
  redirect: (context, state) {
    final path = state.uri.path;
    final launchState = c.launch.state;

    // روابط الويب العالمية `/app/...` تُطوى على نظيرتها المحلية (§76).
    if (path.startsWith('/app/')) {
      return path.startsWith('/app/activate/')
          ? path.replaceFirst('/app/', '/')
          : path.replaceFirst('/app/', '/m/');
    }

    // تفعيل الحساب (§13) نقطة عامة تسبق الدخول — تمرّ بأي حالة إقلاع.
    if (path.startsWith('/activate/')) return null;

    final atGate = path == '/launch';
    final atLogin = path == '/login';
    final isClient = c.account.isClient;
    final atPortal = path == '/portal' || path.startsWith('/portal/');
    // الإشعارات مشتركة بين القشرتين (مسموحة لحساب العميل خادمياً).
    final shared = path == '/notifications';

    return switch (launchState) {
      LaunchReady() when atGate || atLogin => isClient ? '/portal' : '/home',
      // عزل القشرتين (§12): العميل لا يرى وجهة داخلية والداخلي لا يرى
      // البوابة — عرضٌ متسق مع الحرس الخادمي (MobilePortalGuard) لا بديلاً عنه.
      LaunchReady() when isClient && !atPortal && !shared => '/portal',
      LaunchReady() when !isClient && atPortal => '/home',
      LaunchReady() => null,
      LaunchLoggedOut() when !atLogin => '/login',
      LaunchLoggedOut() => null,
      _ when !atGate => '/launch',
      _ => null,
    };
  },
  routes: [
    GoRoute(
      path: '/launch',
      builder: (context, state) => const LaunchGateScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(
        initialEmail: state.uri.queryParameters['email'],
        justActivated: state.uri.queryParameters['activated'] == '1',
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mywork',
              builder: (context, state) => const MyWorkScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/domains',
              builder: (context, state) => const DomainsScreen(),
              routes: [
                GoRoute(
                  path: ':domainKey',
                  builder: (context, state) => DomainDetailScreen(
                    domainKey: state.pathParameters['domainKey']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountScreen(),
              routes: [
                GoRoute(
                  path: 'sessions',
                  builder: (context, state) => const SessionsScreen(),
                ),
                GoRoute(
                  path: 'diagnostics',
                  builder: (context, state) => const DiagnosticsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // قشرة العميل (§12) — بيت البوابة ووجهاتها حصراً، لا وجهة داخلية.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ClientShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portal',
              builder: (context, state) => const ClientHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portal/projects',
              builder: (context, state) => const PortalProjectsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      PortalProjectScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portal/invoices',
              builder: (context, state) => const PortalInvoicesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      PortalInvoiceScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portal/conversations',
              builder: (context, state) => const PortalConversationsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      PortalConversationScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portal/account',
              builder: (context, state) => const AccountScreen(),
              routes: [
                GoRoute(
                  path: 'sessions',
                  builder: (context, state) => const SessionsScreen(),
                ),
                GoRoute(
                  path: 'diagnostics',
                  builder: (context, state) => const DiagnosticsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // وجهتا بوابة تُدفعان من البيت (خارج الشريط السفلي).
    GoRoute(
      path: '/portal/engagements',
      builder: (context, state) => const PortalEngagementsScreen(),
    ),
    GoRoute(
      path: '/portal/documents',
      builder: (context, state) => const PortalDocumentsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              PortalDocumentScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
    // تفعيل حساب العميل (§13) — رابط عميق عام يسبق الدخول.
    GoRoute(
      path: '/activate/:token',
      builder: (context, state) =>
          ActivationScreen(token: state.pathParameters['token']!),
    ),
    // إدارة أعضاء العميل (§15) — للمدير الداخلي من سجل العميل.
    GoRoute(
      path: '/clients/:id/members',
      builder: (context, state) => ClientMembersScreen(
        clientId: state.pathParameters['id']!,
        clientName: state.uri.queryParameters['name'],
      ),
    ),
    // الوجهات المدفوعة بالخادم — قائمة وحدة عامة وسجل عام (§19 §76).
    GoRoute(
      path: '/m/:module',
      builder: (context, state) =>
          ModuleListScreen(module: state.pathParameters['module']!),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) =>
              RecordFormScreen(module: state.pathParameters['module']!),
        ),
        // الرابط العميق القانوني `/m/{module}/{id}[/{action}]`.
        GoRoute(
          path: ':id',
          redirect: (context, state) =>
              '/r/${state.pathParameters['module']}/${state.pathParameters['id']}',
        ),
        GoRoute(
          path: ':id/:action',
          redirect: (context, state) =>
              '/r/${state.pathParameters['module']}/${state.pathParameters['id']}',
        ),
      ],
    ),
    GoRoute(
      path: '/r/:module/:id',
      builder: (context, state) => RecordScreen(
        module: state.pathParameters['module']!,
        id: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => RecordFormScreen(
            module: state.pathParameters['module']!,
            recordId: state.pathParameters['id'],
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const DmThreadsScreen(),
      routes: [
        GoRoute(
          path: ':userId',
          builder: (context, state) => DmChatScreen(
            otherUserId: state.pathParameters['userId']!,
            otherName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/approvals',
      builder: (context, state) => const ApprovalsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              ApprovalDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/ask',
      builder: (context, state) => const AskScreen(),
      routes: [
        GoRoute(
          path: 'threads',
          builder: (context, state) => const AskThreadsScreen(),
        ),
        GoRoute(
          path: 't/:id',
          builder: (context, state) =>
              AskScreen(threadId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
  ],
);
