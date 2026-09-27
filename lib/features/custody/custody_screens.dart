/// «عهدتي» (المرحلة ٣.٣) + بطاقة تسليم/استرداد العهدة على سجل الأصل.
///
/// الإقرار بالاستلام يسلك إجراء السجل القائم (مسار الخادم)، والتسليم والاسترداد
/// السكّة الواحدة `CustodyHandover` — الأهلية (`assets:e`/`custodyAssign` +
/// النطاق) خادمية؛ الرفض يُعرض بصدق.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/feedback.dart';
import '../../l10n/app_localizations.dart';
import '../records/field_editors.dart';
import 'custody_repository.dart';

class MyCustodyScreen extends StatefulWidget {
  const MyCustodyScreen({super.key});

  @override
  State<MyCustodyScreen> createState() => _MyCustodyScreenState();
}

class _MyCustodyScreenState extends State<MyCustodyScreen> {
  MyCustody? _data;
  Object? _error;
  bool _loading = true;
  final Set<String> _acking = {};

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
      final d = await AppScope.of(context).custody.mine();
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ack(PendingReceipt r) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _acking.add(r.id));
    try {
      await AppScope.of(context).custody
          .acknowledge(r, idempotencyKey: const Uuid().v4());
      if (!mounted) return;
      showSnack(context, l.custodyAcked);
      await _load();
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _acking.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.custodyTitle)),
      body: AsyncView<MyCustody>(
        loading: _loading,
        error: _error,
        value: _data,
        onRetry: _load,
        emptyWhen: (d) => d.isEmpty,
        emptyMessage: l.custodyEmpty,
        builder: (context, d) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (d.pendingReceipts.isNotEmpty) ...[
                _Header(l.custodyPendingReceipts),
                for (final r in d.pendingReceipts)
                  Card(
                    child: ListTile(
                      key: Key('custody-receipt-${r.id}'),
                      leading: const Icon(Icons.fact_check_outlined),
                      title: Text(r.title),
                      subtitle: Text(
                        [r.label, r.why].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      trailing: _acking.contains(r.id)
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton(
                              key: Key('custody-ack-${r.id}'),
                              onPressed: () => _ack(r),
                              child: Text(l.custodyAck),
                            ),
                    ),
                  ),
              ],
              _Header(l.custodyAssets(d.assets.length)),
              if (d.assets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.custodyNoAssets),
                ),
              for (final a in d.assets)
                Card(
                  child: ListTile(
                    key: Key('custody-asset-${a.id}'),
                    leading: const Icon(Icons.devices_other_outlined),
                    title: Text(a.name),
                    subtitle: Text(
                      [
                        ?a.code,
                        ?a.type,
                        ?a.serial,
                        ?a.status,
                        ?a.stationName,
                      ].join(' · '),
                    ),
                    trailing: a.receiptPending
                        ? Chip(label: Text(l.custodyReceiptPending))
                        : const Icon(Icons.chevron_right),
                    onTap: () => context.push('/r/assets/${a.id}'),
                  ),
                ),
              if (d.moves.isNotEmpty) ...[
                _Header(l.custodyMoves),
                Card(
                  child: Column(
                    children: [
                      for (final m in d.moves)
                        ListTile(
                          dense: true,
                          title: Text('${m.action} · ${m.assetName}'),
                          subtitle: Text([?m.at, ?m.note].join(' · ')),
                          onTap: m.assetId.isEmpty
                              ? null
                              : () => context.push('/r/assets/${m.assetId}'),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// تسليم/استرداد العهدة على سجل الأصل — يظهر لمن يعدّل الأصول (عرضٌ؛ الخادم
/// يعيد الفحص). منتقي المستلم من وحدة `users` حين يبثّها المخطط لهذا الدور —
/// وإلا فلا زرّ تسليم (لا زرّ بلا وسيلة إكمال).
class CustodyActionsCard extends StatefulWidget {
  const CustodyActionsCard({
    super.key,
    required this.assetId,
    required this.canPickUsers,
    required this.onChanged,
  });

  final String assetId;
  final bool canPickUsers;
  final VoidCallback onChanged;

  @override
  State<CustodyActionsCard> createState() => _CustodyActionsCardState();
}

class _CustodyActionsCardState extends State<CustodyActionsCard> {
  bool _busy = false;

  Future<void> _run(Future<CustodyMoveResult> Function(String key) op) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await op(const Uuid().v4());
      if (!mounted) return;
      showSnack(context, l.actionDone);
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handover() async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).custody;
    final user = await pickReference(context, 'users');
    if (user == null || !mounted) return;
    final note = await promptTextDialog(
      context,
      title: l.custodyHandoverTo(user.name),
      hint: l.custodyNoteHint,
      maxLength: 500,
    );
    if (note == null) return;
    await _run(
      (key) => repo.handover(
        widget.assetId,
        userId: user.id,
        at: DateTime.now(),
        note: note,
        idempotencyKey: key,
      ),
    );
  }

  Future<void> _recover() async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).custody;
    final note = await promptTextDialog(
      context,
      title: l.custodyRecover,
      hint: l.custodyNoteHint,
      maxLength: 500,
    );
    if (note == null) return;
    await _run(
      (key) => repo.recover(
        widget.assetId,
        at: DateTime.now(),
        note: note,
        idempotencyKey: key,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      key: const Key('custody-actions'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l.custodyActionsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (widget.canPickUsers)
              FilledButton.tonalIcon(
                key: const Key('custody-handover'),
                onPressed: _busy ? null : _handover,
                icon: const Icon(Icons.handshake_outlined),
                label: Text(l.custodyHandover),
              ),
            OutlinedButton.icon(
              key: const Key('custody-recover'),
              onPressed: _busy ? null : _recover,
              icon: const Icon(Icons.assignment_return_outlined),
              label: Text(l.custodyRecover),
            ),
          ],
        ),
      ),
    );
  }
}
