/// إدارة القنوات والمجموعات وبحث الرسائل (المرحلة ٤.٢): الدليل والانضمام،
/// إنشاء قناة/مجموعة، شاشة الأعضاء (الأدوار/الإزالة/الإضافة لمن يدير)، وبحث
/// نصّ الرسائل. القدرات من ردود الخادم (`my_role`/`can_manage`) — والخادم يعيد
/// الفحص عند كل فعل.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../core/ui/feedback.dart';
import '../../l10n/app_localizations.dart';
import '../records/field_editors.dart';
import 'collab_repository.dart';

String visibilityLabel(AppLocalizations l, String v) => switch (v) {
  'private' => l.channelVisPrivate,
  'members' => l.channelVisMembers,
  'company' => l.channelVisCompany,
  'public' => l.channelVisPublic,
  _ => v,
};

String roleLabel(AppLocalizations l, String r) => switch (r) {
  ConversationRoles.owner => l.channelRoleOwner,
  ConversationRoles.moderator => l.channelRoleModerator,
  ConversationRoles.member => l.channelRoleMember,
  ConversationRoles.guest => l.channelRoleGuest,
  _ => r,
};

String notifyPrefLabel(AppLocalizations l, String p) => switch (p) {
  'all' => l.channelNotifyAll,
  'mentions' => l.channelNotifyMentions,
  'muted' => l.channelNotifyMuted,
  _ => p,
};

/// مسار شاشة الحاوية مع عنوانها ونوعها.
String conversationRoute(String id, String title, String kind) => Uri(
  path: '/conversations/$id',
  queryParameters: {'title': title, 'kind': kind},
).toString();

/// إنشاء قناة: الاسم والظهور — والخادم يجعلني مالكها.
Future<void> createChannelFlow(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final repo = AppScope.of(context).collab;
  final input = await showDialog<({String title, String? visibility})>(
    context: context,
    builder: (_) => const _NewChannelDialog(),
  );
  if (input == null || !context.mounted) return;
  try {
    final conv = await repo.createChannel(
      title: input.title,
      visibility: input.visibility,
      idempotencyKey: const Uuid().v4(),
    );
    if (!context.mounted) return;
    showSnack(context, l.channelCreated);
    await context.push(conversationRoute(conv.id, conv.title, conv.kind));
  } on Object catch (e) {
    if (context.mounted) showErrorSnack(context, e);
  }
}

class _NewChannelDialog extends StatefulWidget {
  const _NewChannelDialog();

  @override
  State<_NewChannelDialog> createState() => _NewChannelDialogState();
}

class _NewChannelDialogState extends State<_NewChannelDialog> {
  final _title = TextEditingController();
  String? _visibility;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.channelNew),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('channel-title'),
            controller: _title,
            autofocus: true,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l.channelName,
              errorText: _error,
            ),
          ),
          DropdownButtonFormField<String?>(
            initialValue: _visibility,
            decoration: InputDecoration(labelText: l.channelVisibility),
            items: [
              DropdownMenuItem(value: null, child: Text(l.channelVisDefault)),
              for (final v in const ['members', 'company', 'public', 'private'])
                DropdownMenuItem(value: v, child: Text(visibilityLabel(l, v))),
            ],
            onChanged: (v) => setState(() => _visibility = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          key: const Key('channel-create'),
          onPressed: () {
            final t = _title.text.trim();
            if (t.isEmpty) {
              setState(() => _error = l.fieldValueRequired);
              return;
            }
            Navigator.pop(context, (title: t, visibility: _visibility));
          },
          child: Text(l.actionCreate),
        ),
      ],
    );
  }
}

class ChannelDirectoryScreen extends StatefulWidget {
  const ChannelDirectoryScreen({super.key});

  @override
  State<ChannelDirectoryScreen> createState() => _ChannelDirectoryScreenState();
}

