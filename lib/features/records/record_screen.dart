/// شاشة السجل القابلة لإعادة الاستخدام (§21) — نظرة/حقول، إجراءات، تعليقات،
/// مرفقات. التبويبات على قدرات الخلفية الفعلية، لا اختراع.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/step_up_flow.dart';
import '../../l10n/app_localizations.dart';
import '../comments/comments_panel.dart';
import '../files/attachments_panel.dart';
import '../modules/module_repository.dart';
import '../modules/module_schema.dart';
import 'field_display.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.module, required this.id});

  final String module;
  final String id;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  ModuleSchema? _schema;
  RecordData? _record;
  ActionsEnvelope? _actions;
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
      final snapshot = await c.modules.schema();
      final record = await c.modules.show(widget.module, widget.id);
      ActionsEnvelope? actions;
      try {
        actions = await c.modules.actions(widget.module, widget.id);
      } on ApiException {
        // لا إجراءات (صلاحية/حالة) — تبويب الإجراءات يغيب بصدق.
      }
      if (!mounted) return;
      setState(() {
        _schema = snapshot.modules[widget.module];
        _record = record;
        _actions = actions;
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

  Future<void> _runAction(ActionSpec spec) async {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);

    // تمييز الإجراء (§56): هدام ⇒ تأكيد؛ محمي ⇒ إعلام بالتصفيف.
    if (spec.destructive || spec.requiresApproval) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(spec.label),
          content: Text(
            spec.requiresApproval
                ? l.actionNeedsApproval
                : l.actionDestructiveConfirm,
          ),
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
      if (ok != true) return;
    }

    Map<String, dynamic> input = const {};
    if (spec.needs.contains('version')) {
      final version = await _promptText(
        l.recordVersionConflictReload,
        number: true,
      );
      if (version == null) return;
      input = {'version': int.tryParse(version) ?? 0};
    }

    if (!mounted) return;
    try {
      // التصعيد يعالج STEP_UP_REQUIRED ويعيد مرة (§41).
      await runWithStepUp(
        context,
        () => c.modules.runAction(widget.module, widget.id, spec, input: input),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.actionDone)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCode.approvalRequired) {
        _showApprovalQueued(e);
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    }
  }

  void _showApprovalQueued(ApiException e) {
    final l = AppLocalizations.of(context)!;
    final target = e.approvalTarget;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.approvalQueued),
        action: target == null
            ? null
            : SnackBarAction(
                label: l.actionOpen,
                onPressed: () => context.push('/approvals/${target['id']}'),
              ),
      ),
    );
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.recordDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await c.modules.destroy(
        widget.module,
        widget.id,
        ifMatchVersion: _record?.version,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.recordDeleted)));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCode.approvalRequired) {
        _showApprovalQueued(e);
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    }
  }

  Future<String?> _promptText(String title, {bool number = false}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: number ? TextInputType.number : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppLocalizations.of(context)!.actionConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final schema = _schema;
    final record = _record;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || record == null || schema == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module)),
        body: ErrorView(
          error:
              _error ??
              ApiException(
                code: ApiErrorCode.resourceNotFound,
                httpStatus: 404,
                message: l.recordNotFound,
              ),
          onRetry: _load,
        ),
      );
    }

    final hasActions = (_actions?.actions.isNotEmpty ?? false);
    final tabs = [
      Tab(text: l.recordFields),
      if (hasActions) Tab(text: l.recordActions),
      Tab(text: l.recordComments),
      Tab(text: l.recordAttachments),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            record.display(schema),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // إدارة أعضاء العميل (§15) — على سجل العميل لمن يملك تعديله؛
            // الخادم يعيد الفحص (clients:e + hub_scope) في كل نقطة.
            if (widget.module == 'clients' && schema.can.e)
              IconButton(
                tooltip: l.membersTitle,
                icon: const Icon(Icons.group_outlined),
                onPressed: () => context.push(
                  Uri(
                    path: '/clients/${widget.id}/members',
                    queryParameters: {'name': record.display(schema)},
                  ).toString(),
                ),
              ),
            if (schema.can.e)
              IconButton(
                tooltip: l.actionEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context.push('/r/${widget.module}/${widget.id}/edit');
                  _load();
                },
              ),
            if (schema.can.d)
              IconButton(
                tooltip: l.actionDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
          ],
          bottom: TabBar(tabs: tabs, isScrollable: true),
        ),
        body: TabBarView(
          children: [
            _FieldsTab(schema: schema, record: record, actions: _actions),
            if (hasActions) _ActionsTab(envelope: _actions!, onRun: _runAction),
            CommentsPanel(module: widget.module, recordId: widget.id),
            AttachmentsPanel(
              module: widget.module,
              recordId: widget.id,
              schema: schema,
              record: record,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldsTab extends StatelessWidget {
  const _FieldsTab({required this.schema, required this.record, this.actions});

  final ModuleSchema schema;
  final RecordData record;
  final ActionsEnvelope? actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (actions?.status?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(actions!.status!)),
                if (actions!.trashed) Chip(label: Text(l.recordDeleted)),
              ],
            ),
          ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final f in schema.fields)
                ListTile(
                  dense: true,
                  title: Text(
                    f.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodyMedium,
                      child: FieldValueView(field: f, value: record[f.key]),
                    ),
                  ),
                  trailing: f.readonly
                      ? Tooltip(
                          message: l.fieldReadOnly,
                          child: const Icon(Icons.lock_outline, size: 16),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionsTab extends StatelessWidget {
  const _ActionsTab({required this.envelope, required this.onRun});

  final ActionsEnvelope envelope;
  final Future<void> Function(ActionSpec) onRun;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (envelope.actions.isEmpty) {
      return EmptyView(message: l.actionsEmpty);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final a in envelope.actions)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(switch (a.action) {
                'restore' => Icons.restore_from_trash,
                'restore-version' => Icons.history,
                'ack' => Icons.fact_check_outlined,
                _ => Icons.swap_horiz,
              }),
              title: Text(a.label),
              subtitle: a.requiresApproval ? Text(l.actionNeedsApproval) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onRun(a),
            ),
          ),
      ],
    );
  }
}
