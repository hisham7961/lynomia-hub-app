/// شاشة تفعيل حساب العميل (§13) — يلتقطها الرابط العميق `activate/{token}`.
///
/// التدفق: فحص الرمز (بريد مقنَّع، حالة صادقة pending/expired) ⇒ نموذج
/// «رمز + كلمة يضعها العميل» ⇒ إتمام ذرّي ⇒ توجيه لشاشة الدخول ببريده
/// الكامل معبأً. كلمة ضعيفة لا تحرق الرمز (يُعاد الإدخال)، والكلمة لا
/// تُسجَّل ولا تُخزَّن محلياً.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'activation_repository.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key, required this.token});

  final String token;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _form = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  ActivationStatus? _status;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await AppScope.of(context).activation.check(widget.token);
      if (mounted) setState(() => _status = s);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _submitError = null;
    });
    final c = AppScope.of(context);
    try {
      final result = await c.activation.complete(
        token: widget.token,
        otp: _otp.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      // الدخول عبر السكّة الواحدة — البريد الكامل يُكشف بعد الإثبات فقط.
      context.go(
        Uri(
          path: '/login',
          queryParameters: {'email': result.email, 'activated': '1'},
        ).toString(),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.details['reason']?.toString() == 'expired') {
        setState(
          () => _status = const ActivationStatus(
            status: 'expired',
            emailMasked: '',
          ),
        );
      } else {
        setState(() => _submitError = describeError(context, e));
      }
    } on Object catch (e) {
      if (mounted) setState(() => _submitError = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.activationTitle)),
      body: AsyncView<ActivationStatus>(
        loading: _loading,
        error: _error,
        value: _status,
        onRetry: _check,
        builder: (context, status) => status.expired
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_disabled, size: 40),
                      const SizedBox(height: 12),
                      Text(l.activationExpired, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.activationIntro(status.emailMasked),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _otp,
                        decoration: InputDecoration(
                          labelText: l.activationOtp,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.loginRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: l.activationPassword,
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l.loginRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        decoration: InputDecoration(
                          labelText: l.activationPasswordConfirm,
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (v) => v != _password.text
                            ? l.activationPasswordMismatch
                            : null,
                      ),
                      if (_submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _submitError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l.activationSubmit),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
