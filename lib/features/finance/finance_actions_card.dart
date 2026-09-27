/// أفعال مالية على سجلات `fin` · `quotes` · `purchases` (المرحلة ٤.٦) — تظهر
/// لمن يعدّل الوحدة (`can.e` من المخطط — عرض؛ الخادم يعيد الفحص). الدفعة خلف
/// التصعيد، و`409` (طابور اعتماد/تعارض) و`422` تُعرض برسالتها الصادقة.
///
/// الدفعة تُقرأ خياراتها أولاً بلا أثر (`GET fin/{id}/pay-options` — خلفية
/// v2.619): الزرّ لمن `can_pay` وإلا سبب الخادم الآلي نصّاً (ملغى/مسودة أو
/// مسدَّد)، والمتبقي عشريٌّ (`Decimal`) بعملته، ومنتقي البنك من بنوك الدور
/// بالافتراضي `default_bank_id` — وحرّاس البنك تبقى عند الفعل.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/eligibility.dart';
import '../../core/ui/feedback.dart';
import '../../core/ui/step_up_flow.dart';
import '../../l10n/app_localizations.dart';
import 'finance_repository.dart';

/// الوحدات التي لها أفعال مالية على الجوال.
const kFinanceActionModules = {'fin', 'quotes', 'purchases'};

class FinanceActionsCard extends StatefulWidget {
  const FinanceActionsCard({
    super.key,
    required this.module,
    required this.recordId,
    required this.onChanged,
  });

  final String module;
  final String recordId;
  final VoidCallback onChanged;

  @override
  State<FinanceActionsCard> createState() => _FinanceActionsCardState();
}

class _FinanceActionsCardState extends State<FinanceActionsCard> {
  bool _busy = false;
  late final EligibilityLoader<PayOptions> _payOptions = EligibilityLoader(
    this,
    () => AppScope.of(context).finance.payOptions(widget.recordId),
  );

  @override
  void initState() {
    super.initState();
    if (widget.module == 'fin') _payOptions.load();
  }

  /// تنفيذٌ بمفتاحٍ واحد للفعل (ثابت عبر التصعيد والإعادة العابرة).
  Future<void> _run(
    Future<String> Function(String key) op, {
    bool stepUp = false,
  }) async {
    setState(() => _busy = true);
    final key = const Uuid().v4();
    try {
      final message = stepUp
          ? await runWithStepUp(context, () => op(key))
          : await op(key);
      if (!mounted) return;
      showSnack(context, message);
      widget.onChanged();
      if (widget.module == 'fin') await _payOptions.load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      // 409 APPROVAL_REQUIRED: الوحدة بطابور اعتمادٍ معلّق — لا تنفيذ الآن.
      e.code == ApiErrorCode.approvalRequired
          ? showSnack(
              context,
              e.message.isNotEmpty ? e.message : l.financeQueuedBlocked,
            )
          : showErrorSnack(context, e);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay(PayOptions options) async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).finance;
    final input = await showDialog<_PayInput>(
      context: context,
      builder: (_) => _PayDialog(options: options),
    );
    if (input == null || !mounted) return;
    await _run(stepUp: true, (key) async {
      final res = await repo.pay(
        widget.recordId,
        amount: input.amount,
        bankId: input.bankId,
        payRef: input.ref,
        payNote: input.note,
        idempotencyKey: key,
      );
      final rem = res.document.remaining;
      return rem == null
          ? l.financePaid((res.amount ?? input.amount).toString())
          : l.financePaidRemaining(
              (res.amount ?? input.amount).toString(),
              rem.toString(),
              res.document.currency ?? '',
            );
    });
  }

