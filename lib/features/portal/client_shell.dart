/// قشرة العميل (§12) — غلاف بوابة العميل: بيت مستقل ووجهات البوابة حصراً.
///
/// لا وجهة داخلية هنا أصلاً (لا مهام، لا مجالات، لا اعتمادات): القشرة تُختار
/// من `account_type` الخادمي، والعزل الحقيقي خادمي (`MobilePortalGuard`) —
/// فحتى نداء يدوي لمسار داخلي يُصدّ 404 من الخادم لا من إخفاء الأزرار.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../l10n/app_localizations.dart';

class ClientShell extends StatelessWidget {
  const ClientShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final connectivity = AppScope.of(context).connectivity;

    return Scaffold(
      body: Column(
        children: [
          ListenableBuilder(
            listenable: connectivity,
            builder: (context, _) => connectivity.online
                ? const SizedBox.shrink()
                : Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              l.stateOffline,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.rocket_launch_outlined),
            selectedIcon: const Icon(Icons.rocket_launch),
            label: l.portalProjects,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l.portalInvoices,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum),
            label: l.portalConversations,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l.navAccount,
          ),
        ],
      ),
    );
  }
}

/// أيقونات رأس بوابة العميل — إشعارات فقط (مسموحة لحساب العميل خادمياً).
List<Widget> clientHeaderActions(BuildContext context) {
  final account = AppScope.of(context).account;
  return [
    ListenableBuilder(
      listenable: account,
      builder: (context, _) => IconButton(
        tooltip: AppLocalizations.of(context)!.notificationsTitle,
        icon: Badge(
          isLabelVisible: account.unreadNotifications > 0,
          label: Text('${account.unreadNotifications}'),
          child: const Icon(Icons.notifications_outlined),
        ),
        onPressed: () => context.push('/notifications'),
      ),
    ),
  ];
}
