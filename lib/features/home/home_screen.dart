/// الرئيسية (§47) — ما يتطلب انتباهك، مواعيد، مهامك، مشاريعك، آخر النشاط.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../profile/prefs_repository.dart';
import '../shell/app_shell.dart';
import 'home_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;

  /// مثبتاتي من `GET prefs` — تعرض حين يعيدها الخادم؛ وفشلها لا يسقط البيت.
  List<PinTarget> _pins = const [];
  late final ValueNotifier<int> _prefsRevision;

  @override
  void initState() {
    super.initState();
    _prefsRevision = AppScope.of(context).serverPrefs.revision;
    _prefsRevision.addListener(_loadPins);
    _load();
  }

  @override
  void dispose() {
    _prefsRevision.removeListener(_loadPins);
    super.dispose();
  }

  Future<void> _loadPins() async {
    try {
      final prefs = await AppScope.of(context).serverPrefs.fetch();
      if (mounted) setState(() => _pins = prefs.pinned);
    } on Object {
      // قسمٌ ثانوي — يغيب بصدق ولا يحجب البيت.
    }
  }

  void _openPin(PinTarget pin) {
    final module = pin.module;
    if (module != null && module.isNotEmpty) {
      context.push('/m/$module');
    } else {
      // وجهة ويب (رابط علوي) — تُفتح في المتصفح المضمن لا شاشة زائفة (§16).
      launchUrl(
        AppScope.of(context).env.apiRoot,
        mode: LaunchMode.inAppBrowserView,
      );
    }
  }

  Future<void> _load() async {
    unawaited(_loadPins());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await AppScope.of(context).home.fetch();
      if (mounted) setState(() => _snapshot = snap);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final account = AppScope.of(context).account;
    return Scaffold(
      appBar: AppBar(
        title: Text(account.user?.name ?? l.appTitle),
        actions: shellHeaderActions(context),
      ),
      body: AsyncView<HomeSnapshot>(
        loading: _loading,
        error: _error,
        value: _snapshot,
        onRetry: _load,
        builder: (context, snap) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: l.homeMyTasks,
                      value: '${snap.myWorkCount}',
                      icon: Icons.task_alt,
                      onTap: () => context.go('/mywork'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: l.homeApprovalsPending,
                      value: '${snap.approvalsCount}',
                      icon: Icons.approval_outlined,
                      onTap: () => context.push('/approvals'),
                    ),
                  ),
                ],
              ),
              // «اسأل Hub» — يظهر حين يقول الخادمُ إنّه متاحٌ لهذا المستخدم الآن
              // (`feature_flags.can_ask`: الصلاحيّة والبوّابة معاً) — لا بابَ ميّتاً.
              if (account.flag('can_ask'))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    child: ListTile(
                      key: const Key('home-ask'),
                      leading: const Icon(Icons.question_answer_outlined),
                      title: Text(l.askTitle),
                      subtitle: Text(l.askHint),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/ask'),
                    ),
                  ),
                ),
              if (_pins.isNotEmpty)
                _Section(
                  title: l.pinnedTitle,
                  children: _pins
                      .map(
                        (p) => ListTile(
                          key: Key('home-pin-${p.token}'),
                          leading: const Icon(Icons.push_pin_outlined),
                          title: Text(
                            p.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            p.module == null
                                ? Icons.open_in_new
                                : Icons.chevron_right,
                          ),
                          onTap: () => _openPin(p),
                        ),
                      )
                      .toList(),
                ),
              if (snap.attention.isNotEmpty)
                _Section(
                  title: l.homeAttention,
                  children: snap.attention
                      .map(
                        (i) => _ItemTile(
                          name: i.name,
                          subtitle: [
                            if (i.label != null) i.label!,
                            if (i.field != null) i.field!,
                            if (i.date != null) i.date!,
                          ].join(' · '),
                          onTap: () => context.push(i.target.routePath),
                        ),
                      )
                      .toList(),
                ),
              if (snap.due.isNotEmpty)
                _Section(
                  title: l.homeDue,
                  children: snap.due
                      .map(
                        (i) => _ItemTile(
                          name: i.name,
                          subtitle: i.due,
                          onTap: () => context.push(i.target.routePath),
                        ),
                      )
                      .toList(),
                ),
              if (snap.myWork.isNotEmpty)
                _Section(
                  title: l.homeMyTasks,
                  children: snap.myWork
                      .map(
                        (i) => _ItemTile(
                          name: i.name,
                          subtitle: [
                            if (i.status != null) i.status!,
                            if (i.due != null) i.due!,
                          ].join(' · '),
                          onTap: () => context.push(i.target.routePath),
                        ),
                      )
                      .toList(),
                ),
              if (snap.projects.isNotEmpty)
                _Section(
                  title: l.homeProjects,
                  children: snap.projects
                      .map(
                        (i) => _ItemTile(
                          name: i.name,
                          subtitle: i.status,
                          onTap: () => context.push(i.target.routePath),
                        ),
                      )
                      .toList(),
                ),
              if (snap.recent.isNotEmpty)
                _Section(
                  title: l.homeRecent,
                  children: snap.recent
                      .map(
                        (a) => _ItemTile(
                          name: [
                            a.action,
                            a.name,
                          ].where((s) => (s ?? '').isNotEmpty).join(': '),
                          subtitle: [
                            if (a.who != null) a.who!,
                            if (a.when != null) a.when!,
                          ].join(' · '),
                          onTap: a.target == null
                              ? null
                              : () => context.push(a.target!.routePath),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on HomeItem {
  String? get date => due;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      Card(
        margin: EdgeInsets.zero,
        child: Column(children: children),
      ),
    ],
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.name, this.subtitle, this.onTap});

  final String name;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: (subtitle?.isNotEmpty ?? false)
        ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
        : null,
    // chevron_right معلَّم matchTextDirection — ينعكس تلقائياً في RTL (§24)
    trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
