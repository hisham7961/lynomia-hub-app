/// الموجّه (§15) — go_router: إعادة توجيه مصادقة، روابط عميقة `/m/*` و`/app/*`،
/// شاشة تحديث حاجبة، وخمس وجهات سفلية بملاحة متداخلة.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/approvals/approvals_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/launch/launch_gate_screen.dart';
import '../../features/messages/messages_screens.dart';
import '../../features/modules/module_list_screen.dart';
import '../../features/my_work/my_work_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/account_screen.dart';
import '../../features/profile/diagnostics_screen.dart';
import '../../features/profile/sessions_screen.dart';
import '../../features/records/record_form_screen.dart';
import '../../features/records/record_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/workspaces/domains_screen.dart';
import '../bootstrap/launch_controller.dart';
import '../di/app_scope.dart';

GoRouter buildRouter(AppContainer c) => GoRouter(
  initialLocation: '/launch',
  refreshListenable: Listenable.merge([c.launch, c.session]),
  redirect: (context, state) {
    final path = state.uri.path;
    final launchState = c.launch.state;

    // روابط الويب العالمية `/app/...` تُطوى على نظيرتها `/m/...` (§76).
    if (path.startsWith('/app/')) {
      return path.replaceFirst('/app/', '/m/');
    }

    final atGate = path == '/launch';
    final atLogin = path == '/login';

    return switch (launchState) {
      LaunchReady() when atGate || atLogin => '/home',
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
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
  ],
);
