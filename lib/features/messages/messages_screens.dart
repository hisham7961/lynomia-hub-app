/// الرسائل (§52 §106) — مركز التواصل على الجوال:
///  • المباشرة: الخيوط بحضور الطرف (إن كانت القدرة مفعّلة خادمياً).
///  • القنوات: قنواتي وغرفي ومجموعاتي من `conversations`.
///  • المحادثة: إرسال idempotent وختم قراءة، واستطلاع «منذ» ومؤشر كتابة لا
///    يعملان إلا والشاشة ظاهرة، وتفاعلات يحسمها الخادم.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../core/ui/visible_poller.dart';
import '../../l10n/app_localizations.dart';
import '../comments/comments_panel.dart';
import '../comments/reactions.dart';
import 'collab_repository.dart';
import 'dm_repository.dart';
import 'live_events.dart';
import 'save_action.dart';

/// فاصل الاستطلاع في المحادثة المفتوحة.
const kLivePollInterval = Duration(seconds: 4);

bool _capabilityOff(Object e) =>
    e is ApiException && e.code == ApiErrorCode.resourceNotFound;

String presenceLabel(AppLocalizations l, PresenceState p) => switch (p) {
  PresenceState.online => l.presenceOnline,
  PresenceState.recent => l.presenceRecent,
  PresenceState.away => l.presenceAway,
  PresenceState.offline => l.presenceOffline,
};

Color presenceColor(BuildContext context, PresenceState p) => switch (p) {
  PresenceState.online => Colors.green,
  PresenceState.recent => Colors.lightGreen,
  PresenceState.away => Colors.amber,
  PresenceState.offline => Theme.of(context).colorScheme.outline,
};

/// نقطة حضور صغيرة بوصفٍ دلالي.
class PresenceDot extends StatelessWidget {
  const PresenceDot({super.key, required this.state});

  final PresenceState state;

  @override
  Widget build(BuildContext context) {
    final label = presenceLabel(AppLocalizations.of(context)!, state);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: presenceColor(context, state),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// نص «فلان يكتب…» من أسماء يعيدها الخادم.
String typingText(AppLocalizations l, List<String> names) => names.length == 1
    ? l.typingOne(names.single)
    : l.typingMany(names.join(l.listSeparator));

class DmThreadsScreen extends StatelessWidget {
  const DmThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.messagesTitle),
          actions: [
            IconButton(
              key: const Key('open-saved'),
              tooltip: l.savedTitle,
              icon: const Icon(Icons.bookmark_outline),
              onPressed: () => context.push('/saved'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l.messagesTabDirect),
              Tab(text: l.messagesTabChannels),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_DirectThreadsTab(), ConversationsTab()],
        ),
      ),
    );
  }
}

class _DirectThreadsTab extends StatefulWidget {
  const _DirectThreadsTab();

  @override
  State<_DirectThreadsTab> createState() => _DirectThreadsTabState();
}

class _DirectThreadsTabState extends State<_DirectThreadsTab> {
  List<DmThread>? _threads;
  Map<String, PresenceState> _presence = const {};
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await c.dm.threads();
      if (mounted) setState(() => _threads = res.threads);
      // الحضور ثانوي: علم الخادم `collab_presence=false` ⇒ لا نداء؛ والقدرة
      // المطفأة (٤٠٤ من خادمٍ بلا العلم) أو أي فشل ⇒ بلا نقاط، لا خطأ.
      if (!c.account.capabilityAllowed('collab_presence')) {
        if (mounted) setState(() => _presence = const {});
        return;
      }
      try {
        final p = await c.collab.presence(res.threads.map((t) => t.userId));
        if (mounted) setState(() => _presence = p);
      } on Object {
        if (mounted) setState(() => _presence = const {});
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
    return AsyncView<List<DmThread>>(
      loading: _loading,
      error: _error,
      value: _threads,
      onRetry: _load,
      emptyWhen: (t) => t.isEmpty,
      emptyMessage: l.messagesEmpty,
      builder: (context, threads) => RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: threads.length,
          itemBuilder: (context, i) {
            final t = threads[i];
            final p = _presence[t.userId];
            return ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    child: Text(
                      t.userName.isEmpty
                          ? l.unknownInitial
                          : t.userName.characters.first,
                    ),
                  ),
                  if (p != null)
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: PresenceDot(
                        key: Key('presence-${t.userId}'),
                        state: p,
                      ),
                    ),
                ],
              ),
              title: Text(t.userName),
              subtitle: t.lastExcerpt == null
                  ? null
                  : Text(
                      '${t.lastMine ? '↩ ' : ''}${t.lastExcerpt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: t.unread > 0 ? Badge(label: Text('${t.unread}')) : null,
              onTap: () async {
                await context.push(
                  '/messages/${t.userId}?name=${Uri.encodeComponent(t.userName)}',
                );
                _load();
              },
            );
          },
        ),
      ),
    );
  }
}

