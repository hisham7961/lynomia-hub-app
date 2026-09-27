/// محررات الحقول (§20) — كل نوع مخطط له محرر جوال:
/// text/url/sec ⇒ نص · ta ⇒ متعدد أسطر · num ⇒ رقمي · date/dt ⇒ منتقيات ·
/// bool ⇒ مفتاح · sel ⇒ قائمة/رقائق · ref ⇒ منتقي مرجع خادمي · tags ⇒ رقائق ·
/// file/img ⇒ تدار من تبويب المرفقات (لا حذف صامت — ملاحظة صريحة).
/// readonly من قناع الخادم يعرض معطلاً (§20).
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../modules/module_repository.dart';
import '../modules/module_schema.dart';
import 'field_display.dart';

class FieldEditor extends StatelessWidget {
  const FieldEditor({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onSaved,
    this.serverError,
  });

  final FieldSpec field;
  final Object? initialValue;
  final void Function(Object?) onSaved;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (field.readonly) {
      return InputDecorator(
        decoration: _decoration(context).copyWith(
          suffixIcon: Tooltip(
            message: l.fieldReadOnly,
            child: const Icon(Icons.lock_outline, size: 18),
          ),
        ),
        child: FieldValueView(field: field, value: initialValue),
      );
    }

    switch (field.type) {
      case 'ta':
        return _text(context, maxLines: 4);
      case 'num':
        return _text(
          context,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          ltr: true,
        );
      case 'url':
        return _text(context, keyboardType: TextInputType.url, ltr: true);
      case 'sec':
        return _text(context, obscure: true, ltr: true);
      case 'bool':
        return FormField<bool>(
          initialValue:
              initialValue == true || initialValue == 1 || initialValue == '1',
          onSaved: (v) => onSaved(v ?? false),
          builder: (state) => SwitchListTile(
            title: Text(field.label),
            subtitle: serverError != null
                ? Text(
                    serverError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : (field.hint != null ? Text(field.hint!) : null),
            value: state.value ?? false,
            onChanged: state.didChange,
            contentPadding: EdgeInsets.zero,
          ),
        );
      case 'date':
      case 'dt':
        return _DateEditor(
          field: field,
          initialValue: initialValue,
          onSaved: onSaved,
          decoration: _decoration(context),
          withTime: field.type == 'dt',
        );
      case 'sel':
        return field.multi
            ? _MultiSelectEditor(
                field: field,
                initialValue: initialValue,
                onSaved: onSaved,
                decoration: _decoration(context),
              )
            : _singleSelect(context);
      case 'tags':
        return _TagsEditor(
          field: field,
          initialValue: initialValue,
          onSaved: onSaved,
          decoration: _decoration(context),
        );
      case 'ref':
        return _RefEditor(
          field: field,
          initialValue: initialValue,
          onSaved: onSaved,
          decoration: _decoration(context),
        );
      case 'file':
      case 'img':
        // لا يُسقط الحقل صامتاً (§20): يُعرض بقيمته وملاحظة مسار الإدارة.
        return InputDecorator(
          decoration: _decoration(context)
              .copyWith(helperText: l.fieldAttachmentViaTab),
          child: FieldValueView(field: field, value: initialValue),
        );
      default: // text وأي نوع مجهول مستقبلي — محرر نصي آمن (§93)
        return _text(context);
    }
  }

  InputDecoration _decoration(BuildContext context) => InputDecoration(
    labelText: field.label + (field.required ? ' *' : ''),
    helperText: field.hint,
    errorText: serverError,
    border: const OutlineInputBorder(),
  );

  Widget _text(
    BuildContext context, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool obscure = false,
    bool ltr = false,
  }) {
    final l = AppLocalizations.of(context)!;
    return TextFormField(
      initialValue: initialValue?.toString() ?? '',
      maxLines: obscure ? 1 : maxLines,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: ltr ? TextDirection.ltr : null,
      decoration: _decoration(context),
      validator: (v) => field.required && (v == null || v.trim().isEmpty)
          ? l.fieldRequired(field.label)
          : null,
      onSaved: (v) => onSaved(v?.trim() ?? ''),
    );
  }

  Widget _singleSelect(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = field.options ?? const [];
    final current = initialValue?.toString();
    return DropdownButtonFormField<String>(
      initialValue: options.contains(current) ? current : null,
      decoration: _decoration(context),
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      validator: (v) => field.required && (v == null || v.isEmpty)
          ? l.fieldRequired(field.label)
          : null,
      onChanged: (_) {},
      onSaved: onSaved,
    );
  }
}

