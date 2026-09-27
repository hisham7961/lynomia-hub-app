/// تشخيص المطور (§99) — نسخ التطوير فقط، معلومات آمنة، **لا رموز ولا أسرار**.
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/push/push_registrar.dart';
import '../../l10n/app_localizations.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);
    final bootstrap = c.account.bootstrap;

    final rows = <(String, String)>[
      ('APP_ENV', c.env.kind.name),
      (
        'API host',
        c.env.apiBaseUrl.isEmpty ? '—' : Uri.parse(c.env.apiBaseUrl).host,
      ),
      ('mobile_api_version', c.launch.appConfig?.mobileApiVersion ?? '—'),
      ('schema_version', bootstrap?.schemaVersion ?? '—'),
      ('company context', c.viewContext.companyId ?? '—'),
      ('client context', c.viewContext.clientId ?? '—'),
      (
        'session',
        c.session.hasSession
            ? l.diagnosticsSessionActive(c.session.sessionId ?? '—')
            : '—',
      ),
      (
        'push',
        switch (c.push.status) {
          PushSetupStatus.registered => 'registered',
          PushSetupStatus.ready => l.diagnosticsPushReadyNoToken,
          PushSetupStatus.permissionDenied => l.diagnosticsPushPermissionDenied,
          PushSetupStatus.notConfigured => 'NOT_CONFIGURED',
        },
      ),
      ('unread', '${c.account.unreadNotifications}'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.diagnosticsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (k, v) in rows)
            ListTile(
              dense: true,
              title: Text(k, textDirection: TextDirection.ltr),
              subtitle: Text(v, textDirection: TextDirection.ltr),
            ),
        ],
      ),
    );
  }
}
