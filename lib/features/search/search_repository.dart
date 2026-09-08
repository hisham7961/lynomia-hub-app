/// `GET search` (§50) — المحرك المنطَّق الخادمي؛ كل نتيجة وجهة `{module,id}`.
library;

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';

class SearchHit {
  const SearchHit({
    required this.target,
    required this.name,
    required this.label,
  });

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
    target: DeepTarget(
      module: j['module']?.toString() ?? '',
      id: j['id']?.toString() ?? '',
    ),
    name: j['name']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
  );

  final DeepTarget target;
  final String name;

  /// تسمية الوحدة للعرض (من الخادم).
  final String label;
}

class SearchRepository {
  SearchRepository(this.api);

  final ApiClient api;

  /// أقل من حرفين ⇒ فارغ خادمياً — لا يُستدعى أصلاً (تكافؤ العقد).
  Future<List<SearchHit>> search(String q, {int limit = 20}) async {
    final data = await api.getData(
      'search',
      query: {'q': q, 'limit': '$limit'},
    );
    return (data['results'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => SearchHit.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
