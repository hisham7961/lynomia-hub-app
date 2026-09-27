/// بطاقة قرار الإجازة على سجل `leaves` (المرحلة ٣.٢): اعتماد/رفض، والرفض بسببٍ
/// إلزامي. الأهلية تُقرأ أولاً بلا أثر من `GET leaves/{id}/decision` (خلفية
/// v2.619 — القواعد نفسها التي يحسم بها `decide`): البطاقة لمن `can_decide`،
/// والاعتماد لمن `can_approve`، والرفض لمن `can_reject`؛ وغير المقرِّر يرى سبب
/// الخادم الآلي نصّاً من ARB لا زرّاً ميتاً. ورفض الفعل الدلالي (سباقٌ بعد
/// القراءة) يُغلق البطاقة برسالة صادقة كذلك.
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/eligibility.dart';
import '../../core/ui/feedback.dart';
import '../../l10n/app_localizations.dart';
import 'leave_repository.dart';

class LeaveDecisionCard extends StatefulWidget {
  const LeaveDecisionCard({
    super.key,
    required this.leaveId,
    required this.onDecided,
  });

  final String leaveId;
  final VoidCallback onDecided;

  @override
  State<LeaveDecisionCard> createState() => _LeaveDecisionCardState();
}

class _LeaveDecisionCardState extends State<LeaveDecisionCard> {
  bool _busy = false;
  late final EligibilityLoader<LeaveDecisionAbility> _ability =
      EligibilityLoader(
        this,
        () => AppScope.of(context).leaves.decision(widget.leaveId),
      );

  @override
  void initState() {
    super.initState();
    _ability.load();
  }

  /// رسالة نهائية بعد رفضٍ دلالي (لا قرار لي هنا) — تحلّ محلّ الأزرار.
  String? _closedNote;

  Future<void> _decide(LeaveDecisionKind kind) async {
    final l = AppLocalizations.of(context)!;
    String? reason;
    if (kind == LeaveDecisionKind.reject) {
      reason = await promptTextDialog(
        context,
        title: l.leaveRejectReasonTitle,
        hint: l.leaveRejectReasonHint,
        required: true,
        maxLength: 500,
      );
      if (reason == null || !mounted) return;
    } else {
      final ok = await confirmDialog(context, message: l.leaveApproveConfirm);
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final res = await AppScope.of(context).leaves.decide(
        widget.leaveId,
        kind,
        reason: reason,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      showSnack(context, res.message.isNotEmpty ? res.message : l.actionDone);
      widget.onDecided();
    } on ApiException catch (e) {
      if (!mounted) return;
      final code = e.details['reason']?.toString();
      final note = code == LeaveDenyReason.reasonRequired
          ? l.leaveReasonRequired
          : code == null
          ? null
          : leaveReasonTextOrNull(l, code);
      if (note == null) {
        showErrorSnack(context, e);
      } else if (e.details['reason'] == LeaveDenyReason.reasonRequired) {
        showSnack(context, note);
      } else {
        setState(() => _closedNote = note);
      }
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _ability.build(
      context,
      (a) => a.canDecide
          ? _card(context, l, a)
          : EligibilityNote(
              key: const Key('leave-decision-note'),
              text: leaveReasonText(l, a.reason),
            ),
    );
  }

  Widget _card(
    BuildContext context,
    AppLocalizations l,
    LeaveDecisionAbility a,
  ) {
    return Card(
      key: const Key('leave-decision'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.leaveDecisionTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_closedNote != null)
              Text(_closedNote!, key: const Key('leave-closed-note'))
            else ...[
              if (a.canApprove && a.approveStatus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l.leaveApproveBecomes(a.approveStatus!),
                    key: const Key('leave-approve-status'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Wrap(
                spacing: 8,
                children: [
                  if (a.canApprove)
                    FilledButton.icon(
                      key: const Key('leave-approve'),
                      onPressed: _busy
                          ? null
                          : () => _decide(LeaveDecisionKind.approve),
                      icon: const Icon(Icons.check),
                      label: Text(l.actionApprove),
                    ),
                  if (a.canReject)
                    OutlinedButton.icon(
                      key: const Key('leave-reject'),
                      onPressed: _busy
                          ? null
                          : () => _decide(LeaveDecisionKind.reject),
                      icon: const Icon(Icons.close),
                      label: Text(l.actionReject),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// نصّ سبب عدم الأهلية من ARB بالرمز الآلي — لا تفريع على نصّ الخادم.
String? leaveReasonTextOrNull(AppLocalizations l, String? code) =>
    switch (code) {
      LeaveDenyReason.alreadyDecided => l.leaveAlreadyDecided,
      LeaveDenyReason.selfRequest => l.leaveSelfRequest,
      LeaveDenyReason.notDecider => l.leaveNotDecider,
      _ => null,
    };

String leaveReasonText(AppLocalizations l, String? code) =>
    leaveReasonTextOrNull(l, code) ?? l.leaveNotDecider;
