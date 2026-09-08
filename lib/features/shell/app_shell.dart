/// الغلاف المصادق (§16 §129) — خمس وجهات سفلية + وصول سريع للإشعارات والرسائل.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final account = AppScope.of(context).account;
    final connectivity = AppScope.of(context).connectivity;

    return Scaffold(
      body: Column(
        children: [
          // شريط اتصال هادئ (§84) — يظهر فقط دون اتصال.
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
      bottomNavigationBar: ListenableBuilder(
        listenable: account,
        builder: (context, _) => NavigationBar(
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
              icon: Badge(
                isLabelVisible: account.unreadNotifications > 0,
                label: Text('${account.unreadNotifications}'),
                child: const Icon(Icons.task_alt_outlined),
              ),
              selectedIcon: const Icon(Icons.task_alt),
              label: l.navMyWork,
            ),
            NavigationDestination(
              icon: const Icon(Icons.workspaces_outlined),
              selectedIcon: const Icon(Icons.workspaces),
              label: l.navDomains,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search),
              label: l.navSearch,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l.navAccount,
            ),
          ],
        ),
      ),
    );
  }
}

/// أيقونات رأس مشتركة: إشعارات + رسائل + ماسح (وصول سريع §16).
List<Widget> shellHeaderActions(BuildContext context) {
  final account = AppScope.of(context).account;
  return [
    IconButton(
      tooltip: AppLocalizations.of(context)!.scannerTitle,
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: () => context.push('/scanner'),
    ),
    IconButton(
      tooltip: AppLocalizations.of(context)!.messagesTitle,
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () => context.push('/messages'),
    ),
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
