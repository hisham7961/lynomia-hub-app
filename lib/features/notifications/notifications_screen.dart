/// الإشعارات (§51) — مؤشر keyset، غير المقروء، قراءة/قراءة الكل، وملاحة
/// بالوجهة القانونية `{module,id}` — لا اسم شاشة صلب.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scroll = ScrollController();
  final List<HubNotificationItem> _items = [];
  String? _cursor;
  bool _hasMore = false;
  bool _unreadOnly = false;
  int _unread = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeMore);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _cursor = null;
      });
    }
    try {
      final page = await AppScope.of(context).notifications
          .list(cursor: reset ? null : _cursor, unreadOnly: _unreadOnly);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _unread = page.unread;
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _maybeMore() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.extentAfter > 400) return;
    setState(() => _loadingMore = true);
    _load(reset: false);
  }

  Future<void> _open(HubNotificationItem n) async {
    final c = AppScope.of(context);
    // النقر يختم القراءة ويعيد الوجهة (§51)؛ null ⇒ البقاء في القائمة.
    final target = await c.notifications.markRead(n.id);
    await c.account.loadBootstrap(force: true).catchError((_) {});
    if (!mounted) return;
    setState(() {
      final i = _items.indexWhere((x) => x.id == n.id);
      if (i >= 0) {
        _items[i] = HubNotificationItem(
          id: n.id,
          kind: n.kind,
          text: n.text,
          read: true,
          target: n.target,
          createdAt: n.createdAt,
        );
        if (_unread > 0) _unread -= 1;
      }
    });
    if (target != null) context.push(target.routePath);
  }

  Future<void> _markAll() async {
    await AppScope.of(context).notifications.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _unread > 0
              ? '${l.notificationsTitle} (${l.unreadBadge(_unread)})'
              : l.notificationsTitle,
        ),
        actions: [
          IconButton(
            tooltip: l.notificationsUnreadOnly,
            icon: Icon(
              _unreadOnly
                  ? Icons.mark_email_unread
                  : Icons.mark_email_unread_outlined,
            ),
            onPressed: () {
              setState(() => _unreadOnly = !_unreadOnly);
              _load();
            },
          ),
          IconButton(
            tooltip: l.notificationsMarkAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: _unread == 0 ? null : _markAll,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (_error != null && _items.isEmpty) {
            return ErrorView(error: _error!, onRetry: _load);
          }
          if (_items.isEmpty) {
            return EmptyView(
              message: l.notificationsEmpty,
              icon: Icons.notifications_none,
            );
          }
          return RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView.builder(
              controller: _scroll,
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final n = _items[i];
                return ListTile(
                  leading: Icon(
                    n.read
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: n.read
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    n.text ?? n.kind,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: n.read
                        ? null
                        : const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: n.createdAt == null
                      ? null
                      : Text(
                          MaterialLocalizations.of(context)
                              .formatShortDate(n.createdAt!.toLocal()),
                        ),
                  trailing: n.target == null
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: () => _open(n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
