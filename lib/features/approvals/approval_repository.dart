/// الاعتمادات (§54) — طابور المعتمد، تفصيل، اعتماد/رفض عبر السكة الخادمية فقط.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';

class ApprovalCard {
  const ApprovalCard({
    required this.id,
    required this.title,
    this.type,
    required this.status,
    this.op,
    this.amount,
    this.currency,
    this.due,
    this.reason,
    this.requestedBy,
    this.target,
    this.recordVersion,
    this.createdAt,
    this.canDecide = false,
    this.decidedAt,
  });

  factory ApprovalCard.fromJson(Map<String, dynamic> j) => ApprovalCard(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    type: j['type']?.toString(),
    status: j['status']?.toString() ?? '',
    op: j['op']?.toString(),
    amount: j['amount']?.toString(),
    currency: j['currency']?.toString(),
    due: j['due']?.toString(),
    reason: j['reason']?.toString(),
    requestedBy: j['requested_by']?.toString(),
    target: DeepTarget.fromJson(j['target']),
    recordVersion: j['record_version']?.toString(),
    createdAt: j['created_at']?.toString(),
    canDecide: j['can_decide'] == true,
    decidedAt: j['decided_at']?.toString(),
  );

  final String id;
  final String title;
  final String? type;
  final String status;

  /// `e` تعديل | `d` حذف.
  final String? op;

  /// المبلغ نص عشري خادمي — يُعرض عبر Decimal، لا يُحسب محلياً (§81).
  final String? amount;
  final String? currency;
  final String? due;
  final String? reason;
  final String? requestedBy;
  final DeepTarget? target;
  final String? recordVersion;
  final String? createdAt;
  final bool canDecide;
  final String? decidedAt;
}

class ApprovalDecision {
  const ApprovalDecision({
    required this.code,
    required this.message,
    this.status,
  });
  final String code;
  final String message;
  final String? status;
}

class ApprovalRepository {
  ApprovalRepository(this.api);

  final ApiClient api;

  Future<ListPage<ApprovalCard>> pending({int page = 1, int per = 25}) =>
      api.getList(
        'approvals',
        ApprovalCard.fromJson,
        query: {'page': '$page', 'per': '$per'},
      );

  Future<ApprovalCard> show(String id) async {
    final data = await api.getData('approvals/$id');
    return ApprovalCard.fromJson(
      (data['approval'] as Map?)?.cast<String, dynamic>() ?? data,
    );
  }

  /// الحسم قابل لإعادة المحاولة ⇒ Idempotency-Key ثابت للقرار الواحد (§58).
  /// التقادم ⇒ `VERSION_CONFLICT`، والتصعيد ⇒ `STEP_UP_REQUIRED` (يعالجهما
  /// المستدعي عرضاً).
  Future<ApprovalDecision> decide(
    String id, {
    required bool approve,
    String? note,
    String? idempotencyKey,
  }) async {
    final data = await api.sendData(
      'POST',
      'approvals/$id/${approve ? 'approve' : 'reject'}',
      body: {if (note != null && note.isNotEmpty) 'note': note},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return ApprovalDecision(
      code: data['code']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      status: ((data['approval'] as Map?) ?? const {})['status']?.toString(),
    );
  }
}
