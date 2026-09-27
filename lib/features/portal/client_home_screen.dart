/// بيت العميل (§12) — لقطة `portal/home`: منظماته ومعاينات وجهاته الست.
///
/// ليس لوحة داخلية بأزرار مخفية: شاشة مستقلة تعرض عالم العميل وحده كما
/// بثّه الخادم، وعضوية معلّقة تظهر عالماً فارغاً صادقاً برسالة واضحة.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'client_shell.dart';
import 'portal_models.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  PortalHome? _home;
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
    try {
      final home = await AppScope.of(context).portal.home();
      if (mounted) setState(() => _home = home);
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
        title: Text(account.user?.name ?? l.portalTitle),
        actions: clientHeaderActions(context),
      ),
      body: AsyncView<PortalHome>(
        loading: _loading,
        error: _error,
        value: _home,
        onRetry: _load,
        emptyWhen: (h) => h.isEmpty,
        emptyMessage: l.portalEmptyWorld,
        builder: (context, home) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (home.clients.isNotEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.portalYourOrgs,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          home.clients.map((c) => c.name).join(l.listSeparator),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              if (home.engagements.isNotEmpty)
                _PortalSection(
                  title: l.portalEngagements,
                  onShowAll: () => context.push('/portal/engagements'),
                  children: home.engagements
                      .map(
                        (e) => _PortalTile(
                          name: e.name,
                          subtitle: [?e.type, ?e.status].join(' · '),
                        ),
                      )
                      .toList(),
                ),
              if (home.projects.isNotEmpty)
                _PortalSection(
                  title: l.portalProjects,
                  onShowAll: () => context.go('/portal/projects'),
                  children: home.projects
                      .map(
                        (p) => _PortalTile(
                          name: p.name,
                          subtitle: [
                            ?p.status,
                            if (p.progress != null) l.percentValue(p.progress!),
                          ].join(' · '),
                          onTap: () => context.go('/portal/projects/${p.id}'),
                        ),
                      )
                      .toList(),
                ),
              if (home.invoices.isNotEmpty)
                _PortalSection(
                  title: l.portalInvoices,
                  onShowAll: () => context.go('/portal/invoices'),
                  children: home.invoices
                      .map(
                        (i) => _PortalTile(
                          name: i.docNo ?? i.id,
                          subtitle: [
                            ?i.state,
                            if (i.total != null)
                              '${Decimal.tryParse(i.total!) ?? i.total} ${i.currency ?? ''}'
                                  .trim(),
                          ].join(' · '),
                          onTap: () => context.go('/portal/invoices/${i.id}'),
                        ),
                      )
                      .toList(),
                ),
              if (home.documents.isNotEmpty)
                _PortalSection(
                  title: l.portalDocuments,
                  onShowAll: () => context.push('/portal/documents'),
                  children: home.documents
                      .map(
                        (d) => _PortalTile(
                          name: d.name,
                          subtitle: [?d.cat, ?d.docNo].join(' · '),
                          onTap: () =>
                              context.push('/portal/documents/${d.id}'),
                        ),
                      )
                      .toList(),
                ),
              if (home.conversations.isNotEmpty)
                _PortalSection(
                  title: l.portalConversations,
                  onShowAll: () => context.go('/portal/conversations'),
                  children: home.conversations
                      .map(
                        (c) => _PortalTile(
                          name: c.title ?? '',
                          onTap: () =>
                              context.go('/portal/conversations/${c.id}'),
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

class _PortalSection extends StatelessWidget {
  const _PortalSection({
    required this.title,
    required this.children,
    this.onShowAll,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onShowAll != null)
                TextButton(onPressed: onShowAll, child: Text(l.actionShowAll)),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PortalTile extends StatelessWidget {
  const _PortalTile({required this.name, this.subtitle, this.onTap});

  final String name;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: (subtitle?.isNotEmpty ?? false)
        ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
        : null,
    trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
