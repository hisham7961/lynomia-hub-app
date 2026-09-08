/// الاعتمادات (§54) — الطابور والتفصيل والحسم (اعتماد/رفض بتعليل) مع تصعيد
/// عند الطلب وتقادم صريح، ووجهة السجل الهدف.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/step_up_flow.dart';
import '../../l10n/app_localizations.dart';
import 'approval_repository.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<ApprovalCard>? _cards;
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
      final page = await AppScope.of(context).approvals.pending();
      if (mounted) setState(() => _cards = page.items);
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
      appBar: AppBar(title: Text(l.approvalsTitle)),
      body: AsyncView<List<ApprovalCard>>(
        loading: _loading,
        error: _error,
        value: _cards,
        onRetry: _load,
        emptyWhen: (c) => c.isEmpty,
        emptyMessage: l.approvalsEmpty,
        builder: (context, cards) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final a = cards[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (a.type != null) a.type!,
                      if (a.amount != null)
                        '${Decimal.tryParse(a.amount!) ?? a.amount} ${a.currency ?? ''}',
                      if (a.due != null) a.due!,
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/approvals/${a.id}');
                    _load();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ApprovalDetailScreen extends StatefulWidget {
  const ApprovalDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  ApprovalCard? _card;
  Object? _error;
  bool _loading = true;
  bool _deciding = false;

  /// مفتاح ثابت للقرار الواحد — إعادة المحاولة لا تحسم مرتين (§58).
  String _decisionKey = const Uuid().v4();

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
      final card = await AppScope.of(context).approvals.show(widget.id);
      if (mounted) setState(() => _card = card);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(bool approve) async {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);

    String? note;
    if (!approve) {
      note = await _promptNote(l);
      if (!mounted) return;
    }

    setState(() => _deciding = true);
    try {
      await runWithStepUp(
        context,
        () => c.approvals.decide(
          widget.id,
          approve: approve,
          note: note,
          idempotencyKey: _decisionKey,
        ),
      );
      if (!mounted) return;
      _decisionKey = const Uuid().v4();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.approvalDecided)));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCode.versionConflict) {
        // الطلب تقادم — السجل تغير بعد التقديم (§54): تحديث ثم قرار جديد.
        _decisionKey = const Uuid().v4();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.approvalStale)));
        await _load();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  Future<String?> _promptNote(AppLocalizations l) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.actionReject),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l.approvalRejectReason),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.actionReject),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = _card;
    return Scaffold(
      appBar: AppBar(title: Text(l.approvalsTitle)),
      body: AsyncView<ApprovalCard>(
        loading: _loading,
        error: _error,
        value: a,
        onRetry: _load,
        builder: (context, card) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(card.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(card.status)),
                if (card.type != null) Chip(label: Text(card.type!)),
                if (card.op != null)
                  Chip(
                    label: Text(card.op == 'd' ? l.actionDelete : l.actionEdit),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (card.amount != null)
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(
                  '${Decimal.tryParse(card.amount!) ?? card.amount} ${card.currency ?? ''}',
                  textDirection: TextDirection.ltr,
                ),
              ),
            if (card.reason != null && card.reason!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.notes),
                title: Text(card.reason!),
              ),
            if (card.due != null)
              ListTile(
                leading: const Icon(Icons.event),
                title: Text(card.due!),
              ),
            if (card.target != null)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l.approvalOpenTarget),
                onTap: () => context.push(card.target!.routePath),
              ),
            const SizedBox(height: 24),
            if (card.canDecide)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _deciding ? null : () => _decide(true),
                      icon: const Icon(Icons.check),
                      label: Text(l.actionApprove),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deciding ? null : () => _decide(false),
                      icon: const Icon(Icons.close),
                      label: Text(l.actionReject),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
