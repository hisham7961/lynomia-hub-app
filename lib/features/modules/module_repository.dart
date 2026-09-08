/// محرك الوحدات العام (§19) — CRUD + إجراءات لأي وحدة يبثها المخطط.
///
/// وحدة جديدة على الخادم تظهر تلقائياً: المخطط يبثها، القوائم والنماذج تُبنى
/// منه، والإجراءات من `GET actions` — لا إصدار جوال جديد لمجرد الاكتشاف.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';
import 'module_schema.dart';

/// سجل عام: خريطة الحقول كما شكّلها الخادم لدور المستخدم.
class RecordData {
  const RecordData(this.fields);

  final Map<String, dynamic> fields;

  String get id => fields['id']?.toString() ?? '';

  /// نسخة القفل التفاؤلي (§57) — تُحفظ وتُبث `If-Match` عند الكتابة.
  int? get version => switch (fields['version']) {
    final int v => v,
    final String s => int.tryParse(s),
    _ => null,
  };

  Object? operator [](String key) => fields[key];

  String display(ModuleSchema schema) {
    final f = schema.displayField;
    final v = f == null ? null : fields[f.key];
    final s = v?.toString() ?? '';
    return s.isEmpty ? id : s;
  }
}

class ActionSpec {
  const ActionSpec({
    required this.action,
    required this.label,
    this.to,
    this.requiresApproval = false,
    this.needs = const [],
  });

  factory ActionSpec.fromJson(Map<String, dynamic> j) => ActionSpec(
    action: j['action']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    to: j['to']?.toString(),
    requiresApproval: j['requires_approval'] == true,
    needs: (j['needs'] as List? ?? const []).map((e) => e.toString()).toList(),
  );

  final String action;
  final String label;

  /// حالة الانتقال لإجراء `status`.
  final String? to;

  /// تنفيذه سيصف طلب موافقة (§56).
  final bool requiresApproval;
  final List<String> needs;

  /// تمييز الهدام لواجهة التأكيد (§56) — الاستعادة ليست هدامة.
  bool get destructive => action == 'restore-version';
}

class ActionsEnvelope {
  const ActionsEnvelope({
    required this.module,
    required this.id,
    this.status,
    this.trashed = false,
    this.version,
    required this.actions,
  });

  factory ActionsEnvelope.fromJson(Map<String, dynamic> j) => ActionsEnvelope(
    module: j['module']?.toString() ?? '',
    id: j['id']?.toString() ?? '',
    status: j['status']?.toString(),
    trashed: j['trashed'] == true,
    version: switch (j['version']) {
      final int v => v,
      final String s => int.tryParse(s),
      _ => null,
    },
    actions: (j['actions'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ActionSpec.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  final String module;
  final String id;
  final String? status;
  final bool trashed;
  final int? version;
  final List<ActionSpec> actions;
}

class ModuleRepository {
  ModuleRepository(this.api);

  final ApiClient api;

  SchemaSnapshot? _schema;
  String? _schemaEtag;

  /// `GET schema` (ETag/304) — تُخبأ اللقطة في الذاكرة لعمر الجلسة (§93).
  Future<SchemaSnapshot> schema({bool force = false}) async {
    final resp = await api.send(
      ApiRequest('GET', 'schema', ifNoneMatch: force ? null : _schemaEtag),
    );
    if (resp.notModified && _schema != null) return _schema!;
    _schemaEtag = resp.etag;
    return _schema = SchemaSnapshot.fromJson(resp.dataMap);
  }

  void invalidateSchema() {
    _schema = null;
    _schemaEtag = null;
  }

  /// `GET {module}` — ترقيم/بحث/فرز من الحقول الظاهرة (§19).
  Future<ListPage<RecordData>> list(
    String module, {
    int page = 1,
    int per = 25,
    String? q,
    String? status,
    String? sort,
    String? dir,
  }) => api.getList(
    module,
    (j) => RecordData(j),
    query: {
      'page': '$page',
      'per': '$per',
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (dir != null && dir.isNotEmpty) 'dir': dir,
    },
  );

  Future<RecordData> show(String module, String id) async =>
      RecordData(await api.getData('$module/$id'));

  /// إنشاء — Idempotency-Key لكل فعل مستخدم (ثابت عبر إعادة المحاولة §58).
  Future<RecordData> create(
    String module,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async => RecordData(
    await api.sendData(
      'POST',
      module,
      body: body,
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  /// استبدال كامل — `If-Match` إلزامي من نسخة السجل (§57).
  Future<RecordData> update(
    String module,
    String id,
    Map<String, dynamic> body, {
    required int? ifMatchVersion,
  }) async => RecordData(
    await api.sendData(
      'PUT',
      '$module/$id',
      body: body,
      ifMatchVersion: ifMatchVersion,
    ),
  );

  Future<RecordData> patch(
    String module,
    String id,
    Map<String, dynamic> body, {
    required int? ifMatchVersion,
    String? idempotencyKey,
  }) async => RecordData(
    await api.sendData(
      'PATCH',
      '$module/$id',
      body: body,
      ifMatchVersion: ifMatchVersion,
      idempotencyKey: idempotencyKey,
    ),
  );

  Future<void> destroy(String module, String id, {int? ifMatchVersion}) =>
      api.sendData('DELETE', '$module/$id', ifMatchVersion: ifMatchVersion);

  /// `GET {module}/{id}/actions` — الخادم يشتق allowlist؛ يُعرض ما يصل فقط (§55).
  Future<ActionsEnvelope> actions(String module, String id) async =>
      ActionsEnvelope.fromJson(await api.getData('$module/$id/actions'));

  /// `POST {module}/{id}/actions/{action}` — من الـallowlist حصراً، لا منفذ عام.
  Future<Map<String, dynamic>> runAction(
    String module,
    String id,
    ActionSpec spec, {
    Map<String, dynamic> input = const {},
    String? idempotencyKey,
  }) => api.sendData(
    'POST',
    '$module/$id/actions/${spec.action}',
    body: {if (spec.to != null) 'to': spec.to, ...input},
    idempotencyKey: idempotencyKey ?? const Uuid().v4(),
  );
}
