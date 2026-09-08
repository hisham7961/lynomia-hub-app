/// لوحة مرفقات السجل (§67 §68 §69) — رفع مقطّع بتقدم/إلغاء/إعادة من الكاميرا
/// أو مكتبة الصور أو المستندات، وعرض حقول file/img بقيمها.
///
/// ملاحظة عقدية: لا نقطة جوال تسرد مرفقات سجل قائمة — المعروض هنا حقول
/// file/img من السجل وما رُفع في هذه الجلسة (موثق في docs/backend-change-requests.md).
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../modules/module_repository.dart';
import '../modules/module_schema.dart';
import '../records/field_display.dart';
import 'file_repository.dart';

class AttachmentsPanel extends StatefulWidget {
  const AttachmentsPanel({
    super.key,
    required this.module,
    required this.recordId,
    required this.schema,
    required this.record,
  });

  final String module;
  final String recordId;
  final ModuleSchema schema;
  final RecordData record;

  @override
  State<AttachmentsPanel> createState() => _AttachmentsPanelState();
}

class _AttachmentsPanelState extends State<AttachmentsPanel> {
  final List<AttachmentInfo> _uploaded = [];
  _UploadJob? _job;

  Future<void> _pickAndUpload(_PickSource source) async {
    final l = AppLocalizations.of(context)!;
    File? file;
    String? name;
    try {
      switch (source) {
        case _PickSource.camera:
        case _PickSource.gallery:
          final picked = await ImagePicker().pickImage(
            source: source == _PickSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
          );
          if (picked != null) {
            file = File(picked.path);
            name = picked.name;
          }
        case _PickSource.document:
          final res = await FilePicker.platform.pickFiles();
          final path = res?.files.single.path;
          if (path != null) {
            file = File(path);
            name = res!.files.single.name;
          }
      }
    } on Object {
      // إذن مرفوض/منصة بلا قناة — لا انهيار.
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.filesUploadFailed)));
      }
      return;
    }
    if (file == null || name == null || !mounted) return;
    await _upload(file, name);
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
              onPressed: () => _pickAndUpload(_PickSource.camera),
            ),
            ActionChip(
              avatar: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l.filesGallery),
              onPressed: () => _pickAndUpload(_PickSource.gallery),
            ),
            ActionChip(
              avatar: const Icon(Icons.folder_outlined, size: 18),
              label: Text(l.filesDocument),
              onPressed: () => _pickAndUpload(_PickSource.document),
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
                subtitle: a.size == null ? null : Text('${a.size} B'),
              ),
            ),
        ],
      ],
    );
  }
}

enum _PickSource { camera, gallery, document }

class _UploadJob {
  _UploadJob({required this.name});

  final String name;
  final String completeKey = const Uuid().v4();
  double progress = 0;
  bool cancelled = false;
  bool failed = false;
}
