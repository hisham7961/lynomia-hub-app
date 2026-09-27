/// قائمة الوحدة العامة (§19) — أي وحدة يبثها المخطط: بحث، فرز، ترقيم لانهائي،
/// إنشاء حيث `can.a`، وسقوط للخبيئة المشفرة عند الانقطاع للوحدات القابلة (§60).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'module_repository.dart';
import 'module_schema.dart';

class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({super.key, required this.module});

  final String module;

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();

  ModuleSchema? _schema;
  final List<RecordData> _records = [];
  CachedModule? _cachedFallback;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _query = '';
  String? _sort;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    final c = AppScope.of(context);
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _cachedFallback = null;
        _page = 1;
      });
    }
    try {
      final snapshot = await c.modules.schema();
      final schema = snapshot.modules[widget.module];
      final page = await c.modules.list(
        widget.module,
        page: _page,
        q: _query,
        sort: _sort,
      );
      if (!mounted) return;
      // القائمة الحية نجحت ⇒ تحديث الخبيئة في الخلفية للوحدات القابلة فقط
      // (`CACHEABLE_*` من المخطط؛ الحساس لا يُطلب ويُمحى أثره) — §60 §62.
      if (reset && _page == 1 && _query.isEmpty) {
        unawaited(c.syncScheduler.syncOnOpen(widget.module, schema));
      }
      setState(() {
        _schema = schema;
        if (reset) _records.clear();
        _records.addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      // انقطاع ⇒ سقوط صادق للخبيئة إن كانت الوحدة قابلة للتخبئة (§60 §83).
      CachedModule? cached;
      final schema = _schema ?? c.modules.lastSchema?.modules[widget.module];
      if (e is NetworkException &&
          _query.isEmpty &&
          (schema == null || isCacheableClass(schema.syncClass))) {
        cached = await c.sync.readCached(widget.module);
      }
      if (!mounted) return;
      setState(() {
        _schema ??= schema;
        _error = e;
        _cachedFallback = cached;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.extentAfter > 400) return;
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    _load(reset: false);
  }

  void _onSearch(String q) {
    _query = q.trim();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final schema = _schema;
    final title = schema?.label ?? widget.module;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (schema != null && schema.fields.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: l.moduleSort,
              onSelected: (key) {
                setState(() => _sort = key == _sort ? '-$key' : key);
                _load();
              },
              itemBuilder: (context) => [
                for (final f in schema.fields.take(8))
                  PopupMenuItem(value: f.key, child: Text(f.label)),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.moduleSearchHint(title),
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearch,
            ),
          ),
        ),
      ),
      floatingActionButton: (schema?.can.a ?? false)
          ? FloatingActionButton(
              tooltip: l.actionCreate,
              onPressed: () => context.push('/m/${widget.module}/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: _body(l),
    );
  }

  Widget _body(AppLocalizations l) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    // وضع الخبيئة دون اتصال — لافتة بائت صادقة (§83 §84).
    final cached = _cachedFallback;
    if (_error != null && cached != null && cached.records.isNotEmpty) {
      final schema = _schema;
      return Column(
        children: [
          MaterialBanner(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.stateOfflineCached),
                if (cached.syncedAt != null)
                  Text(
                    l.syncedAt(
                      MaterialLocalizations.of(context)
                          .formatShortDate(cached.syncedAt!.toLocal()),
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(cached.syncedAt!.toLocal()),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            leading: const Icon(Icons.cloud_off),
            actions: [TextButton(onPressed: _load, child: Text(l.actionRetry))],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cached.records.length,
              itemBuilder: (context, i) {
                final rec = RecordData(cached.records[i]);
                return _RecordTile(
                  record: rec,
                  schema: schema,
                  module: widget.module,
                );
              },
            ),
          ),
        ],
      );
    }

    if (_error != null && _records.isEmpty) {
      return ErrorView(error: _error!, onRetry: _load);
    }
    if (_records.isEmpty) return const EmptyView();

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.builder(
        controller: _scroll,
        itemCount: _records.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _records.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _RecordTile(
            record: _records[i],
            schema: _schema,
            module: widget.module,
          );
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.schema,
    required this.module,
  });

  final RecordData record;
  final ModuleSchema? schema;
  final String module;

  @override
  Widget build(BuildContext context) {
    final s = schema;
    final title = record.display(s);
    String? subtitle;
    if (s != null) {
      final statusField = s.fields
          .where((f) => f.type == 'sel' && !f.multi)
          .firstOrNull;
      final v = statusField == null ? null : record[statusField.key];
      subtitle = v?.toString();
    }
    return ListTile(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: (subtitle?.isNotEmpty ?? false) ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/r/$module/${record.id}'),
    );
  }
}