class _DateEditor extends StatefulWidget {
  const _DateEditor({
    required this.field,
    required this.initialValue,
    required this.onSaved,
    required this.decoration,
    required this.withTime,
  });

  final FieldSpec field;
  final Object? initialValue;
  final void Function(Object?) onSaved;
  final InputDecoration decoration;
  final bool withTime;

  @override
  State<_DateEditor> createState() => _DateEditorState();
}

class _DateEditorState extends State<_DateEditor> {
  DateTime? _value;

  @override
  void initState() {
    super.initState();
    _value = DateTime.tryParse(widget.initialValue?.toString() ?? '');
  }

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    var result = date;
    if (widget.withTime) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_value ?? DateTime.now()),
      );
      if (time != null) {
        result = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
    setState(() => _value = result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FormField<DateTime>(
      validator: (_) => widget.field.required && _value == null
          ? l.fieldRequired(widget.field.label)
          : null,
      onSaved: (_) {
        if (_value == null) {
          widget.onSaved(null);
        } else if (widget.withTime) {
          widget.onSaved(_value!.toIso8601String());
        } else {
          final d = _value!;
          widget.onSaved(
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          );
        }
      },
      builder: (state) => InkWell(
        onTap: _pick,
        child: InputDecorator(
          decoration: widget.decoration.copyWith(
            errorText: widget.decoration.errorText ?? state.errorText,
            suffixIcon: const Icon(Icons.event),
          ),
          child: Text(
            _value == null
                ? l.fieldPickDate
                : FieldValueViewText.format(context, _value!, widget.withTime),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

/// تنسيق تاريخ للعرض داخل المحرر.
abstract final class FieldValueViewText {
  static String format(BuildContext context, DateTime value, bool withTime) {
    final d = value.toLocal();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (!withTime) return date;
    return '$date ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _MultiSelectEditor extends StatefulWidget {
  const _MultiSelectEditor({
    required this.field,
    required this.initialValue,
    required this.onSaved,
    required this.decoration,
  });

  final FieldSpec field;
  final Object? initialValue;
  final void Function(Object?) onSaved;
  final InputDecoration decoration;

  @override
  State<_MultiSelectEditor> createState() => _MultiSelectEditorState();
}

class _MultiSelectEditorState extends State<_MultiSelectEditor> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue;
    _selected = init is List
        ? init.map((e) => e.toString()).toSet()
        : (init?.toString().isNotEmpty ?? false)
        ? {init.toString()}
        : {};
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FormField<Set<String>>(
      validator: (_) => widget.field.required && _selected.isEmpty
          ? l.fieldRequired(widget.field.label)
          : null,
      onSaved: (_) => widget.onSaved(_selected.toList()),
      builder: (state) => InputDecorator(
        decoration: widget.decoration.copyWith(
          errorText: widget.decoration.errorText ?? state.errorText,
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in widget.field.options ?? const <String>[])
              FilterChip(
                label: Text(o),
                selected: _selected.contains(o),
                onSelected: (on) =>
                    setState(() => on ? _selected.add(o) : _selected.remove(o)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagsEditor extends StatefulWidget {
  const _TagsEditor({
    required this.field,
    required this.initialValue,
    required this.onSaved,
    required this.decoration,
  });

  final FieldSpec field;
  final Object? initialValue;
  final void Function(Object?) onSaved;
  final InputDecoration decoration;

  @override
  State<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<_TagsEditor> {
  late final List<String> _tags;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue;
    _tags = init is List
        ? init.map((e) => e.toString()).toList()
        : (init?.toString() ?? '')
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    setState(() {
      if (!_tags.contains(t)) _tags.add(t);
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) => FormField<List<String>>(
    onSaved: (_) => widget.onSaved(_tags),
    builder: (state) => InputDecorator(
      decoration: widget.decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in _tags)
                InputChip(
                  label: Text(t),
                  onDeleted: () => setState(() => _tags.remove(t)),
                ),
            ],
          ),
          TextField(
            controller: _input,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onSubmitted: _add,
          ),
        ],
      ),
    ),
  );
}

/// منتقي مرجع خادمي (§19): يبحث في وحدة `ref` عبر المحرك العام ويخزن المعرف.
class _RefEditor extends StatefulWidget {
  const _RefEditor({
    required this.field,
    required this.initialValue,
    required this.onSaved,
    required this.decoration,
  });

  final FieldSpec field;
  final Object? initialValue;
  final void Function(Object?) onSaved;
  final InputDecoration decoration;

  @override
  State<_RefEditor> createState() => _RefEditorState();
}

class _RefEditorState extends State<_RefEditor> {
  late List<({String id, String name})> _selected;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue;
    final ids = init is List
        ? init.map((e) => e.toString()).toList()
        : (init?.toString().isNotEmpty ?? false)
        ? [init.toString()]
        : <String>[];
    _selected = [for (final id in ids) (id: id, name: id)];
  }

  Future<void> _pick() async {
    final picked = await showModalBottomSheet<({String id, String name})>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => RefPickerSheet(refModule: widget.field.ref!),
    );
    if (picked == null) return;
    setState(() {
      if (widget.field.multi) {
        if (!_selected.any((s) => s.id == picked.id)) _selected.add(picked);
      } else {
        _selected = [picked];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FormField<List<String>>(
      validator: (_) => widget.field.required && _selected.isEmpty
          ? l.fieldRequired(widget.field.label)
          : null,
      onSaved: (_) => widget.onSaved(
        widget.field.multi
            ? _selected.map((s) => s.id).toList()
            : (_selected.isEmpty ? null : _selected.first.id),
      ),
      builder: (state) => InkWell(
        onTap: widget.field.ref == null ? null : _pick,
        child: InputDecorator(
          decoration: widget.decoration.copyWith(
            errorText: widget.decoration.errorText ?? state.errorText,
            suffixIcon: const Icon(Icons.manage_search),
          ),
          child: _selected.isEmpty
              ? Text(l.fieldPickReference(widget.field.ref ?? ''))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in _selected)
                      InputChip(
                        label: Text(s.name),
                        onDeleted: () => setState(
                          () => _selected.removeWhere((x) => x.id == s.id),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// يفتح [RefPickerSheet] ويعيد الاختيار.
Future<({String id, String name})?> pickReference(
  BuildContext context,
  String refModule,
) => showModalBottomSheet<({String id, String name})>(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => RefPickerSheet(refModule: refModule),
);

/// منتقي سجلٍّ من وحدةٍ مرجعية (بحثٌ خادمي) — يُعيد `(id, name)` أو null.
/// عامٌّ ليُستعمل خارج النموذج (مستلم العهدة، عضو القناة).
class RefPickerSheet extends StatefulWidget {
  const RefPickerSheet({super.key, required this.refModule});

  final String refModule;

  @override
  State<RefPickerSheet> createState() => RefPickerSheetState();
}

class RefPickerSheetState extends State<RefPickerSheet> {
  List<RecordData> _records = const [];
  ModuleSchema? _schema;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final c = AppScope.of(context);
    try {
      final snapshot = await c.modules.schema();
      final page = await c.modules.list(widget.refModule, q: q.trim(), per: 30);
      if (!mounted) return;
      setState(() {
        _schema = snapshot.modules[widget.refModule];
        _records = page.items;
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.moduleSearchHint(
                  _schema?.label ?? widget.refModule,
                ),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ErrorView(error: _error!, onRetry: () => _search(''))
                : _records.isEmpty
                ? const EmptyView()
                : ListView.builder(
                    controller: scroll,
                    itemCount: _records.length,
                    itemBuilder: (context, i) {
                      final r = _records[i];
                      final name = _schema == null ? r.id : r.display(_schema!);
                      return ListTile(
                        title: Text(name),
                        onTap: () =>
                            Navigator.pop(context, (id: r.id, name: name)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
