/// قرار الإجازة (المرحلة ٣.٢) — `POST leaves/{id}/decide`.
///
/// السلسلة خادمية (`LeaveDecision`): المدير يوصي والموارد البشرية تحسم، والرفض
/// بسببٍ إلزامي، ولا قرار في طلب النفس ولا فوق قرار. التطبيق يتفرّع على
/// `details.reason` الآلي فقط.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';

enum LeaveDecisionKind {
  approve('approve'),
  reject('reject');

  const LeaveDecisionKind(this.wire);
  final String wire;
}

/// أسباب الرفض الآلية (`details.reason`).
abstract final class LeaveDenyReason {
  static const alreadyDecided = 'already_decided';
  static const selfRequest = 'self_request';
  static const notDecider = 'not_decider';
  static const reasonRequired = 'reason_required';
}

class LeaveDecisionResult {
  const LeaveDecisionResult({
    required this.status,
    required this.previousStatus,
    required this.message,
  });

  factory LeaveDecisionResult.fromJson(Map<String, dynamic> j) =>
      LeaveDecisionResult(
        status: j['status']?.toString() ?? '',
        previousStatus: j['previous_status']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
      );

  final String status;
  final String previousStatus;

  /// رسالة الخادم — للعرض فقط.
  final String message;
}

class LeaveRepository {
  LeaveRepository(this.api);

  final ApiClient api;

  Future<LeaveDecisionResult> decide(
    String leaveId,
    LeaveDecisionKind decision, {
    String? reason,
    String? idempotencyKey,
  }) async => LeaveDecisionResult.fromJson(
    await api.sendData(
      'POST',
      'leaves/${Uri.encodeComponent(leaveId)}/decide',
      body: {
        'decision': decision.wire,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );
}
