/// جلسات الجرد بالمسح (المرحلة ٣.٤) — `inventory/sessions*`.
///
/// المحرّك خادمي (`InventorySessions`): التجميد لقطةٌ بنطاقي، والمسح عبر المحلِّل
/// الموحّد (الرمز الأجنبي لا يُخزَّن)، والمصالحة والإغلاق خلف تصعيد الهوية (428 ⇒
/// `runWithStepUp`). `can` عرضٌ يعيد الخادم فحصه عند كل فعل.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';

class InventoryAbilities {
  const InventoryAbilities({
    this.freeze = false,
    this.scan = false,
    this.reconcile = false,
    this.close = false,
  });

  factory InventoryAbilities.fromJson(Map<String, dynamic> j) =>
      InventoryAbilities(
        freeze: j['freeze'] == true,
        scan: j['scan'] == true,
        reconcile: j['reconcile'] == true,
        close: j['close'] == true,
      );

  final bool freeze;
  final bool scan;
  final bool reconcile;
  final bool close;
}

class InventorySession {
  const InventorySession({
    required this.id,
    required this.status,
    required this.open,
    this.byName,
    this.createdAt,
    this.closedAt,
    this.reconciledAt,
    this.itemsCount,
    this.scansCount,
    this.counts = const {},
    this.total,
    this.scansTotal,
  });

  factory InventorySession.fromJson(Map<String, dynamic> j) => InventorySession(
    id: j['id']?.toString() ?? '',
    status: j['status']?.toString() ?? '',
    open: j['open'] == true,
    byName: jsonStr(jsonMap(j['by'])['name']),
    createdAt: jsonDate(j['created_at']),
    closedAt: jsonDate(j['closed_at']),
    reconciledAt: jsonStr(j['reconciled_at']),
    itemsCount: jsonIntOrNull(j['items_count']),
    scansCount: jsonIntOrNull(j['scans_count']),
    counts: {
      for (final e in jsonMap(j['counts']).entries) e.key: jsonInt(e.value),
    },
    total: jsonIntOrNull(j['total']),
    scansTotal: jsonIntOrNull(j['scans_total']),
  );

  final String id;

  /// حالة الجلسة كما يسمّيها الخادم (عرض)؛ و[open] هو المرجع الآلي.
  final String status;
  final bool open;
  final String? byName;
  final DateTime? createdAt;
  final DateTime? closedAt;
  final String? reconciledAt;
  final int? itemsCount;
  final int? scansCount;

  /// العدّ بالحكم (في التفصيل وحده).
  final Map<String, int> counts;
  final int? total;
  final int? scansTotal;
}

class InventoryItemRow {
  const InventoryItemRow({
    required this.assetId,
    required this.verdict,
    required this.code,
    required this.name,
    this.type,
    this.status,
  });

  factory InventoryItemRow.fromJson(Map<String, dynamic> j) => InventoryItemRow(
    assetId: j['asset_id']?.toString() ?? '',
    verdict: j['verdict']?.toString() ?? '',
    code: j['code']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    type: jsonStr(j['type']),
    status: jsonStr(j['status']),
  );

  final String assetId;
  final String verdict;
  final String code;
  final String name;
  final String? type;
  final String? status;
}

class InventoryScanRow {
  const InventoryScanRow({
    required this.id,
    required this.result,
    this.assetId,
    this.code,
    this.byName,
    this.at,
  });

  factory InventoryScanRow.fromJson(Map<String, dynamic> j) => InventoryScanRow(
    id: j['id']?.toString() ?? '',
    result: j['result']?.toString() ?? '',
    assetId: jsonStr(j['asset_id']),
    code: jsonStr(j['code']),
    byName: jsonStr(jsonMap(j['by'])['name']),
    at: jsonDate(j['at']),
  );

  final String id;
  final String result;
  final String? assetId;

  /// للمحلول داخل النطاق وحده — «غير معروف» بلا رمز.
  final String? code;
  final String? byName;
  final DateTime? at;
}

class InventoryList {
  const InventoryList({required this.sessions, required this.can});

