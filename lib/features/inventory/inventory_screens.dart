/// شاشات الجرد (المرحلة ٣.٤): القائمة والتجميد، والتفصيل بالعدّ والأصناف
/// والمسحات، والمسح المتتابع بالماسح القائم (`ScanViewBuilder`)، والمصالحة
/// والإغلاق خلف تصعيد الهوية (`runWithStepUp`).
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
import '../scanner/scanner_screen.dart';
import 'inventory_repository.dart';

class InventorySessionsScreen extends StatefulWidget {
  const InventorySessionsScreen({super.key});

  @override
  State<InventorySessionsScreen> createState() =>
      _InventorySessionsScreenState();
}

class _InventorySessionsScreenState extends State<InventorySessionsScreen> {
  InventoryList? _data;
  Object? _error;
  bool _loading = true;
  bool _freezing = false;

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
    try {
      final d = await AppScope.of(context).inventory.sessions();
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _freeze() async {
    final l = AppLocalizations.of(context)!;
    final ok = await confirmDialog(context, message: l.inventoryFreezeConfirm);
    if (!ok || !mounted) return;
    setState(() => _freezing = true);
    try {
      final res = await AppScope.of(context).inventory
          .freeze(idempotencyKey: const Uuid().v4());
      if (!mounted) return;
      showSnack(context, l.inventoryFrozen(res.frozen));
      await context.push('/inventory/${res.session.id}');
      if (mounted) _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      // سياق شركةٍ غير معروف (ترويسة X-Lynomia-Company) — سببٌ آلي.
      e.details['reason'] == 'unknown_company'
          ? showSnack(context, l.inventoryUnknownCompany)
          : showErrorSnack(context, e);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _freezing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.inventoryTitle)),
      floatingActionButton: (_data?.can.freeze ?? false)
          ? FloatingActionButton.extended(
              key: const Key('inventory-freeze'),
              onPressed: _freezing ? null : _freeze,
              icon: const Icon(Icons.ac_unit),
              label: Text(l.inventoryFreeze),
            )
          : null,
      body: AsyncView<InventoryList>(
        loading: _loading,
        error: _error,
        value: _data,
        onRetry: _load,
        emptyWhen: (d) => d.sessions.isEmpty,
        emptyMessage: l.inventoryEmpty,
        builder: (context, d) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: d.sessions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = d.sessions[i];
              return ListTile(
                key: Key('inventory-session-${s.id}'),
                leading: Icon(
                  s.open ? Icons.qr_code_scanner : Icons.lock_outline,
                ),
                title: Text(
                  [
                    s.status,
                    if (s.createdAt != null)
                      formatShortDate(s.createdAt!, locale),
                  ].join(' · '),
                ),
                subtitle: Text(
                  l.inventorySessionMeta(
                    s.itemsCount ?? 0,
                    s.scansCount ?? 0,
                    s.byName ?? '',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/inventory/${s.id}');
                  if (mounted) _load();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class InventorySessionScreen extends StatefulWidget {
  const InventorySessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<InventorySessionScreen> createState() => _InventorySessionScreenState();
}

class _InventorySessionScreenState extends State<InventorySessionScreen> {
  InventoryDetail? _data;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  int _page = 1;

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
    try {
      final d = await AppScope.of(context).inventory
          .session(widget.sessionId, page: _page);
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// فعلٌ خلف التصعيد: مفتاحٌ واحد للفعل عبر محاولة التصعيد وإعادتها.
  Future<void> _stepUpAction({
    required String confirm,
    required Future<Object?> Function(String key) op,
    required String done,
  }) async {
    final ok = await confirmDialog(context, message: confirm);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final key = const Uuid().v4();
    try {
      await runWithStepUp(context, () => op(key));
      if (!mounted) return;
      showSnack(context, done);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).inventory;
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.inventorySession),
        actions: [
          if (d != null && d.can.reconcile)
            IconButton(
              key: const Key('inventory-reconcile'),
              tooltip: l.inventoryReconcile,
              icon: const Icon(Icons.rule),
              onPressed: _busy
                  ? null
                  : () => _stepUpAction(
                      confirm: l.inventoryReconcileConfirm,
                      op: (k) =>
                          repo.reconcile(widget.sessionId, idempotencyKey: k),
                      done: l.inventoryReconciled,
                    ),
            ),
          if (d != null && d.can.close)
            IconButton(
              key: const Key('inventory-close'),
              tooltip: l.inventoryClose,
              icon: const Icon(Icons.lock_outline),
              onPressed: _busy
                  ? null
                  : () => _stepUpAction(
                      confirm: l.inventoryCloseConfirm,
                      op: (k) =>
                          repo.close(widget.sessionId, idempotencyKey: k),
                      done: l.inventoryClosed,
                    ),
            ),
        ],
      ),
      floatingActionButton: (d?.can.scan ?? false)
          ? FloatingActionButton.extended(
              key: const Key('inventory-scan'),
              onPressed: () async {
                await context.push('/inventory/${widget.sessionId}/scan');
                if (mounted) _load();
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l.inventoryScan),
            )
          : null,
      body: AsyncView<InventoryDetail>(
        loading: _loading,
        error: _error,
        value: d,
        onRetry: _load,
        builder: (context, d) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(label: Text(d.session.status)),
                  for (final e in d.session.counts.entries)
                    Chip(
                      key: Key('inventory-count-${e.key}'),
                      label: Text('${e.key}: ${e.value}'),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  l.inventoryItems(d.itemsTotal),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final it in d.items)
                      ListTile(
                        dense: true,
                        title: Text(it.name.isEmpty ? it.code : it.name),
                        subtitle: Text([it.code, ?it.type].join(' · ')),
                        // الحكم تسميةٌ خادمية تُعرض كما هي.
                        trailing: Text(it.verdict),
                        onTap: it.assetId.isEmpty
                            ? null
                            : () => context.push('/r/assets/${it.assetId}'),
                      ),
                  ],
                ),
              ),
              if (d.lastPage > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page > 1
                          ? () {
                              _page--;
                              _load();
                            }
                          : null,
                    ),
                    Text(l.pageOf(d.page, d.lastPage)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page < d.lastPage
                          ? () {
                              _page++;
                              _load();
                            }
                          : null,
                    ),
                  ],
                ),
              if (d.scans.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    l.inventoryRecentScans,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      for (final s in d.scans)
                        ListTile(
                          dense: true,
                          // المحلول داخل النطاق له أصلٌ ورمز؛ غيره بلا أيٍّ منهما.
                          leading: Icon(
                            s.assetId == null
                                ? Icons.block
                                : Icons.check_circle_outline,
                          ),
                          title: Text(s.code ?? l.inventoryUnknownCode),
                          subtitle: Text([s.result, ?s.byName].join(' · ')),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// المسح المتتابع: كل رمزٍ يُرسل للمحلِّل الخادمي ويُعرض حكمه، والرمز نفسه لا
/// يُعاد إرساله خلال ثانيتين (الكاميرا تقرؤه مرات).
class InventoryScanScreen extends StatefulWidget {
  const InventoryScanScreen({
    super.key,
    required this.sessionId,
    this.scanView = cameraScanView,
  });

  final String sessionId;
  final ScanViewBuilder scanView;

  @override
  State<InventoryScanScreen> createState() => _InventoryScanScreenState();
}

class _InventoryScanScreenState extends State<InventoryScanScreen> {
  bool _sending = false;
  String? _lastCode;
  DateTime? _lastAt;
  InventoryScanResult? _result;
  String? _error;
  int _count = 0;

  Future<void> _onCode(String code) async {
    final now = DateTime.now();
    if (_sending || code.isEmpty) return;
    if (code == _lastCode &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastCode = code;
    _lastAt = now;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final r = await AppScope.of(context).inventory
          .scan(widget.sessionId, code, idempotencyKey: const Uuid().v4());
      if (mounted) {
        setState(() {
          _result = r;
          _count++;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(
        () => _error = e.details['reason'] == 'session_closed'
            ? l.inventorySessionClosed
            : describeError(context, e),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final r = _result;
    final text =
        _error ??
        (_sending
            ? l.stateLoading
            : r == null
            ? l.inventoryScanHint
            : switch (r.resultKey) {
                'known' => l.inventoryScanKnown(
                  r.assetName ?? r.assetCode ?? '',
                ),
                'unexpected' => l.inventoryScanUnexpected(
                  r.assetName ?? r.assetCode ?? '',
                ),
                _ => l.inventoryScanUnknown,
              });
    return Scaffold(
      appBar: AppBar(title: Text(l.inventoryScanCount(_count))),
      body: Stack(
        children: [
          widget.scanView(context, _onCode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                text,
                key: const Key('inventory-scan-result'),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