/// تبويب القنوات/الغرف/المجموعات (`GET conversations`).
class ConversationsTab extends StatefulWidget {
  const ConversationsTab({super.key});

  @override
  State<ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends State<ConversationsTab> {
  ConversationsRail? _rail;
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
    try {
      final rail = await AppScope.of(context).collab.conversations();
      if (mounted) setState(() => _rail = rail);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AsyncView<ConversationsRail>(
      loading: _loading,
      error: _error,
      value: _rail,
      onRetry: _load,
      emptyWhen: (r) => !r.hasContainers,
      emptyMessage: l.conversationsEmpty,
      builder: (context, rail) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            for (final (title, items, icon) in [
              (l.conversationsChannels, rail.channels, Icons.tag),
              (l.conversationsRooms, rail.rooms, Icons.meeting_room_outlined),
              (l.conversationsGroups, rail.groups, Icons.group_outlined),
            ])
              if (items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final c in items)
                  ListTile(
                    key: Key('conv-${c.id}'),
                    leading: Icon(icon),
                    title: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.favorite)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(end: 8),
                            child: Icon(Icons.star, size: 16),
                          ),
                        if (c.unread > 0) Badge(label: Text('${c.unread}')),
                      ],
                    ),
                    onTap: () async {
                      await context.push(
                        '/conversations/${c.id}?title=${Uri.encodeComponent(c.title)}',
                      );
                      _load();
                    },
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

/// قناة/غرفة/مجموعة: تعليقات الحاوية (`module=channel`) باستطلاع «منذ» وكتابة.
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: CommentsPanel(
      module: 'channel',
      recordId: conversationId,
      liveConversationId: conversationId,
    ),
  );
}

