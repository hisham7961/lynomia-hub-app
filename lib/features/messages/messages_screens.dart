/// الرسائل المباشرة (§52) — الخيوط ثم المحادثة: إرسال idempotent وختم قراءة.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'dm_repository.dart';

class DmThreadsScreen extends StatefulWidget {
  const DmThreadsScreen({super.key});

  @override
  State<DmThreadsScreen> createState() => _DmThreadsScreenState();
}

class _DmThreadsScreenState extends State<DmThreadsScreen> {
  List<DmThread>? _threads;
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
      final res = await AppScope.of(context).dm.threads();
      if (mounted) setState(() => _threads = res.threads);
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
      appBar: AppBar(title: Text(l.messagesTitle)),
      body: AsyncView<List<DmThread>>(
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
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    t.userName.isEmpty ? '؟' : t.userName.characters.first,
                  ),
                ),
                title: Text(t.userName),
                subtitle: t.lastExcerpt == null
                    ? null
                    : Text(
                        '${t.lastMine ? '↩ ' : ''}${t.lastExcerpt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: t.unread > 0
                    ? Badge(label: Text('${t.unread}'))
                    : null,
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
      ),
    );
  }
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
      final msgs = await c.dm.messages(widget.otherUserId);
      // ختم القراءة عند فتح الخيط (§52).
      c.dm.markRead(widget.otherUserId).catchError((_) => 0);
      if (mounted) setState(() => _messages = msgs);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await AppScope.of(context).dm.send(widget.otherUserId, body);
      if (!mounted) return;
      _input.clear();
      setState(() => _messages = [...?_messages, msg]);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
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
                  return Align(
                    alignment: m.mine
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: m.mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
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
