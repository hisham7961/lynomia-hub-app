/// تدفق التصعيد (§41): عملية ترد `STEP_UP_REQUIRED` ⇒ حوار اعتماد آمن ⇒
/// `auth/step-up` بالغرض المرفق ⇒ إعادة العملية مرة واحدة. لا رفع صلاحية دائم.
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../errors/api_exception.dart';

Future<T> runWithStepUp<T>(
  BuildContext context,
  Future<T> Function() operation,
) async {
  try {
    return await operation();
  } on ApiException catch (e) {
    if (e.code != ApiErrorCode.stepUpRequired || !context.mounted) rethrow;
    final purpose = e.details['purpose']?.toString() ?? '';
    final method = e.details['method']?.toString() ?? 'password';
    final granted = await _promptAndGrant(
      context,
      purpose: purpose,
      method: method,
    );
    if (!granted) rethrow;
    return operation(); // المنحة مثبتة خادمياً — إعادة واحدة
  }
}

Future<bool> _promptAndGrant(
  BuildContext context, {
  required String purpose,
  required String method,
}) async {
  final container = AppScope.of(context);
  final credential = await showDialog<String>(
    context: context,
    builder: (ctx) => _StepUpDialog(method: method),
  );
  if (credential == null || credential.isEmpty) return false;
  try {
    await container.auth.stepUp(purpose: purpose, credential: credential);
    return true;
  } on ApiException {
    return false;
  }
}

class _StepUpDialog extends StatefulWidget {
  const _StepUpDialog({required this.method});

  final String method;

  @override
  State<_StepUpDialog> createState() => _StepUpDialogState();
}

class _StepUpDialogState extends State<_StepUpDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isTotp = widget.method == 'totp';
    return AlertDialog(
      title: Text(l.stepUpTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isTotp ? l.stepUpTotp : l.stepUpPassword),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: !isTotp,
            keyboardType: isTotp ? TextInputType.number : null,
            autofillHints: isTotp ? const [AutofillHints.oneTimeCode] : null,
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l.actionConfirm),
        ),
      ],
    );
  }
}
