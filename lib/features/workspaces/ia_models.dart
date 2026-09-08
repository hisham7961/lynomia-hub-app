/// نماذج معمارية المعلومات (IA) كما يبثها الخادم (§16 §17 — عقد `navigation`).
///
/// لا بنية مجالات صلبة في التطبيق: الشجرة تُقرأ من `bootstrap.ia`/`GET navigation`
/// منطَّقةً سلفاً بصلاحية المستخدم — ما لا يصل لا يُعرض.
library;

enum MobileFit { suitable, deepLinkOnly, webOnly }

MobileFit _fitOf(String? raw) => switch (raw) {
  'deep-link-only' => MobileFit.deepLinkOnly,
  'web-only' => MobileFit.webOnly,
  _ => MobileFit.suitable,
};

class IaDestination {
  const IaDestination({
    required this.label,
    required this.type,
    required this.importance,
    required this.mobile,
    this.module,
    this.route,
    this.portal,
    this.args = const [],
  });

  factory IaDestination.fromJson(Map<String, dynamic> j) => IaDestination(
    label: j['label']?.toString() ?? '',
    type: j['type']?.toString() ?? 'module',
    importance: j['importance']?.toString() ?? 'primary',
    mobile: _fitOf(j['mobile']?.toString()),
    module: j['module']?.toString(),
    route: j['route']?.toString(),
    portal: j['portal']?.toString(),
    args: (j['args'] as List? ?? const []).map((e) => e.toString()).toList(),
  );

  final String label;

  /// `module | center | admin | entity | personal | system`.
  final String type;

  /// `primary | secondary | advanced` — ترتيب العرض/الطي.
  final String importance;
  final MobileFit mobile;

  /// مفتاح منطقي لشاشة قائمة الوحدة — الوجهة الأساسية للجوال.
  final String? module;
  final String? route;

  /// مفتاح وجهة بوابة العميل (`type: portal`) — home/engagements/projects/
  /// documents/invoices/conversations.
  final String? portal;
  final List<String> args;
}

class IaSection {
  const IaSection({
    required this.key,
    required this.label,
    required this.destinations,
  });

  factory IaSection.fromJson(Map<String, dynamic> j) => IaSection(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    destinations: (j['destinations'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => IaDestination.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  final String key;
  final String label;
  final List<IaDestination> destinations;
}

class IaDomain {
  const IaDomain({
    required this.key,
    required this.label,
    this.icon,
    this.plane,
    required this.sections,
  });

  factory IaDomain.fromJson(Map<String, dynamic> j) => IaDomain(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    icon: j['icon']?.toString(),
    plane: j['plane']?.toString(),
    sections: (j['sections'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => IaSection.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  final String key;
  final String label;
  final String? icon;
  final String? plane;
  final List<IaSection> sections;
}

class IaTree {
  const IaTree({required this.domains, required this.surfaces});

  factory IaTree.fromJson(Map<String, dynamic> j) => IaTree(
    surfaces: (j['surfaces'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => IaDomain.fromJson(e.cast<String, dynamic>()))
        .toList(),
    domains: (j['domains'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => IaDomain.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  static const empty = IaTree(domains: [], surfaces: []);

  final List<IaDomain> domains;
  final List<IaDomain> surfaces;
}
