/// نموذج السجل العام (§19 §20 §96) — يُبنى من المخطط بكل الأنواع المبثوثة،
/// تحقق عميل للتجربة والخادم حاسم (422 بجانب الحقل)، وIf-Match على التعديل
/// مع مسار حل صريح لتعارض النسخة (§57).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../modules/module_repository.dart';
import '../modules/module_schema.dart';
import 'field_editors.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, required this.module, this.recordId});

  final String module;

  /// null = إنشاء.
  final String? recordId;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _form = GlobalKey<FormState>();

  ModuleSchema? _schema;
  RecordData? _existing;
  final Map<String, Object?> _values = {};
  Map<String, List<String>> _serverErrors = const {};
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  /// مفتاح idempotency ثابت لعملية الحفظ الواحدة عبر إعادة المحاولة (§58)؛
  /// يتجدد بعد نجاح أو تعديل جديد.
  String _opKey = const Uuid().v4();

  bool get isEdit => widget.recordId != null;

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
    final c = AppScope.of(context);
    try {
      final snapshot = await c.modules.schema();
      final schema = snapshot.modules[widget.module];
      RecordData? existing;
      if (isEdit) {
        existing = await c.modules.show(widget.module, widget.recordId!);
      }
      if (!mounted) return;
      setState(() {
        _schema = schema;
        _existing = existing;
        _values.clear();
        if (existing != null && schema != null) {
          for (final f in schema.fields) {
            _values[f.key] = existing[f.key];
          }
        }
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!(_form.currentState?.validate() ?? false)) return;
    _form.currentState?.save();
    final schema = _schema!;
    setState(() {
      _saving = true;
      _serverErrors = const {};
    });
    final c = AppScope.of(context);

    // يُرسل القابل للكتابة فقط — file/img تدار من المرفقات، وreadonly لا يُبث.
    final body = <String, dynamic>{};
    for (final f in schema.fields) {
      if (f.readonly || f.type == 'file' || f.type == 'img') continue;
      final v = _values[f.key];
      if (!isEdit && (v == null || (v is String && v.isEmpty))) continue;
      body[f.key] = v;
    }

    try {
      if (isEdit) {
        await c.modules.update(
          widget.module,
          widget.recordId!,
          body,
          ifMatchVersion: _existing?.version,
        );
      } else {
        await c.modules.create(widget.module, body, idempotencyKey: _opKey);
      }
      if (!mounted) return;
      _opKey = const Uuid().v4();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? l.recordSaved : l.recordCreated)),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case ApiErrorCode.validationFailed:
          // 422 خادمية بجانب حقولها (§96).
          setState(() => _serverErrors = e.fieldErrors);
          _form.currentState?.validate();
        case ApiErrorCode.versionConflict:
          await _onVersionConflict(e);
        case ApiErrorCode.approvalRequired:
          // الكتابة المحمية صُفّت طلباً حقيقياً (§54) — ليس فشلاً.
          final target = e.approvalTarget;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.approvalQueued),
              action: target == null
                  ? null
                  : SnackBarAction(
                      label: l.actionOpen,
                      onPressed: () =>
                          context.push('/approvals/${target['id']}'),
                    ),
            ),
          );
          context.pop();
        default:
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(describeError(context, e))));
      }
    } on NetworkException {
      if (!mounted) return;
      // المفتاح نفسه يبقى — إعادة المحاولة لا تنشئ سجلين (§58).
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.errNetwork)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// تعارض نسخة (§57): لا كتابة صامتة فوق تعديل الغير — تحديث ثم إعادة تحرير.
  Future<void> _onVersionConflict(ApiException e) async {
    final l = AppLocalizations.of(context)!;
    final reload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.recordVersionConflictTitle),
        content: Text(l.recordVersionConflictBody('${e.serverVersion ?? '?'}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.recordVersionConflictReload),
          ),
        ],
      ),
    );
    if (reload == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final schema = _schema;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (schema == null || _error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module)),
        body: ErrorView(
          error:
              _error ??
              ApiException(
                code: ApiErrorCode.forbidden,
                httpStatus: 403,
                message: l.recordNoAccess,
              ),
          onRetry: _load,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isEdit ? l.actionEdit : l.actionCreate} · ${schema.label}',
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.actionSave),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final f in schema.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FieldEditor(
                  field: f,
                  initialValue: _values[f.key],
                  serverError: _serverErrors[f.key]?.join('\n'),
                  onSaved: (v) => _values[f.key] = v,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
