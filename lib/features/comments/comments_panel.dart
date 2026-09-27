/// لوحة التعليقات (§53) — قراءة بردود وتفاعلات (تبديلٌ يحسمه الخادم)، ونشر
/// برد. تُستخدم داخل شاشة السجل، وفي القناة/المجموعة (`module=channel`) مع
/// استطلاع «منذ» ومؤشر كتابة لا يعملان إلا والشاشة ظاهرة (§106).
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/visible_poller.dart';
import '../../l10n/app_localizations.dart';
import '../messages/live_events.dart';
import '../messages/save_action.dart';
import 'comment_repository.dart';
import 'reactions.dart';

/// فاصل استطلاع القناة المفتوحة.
const kChannelPollInterval = Duration(seconds: 5);

class CommentsPanel extends StatefulWidget {
  const CommentsPanel({
    super.key,
    required this.module,
    required this.recordId,
    this.liveConversationId,
  });

  final String module;
  final String recordId;

  /// حين تكون اللوحة لقناةٍ/مجموعة: معرّفها لاستطلاع «منذ» والكتابة.
  final String? liveConversationId;

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final _input = TextEditingController();
  List<RecordComment>? _comments;
  Object? _error;
  bool _loading = true;
  bool _posting = false;
  String? _replyTo;
  String? _replyToName;
  List<String> _typing = const [];

  SinceFeed<ChannelLiveEvent>? _feed;
  VisiblePoller? _poller;
  TypingThrottle? _typingPing;

  @override
  void initState() {
    super.initState();
    final convId = widget.liveConversationId;
    if (convId != null) {
      final c = AppScope.of(context);
      _feed = SinceFeed(
        (cursor) => c.collab.channelSince(convId, cursor: cursor),
      );
      _poller = VisiblePoller(
        interval: kChannelPollInterval,
        onTick: _poll,
        isVisible: () => routeIsCurrent(context),
      );
      // علم الخادم `collab_typing=false` ⇒ لا نبض أصلاً؛ غيابه (خادمٌ أقدم) ⇒
      // يُجرَّب والـ٤٠٤ يوقفه.
      if (c.account.capabilityAllowed('collab_typing')) {
        _typingPing = TypingThrottle(() async {
          try {
            await c.collab.channelTyping(convId);
          } on ApiException catch (e) {
            // القدرة مطفأة خادمياً (٤٠٤) أو ضيفٌ لا يكتب (٤٠٣) ⇒ نكفّ عن النبض.
            if (e.code == ApiErrorCode.resourceNotFound ||
                e.code == ApiErrorCode.forbidden) {
              _typingPing?.disable();
            }
          }
        });
      }
    }
    _load().then((_) async {
      if (!mounted || _poller == null || _comments == null) return;
      await _poll();
      if (mounted) _poller!.start();
    });
  }

