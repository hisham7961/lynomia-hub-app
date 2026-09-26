/// «اسأل Hub» — محادثةٌ تُسأل فيها البيانات بعين المستخدم، ومحادثاتٌ محفوظة.
///
/// عرضٌ فقط: الخادم يقرأ ويصادق المراجع ويعيد تحقق الجواب المحفوظ. لا إعادة
/// إرسالٍ تلقائية (السؤال نداءٌ مدفوع)، ولا سؤالٌ ثانٍ قبل ردّ الأول.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'ask_repository.dart';

String askFailureText(AppLocalizations l, AskFailureKind k) => switch (k) {
  AskFailureKind.unavailable => l.askErrUnavailable,
  AskFailureKind.limit => l.askErrLimit,
  AskFailureKind.denied => l.askErrDenied,
  AskFailureKind.noData => l.askErrNoData,
  AskFailureKind.question => l.askErrQuestion,
  AskFailureKind.tooBig => l.askErrTooBig,
  AskFailureKind.other => l.askErrGeneric,
};

/// دورٌ معروض: سؤالٌ وجوابُه (أو إخفاقه أو حجبه).
class _Turn {
  _Turn(this.question);

  final String question;
  bool pending = true;
  String? answer;
  bool partial = false;
  bool hidden = false;
  AskFailureKind? failure;
  List<AskSource> sources = const [];
}

class AskScreen extends StatefulWidget {
  const AskScreen({super.key, this.threadId});

  /// متابعةُ محادثةٍ محفوظة — أو `null` لمحادثةٍ جديدة.
  final String? threadId;

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _input = TextEditingController();
  final _turns = <_Turn>[];
  String? _thread;
  bool _loading = false;
  Object? _loadError;

  bool get _busy => _turns.isNotEmpty && _turns.last.pending;

  @override
  void initState() {
    super.initState();
    _thread = widget.threadId;
    if (_thread != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final turns = await AppScope.of(context).ask.turns(_thread!);
      if (!mounted) return;
      setState(() {
        _turns
          ..clear()
          ..addAll(
            turns.map(
              (t) => _Turn(t.question)
                ..pending = false
                ..answer = t.answer
                ..hidden = t.hidden
                ..failure = !t.ok && !t.hidden
                    ? askFailureKind(t.failure)
                    : null,
            ),
          );
      });
    } on Object catch (e) {
      if (mounted) setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    final turn = _Turn(q);
    setState(() {
      _turns.add(turn);
      _input.clear();
    });
    try {
      final a = await AppScope.of(context).ask.ask(q, thread: _thread);
      turn
        ..answer = a.ok ? a.answer : null
        ..partial = a.partial
        ..sources = a.sources
        ..failure = a.ok ? null : a.failureKind;
      _thread = a.thread ?? _thread;
    } on ApiException catch (e) {
      turn.failure = e.code == ApiErrorCode.forbidden
          ? AskFailureKind.denied
          : AskFailureKind.other;
    } on Object {
      turn.failure = AskFailureKind.other;
    } finally {
      turn.pending = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.askTitle),
        actions: [
          IconButton(
            tooltip: l.askNewThread,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _busy
                ? null
                : () => setState(() {
                    _turns.clear();
                    _thread = null;
                  }),
          ),
          IconButton(
            tooltip: l.askThreads,
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/ask/threads'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_loadError != null) {
                  return ErrorView(error: _loadError!, onRetry: _load);
                }
                if (_turns.isEmpty) {
                  return EmptyView(
                    message: l.askEmpty,
                    icon: Icons.question_answer_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _turns.length,
                  itemBuilder: (context, i) => _TurnView(turn: _turns[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ask-input'),
                      controller: _input,
                      enabled: !_busy,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l.askHint,
                        counterText: '',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('ask-send'),
                    tooltip: l.askSend,
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : _send,
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

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn});

  final _Turn turn;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(turn.question),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (turn.pending)
                  Row(
                    children: [
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.askWorking)),
                    ],
                  )
                else if (turn.hidden)
                  Text(
                    l.askHiddenTurn,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                else if (turn.failure != null)
                  Text(
                    '⚠️ ${askFailureText(l, turn.failure!)}',
                    style: TextStyle(color: scheme.error),
                  )
                else ...[
                  SelectableText(turn.answer ?? ''),
                  if (turn.partial)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l.askPartial,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  if (turn.sources.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.askSources,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Wrap(
                      spacing: 6,
                      children: turn.sources.map((s) {
                        final target = s.target;
                        final label = l.askSourceRows(s.label, s.rows);
                        return target == null
                            ? Chip(label: Text(label))
                            : ActionChip(
                                label: Text(label),
                                onPressed: () => context.push(target.routePath),
                              );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AskThreadsScreen extends StatefulWidget {
  const AskThreadsScreen({super.key});

  @override
  State<AskThreadsScreen> createState() => _AskThreadsScreenState();
}

class _AskThreadsScreenState extends State<AskThreadsScreen> {
  AskThreads? _data;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await AppScope.of(context).ask.threads();
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String text) async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.actionDelete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteOne(AskThreadSummary t) async {
    final l = AppLocalizations.of(context)!;
    if (!await _confirm(l.askDeleteConfirm) || !mounted) return;
    try {
      await AppScope.of(context).ask.deleteThread(t.id);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
      return;
    }
    await _load();
  }

  Future<void> _deleteAll() async {
    final l = AppLocalizations.of(context)!;
    if (!await _confirm(l.askDeleteAllConfirm) || !mounted) return;
    try {
      await AppScope.of(context).ask.deleteAll();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.askThreads),
        actions: [
          if (d != null && d.threads.isNotEmpty)
            IconButton(
              tooltip: l.askDeleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _deleteAll,
            ),
        ],
      ),
      body: AsyncView<AskThreads>(
        loading: _loading,
        error: _error,
        value: d,
        onRetry: _load,
        builder: (context, d) => ListView(
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline),
              title: Text(
                d.memory ? l.askRetention(d.retentionDays) : l.askMemoryOff,
              ),
            ),
            if (d.threads.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l.askNoThreads)),
              ),
            ...d.threads.map(
              (t) => ListTile(
                title: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.forum_outlined),
                trailing: IconButton(
                  tooltip: l.actionDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteOne(t),
                ),
                onTap: () =>
                    context.push('/ask/t/${Uri.encodeComponent(t.id)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
