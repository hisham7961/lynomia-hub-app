/// غلاف ردود `/api/mobile/v1` (عقد `Api::*`).
library;

/// صفحة قائمة قياسية: `{data:[], total, page, last_page, meta, request_id}`.
class ListPage<T> {
  const ListPage({
    required this.items,
    required this.total,
    required this.page,
    required this.lastPage,
    required this.hasMore,
    this.requestId,
  });

  factory ListPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemOf,
  ) {
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ListPage(
      items: (json['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => itemOf(e.cast<String, dynamic>()))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      hasMore: meta['has_more'] == true,
      requestId: json['request_id']?.toString(),
    );
  }

  final List<T> items;
  final int total;
  final int page;
  final int lastPage;
  final bool hasMore;
  final String? requestId;
}

/// وجهة الرابط العميق القانونية `{module, id, action}` (عقد §08).
class DeepTarget {
  const DeepTarget({
    required this.module,
    required this.id,
    this.action = 'show',
  });

  static DeepTarget? fromJson(Object? json) {
    if (json is! Map) return null;
    final module = json['module']?.toString();
    final id = json['id']?.toString();
    if (module == null || module.isEmpty || id == null || id.isEmpty) {
      return null;
    }
    return DeepTarget(
      module: module,
      id: id,
      action: json['action']?.toString() ?? 'show',
    );
  }

  final String module;
  final String id;
  final String action;

  /// مسار شاشة السجل داخل التطبيق.
  String get routePath => '/r/$module/$id';
}
