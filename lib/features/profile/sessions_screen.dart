/// جلسات الجوال (§39) — قائمة الجلسات وإبطال جلسة أخرى مملوكة.
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<MobileSessionInfo>? _sessions;
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
    final c = AppScope.of(context);
    try {
      final sessions = await c.auth.sessions(currentId: c.session.sessionId);
      if (mounted) setState(() => _sessions = sessions);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(MobileSessionInfo s) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.accountSessionRevoke),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).auth.revokeSession(s.id);
      await _load();
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.accountSessions)),
      body: AsyncView<List<MobileSessionInfo>>(
        loading: _loading,
        error: _error,
        value: _sessions,
        onRetry: _load,
        emptyWhen: (s) => s.isEmpty,
        builder: (context, sessions) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final s = sessions[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    s.platform == 'ios'
                        ? Icons.phone_iphone
                        : Icons.phone_android,
                  ),
                  title: Text(
                    [
                      s.platform ?? l.unknownInitial,
                      if (s.appVersion != null) 'v${s.appVersion}',
                    ].join(' · '),
                  ),
                  subtitle: Text(
                    [
                      if (s.current) l.accountSessionCurrent,
                      if (s.lastUsedAt != null)
                        MaterialLocalizations.of(context)
                            .formatShortDate(s.lastUsedAt!.toLocal()),
                    ].join(' · '),
                  ),
                  trailing: s.current
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : IconButton(
                          tooltip: l.accountSessionRevoke,
                          icon: const Icon(Icons.link_off),
                          onPressed: () => _revoke(s),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