  final List<InventorySession> sessions;
  final InventoryAbilities can;
}

class InventoryDetail {
  const InventoryDetail({
    required this.session,
    required this.items,
    required this.page,
    required this.lastPage,
    required this.itemsTotal,
    required this.scans,
    required this.can,
  });

  factory InventoryDetail.fromJson(Map<String, dynamic> j) => InventoryDetail(
    session: InventorySession.fromJson(jsonMap(j['session'])),
    items: jsonMaps(j['items']).map(InventoryItemRow.fromJson).toList(),
    page: jsonInt(j['page'], 1),
    lastPage: jsonInt(j['last_page'], 1),
    itemsTotal: jsonInt(j['items_total']),
    scans: jsonMaps(j['scans']).map(InventoryScanRow.fromJson).toList(),
    can: InventoryAbilities.fromJson(jsonMap(j['can'])),
  );

  final InventorySession session;
  final List<InventoryItemRow> items;
  final int page;
  final int lastPage;
  final int itemsTotal;
  final List<InventoryScanRow> scans;
  final InventoryAbilities can;
}

/// نتيجة المسح: `known` | `unexpected` | `unknown` (المفتاح الآلي).
class InventoryScanResult {
  const InventoryScanResult({
    required this.resultKey,
    required this.message,
    this.assetName,
    this.assetCode,
  });

  factory InventoryScanResult.fromJson(Map<String, dynamic> j) {
    final asset = jsonMap(j['asset']);
    return InventoryScanResult(
      resultKey: j['result_key']?.toString() ?? 'unknown',
      message: j['message']?.toString() ?? '',
      assetName: jsonStr(asset['name']),
      assetCode: jsonStr(asset['code']),
    );
  }

  final String resultKey;
  final String message;
  final String? assetName;
  final String? assetCode;
}

class InventoryRepository {
  InventoryRepository(this.api);

  final ApiClient api;

  Future<InventoryList> sessions() async {
    final d = await api.getData('inventory/sessions');
    return InventoryList(
      sessions: jsonMaps(d['sessions']).map(InventorySession.fromJson).toList(),
      can: InventoryAbilities.fromJson(jsonMap(d['can'])),
    );
  }

  Future<InventoryDetail> session(String id, {int page = 1}) async =>
      InventoryDetail.fromJson(
        await api.getData(
          'inventory/sessions/${Uri.encodeComponent(id)}',
          query: page > 1 ? {'page': '$page'} : const {},
        ),
      );

  /// التجميد (`POST inventory/sessions`) — جلسة جديدة بلقطة أصولي المنطّقة.
  Future<({InventorySession session, int frozen})> freeze({
    String? idempotencyKey,
  }) async {
    final d = await api.sendData(
      'POST',
      'inventory/sessions',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return (
      session: InventorySession.fromJson(jsonMap(d['session'])),
      frozen: jsonInt(d['frozen']),
    );
  }

  /// مسح رمز — المفتاح لكل مسحة (الإعادة العابرة لا تسجّل مسحتين).
  Future<InventoryScanResult> scan(
    String sessionId,
    String code, {
    String? idempotencyKey,
  }) async => InventoryScanResult.fromJson(
    await api.sendData(
      'POST',
      'inventory/sessions/${Uri.encodeComponent(sessionId)}/scan',
      body: {'code': code},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  /// المصالحة — خلف التصعيد (`action:inventory:reconcile`).
  Future<Map<String, int>> reconcile(
    String sessionId, {
    String? idempotencyKey,
  }) async {
    final d = await api.sendData(
      'POST',
      'inventory/sessions/${Uri.encodeComponent(sessionId)}/reconcile',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return {
      for (final e in jsonMap(d['counts']).entries) e.key: jsonInt(e.value),
    };
  }

  /// الإغلاق — خلف التصعيد (`action:inventory:close`)؛ لا مسح بعده.
  Future<bool> close(String sessionId, {String? idempotencyKey}) async {
    final d = await api.sendData(
      'POST',
      'inventory/sessions/${Uri.encodeComponent(sessionId)}/close',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return d['closed_now'] == true;
  }
}
