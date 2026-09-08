/// مهامي (§48) — تجميع قدرات المستخدم القائمة: مهامه، اعتماداته، إشعاراته،
/// رسائله — عبر واجهات فعلية لا منطق أعمال مكرر.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_repository.dart';
import '../shell/app_shell.dart';

class MyWorkScreen extends StatefulWidget {
  const MyWorkScreen({super.key});

  @override
  State<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends State<MyWorkScreen> {
  HomeSnapshot? _snapshot;
  int _dmUnread = 0;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final c = AppScope.of(context);
    try {
      final snap = await c.home.fetch();
      var dmUnread = 0;
      try {
        dmUnread = (await c.dm.threads()).unreadTotal;
      } on Object {
        // الرسائل ثانوية هنا — فشلها لا يسقط الشاشة.
      }
      if (mounted) {
        setState(() {
          _snapshot = snap;
          _dmUnread = dmUnread;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.myWorkTitle),
        actions: shellHeaderActions(context),
      ),
      body: AsyncView<HomeSnapshot>(
        loading: _loading,
        error: _error,
        value: _snapshot,
        onRetry: _load,
        builder: (context, snap) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EntryTile(
                icon: Icons.approval_outlined,
                title: l.myWorkApprovals,
                count: snap.approvalsCount,
                onTap: () => context.push('/approvals'),
              ),
              _EntryTile(
                icon: Icons.notifications_outlined,
                title: l.myWorkNotifications,
                count: snap.unreadNotifications,
                onTap: () => context.push('/notifications'),
              ),
              _EntryTile(
                icon: Icons.chat_bubble_outline,
                title: l.myWorkMessages,
                count: _dmUnread,
                onTap: () => context.push('/messages'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  '${l.myWorkTasks} (${snap.myWorkCount})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (snap.myWork.isEmpty)
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyView(),
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: snap.myWork
                        .map(
                          (i) => ListTile(
                            title: Text(
                              i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                if (i.status != null) i.status!,
                                if (i.due != null) i.due!,
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(i.target.routePath),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) Badge(label: Text('$count')),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    ),
  );
}
