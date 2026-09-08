/// الدخول + MFA (§32 §33) — تدفق العقد الفعلي، والتفريع على `code` حصراً.
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  bool _busy = false;
  String? _error;
  LoginMfaChallenge? _challenge;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (_challenge == null && !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final c = AppScope.of(context);
    try {
      final LoginOutcome outcome;
      if (_challenge == null) {
        outcome = await c.auth.login(
          email: _email.text.trim(),
          password: _password.text,
          locale: Localizations.localeOf(context).languageCode,
          timezone: DateTime.now().timeZoneName,
        );
      } else {
        outcome = await c.auth.mfaVerify(
          challengeId: _challenge!.challengeId,
          code: _code.text.trim(),
        );
      }
      if (!mounted) return;
      switch (outcome) {
        case final LoginMfaChallenge challenge:
          setState(() => _challenge = challenge);
        case LoginSession(:final tokens):
          final platform = Theme.of(context).platform == TargetPlatform.iOS
              ? 'ios'
              : 'android';
          await c.session.adopt(tokens);
          await c.launch.onSignedIn();
          // تسجيل الدفع إن كان المزود مهيأ — صامت وصادق (§74).
          await c.push.registerIfPossible(platform: platform);
      }
    } on ApiException catch (e) {
      setState(() {
        if (_challenge != null && e.code == ApiErrorCode.mfaRequired) {
          // رمز خاطئ ضمن التحدي الحي — يبقى في شاشة الرمز.
          _error = e.message.isNotEmpty ? e.message : l.mfaHint;
        } else if (_challenge != null) {
          // انتهت مهلة التحدي — عودة لبيانات الدخول.
          _challenge = null;
          _error = l.mfaExpired;
        } else {
          _error = describeError(context, e);
        }
      });
    } on NetworkException {
      setState(() => _error = l.errNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mfa = _challenge != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FlutterLogo(size: 56),
                    const SizedBox(height: 16),
                    Text(
                      mfa ? l.mfaTitle : l.loginTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (!mfa) ...[
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l.loginEmail,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l.loginRequired;
                          }
                          if (!v.contains('@')) return l.loginInvalidEmail;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l.loginPassword,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l.loginRequired : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ] else ...[
                      Text(l.mfaHint, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _code,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        decoration: InputDecoration(
                          labelText: l.mfaCode,
                          border: const OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(mfa ? l.actionConfirm : l.actionLogin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
