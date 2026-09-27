/// بطاقة قرار الإجازة على سجل `leaves` (المرحلة ٣.٢): اعتماد/رفض، والرفض بسببٍ
/// إلزامي. الخادم يحسم الأهلية (مدير/موارد بشرية/طلب النفس/محسوم) — ورفضه
/// الدلالي بسببٍ آلي يُخفي البطاقة بعده برسالة صادقة لا زرّاً ميتاً.
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
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
      final note = switch (e.details['reason']?.toString()) {
        LeaveDenyReason.alreadyDecided => l.leaveAlreadyDecided,
        LeaveDenyReason.selfRequest => l.leaveSelfRequest,
        LeaveDenyReason.notDecider => l.leaveNotDecider,
        LeaveDenyReason.reasonRequired => l.leaveReasonRequired,
        _ => null,
      };
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
            else
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('leave-approve'),
                    onPressed: _busy
                        ? null
                        : () => _decide(LeaveDecisionKind.approve),
                    icon: const Icon(Icons.check),
                    label: Text(l.actionApprove),
                  ),
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
        ),
      ),
    );
  }
}
