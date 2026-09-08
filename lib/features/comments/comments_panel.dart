/// لوحة تعليقات السجل (§53) — قراءة بردود وتفاعلات، ونشر برد. تُستخدم داخل
/// شاشة السجل.
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'comment_repository.dart';

class CommentsPanel extends StatefulWidget {
  const CommentsPanel({
    super.key,
    required this.module,
    required this.recordId,
  });

  final String module;
  final String recordId;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await AppScope.of(context).comments
          .forRecord(widget.module, widget.recordId);
      if (mounted) setState(() => _comments = comments);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                      onReply: () => setState(() {
                        _replyTo = c.id;
                        _replyToName = c.userName;
                      }),
                    ),
                    for (final r in c.replies)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 32),
                        child: _CommentTile(comment: r),
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
                        controller: _input,
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
  const _CommentTile({required this.comment, this.onReply});

  final RecordComment comment;
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
                        ? '؟'
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
                if (comment.reactions.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final r in comment.reactions)
                          Chip(
                            label: Text('${r.emoji} ${r.count}'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: r.mine
                                ? BorderSide(color: theme.colorScheme.primary)
                                : null,
                          ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (onReply != null)
                  TextButton(onPressed: onReply, child: const Text('↩')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
