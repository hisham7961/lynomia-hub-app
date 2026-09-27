/// العهدة (المرحلة ٣.٣) — «عهدتي» (`me/custody`)، وتسليم/استرداد عهدة أصلٍ
/// (`custody/{id}/handover|recover`)، وإقرار الاستلام عبر إجراء السجل القائم
/// (`assets/{id}/actions/ack` — المسار كما يبثّه الخادم في `pending_receipts`).
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';

class CustodyAsset {
  const CustodyAsset({
    required this.id,
    required this.name,
    this.code,
    this.type,
    this.tag,
    this.serial,
    this.status,
    this.stationName,
    this.receiptPending = false,
  });

  factory CustodyAsset.fromJson(Map<String, dynamic> j) => CustodyAsset(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    code: jsonStr(j['code']),
    type: jsonStr(j['type']),
    tag: jsonStr(j['tag']),
    // null حين يحجبه قيد الحقل على الدور — لا يُعرض.
    serial: jsonStr(j['serial']),
    status: jsonStr(j['status']),
    stationName: jsonStr(jsonMap(j['station'])['name']),
    receiptPending: j['receipt_pending'] == true,
  );

  final String id;
  final String name;
  final String? code;
  final String? type;
  final String? tag;
  final String? serial;
  final String? status;
  final String? stationName;
  final bool receiptPending;
}

class CustodyMoveItem {
  const CustodyMoveItem({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.action,
    this.at,
    this.note,
  });

  factory CustodyMoveItem.fromJson(Map<String, dynamic> j) => CustodyMoveItem(
    id: j['id']?.toString() ?? '',
    assetId: j['asset_id']?.toString() ?? '',
    assetName: j['asset_name']?.toString() ?? '',
    action: j['action']?.toString() ?? '',
    at: jsonStr(j['at']),
    note: jsonStr(j['note']),
  );

  final String id;
  final String assetId;
  final String assetName;

  /// تسمية الحركة كما يخزّنها الخادم (عرضٌ).
  final String action;
  final String? at;
  final String? note;
}

class PendingReceipt {
  const PendingReceipt({
    required this.module,
    required this.id,
    required this.title,
    required this.label,
    required this.why,
    this.ackPath,
  });

  factory PendingReceipt.fromJson(Map<String, dynamic> j) {
    final ack = jsonMap(j['ack']);
    return PendingReceipt(
      module: j['module']?.toString() ?? 'assets',
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      label: j['label']?.toString() ?? '',
      why: j['why']?.toString() ?? '',
      ackPath: jsonStr(ack['path']),
    );
  }

  final String module;
  final String id;
  final String title;
  final String label;
  final String why;

  /// مسار الإقرار من الخادم (الباب الواحد) — نسبيٌّ بعد التطبيع.
  final String? ackPath;
}

class MyCustody {
  const MyCustody({
    required this.assets,
    required this.moves,
    required this.pendingReceipts,
  });

  factory MyCustody.fromJson(Map<String, dynamic> j) => MyCustody(
    assets: jsonMaps(j['assets']).map(CustodyAsset.fromJson).toList(),
    moves: jsonMaps(j['moves']).map(CustodyMoveItem.fromJson).toList(),
    pendingReceipts: jsonMaps(j['pending_receipts'])
        .map(PendingReceipt.fromJson)
        .toList(),
  );

  final List<CustodyAsset> assets;
  final List<CustodyMoveItem> moves;
  final List<PendingReceipt> pendingReceipts;

  bool get isEmpty =>
      assets.isEmpty && moves.isEmpty && pendingReceipts.isEmpty;
}

class CustodyMoveResult {
  const CustodyMoveResult({
    required this.assetId,
    required this.movementAction,
    this.holderId,
    this.status,
  });

  factory CustodyMoveResult.fromJson(Map<String, dynamic> j) {
    final asset = jsonMap(j['asset']);
    final move = jsonMap(j['movement']);
    return CustodyMoveResult(
      assetId: asset['id']?.toString() ?? '',
      holderId: jsonStr(asset['holder_id']),
      status: jsonStr(asset['status']),
      movementAction: move['action']?.toString() ?? '',
    );
  }

  final String assetId;
  final String? holderId;
  final String? status;
  final String movementAction;
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// أسباب عدم الأهلية الآلية (`custody/{id}/abilities`).
abstract final class CustodyDenyReason {
  static const notPermitted = 'not_permitted';
  static const notHeld = 'not_held';
}

/// أهلية التسليم/الاسترداد بلا أثر (خلفية v2.619) من بوّابة `CustodyHandover`
/// نفسها: `assets:e` **أو** المفتاح الدقيق `custodyAssign`، والاسترداد لعهدةٍ
/// بيد أحد. عرضٌ يعيد الخادم فحصه عند الفعل.
class CustodyAbilities {
  const CustodyAbilities({
    required this.id,
    required this.canHandover,
    required this.canRecover,
    this.holderId,
    this.reason,
  });

  factory CustodyAbilities.fromJson(Map<String, dynamic> j) => CustodyAbilities(
    id: j['id']?.toString() ?? '',
    canHandover: j['can_handover'] == true,
    canRecover: j['can_recover'] == true,
    holderId: jsonStr(j['holder_id']),
    reason: jsonStr(j['reason']),
  );

  final String id;
  final bool canHandover;
  final bool canRecover;

  /// null إن لم تكن بيد أحد أو حُجب الحقل عن الدور.
  final String? holderId;

  /// `not_permitted` | `not_held` | null.
  final String? reason;
}

class CustodyRepository {
  CustodyRepository(this.api);

  final ApiClient api;

  Future<MyCustody> mine() async =>
      MyCustody.fromJson(await api.getData('me/custody'));

  /// `GET custody/{id}/abilities` — قراءة بلا أثر (403 بلا رؤية ولا فعل، 404 خارج النطاق).
  Future<CustodyAbilities> abilities(String assetId) async =>
      CustodyAbilities.fromJson(
        await api.getData('custody/${Uri.encodeComponent(assetId)}/abilities'),
      );

  /// `POST custody/{id}/handover` — Idempotency ثابت للفعل الواحد.
  Future<CustodyMoveResult> handover(
    String assetId, {
    required String userId,
    required DateTime at,
    String? note,
    String? projectId,
    String? idempotencyKey,
  }) async => CustodyMoveResult.fromJson(
    await api.sendData(
      'POST',
      'custody/${Uri.encodeComponent(assetId)}/handover',
      body: {
        'user_id': userId,
        'at': isoDate(at),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'project_id': ?projectId,
      },
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  /// `POST custody/{id}/recover` — العهدة بيد أحدٍ شرط (وإلا ٤٢٢).
  Future<CustodyMoveResult> recover(
    String assetId, {
    required DateTime at,
    String? note,
    String? idempotencyKey,
  }) async => CustodyMoveResult.fromJson(
    await api.sendData(
      'POST',
      'custody/${Uri.encodeComponent(assetId)}/recover',
      body: {
        'at': isoDate(at),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  /// إقرار الاستلام عبر مسار الخادم (`ack.path`) أو الإجراء القائم افتراضاً.
  Future<void> acknowledge(
    PendingReceipt receipt, {
    String? idempotencyKey,
  }) => api.sendData(
    'POST',
    receipt.ackPath != null
        ? mobileRelativePath(receipt.ackPath!)
        : '${receipt.module}/${Uri.encodeComponent(receipt.id)}/actions/ack',
    body: const {},
    idempotencyKey: idempotencyKey ?? const Uuid().v4(),
  );
}
