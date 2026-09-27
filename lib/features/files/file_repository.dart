/// الملفات (§67 §69) — رفع مقطّع (جلسة/قطع/إتمام)، إرفاق مفرد، تنزيل مصادق.
///
/// لا base64 في JSON، ولا روابط عامة: التنزيل والبث خلف بوابة التخويل نفسها.
library;

import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';

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

/// مرفقُ سجلٍّ كما يسرده الخادم بقواعد شاشة الويب (`GET attachments`) مع ما
/// يجوز للقارئ الآن (`can`) — عرضٌ يعيد الخادم فحصه عند الفعل.
class RecordFile {
  const RecordFile({
    required this.info,
    this.kindLabel,
    this.avStatus,
    this.expiresAt,
    this.uploadedBy,
    this.createdAt,
    this.canDownload = false,
    this.canPreview = false,
    this.canDelete = false,
  });

  factory RecordFile.fromJson(Map<String, dynamic> j) {
    final can = jsonMap(j['can']);
    return RecordFile(
      info: AttachmentInfo.fromJson(j),
      kindLabel: jsonStr(j['kind_label']),
      avStatus: jsonStr(j['av_status']),
      expiresAt: jsonStr(j['expires_at']),
      uploadedBy: UserRef.fromJson(j['uploaded_by']),
      createdAt: jsonDate(j['created_at']),
      canDownload: can['download'] == true,
      canPreview: can['preview'] == true,
      canDelete: can['delete'] == true,
    );
  }

  final AttachmentInfo info;
  final String? kindLabel;

  /// حالة الفحص كما يبثّها الخادم (`infected` ⇒ لا تنزيل).
  final String? avStatus;
  final String? expiresAt;
  final UserRef? uploadedBy;
  final DateTime? createdAt;
  final bool canDownload;
  final bool canPreview;
  final bool canDelete;

  String get id => info.id;
  bool get infected => avStatus == 'infected';
}

/// مقبض مرفق رسالة/تعليق `{id, name, size, mime, download}` — `id` معرّف
/// صاحبه (الرسالة/التعليق) والتنزيل عبر `download` المصادَق.
class MessageAttachmentRef {
  const MessageAttachmentRef({
    required this.ownerId,
    required this.name,
    required this.downloadPath,
    this.size,
    this.mime,
  });

  static MessageAttachmentRef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final path = jsonStr(j['download']);
    if (path == null) return null;
    return MessageAttachmentRef(
      ownerId: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      downloadPath: path,
      size: jsonIntOrNull(j['size']),
      mime: jsonStr(j['mime']),
    );
  }

  final String ownerId;
  final String name;
  final String downloadPath;
  final int? size;
  final String? mime;

  AttachmentInfo get asInfo => AttachmentInfo(
    id: ownerId,
    name: name,
    size: size,
    mime: mime,
    downloadPath: downloadPath,
  );
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

  /// `GET attachments?module=&record_id=` — مرفقات السجل بقواعد الويب (الممنوع
  /// صراحةً لا يُعرض). (مسارٌ منفصل عن CRUD وحدة `files` كي لا يلتبس بها.)
  Future<List<RecordFile>> recordFiles(String module, String recordId) async {
    final d = await api.getData(
      'attachments',
      query: {'module': module, 'record_id': recordId},
    );
    return jsonMaps(d['files']).map(RecordFile.fromJson).toList();
  }

  /// `DELETE attachments/{id}` — حذفٌ ناعم بحارس الويب (رافعه/المالك/محرّر
  /// الوحدة). لا إعادة تلقائية.
  Future<void> deleteFile(String attachmentId) => api.sendData(
    'DELETE',
    'attachments/${Uri.encodeComponent(attachmentId)}',
  );

  /// تنزيل مصادَق إلى الذاكرة عبر مسارٍ يبثّه الخادم (مرفق تعليق/رسالة:
  /// `comments/{id}/attachment` · `dm/messages/{id}/attachment`).
  Future<Uint8List> downloadPath(String serverPath) async {
    final resp = await api.send(
      ApiRequest(
        'GET',
        mobileRelativePath(serverPath),
        timeout: const Duration(minutes: 3),
      ),
    );
    return Uint8List.fromList(resp.bodyBytes ?? const []);
  }
}