  @override
  void dispose() {
    _poller?.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    setState(() {
      if (!quiet) _loading = true;
      _error = null;
    });
    try {
      final thread = await AppScope.of(context).comments
          .thread(widget.module, widget.recordId);
      // أول تحميل للقناة يبذر «منذ» بمؤشر الذيل الخادمي — النبضات تبدأ من الآن.
      final cursor = thread.cursor;
      final feed = _feed;
      if (feed != null && !feed.caughtUp && cursor != null) feed.seed(cursor);
      if (mounted) setState(() => _comments = thread.comments);
    } on Object catch (e) {
      if (mounted && !quiet) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<String> _knownIds() => {
    for (final c in _comments ?? const <RecordComment>[]) ...[
      c.id,
      for (final r in c.replies) r.id,
    ],
  };

  /// نبضة «منذ» من مؤشر الذيل: أي حدثٍ لا نعرفه ⇒ إعادة جلب هادئة للقائمة
  /// (ردود وتفاعلات بشكلها الخادمي الكامل). خادمٌ أقدم بلا مؤشر ⇒ اللحاق بالذيل
  /// صفحاتٍ محدودةً في كل نبضة، ولا إعادة جلب قبل بلوغه.
  Future<void> _poll() async {
    final feed = _feed;
    if (feed == null) return;
    try {
      final batch = await feed.pull(maxPages: 5);
      if (!mounted) return;
      setState(() => _typing = batch.typing);
      final known = _knownIds();
      final fresh = batch.events.any((e) => !known.contains(e.id));
      if (fresh && batch.caughtUp) await _load(quiet: true);
    } on ApiException catch (e) {
      // لم أعد عضواً (٤٠٤) ⇒ لا استطلاع بعده.
      if (e.code == ApiErrorCode.resourceNotFound) _poller?.stop();
    }
  }

  Future<void> _react(RecordComment c, [String? emoji]) async {
    final chosen = emoji ?? await pickReaction(context);
    if (chosen == null || !mounted) return;
    try {
      final t = await AppScope.of(context).comments.react(c.id, chosen);
      if (!mounted) return;
      setState(
        () => _comments = [
          for (final x in _comments ?? const <RecordComment>[])
            x.applyReaction(t),
        ],
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    }
  }

  Future<void> _post() async {
    final body = _input.text.trim();
    if (body.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await AppScope.of(context).comments.post(
        module: widget.module,
        recordId: widget.recordId,
        body: body,
        parentId: _replyTo,
      );
      if (!mounted) return;
      _input.clear();
      setState(() {
        _replyTo = null;
        _replyToName = null;
      });
      await _load();
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: AsyncView<List<RecordComment>>(
            loading: _loading,
            error: _error,
            value: _comments,
            onRetry: _load,
            emptyWhen: (list) => list.isEmpty,
            emptyMessage: l.commentsEmpty,
            builder: (context, comments) => RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final c in comments) ...[
                    _CommentTile(
                      comment: c,
                      onReact: (emoji) => _react(c, emoji),
                      onSave: () => saveWithUndo(
                        context,
                        targetType: 'comment',
                        targetId: c.id,
                      ),
                      onReply: () => setState(() {
                        _replyTo = c.id;
                        _replyToName = c.userName;
                      }),
                    ),
                    for (final r in c.replies)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 32),
                        child: _CommentTile(
                          comment: r,
                          onReact: (emoji) => _react(r, emoji),
                          onSave: () => saveWithUndo(
                            context,
                            targetType: 'comment',
                            targetId: r.id,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              children: [
                if (_typing.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _typing.length == 1
                          ? l.typingOne(_typing.single)
                          : l.typingMany(_typing.join(l.listSeparator)),
                      key: const Key('channel-typing'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_replyTo != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '↩ ${_replyToName ?? ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _replyTo = null;
                          _replyToName = null;
                        }),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('comment-input'),
                        controller: _input,
                        onChanged: (_) => _typingPing?.onInput(),
                        decoration: InputDecoration(
                          hintText: l.commentsHint,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: _posting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _posting ? null : _post,
                      tooltip: l.actionSend,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReact,
    required this.onSave,
    this.onReply,
  });

  final RecordComment comment;

  /// null ⇒ ورقة الاختيار؛ رمزٌ ⇒ تبديله مباشرة.
  final void Function(String? emoji) onReact;
  final VoidCallback onSave;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    comment.userName.isEmpty
                        ? l.unknownInitial
                        : comment.userName.characters.first,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.userName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (comment.pinned)
                  Tooltip(
                    message: l.commentPinned,
                    child: const Icon(Icons.push_pin, size: 14),
                  ),
                if (comment.internal)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Chip(
                      label: Text(l.commentInternal),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (comment.resolved)
                  Tooltip(
                    message: l.commentResolved,
                    child: const Icon(Icons.check_circle_outline, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.body),
            if (comment.hasAttachment)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.attach_file,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: [
                      for (final r in comment.reactions)
                        ReactionChip(
                          key: Key('reaction-${comment.id}-${r.emoji}'),
                          emoji: r.emoji,
                          count: r.count,
                          mine: r.mine,
                          onTap: () => onReact(r.emoji),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('save-${comment.id}'),
                  tooltip: l.savedAction,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  onPressed: onSave,
                ),
                IconButton(
                  key: Key('react-${comment.id}'),
                  tooltip: l.reactionsAdd,
                  icon: const Icon(Icons.add_reaction_outlined, size: 18),
                  onPressed: () => onReact(null),
                ),
                if (onReply != null)
                  IconButton(
                    key: Key('reply-${comment.id}'),
                    tooltip: l.commentReply,
                    icon: const Icon(Icons.reply, size: 18),
                    onPressed: onReply,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
