/// لوحة مرفقات السجل (§67 §68 §69) — رفع مقطّع بتقدم/إلغاء/إعادة من الكاميرا
/// أو مكتبة الصور أو المستندات، وعرض حقول file/img بقيمها.
///
/// ملاحظة عقدية: لا نقطة جوال تسرد مرفقات سجل قائمة — المعروض هنا حقول
/// file/img من السجل وما رُفع في هذه الجلسة (موثق في docs/backend-change-requests.md).
///
/// الفتح (§69): المرفق المرفوع يُنزَّل عبر `files/{id}/download` **إلى الذاكرة**؛
/// الصورة تُعرض من البايتات ولا تلمس القرص، وما عداها يُفتح بصدقٍ من المنصة على
/// الويب (لا عارض أصلي بلا كتابة ملف مؤقت — قاعدة عدم الإبقاء على القرص).
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../modules/module_repository.dart';
import '../modules/module_schema.dart';
import '../records/field_display.dart';
import 'file_repository.dart';

/// مصدر الإرفاق كما يختاره المستخدم.
enum AttachmentSource { camera, gallery, document }

/// ملف اختاره المستخدم من منصة الجهاز.
class PickedAttachment {
  const PickedAttachment(this.file, this.name);
  final File file;
  final String name;
}

typedef AttachmentPicker = Future<PickedAttachment?> Function(
  AttachmentSource source,
);

/// المنتقي الحقيقي (كاميرا/مكتبة/مستندات) — خلف واجهة لها Fake في الاختبار.
Future<PickedAttachment?> platformAttachmentPicker(
  AttachmentSource source,
) async {
  switch (source) {
    case AttachmentSource.camera:
    case AttachmentSource.gallery:
      final picked = await ImagePicker().pickImage(
        source: source == AttachmentSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      return picked == null
          ? null
          : PickedAttachment(File(picked.path), picked.name);
    case AttachmentSource.document:
      final res = await FilePicker.platform.pickFiles();
      final path = res?.files.single.path;
      return path == null
          ? null
          : PickedAttachment(File(path), res!.files.single.name);
  }
}

/// صيغة حجم مقروءة (بايت/ك.ب/م.ب) من ARB — لا وحدة صلبة.
String formatFileSize(AppLocalizations l, int bytes) {
  if (bytes < 1024) return l.fileSizeBytes(bytes);
  if (bytes < 1024 * 1024) {
    return l.fileSizeKb((bytes / 1024).toStringAsFixed(1));
  }
  return l.fileSizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
}

class AttachmentsPanel extends StatefulWidget {
  const AttachmentsPanel({
    super.key,
    required this.module,
    required this.recordId,
    required this.schema,
    required this.record,
    this.picker = platformAttachmentPicker,
  });

  final String module;
  final String recordId;
  final ModuleSchema schema;
  final RecordData record;
  final AttachmentPicker picker;

  @override
  State<AttachmentsPanel> createState() => _AttachmentsPanelState();
}

class _AttachmentsPanelState extends State<AttachmentsPanel> {
  final List<AttachmentInfo> _uploaded = [];
  _UploadJob? _job;

  Future<void> _pickAndUpload(AttachmentSource source) async {
    final l = AppLocalizations.of(context)!;
    PickedAttachment? picked;
    try {
      picked = await widget.picker(source);
    } on Object {
      // إذن مرفوض/منصة بلا قناة — لا انهيار.
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.filesUploadFailed)));
      }
      return;
    }
    if (picked == null || !mounted) return;
    await _upload(picked.file, picked.name);
  }

  /// فتح مرفق: صورة ⇒ معاينة من الذاكرة؛ غيرها ⇒ صدقٌ: يُفتح من الويب.
  Future<void> _open(AttachmentInfo a) async {
    if (a.isImage) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AttachmentPreviewScreen(attachment: a),
        ),
      );
      return;
    }
    await _offerWeb(AppLocalizations.of(context)!.filesNoInAppPreview);
  }

  Future<void> _offerWeb(String message) async {
    final l = AppLocalizations.of(context)!;
    final webUri = _webRecordUri();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionClose),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.open_in_new),
            label: Text(l.filesOpenOnWeb),
          ),
        ],
      ),
    );
    if (go == true) {
      await launchUrl(webUri, mode: LaunchMode.inAppBrowserView);
    }
  }

  /// صفحة السجل على الويب (`/m/{module}/{id}`) — خلف دخول الويب نفسه.
  Uri _webRecordUri() {
    final root = AppScope.of(context).env.apiRoot;
    final base = root.path.replaceAll(RegExp(r'/+$'), '');
    return root.replace(
      path:
          '$base/m/${Uri.encodeComponent(widget.module)}/'
          '${Uri.encodeComponent(widget.recordId)}',
    );
  }

  Future<void> _upload(File file, String name) async {
    final c = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final size = await file.length();
    final job = _UploadJob(name: name);
    setState(() => _job = job);

    try {
      final session = await c.files.startUploadSession(
        module: widget.module,
        recordId: widget.recordId,
        filename: name,
        mime: _mimeOf(name),
        size: size,
      );
      final chunkSize = max(64 * 1024, session.chunkSize);
      final raf = await file.open();
      var index = 0;
      var sent = 0;
      try {
        while (sent < size) {
          if (job.cancelled) return;
          final len = min(chunkSize, size - sent);
          final bytes = Uint8List(len);
          await raf.readInto(bytes);
          await c.files.uploadChunk(session.token, index, bytes);
          sent += len;
          index += 1;
          if (mounted) setState(() => job.progress = sent / size);
        }
      } finally {
        await raf.close();
      }
      // الإتمام idempotent — المفتاح ثابت لهذه الرفعة (§58).
      final attachments = await c.files.completeUpload(
        session.token,
        parts: index,
        idempotencyKey: job.completeKey,
      );
      if (!mounted) return;
      setState(() {
        _uploaded.addAll(attachments);
        _job = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.filesUploadDone)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => job.failed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(describeError(context, e)),
          action: SnackBarAction(
            label: l.actionRetry,
            onPressed: () => _upload(file, name),
          ),
        ),
      );
    }
  }

  String _mimeOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'csv' => 'text/csv',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fileFields = widget.schema.fields
        .where((f) => f.type == 'file' || f.type == 'img')
        .toList();
    final hasAny =
        fileFields.any((f) {
          final v = widget.record[f.key];
          return v != null && v.toString().isNotEmpty;
        }) ||
        _uploaded.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(l.filesCamera),
              onPressed: () => _pickAndUpload(AttachmentSource.camera),
            ),
            ActionChip(
              avatar: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l.filesGallery),
              onPressed: () => _pickAndUpload(AttachmentSource.gallery),
            ),
            ActionChip(
              avatar: const Icon(Icons.folder_outlined, size: 18),
              label: Text(l.filesDocument),
              onPressed: () => _pickAndUpload(AttachmentSource.document),
            ),
          ],
        ),
        if (_job != null)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(
                _job!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _job!.failed
                  ? Text(l.filesUploadFailed)
                  : LinearProgressIndicator(value: _job!.progress),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l.actionCancel,
                onPressed: () => setState(() {
                  _job!.cancelled = true;
                  _job = null;
                }),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (!hasAny)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: EmptyView(message: l.filesEmpty, icon: Icons.attach_file),
          )
        else ...[
          for (final f in fileFields)
            if (widget.record[f.key] != null &&
                widget.record[f.key].toString().isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(f.label),
                  subtitle: FieldValueView(
                    field: f,
                    value: widget.record[f.key],
                  ),
                  // قيمة الحقل مسار تخزين لا معرّف مرفق — لا نقطة جوال لبايتاته،
                  // فالفتح صادقٌ عبر صفحة السجل على الويب.
                  trailing: IconButton(
                    tooltip: l.filesOpenOnWeb,
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _offerWeb(l.filesFieldOnWebOnly),
                  ),
                ),
              ),
          for (final a in _uploaded)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: a.size == null
                    ? null
                    : Text(formatFileSize(l, a.size!)),
                trailing: IconButton(
                  key: Key('attachment-open-${a.id}'),
                  tooltip: l.actionOpen,
                  icon: Icon(
                    a.isImage ? Icons.visibility_outlined : Icons.open_in_new,
                  ),
                  onPressed: () => _open(a),
                ),
                onTap: () => _open(a),
              ),
            ),
        ],
      ],
    );
  }
}