class DmChatScreen extends StatefulWidget {
  const DmChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherName,
  });

  final String otherUserId;
  final String otherName;

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen> {
  final _input = TextEditingController();
  List<DmMessage>? _messages;
  Object? _error;
  bool _loading = true;
  bool _sending = false;
  String _fetchedName = '';

  List<String> _typing = const [];
  PresenceState? _presence;
  bool _presenceOff = false;
  int _ticks = 0;

  late final SinceFeed<DmLiveEvent> _feed;
  late final VisiblePoller _poller;
  TypingThrottle? _typingPing;

  String get _name =>
      widget.otherName.isNotEmpty ? widget.otherName : _fetchedName;

  @override
  void initState() {
    super.initState();
    final c = AppScope.of(context);
    _feed = SinceFeed(
      (cursor) => c.dm.since(widget.otherUserId, cursor: cursor),
    );
    _poller = VisiblePoller(
      interval: kLivePollInterval,
      onTick: _poll,
      isVisible: () => routeIsCurrent(context),
    );
    // أعلام الخادم: `false` صريح ⇒ لا نداء أصلاً؛ غيابها (خادمٌ أقدم) ⇒ يُجرَّب
    // والـ٤٠٤ يوقفه لبقية الجلسة.
    _presenceOff = !c.account.capabilityAllowed('collab_presence');
    if (c.account.capabilityAllowed('collab_typing')) {
      _typingPing = TypingThrottle(() async {
        try {
          await c.dm.typing(widget.otherUserId);
        } on Object catch (e) {
          if (_capabilityOff(e)) _typingPing?.disable();
        }
      });
    }
    _load();
  }

  @override
  void dispose() {
    _poller.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await c.dm.thread(widget.otherUserId);
      // ختم القراءة عند فتح الخيط (§52).
      c.dm.markRead(widget.otherUserId).catchError((_) => 0);
      // «منذ» يبدأ من مؤشر الذيل الخادمي (لا مشيَ صفحاتٍ من أول الخيط).
      final cursor = page.cursor;
      if (cursor != null && !_feed.caughtUp) _feed.seed(cursor);
      if (mounted) {
        setState(() {
          _messages = page.messages;
          _fetchedName = page.userName;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted || _messages == null) return;
    await _refreshPresence();
    await _poll();
    if (mounted) _poller.start();
  }

  Future<void> _refreshPresence() async {
    if (_presenceOff) return;
    try {
      final p = await AppScope.of(context).collab
          .presence([widget.otherUserId]);
      if (mounted) setState(() => _presence = p[widget.otherUserId]);
    } on Object catch (e) {
      if (_capabilityOff(e)) _presenceOff = true;
    }
  }

  Future<void> _poll() async {
    try {
      final batch = await _feed.pull(maxPages: 5);
      if (!mounted) return;
      setState(() {
        _merge(batch.events);
        _typing = batch.typing;
      });
    } on Object catch (e) {
      // لم يعد الخيط في متناولي (٤٠٤) ⇒ لا استطلاع بعده.
      if (_capabilityOff(e)) _poller.stop();
    }
    if (++_ticks % 15 == 0) await _refreshPresence();
  }

  /// دمج أحداث «منذ»: الجديد يُلحق بتفاعلاته، والمحذوف يُعلَّم. والأقدم من أحدث
  /// رسالة محمّلة يُتجاوز (يحدث فقط مع خادمٍ أقدم بلا مؤشر ذيل).
  void _merge(List<DmLiveEvent> events) {
    final list = [...?_messages];
    final index = {for (var i = 0; i < list.length; i++) list[i].id: i};
    DateTime? newest;
    for (final m in list) {
      final t = m.createdAt;
      if (t != null && (newest == null || t.isAfter(newest))) newest = t;
    }
    for (final e in events) {
      final at = index[e.id];
      if (at != null) {
        if (e.deleted && !list[at].deleted) {
          list[at] = list[at].copyWith(deleted: true);
        }
        continue;
      }
      if (newest != null &&
          e.createdAt != null &&
          e.createdAt!.isBefore(newest)) {
        continue;
      }
      index[e.id] = list.length;
      list.add(
        DmMessage(
          id: e.id,
          mine: e.mine,
          body: e.body,
          deleted: e.deleted,
          createdAt: e.createdAt,
          reactions: e.reactions,
        ),
      );
    }
    _messages = list;
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await AppScope.of(context).dm.send(widget.otherUserId, body);
      if (!mounted) return;
      _input.clear();
      setState(
        () => _merge([
          DmLiveEvent(
            type: kEvMessageCreated,
            id: msg.id,
            mine: true,
            body: msg.body,
            createdAt: msg.createdAt,
          ),
        ]),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// ضغطٌ مطوّل: ورقة الرموز + «احفظ الرسالة».
  Future<void> _actions(DmMessage m) async {
    final l = AppLocalizations.of(context)!;
    const save = '__save__';
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final e in kReactionEmojis)
                    InkWell(
                      key: Key('react-$e'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.pop(ctx, e),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                ],
              ),
              ListTile(
                key: const Key('dm-save'),
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(l.savedAction),
                onTap: () => Navigator.pop(ctx, save),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == save) {
      await saveWithUndo(context, targetType: 'dm', targetId: m.id);
    } else {
      await _react(m, choice);
    }
  }

  Future<void> _react(DmMessage m, String emoji) async {
    try {
      final t = await AppScope.of(context).dm.react(m.id, emoji);
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final x in _messages ?? const <DmMessage>[])
            x.id == t.targetId
                ? x.copyWith(reactions: applyToggle(x.reactions, t))
                : x,
        ];
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name),
            if (_typing.isNotEmpty)
              Text(
                typingText(l, _typing),
                key: const Key('dm-typing'),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (_presence != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PresenceDot(state: _presence!),
                  const SizedBox(width: 4),
                  Text(
                    presenceLabel(l, _presence!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<List<DmMessage>>(
              loading: _loading,
              error: _error,
              value: _messages,
              onRetry: _load,
              emptyWhen: (m) => m.isEmpty,
              emptyMessage: l.messagesEmpty,
              builder: (context, messages) => ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[messages.length - 1 - i];
                  return _Bubble(
                    message: m,
                    onLongPress: m.deleted ? null : () => _actions(m),
                    onToggle: (emoji) => _react(m, emoji),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('dm-input'),
                      controller: _input,
                      decoration: InputDecoration(
                        hintText: l.messagesHint,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (_) => _typingPing?.onInput(),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                    tooltip: l.actionSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.onLongPress,
    required this.onToggle,
  });

  final DmMessage message;
  final VoidCallback? onLongPress;
  final void Function(String emoji) onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final m = message;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: m.mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: m.mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: Key('dm-msg-${m.id}'),
            onLongPress: onLongPress,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: m.mine
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.deleted ? l.messageDeleted : (m.body ?? ''),
                    style: m.deleted
                        ? TextStyle(
                            fontStyle: FontStyle.italic,
                            color: scheme.outline,
                          )
                        : null,
                  ),
                  if (m.hasAttachment)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.attach_file, size: 14),
                    ),
                ],
              ),
            ),
          ),
          if (m.reactions.isNotEmpty && !m.deleted)
            Wrap(
              spacing: 4,
              children: [
                for (final r in m.reactions)
                  ReactionChip(
                    emoji: r.emoji,
                    count: r.count,
                    mine: r.mine,
                    onTap: () => onToggle(r.emoji),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// المحفوظات (`GET saved`) — مُعادةُ التخويل عند كل فتح.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<SavedItem>? _items;
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
    try {
      final items = await AppScope.of(context).collab.saved();
      if (mounted) setState(() => _items = items);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(SavedItem s) async {
    final l = AppLocalizations.of(context)!;
    try {
      await AppScope.of(context).collab.unsave(s.id);
      if (!mounted) return;
      setState(() => _items = [...?_items]..removeWhere((x) => x.id == s.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.savedRemoved)));
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.savedTitle)),
      body: AsyncView<List<SavedItem>>(
        loading: _loading,
        error: _error,
        value: _items,
        onRetry: _load,
        emptyWhen: (i) => i.isEmpty,
        emptyMessage: l.savedEmpty,
        builder: (context, items) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = items[i];
              final outline = Theme.of(context).colorScheme.outline;
              final meta = [
                s.type == 'dm' ? l.savedTypeDm : l.savedTypeComment,
                if (s.available && s.author != null) s.author!,
                if (s.savedAt != null)
                  l.savedAt(formatShortDate(s.savedAt!, locale)),
              ].join(' · ');
              return ListTile(
                key: Key('saved-${s.id}'),
                leading: Icon(
                  s.type == 'dm'
                      ? Icons.chat_bubble_outline
                      : Icons.comment_outlined,
                  color: s.available ? null : outline,
                ),
                title: Text(
                  s.available ? (s.title ?? '') : l.savedUnavailable,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: s.available
                      ? null
                      : TextStyle(fontStyle: FontStyle.italic, color: outline),
                ),
                subtitle: Text(
                  [
                    meta,
                    if (s.note != null && s.note!.isNotEmpty) s.note!,
                  ].join('\n'),
                ),
                isThreeLine: s.note != null && s.note!.isNotEmpty,
                // غير المتاح يبقى كي يُزيله صاحبه — بلا فتح.
                trailing: IconButton(
                  key: Key('unsave-${s.id}'),
                  tooltip: l.savedRemove,
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  onPressed: () => _remove(s),
                ),
                // الوجهة من الخادم وحده (`target`)؛ لا شاشة لها ⇒ لا نقر.
                onTap: switch (s.target?.routePath) {
                  final String path => () async {
                    await context.push(path);
                    if (mounted) _load();
                  },
                  _ => null,
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
