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

/// أهلية القرار بلا أثر (`GET leaves/{id}/decision` — خلفية v2.619) من
/// `LeaveDecision::abilities` نفسها التي يحسم بها `decide`. عرضٌ يعيد الخادم
/// فحصه عند الفعل؛ السبب آلي (`LeaveDenyReason`) لا نصّ.
class LeaveDecisionAbility {
  const LeaveDecisionAbility({
    required this.id,
    required this.status,
    required this.canDecide,
    required this.canApprove,
    required this.canReject,
    this.reason,
    this.approveStatus,
    this.rejectReasonRequired = true,
  });

  factory LeaveDecisionAbility.fromJson(Map<String, dynamic> j) =>
      LeaveDecisionAbility(
        id: j['id']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        canDecide: j['can_decide'] == true,
        reason: j['reason']?.toString(),
        canApprove: j['can_approve'] == true,
        canReject: j['can_reject'] == true,
        approveStatus: j['approve_status']?.toString(),
        rejectReasonRequired: j['reject_reason_required'] != false,
      );

  final String id;

  /// حالة الطلب كما يخزّنها الخادم — للعرض فقط.
  final String status;
  final bool canDecide;

  /// `already_decided` | `self_request` | `not_decider` — null حين `canDecide`.
  final String? reason;
  final bool canApprove;
  final bool canReject;

  /// ما يصير إليه الطلب بالموافقة (نصّ حالة خادمي للعرض) — null بلا موافقة.
  final String? approveStatus;
  final bool rejectReasonRequired;
}

class LeaveRepository {
  LeaveRepository(this.api);

  final ApiClient api;

  /// `GET leaves/{id}/decision` — قراءة بلا أثر (403 بلا `leaves:v`، 404 خارج النطاق).
  Future<LeaveDecisionAbility> decision(String leaveId) async =>
      LeaveDecisionAbility.fromJson(
        await api.getData('leaves/${Uri.encodeComponent(leaveId)}/decision'),
      );

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
