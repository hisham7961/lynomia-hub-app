/// نسخ السجل (المرحلة ٣.٦) — `GET {module}/{id}/versions` تفعّل إجراء
/// `restore-version` القائم: الاستعادة من الـallowlist ذاته (`runAction`) بعد
/// تأكيد، مع التصعيد والتصفيف للاعتماد كأي إجراء.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../core/ui/feedback.dart';
import '../../core/ui/step_up_flow.dart';
import '../../l10n/app_localizations.dart';
import '../modules/module_repository.dart';

class RecordVersionsScreen extends StatefulWidget {
  const RecordVersionsScreen({
    super.key,
    required this.module,
    required this.id,
  });

  final String module;
  final String id;

  @override
  State<RecordVersionsScreen> createState() => _RecordVersionsScreenState();
}

class _RecordVersionsScreenState extends State<RecordVersionsScreen> {
  RecordVersions? _data;
  Map<String, String> _labels = const {};
  Object? _error;
  bool _loading = true;
  bool _busy = false;

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
      final d = await c.modules.versions(widget.module, widget.id);
      // تسميات الحقول من المخطط (المفاتيح وحدها تأتي من الخادم).
      final schema = c.modules.lastSchema?.modules[widget.module];
      if (!mounted) return;
      setState(() {
        _data = d;
        _labels = {for (final f in schema?.fields ?? const []) f.key: f.label};
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore(RecordVersionItem v) async {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);
    final ok = await confirmDialog(
      context,
      message: l.versionsRestoreConfirm(v.version),
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final spec = ActionSpec(
      action: _data?.restoreAction ?? 'restore-version',
      label: l.versionsRestore,
      needs: const ['version'],
    );
    final key = const Uuid().v4();
    try {
      await runWithStepUp(
        context,
        () => c.modules.runAction(
          widget.module,
          widget.id,
          spec,
          input: {'version': v.version},
          idempotencyKey: key,
        ),
      );
      if (!mounted) return;
      showSnack(context, l.versionsRestored(v.version));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCode.approvalRequired) {
        final target = e.approvalTarget;
        showSnack(
          context,
          l.approvalQueued,
          action: target == null
              ? null
              : SnackBarAction(
                  label: l.actionOpen,
                  onPressed: () => context.push('/approvals/${target['id']}'),
                ),
        );
      } else {
        showErrorSnack(context, e);
      }
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.versionsTitle)),
      body: AsyncView<RecordVersions>(
        loading: _loading,
        error: _error,
        value: _data,
        onRetry: _load,
        emptyWhen: (d) => d.versions.isEmpty,
        emptyMessage: l.versionsEmpty,
        builder: (context, d) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            itemCount: d.versions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final v = d.versions[i];
              final changed = v.changed;
              return ListTile(
                key: Key('version-${v.version}'),
                leading: CircleAvatar(child: Text('${v.version}')),
                title: Text(
                  [
                    if (v.at != null)
                      '${formatShortDate(v.at!, locale)} ${formatShortTime(v.at!, locale)}',
                    ?v.by?.name,
                  ].join(' · '),
                ),
                subtitle: Text(
                  v.current
                      ? l.versionsCurrent
                      : changed == null
                      ? l.versionsOldest
                      : changed.isEmpty
                      ? l.versionsNoVisibleChange
                      : l.versionsChanged(
                          changed
                              .map((k) => _labels[k] ?? k)
                              .join(l.listSeparator),
                        ),
                ),
                trailing: v.restorable
                    ? TextButton(
                        key: Key('version-restore-${v.version}'),
                        onPressed: _busy ? null : () => _restore(v),
                        child: Text(l.versionsRestore),
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
