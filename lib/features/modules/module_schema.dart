/// مخطط الوحدات الواعي بالصلاحية (§18 §19) — من `GET schema` (ETag).
///
/// الوحدات والحقول كما يراها **هذا** المستخدم: المحجوب غائب أصلاً، و`readonly`
/// مشتق خادمياً من قناع الحقل. لا قائمة وحدات مكتوبة يدوياً في التطبيق.
library;

class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.ref,
    this.multi = false,
    this.options,
    this.hint,
    this.readonly = false,
  });

  factory FieldSpec.fromJson(Map<String, dynamic> j) => FieldSpec(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? j['key']?.toString() ?? '',
    type: j['type']?.toString() ?? 'text',
    required: j['required'] == true,
    ref: j['ref']?.toString(),
    multi: j['multi'] == true,
    options: (j['options'] as List?)?.map((e) => e.toString()).toList(),
    hint: j['hint']?.toString(),
    readonly: j['readonly'] == true,
  );

  final String key;
  final String label;

  /// `text ta num date dt bool sel ref tags url file img sec` — التغطية الكاملة
  /// موثقة في docs/schema-field-coverage.md (أنواع مجهولة لا تسقط الإصدار §93).
  final String type;
  final bool required;
  final String? ref;
  final bool multi;
  final List<String>? options;
  final String? hint;
  final bool readonly;
}

class ModuleCan {
  const ModuleCan({
    this.v = false,
    this.a = false,
    this.e = false,
    this.d = false,
  });

  factory ModuleCan.fromJson(Map<String, dynamic> j) => ModuleCan(
    v: j['v'] == true,
    a: j['a'] == true,
    e: j['e'] == true,
    d: j['d'] == true,
  );

  final bool v;
  final bool a;
  final bool e;
  final bool d;
}

class ModuleSchema {
  const ModuleSchema({
    required this.key,
    required this.label,
    required this.syncClass,
    required this.can,
    required this.fields,
  });

  factory ModuleSchema.fromJson(Map<String, dynamic> j) => ModuleSchema(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? j['key']?.toString() ?? '',
    syncClass: j['sync_class']?.toString() ?? 'ONLINE_ONLY',
    can: ModuleCan.fromJson(
      (j['can'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    fields: (j['fields'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => FieldSpec.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  final String key;
  final String label;
  final String syncClass;
  final ModuleCan can;
  final List<FieldSpec> fields;

  bool get sensitiveNoPersist => syncClass == 'SENSITIVE_NO_PERSIST';
  bool get cacheable => syncClass.startsWith('CACHEABLE');

  FieldSpec? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }

  /// حقل العرض التقريبي: أول حقل نصي — للبطاقات والقوائم.
  FieldSpec? get displayField {
    for (final f in fields) {
      if (f.type == 'text') return f;
    }
    return fields.isEmpty ? null : fields.first;
  }
}

class SchemaSnapshot {
  const SchemaSnapshot({required this.version, required this.modules});

  factory SchemaSnapshot.fromJson(Map<String, dynamic> j) => SchemaSnapshot(
    version: j['schema_version']?.toString() ?? '',
    modules: {
      for (final m in (j['modules'] as List? ?? const []).whereType<Map>())
        (m['key']?.toString() ?? ''): ModuleSchema.fromJson(
          m.cast<String, dynamic>(),
        ),
    },
  );

  final String version;
  final Map<String, ModuleSchema> modules;
}
