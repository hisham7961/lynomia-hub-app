/// «وثائقي» — `me/documents` و`me/documents/{id}/file`: وثائق ملفّي الوظيفي.
///
/// التفويض خادمي (ارتباط `employees.user_id` + `DocumentPolicy`): وثيقة زميلٍ
/// ٤٠٤، والمنع الصريح على وثيقتي ٤٠٣، والمصاب ٤٢٣. البايتات **لا تهبط القرص**
/// (وثائق شخصية حساسة): تُحمَّل إلى الذاكرة للعرض ثم تُترك مع الشاشة.
library;

import 'dart:typed_data';

import '../../core/api/api_client.dart';

class MyDocument {
  const MyDocument({
    required this.id,
    required this.kind,
    required this.label,
    required this.name,
    this.docNo,
    required this.mime,
    required this.size,
    this.expiresOn,
    this.daysLeft,
    this.infected = false,
    this.tone = '',
  });

  factory MyDocument.fromJson(Map<String, dynamic> j) => MyDocument(
    id: j['id']?.toString() ?? '',
    kind: j['kind']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    docNo: j['doc_no']?.toString(),
    mime: j['mime']?.toString() ?? '',
    size: (j['size'] as num?)?.toInt() ?? 0,
    expiresOn: j['date']?.toString(),
    daysLeft: (j['days'] as num?)?.toInt(),
    infected: j['infected'] == true,
    tone: j['tone']?.toString() ?? '',
  );

  final String id;
  final String kind;

  /// تسمية نوع الوثيقة كما يسمّيها الخادم.
  final String label;
  final String name;
  final String? docNo;
  final String mime;
  final int size;

  /// تاريخ الانتهاء (YYYY-MM-DD) إن كانت مؤرَّخة.
  final String? expiresOn;

  /// الأيام المتبقية (سالبة = منتهية) — يحسبها الخادم.
  final int? daysLeft;
  final bool infected;

  /// نغمة الرادار الخادمية: `bad` منتهية · `wn` قريبة · '' عادية.
  final String tone;

  bool get isImage => mime.startsWith('image/');
}

class MyDocumentsRepository {
  MyDocumentsRepository(this.api);

  final ApiClient api;

  /// `GET me/documents`.
  Future<List<MyDocument>> list() async =>
      ((await api.getData('me/documents'))['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MyDocument.fromJson(e.cast<String, dynamic>()))
          .toList();

  /// `GET me/documents/{id}/file` — بايتات في الذاكرة فقط (لا كتابة قرص).
  Future<Uint8List> file(String id) async {
    final resp = await api.send(
      ApiRequest(
        'GET',
        'me/documents/$id/file',
        timeout: const Duration(minutes: 3),
      ),
    );
    return Uint8List.fromList(resp.bodyBytes ?? const []);
  }
}