class _ChannelDirectoryScreenState extends State<ChannelDirectoryScreen> {
  List<DirectoryChannel>? _items;
  Object? _error;
  bool _loading = true;
  String? _joining;

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
      final d = await AppScope.of(context).collab.directory();
      if (mounted) setState(() => _items = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(DirectoryChannel ch) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _joining = ch.id);
    try {
      final res = await AppScope.of(context).collab.join(ch.id);
      if (!mounted) return;
      showSnack(context, res.joined ? l.channelJoined : l.channelAlreadyMember);
      await context.push(
        conversationRoute(
          res.conversation.id,
          res.conversation.title.isEmpty ? ch.title : res.conversation.title,
          res.conversation.kind,
        ),
      );
      if (mounted) _load();
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _joining = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.channelDirectory)),
      body: AsyncView<List<DirectoryChannel>>(
        loading: _loading,
        error: _error,
        value: _items,
        onRetry: _load,
        emptyWhen: (d) => d.isEmpty,
        emptyMessage: l.channelDirectoryEmpty,
        builder: (context, items) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final ch = items[i];
              return ListTile(
                key: Key('directory-${ch.id}'),
                leading: const Icon(Icons.tag),
                title: Text(ch.title),
                subtitle: Text(
                  '${visibilityLabel(l, ch.visibility)} · ${l.channelMembersCount(ch.members)}',
                ),
                trailing: _joining == ch.id
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton.tonal(
                        key: Key('join-${ch.id}'),
                        onPressed: _joining == null ? () => _join(ch) : null,
                        child: Text(l.channelJoin),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// مجموعة رسائل جديدة: المشاركون من جهات رسائلي المباشرة (أشخاصٌ أراسلهم) —
/// والخادم يتحقق أنهم داخليون ضمن نطاقي.
class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _title = TextEditingController();
  List<({String id, String name})>? _contacts;
  final Set<String> _picked = {};
  Object? _error;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await AppScope.of(context).dm.threads();
      if (mounted) {
        setState(
          () => _contacts = [
            for (final th in t.threads)
              if (th.userId.isNotEmpty) (id: th.userId, name: th.userName),
          ],
        );
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_picked.isEmpty || _creating) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _creating = true);
    try {
      final conv = await AppScope.of(context).collab.createGroup(
        _picked.toList(),
        title: _title.text,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      showSnack(context, l.groupCreated);
      context.pushReplacement(
        conversationRoute(
          conv.id,
          conv.title.isEmpty ? l.conversationsGroups : conv.title,
          conv.kind,
        ),
      );
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.groupNew),
        actions: [
          TextButton(
            key: const Key('group-create'),
            onPressed: _picked.isEmpty || _creating ? null : _create,
            child: Text(l.actionCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _title,
              maxLength: 200,
              decoration: InputDecoration(labelText: l.groupTitleOptional),
            ),
          ),
          Expanded(
            child: AsyncView<List<({String id, String name})>>(
              loading: _loading,
              error: _error,
              value: _contacts,
              onRetry: _load,
              emptyWhen: (c) => c.isEmpty,
              emptyMessage: l.groupNoContacts,
              builder: (context, contacts) => ListView(
                children: [
                  for (final c in contacts)
                    CheckboxListTile(
                      key: Key('group-pick-${c.id}'),
                      value: _picked.contains(c.id),
                      title: Text(c.name),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _picked.add(c.id)
                            : _picked.remove(c.id),
                      ),
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

class ConversationMembersScreen extends StatefulWidget {
  const ConversationMembersScreen({
    super.key,
    required this.conversationId,
    this.kind = '',
  });

  final String conversationId;
  final String kind;

  @override
  State<ConversationMembersScreen> createState() =>
      _ConversationMembersScreenState();
}

class _ConversationMembersScreenState extends State<ConversationMembersScreen> {
  ConversationMembers? _data;
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
      final d = await AppScope.of(context).collab
          .members(widget.conversationId);
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
      if (!mounted) return;
      showSnack(context, AppLocalizations.of(context)!.actionDone);
      await _load();
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _memberMenu(ConversationMember m, String choice) async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).collab;
    if (choice == 'remove') {
      if (!await confirmDialog(
        context,
        message: l.channelRemoveConfirm(m.name),
        confirmLabel: l.channelRemove,
      )) {
        return;
      }
      await _guard(() => repo.removeMember(widget.conversationId, m.userId));
    } else {
      await _guard(
        () async => repo.setMemberRole(widget.conversationId, m.userId, choice),
      );
    }
  }

  Future<void> _add() async {
    final picked = await pickReference(context, 'users');
    if (picked == null || !mounted) return;
    await _guard(
      () async =>
          AppScope.of(context).collab
              .addMember(widget.conversationId, picked.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = _data;
    final me = AppScope.of(context).account.user?.id;
    // إضافة عضو: لمن يدير القناة (لا المجموعة — الإضافة فيها مجموعةٌ جديدة)،
    // وحين يبثّ المخطط وحدة المستخدمين لمنتقي المستلم.
    final canPick =
        AppScope.of(context).modules.lastSchema?.modules['users']?.can.v ??
        false;
    return Scaffold(
      appBar: AppBar(title: Text(l.channelMembers)),
      floatingActionButton:
          d != null && d.canManage && widget.kind != 'group' && canPick
          ? FloatingActionButton(
              key: const Key('member-add'),
              tooltip: l.channelAddMember,
              onPressed: _add,
              child: const Icon(Icons.person_add_alt),
            )
          : null,
      body: AsyncView<ConversationMembers>(
        loading: _loading,
        error: _error,
        value: d,
        onRetry: _load,
        builder: (context, d) => ListView(
          children: [
            for (final m in d.members)
              ListTile(
                key: Key('member-${m.userId}'),
                leading: CircleAvatar(
                  child: Text(
                    m.name.isEmpty ? l.unknownInitial : m.name.characters.first,
                  ),
                ),
                title: Text(m.name),
                subtitle: Text(roleLabel(l, m.role)),
                trailing: d.canManage && m.userId != me
                    ? PopupMenuButton<String>(
                        key: Key('member-menu-${m.userId}'),
                        onSelected: (c) => _memberMenu(m, c),
                        itemBuilder: (_) => [
                          for (final r in ConversationRoles.all)
                            if (r != m.role &&
                                (d.isOwner ||
                                    (r != ConversationRoles.owner &&
                                        r != ConversationRoles.moderator)))
                              PopupMenuItem(
                                value: r,
                                child: Text(l.channelMakeRole(roleLabel(l, r))),
                              ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l.channelRemove),
                          ),
                        ],
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final _q = TextEditingController();
  MessageSearchResult? _result;
  Object? _error;
  bool _loading = false;
  int _minChars = 2;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.length < _minChars) {
      setState(() {
        _result = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await AppScope.of(context).collab.searchMessages(q);
      if (mounted) {
        setState(() {
          _result = r;
          _minChars = r.minChars;
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
    final locale = Localizations.localeOf(context).toString();
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('message-search-input'),
          controller: _q,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: l.messageSearchHint,
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l.navSearch,
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(error: _error!, onRetry: _search)
          : r == null
          ? EmptyView(
              message: l.messageSearchMin(_minChars),
              icon: Icons.manage_search,
            )
          : r.hits.isEmpty
          ? EmptyView(message: l.messageSearchNone)
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l.messageSearchTotal(r.total)),
                ),
                for (final h in r.hits)
                  ListTile(
                    key: Key('message-hit-${h.id}'),
                    leading: Icon(switch (h.type) {
                      'dm' => Icons.chat_bubble_outline,
                      'channel' => Icons.tag,
                      _ => Icons.dynamic_feed_outlined,
                    }),
                    title: Text(
                      h.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        ?h.author,
                        if (h.createdAt != null)
                          formatShortDate(h.createdAt!, locale),
                      ].join(' · '),
                    ),
                    // الوجهة من الخادم وحده؛ لا شاشة لها ⇒ لا نقر.
                    onTap: switch (h.target?.routePath) {
                      final String path => () => context.push(path),
                      _ => null,
                    },
                  ),
              ],
            ),
    );
  }
}
