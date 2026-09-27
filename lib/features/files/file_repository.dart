/// الملفات (§67 §69) — رفع مقطّع (جلسة/قطع/إتمام)، إرفاق مفرد، تنزيل مصادق.
///
/// لا base64 في JSON، ولا روابط عامة: التنزيل والبث خلف بوابة التخويل نفسها.
library;

import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';

class UploadSession {
  const UploadSession({
    required this.token,
    required this.chunkSize,
    required this.maxParts,
    required this.maxBytes,
  });

  factory UploadSession.fromJson(Map<String, dynamic> j) => UploadSession(
    token: (j['token'] ?? j['id'] ?? j['session'])?.toString() ?? '',
    chunkSize: (j['chunk_size'] as num?)?.toInt() ?? 512 * 1024,
    maxParts: (j['max_parts'] as num?)?.toInt() ?? 4096,
    maxBytes: (j['max_bytes'] as num?)?.toInt() ?? 0,
  );

  final String token;
  final int chunkSize;
  final int maxParts;
  final int maxBytes;
}

class AttachmentInfo {
  const AttachmentInfo({
    required this.id,
    required this.name,
    this.size,
    this.mime,
    this.downloadPath,
    this.streamPath,
  });

  factory AttachmentInfo.fromJson(Map<String, dynamic> j) => AttachmentInfo(
    id: j['id']?.toString() ?? '',
    // الخادم يبث `original_name` (MobileFileController::attachmentsPayload).
    name: (j['original_name'] ?? j['name'] ?? j['filename'])?.toString() ?? '',
    size: (j['size'] as num?)?.toInt(),
    mime: j['mime']?.toString(),
    downloadPath: j['download']?.toString(),
    streamPath: j['stream']?.toString(),
  );

  final String id;
  final String name;
  final int? size;
  final String? mime;

  /// مساران **نسبيان** لنقاط مصادقة — لا روابط عامة (عقد §07 الخلفي).
  final String? downloadPath;
  final String? streamPath;

  /// صورة نقطية قابلة للمعاينة في الذاكرة (من mime الخادم ثم الامتداد).
  bool get isImage {
    final m = mime ?? '';
    if (m.isNotEmpty) return m.startsWith('image/') && m != 'image/svg+xml';
    final ext = name.split('.').last.toLowerCase();
    return const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'}.contains(ext);
  }
}

class FileRepository {
  FileRepository(this.api);

  final ApiClient api;

  /// بدء جلسة رفع مقطّع — الخادم يتحقق من الهدف والامتداد والحجم مبكراً.
  Future<UploadSession> startUploadSession({
    required String module,
    required String recordId,
    required String filename,
    required String mime,
    required int size,
    String? kind,
  }) async => UploadSession.fromJson(
    await api.sendData(
      'POST',
      'files/upload-session',
      body: {
        'module': module,
        'record_id': recordId,
        'filename': filename,
        'mime': mime,
        'size': size,
        'kind': ?kind,
      },
    ),
  );

  Future<void> uploadChunk(String token, int index, Uint8List bytes) =>
      api.send(
        ApiRequest(
          'PUT',
          'files/upload-session/$token/chunk',
          query: {'i': '$index'},
          bodyBytes: bytes,
          contentType: 'application/octet-stream',
          timeout: const Duration(minutes: 3),
        ),
      );

  /// الإتمام idempotent خادمياً — المفتاح ثابت للرفعة الواحدة (§58).
  Future<List<AttachmentInfo>> completeUpload(
    String token, {
    required int parts,
    String? idempotencyKey,
  }) async {
    final data = await api.sendData(
      'POST',
      'files/upload-session/$token/complete',
      body: {'parts': parts},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return _attachments(data);
  }

  List<AttachmentInfo> _attachments(Map<String, dynamic> data) =>
      ((data['attachments'] ?? data['files']) as List? ?? const [])
          .whereType<Map>()
          .map((e) => AttachmentInfo.fromJson(e.cast<String, dynamic>()))
          .toList();

  /// تنزيل مصادق إلى **الذاكرة** (§69) — لا ملف ولا خبيئة؛ المستدعي يعرض
  /// الصور من البايتات مباشرة، وما عداها يُفتح من الويب (لا كتابة قرص).
  Future<Uint8List> download(String attachmentId) async {
    final resp = await api.send(
      ApiRequest(
        'GET',
        'files/$attachmentId/download',
        timeout: const Duration(minutes: 3),
      ),
    );
    return Uint8List.fromList(resp.bodyBytes ?? const []);
  }
}