  Future<void> _sendQuote() async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).finance;
    if (!await confirmDialog(context, message: l.financeQuoteSendConfirm)) {
      return;
    }
    await _run((key) async {
      final r = await repo.sendQuote(widget.recordId, idempotencyKey: key);
      return r.outcome == 'escalated'
          ? l.financeQuoteEscalated
          : l.financeQuoteSent;
    });
  }

  Future<void> _acceptQuote() async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).finance;
    if (!await confirmDialog(context, message: l.financeQuoteAcceptConfirm)) {
      return;
    }
    await _run((key) async {
      final r = await repo.acceptQuote(widget.recordId, idempotencyKey: key);
      return r.accepted
          ? l.financeQuoteAccepted
          : l.financeQuoteAlreadyAccepted;
    });
  }

  Future<void> _receive() async {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).finance;
    if (!await confirmDialog(context, message: l.financeReceiveConfirm)) {
      return;
    }
    await _run((key) async {
      final r = await repo.receivePurchase(
        widget.recordId,
        idempotencyKey: key,
      );
      return r.already
          ? l.financeAlreadyReceived
          : l.financeReceived(r.moves, r.skipped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.module == 'fin') {
      return _payOptions.build(context, (o) => _payCard(context, l, o));
    }
    final buttons = switch (widget.module) {
      'quotes' => [
        FilledButton.tonalIcon(
          key: const Key('quote-send'),
          onPressed: _busy ? null : _sendQuote,
          icon: const Icon(Icons.send_outlined),
          label: Text(l.financeQuoteSend),
        ),
        FilledButton.icon(
          key: const Key('quote-accept'),
          onPressed: _busy ? null : _acceptQuote,
          icon: const Icon(Icons.handshake_outlined),
          label: Text(l.financeQuoteAccept),
        ),
      ],
      'purchases' => [
        FilledButton.icon(
          key: const Key('purchase-receive'),
          onPressed: _busy ? null : _receive,
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(l.financeReceive),
        ),
      ],
      _ => const <Widget>[],
    };
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ),
    );
  }

  Widget _payCard(BuildContext context, AppLocalizations l, PayOptions o) {
    final remaining = o.remaining == null
        ? null
        : Text(
            l.financeRemaining(o.remaining!.toString(), o.currency ?? ''),
            key: const Key('fin-remaining'),
          );
    if (!o.canPay) {
      return EligibilityNote(
        key: const Key('fin-pay-note'),
        text: o.reason == PayDenyReason.settled
            ? l.financePaySettled
            : l.financePayDeadState,
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('fin-pay'),
              onPressed: _busy ? null : () => _pay(o),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l.financePay),
            ),
            ?remaining,
          ],
        ),
      ),
    );
  }
}

class _PayInput {
  const _PayInput(this.amount, this.bankId, this.ref, this.note);
  final Decimal amount;
  final String? bankId;
  final String? ref;
  final String? note;
}

class _PayDialog extends StatefulWidget {
  const _PayDialog({required this.options});

  final PayOptions options;

  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  final _amount = TextEditingController();
  final _ref = TextEditingController();
  final _note = TextEditingController();
  late String? _bankId = widget.options.defaultBankId;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _ref.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppLocalizations.of(context)!;
    final amount = parseAmount(_amount.text);
    if (amount == null) {
      setState(() => _error = l.financeAmountInvalid);
      return;
    }
    Navigator.pop(context, _PayInput(amount, _bankId, _ref.text, _note.text));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final o = widget.options;
    return AlertDialog(
      title: Text(l.financePay),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('pay-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l.financeAmount,
                hintText: '0.000',
                helperText: o.remaining == null
                    ? null
                    : l.financeRemaining(
                        o.remaining!.toString(),
                        o.currency ?? '',
                      ),
                errorText: _error,
              ),
            ),
            if (o.banks.isNotEmpty)
              DropdownButtonFormField<String?>(
                key: const Key('pay-bank'),
                initialValue: _bankId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.financeBank),
                items: [
                  DropdownMenuItem<String?>(child: Text(l.financeNoBank)),
                  for (final b in o.banks)
                    DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(
                        b.currency == null
                            ? b.name
                            : '${b.name} · ${b.currency}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _bankId = v),
              ),
            TextField(
              controller: _ref,
              maxLength: 200,
              decoration: InputDecoration(labelText: l.financePayRef),
            ),
            TextField(
              controller: _note,
              maxLength: 500,
              decoration: InputDecoration(labelText: l.financePayNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          key: const Key('pay-submit'),
          onPressed: _submit,
          child: Text(l.actionConfirm),
        ),
      ],
    );
  }
}
