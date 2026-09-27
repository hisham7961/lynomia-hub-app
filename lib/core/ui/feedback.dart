/// تغذية راجعة موحّدة للأفعال (§83): شريط رسالة، وحوار تأكيد، وحوار نصٍّ
/// (سبب/ملاحظة) بتحقّقٍ محلي للإلزام — والخادم يعيد الفحص دائماً.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'async_view.dart';

void showSnack(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));
}

/// خطأ مكتوب ⇒ نصّ عرضٍ من `code` (مع رسالة الخادم حيث تكون أدق).
void showErrorSnack(BuildContext context, Object error) =>
    showSnack(context, describeError(context, error));

Future<bool> confirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  String? confirmLabel,
}) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          key: const Key('confirm-ok'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? l.actionConfirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// حوار نصٍّ: `required` ⇒ لا يُقبل فارغاً (رسالة محلية) — null عند الإلغاء.
Future<String?> promptTextDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String initial = '',
  bool required = false,
  int maxLines = 3,
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _PromptDialog(
      title: title,
      hint: hint,
      initial: initial,
      required: required,
      maxLines: maxLines,
      maxLength: maxLength,
    ),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    this.hint,
    required this.initial,
    required this.required,
    required this.maxLines,
    this.maxLength,
  });

  final String title;
  final String? hint;
  final String initial;
  final bool required;
  final int maxLines;
  final int? maxLength;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppLocalizations.of(context)!;
    final v = _c.text.trim();
    if (widget.required && v.isEmpty) {
      setState(() => _error = l.fieldValueRequired);
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('prompt-input'),
        controller: _c,
        autofocus: true,
        minLines: 1,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        decoration: InputDecoration(hintText: widget.hint, errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          key: const Key('prompt-ok'),
          onPressed: _submit,
          child: Text(l.actionConfirm),
        ),
      ],
    );
  }
}