/// معاينة صورة مرفق من الذاكرة — البايتات تُترك مع الشاشة، لا ملف ولا خبيئة
/// (نظير معاينة «وثائقي»؛ صالحة للحسّاس لأن لا شيء يهبط القرص).
class AttachmentPreviewScreen extends StatefulWidget {
  const AttachmentPreviewScreen({super.key, required this.attachment});

  final AttachmentInfo attachment;

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await AppScope.of(context).files
          .download(widget.attachment.id);
      if (mounted) setState(() => _bytes = bytes);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = _error;
    // الإصابة (٤٢٣ LOCKED) حالة معروفة بنصٍّ محلي من الرمز لا من الرسالة.
    final infected = e is ApiException && e.code == ApiErrorCode.locked;
    return Scaffold(
      appBar: AppBar(title: Text(widget.attachment.name)),
      body: infected
          ? EmptyView(message: l.filesInfected, icon: Icons.gpp_bad_outlined)
          : AsyncView<Uint8List>(
              loading: _loading,
              error: _error,
              value: _bytes,
              onRetry: _load,
              emptyWhen: (b) => b.isEmpty,
              builder: (context, bytes) => InteractiveViewer(
                child: Center(
                  child: Image.memory(
                    bytes,
                    key: const Key('attachment-image'),
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) =>
                        EmptyView(message: l.filesNoInAppPreview),
                  ),
                ),
              ),
            ),
    );
  }
}

class _UploadJob {
  _UploadJob({required this.name});

  final String name;
  final String completeKey = const Uuid().v4();
  double progress = 0;
  bool cancelled = false;
  bool failed = false;
}
