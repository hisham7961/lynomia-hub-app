/// المجالات (§49) — شجرة IA الخادمية: مجالات ← أقسام ← وجهات مسموحة فقط.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import 'ia_models.dart';

class DomainsScreen extends StatelessWidget {
  const DomainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final account = AppScope.of(context).account;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.domainsTitle),
        actions: shellHeaderActions(context),
      ),
      body: ListenableBuilder(
        listenable: account,
        builder: (context, _) {
          final domains = account.ia.domains;
          if (domains.isEmpty) {
            return RefreshIndicator(
              onRefresh: account.refreshEntitlements,
              child: ListView(
                children: const [SizedBox(height: 200), EmptyView()],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: account.refreshEntitlements,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: domains.length,
              itemBuilder: (context, i) {
                final d = domains[i];
                final destinations = d.sections.fold<int>(
                  0,
                  (sum, s) => sum + s.destinations.length,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      d.icon ?? '📁',
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(d.label),
                    subtitle: Text('$destinations'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/domains/${d.key}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DomainDetailScreen extends StatelessWidget {
  const DomainDetailScreen({super.key, required this.domainKey});

  final String domainKey;

  @override
  Widget build(BuildContext context) {
    final account = AppScope.of(context).account;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final domain = account.ia.domains
            .where((d) => d.key == domainKey)
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(title: Text(domain?.label ?? domainKey)),
          body: domain == null
              ? const EmptyView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final section in domain.sections) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          section.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final dest in _ordered(section.destinations))
                              DestinationTile(destination: dest),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  /// primary ثم secondary ثم advanced (§16 — importance يقود الترتيب).
  List<IaDestination> _ordered(List<IaDestination> list) {
    int rank(String importance) => switch (importance) {
      'primary' => 0,
      'secondary' => 1,
      _ => 2,
    };
    final sorted = [...list]
      ..sort((a, b) => rank(a.importance).compareTo(rank(b.importance)));
    return sorted;
  }
}

class DestinationTile extends StatelessWidget {
  const DestinationTile({super.key, required this.destination});

  final IaDestination destination;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);
    final webOnly = destination.mobile == MobileFit.webOnly;
    return ListTile(
      title: Text(destination.label),
      subtitle: webOnly
          ? Text(
              l.webOnlyDestination,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: Icon(webOnly ? Icons.open_in_new : Icons.chevron_right),
      onTap: () {
        if (destination.module != null && !webOnly) {
          // الوجهة الأساسية: قائمة الوحدة عبر المحرك العام (§18).
          context.push('/m/${destination.module}');
        } else if (webOnly) {
          // وجهة ويب — تفتح في متصفح مضمن (§16)، لا شاشة زائفة.
          final root = c.env.apiRoot;
          launchUrl(root, mode: LaunchMode.inAppBrowserView);
        } else if (destination.module != null) {
          context.push('/m/${destination.module}');
        }
      },
    );
  }
}
