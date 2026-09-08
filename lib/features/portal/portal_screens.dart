/// شاشات بوابة العميل (§12/§17/§18) — قوائم وتفاصيل الوجهات الخمس وغرفة
/// المحادثة. كل ما يظهر هنا بثّه الخادم بأعمدته العميلية حصراً؛ 404 عابر
/// العملاء يُعرض حالة «غير موجود» الصادقة نفسها.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'portal_models.dart';

/// قالب قائمة بوابة موحّد: تحميل/خطأ/فارغ/تحديث بالسحب.
class _PortalListScreen<T> extends StatefulWidget {
  const _PortalListScreen({
    super.key,
    required this.title,
    required this.fetch,
    required this.tileBuilder,
  });

  final String title;
  final Future<List<T>> Function(BuildContext) fetch;
  final Widget Function(BuildContext, T) tileBuilder;

  @override
  State<_PortalListScreen<T>> createState() => _PortalListScreenState<T>();
}

class _PortalListScreenState<T> extends State<_PortalListScreen<T>> {
  List<T>? _items;
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
      final items = await widget.fetch(context);
      if (mounted) setState(() => _items = items);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: AsyncView<List<T>>(
      loading: _loading,
      error: _error,
      value: _items,
      onRetry: _load,
      emptyWhen: (items) => items.isEmpty,
      builder: (context, items) => RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => widget.tileBuilder(context, items[i]),
        ),
      ),
    ),
  );
}

class PortalEngagementsScreen extends StatelessWidget {
  const PortalEngagementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _PortalListScreen<PortalEngagement>(
      title: l.portalEngagements,
      fetch: (context) => AppScope.of(context).portal.engagements(),
      tileBuilder: (context, e) => ListTile(
        title: Text(e.name),
        subtitle: Text(
          [
            [?e.type, ?e.status, ?e.renewal].join(' · '),
            if (e.clientNote?.isNotEmpty ?? false)
              '${l.portalClientNote}: ${e.clientNote}',
          ].where((s) => s.isNotEmpty).join('\n'),
        ),
        isThreeLine: e.clientNote?.isNotEmpty ?? false,
      ),
    );
  }
}

class PortalProjectsScreen extends StatelessWidget {
  const PortalProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _PortalListScreen<PortalProject>(
      title: l.portalProjects,
      fetch: (context) => AppScope.of(context).portal.projects(),
      tileBuilder: (context, p) => ListTile(
        title: Text(p.name),
        subtitle: Text(
          [
            ?p.status,
            if (p.progress != null) '${p.progress}٪',
            ?p.launchExpected,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/portal/projects/${p.id}'),
      ),
    );
  }
}

class PortalProjectScreen extends StatefulWidget {
  const PortalProjectScreen({super.key, required this.id});

  final String id;

  @override
  State<PortalProjectScreen> createState() => _PortalProjectScreenState();
}

class _PortalProjectScreenState extends State<PortalProjectScreen> {
  PortalProject? _project;
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
      final p = await AppScope.of(context).portal.project(widget.id);
      if (mounted) setState(() => _project = p);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_project?.name ?? l.portalProjects)),
      body: AsyncView<PortalProject>(
        loading: _loading,
        error: _error,
        value: _project,
        onRetry: _load,
        builder: (context, p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (p.progress != null) ...[
              Text(
                '${l.projectProgress}: ${p.progress}٪',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (p.progress!.clamp(0, 100)) / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],
            _DetailRow(label: l.projectStatus, value: p.status),
            _DetailRow(label: l.projectPriority, value: p.priority),
            _DetailRow(label: l.projectStart, value: p.startDate),
            _DetailRow(label: l.projectLaunchExpected, value: p.launchExpected),
            _DetailRow(label: l.projectLaunchActual, value: p.launchActual),
            _DetailRow(label: l.projectClient, value: p.clientName),
            _DetailRow(label: l.projectEngagement, value: p.engagementName),
            if (p.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(p.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class PortalDocumentsScreen extends StatelessWidget {
  const PortalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _PortalListScreen<PortalDocument>(
      title: l.portalDocuments,
      fetch: (context) => AppScope.of(context).portal.documents(),
      tileBuilder: (context, d) => ListTile(
        title: Text(d.name),
        subtitle: Text([?d.cat, ?d.docNo, ?d.expiry].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/portal/documents/${d.id}'),
      ),
    );
  }
}

class PortalDocumentScreen extends StatefulWidget {
  const PortalDocumentScreen({super.key, required this.id});

  final String id;

  @override
  State<PortalDocumentScreen> createState() => _PortalDocumentScreenState();
}

class _PortalDocumentScreenState extends State<PortalDocumentScreen> {
  PortalDocument? _doc;
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
      final d = await AppScope.of(context).portal.document(widget.id);
      if (mounted) setState(() => _doc = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_doc?.name ?? l.portalDocuments)),
      body: AsyncView<PortalDocument>(
        loading: _loading,
        error: _error,
        value: _doc,
        onRetry: _load,
        builder: (context, d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetailRow(label: l.docCategory, value: d.cat),
            _DetailRow(label: l.docNo, value: d.docNo),
            _DetailRow(label: l.docIssueDate, value: d.issueDate),
            _DetailRow(label: l.docExpiry, value: d.expiry),
            if (d.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(d.description!),
            ],
          ],
        ),
      ),
    );
  }
}

String _money(AppLocalizations l, String? amount, String? currency) {
  if (amount == null) return '';
  final d = Decimal.tryParse(amount);
  return '${d ?? amount} ${currency ?? ''}'.trim();
}

class PortalInvoicesScreen extends StatelessWidget {
  const PortalInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _PortalListScreen<PortalInvoice>(
      title: l.portalInvoices,
      fetch: (context) => AppScope.of(context).portal.invoices(),
      tileBuilder: (context, i) => ListTile(
        title: Text(i.docNo ?? i.id),
        subtitle: Text(
          [
            ?i.kind,
            ?i.state,
            if (i.total != null) _money(l, i.total, i.currency),
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/portal/invoices/${i.id}'),
      ),
    );
  }
}

class PortalInvoiceScreen extends StatefulWidget {
  const PortalInvoiceScreen({super.key, required this.id});

  final String id;

  @override
  State<PortalInvoiceScreen> createState() => _PortalInvoiceScreenState();
}

class _PortalInvoiceScreenState extends State<PortalInvoiceScreen> {
  PortalInvoice? _invoice;
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
      final inv = await AppScope.of(context).portal.invoice(widget.id);
      if (mounted) setState(() => _invoice = inv);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_invoice?.docNo ?? l.portalInvoices)),
      body: AsyncView<PortalInvoice>(
        loading: _loading,
        error: _error,
        value: _invoice,
        onRetry: _load,
        builder: (context, i) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetailRow(label: l.invoiceKind, value: i.kind),
            _DetailRow(label: l.invoiceState, value: i.state),
            _DetailRow(label: l.invoiceDate, value: i.date),
            _DetailRow(label: l.invoiceDue, value: i.due),
            _DetailRow(
              label: l.invoiceTotal,
              value: _money(l, i.total, i.currency),
            ),
            _DetailRow(
              label: l.invoicePaid,
              value: _money(l, i.paid, i.currency),
            ),
          ],
        ),
      ),
    );
  }
}

class PortalConversationsScreen extends StatelessWidget {
  const PortalConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _PortalListScreen<PortalConversation>(
      title: l.portalConversations,
      fetch: (context) => AppScope.of(context).portal.conversations(),
      tileBuilder: (context, c) => ListTile(
        leading: const Icon(Icons.forum_outlined),
        title: Text(c.title ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/portal/conversations/${c.id}'),
      ),
    );
  }
}

/// غرفة محادثة العميل (§17): القارئ يخفي `internal` بنيوياً على الخادم،
/// والإرسال عبر سكّة التعليقات الواحدة (module=channel) — الخادم يفرض
/// `internal=false` لحساب العميل مهما أرسل التطبيق.
class PortalConversationScreen extends StatefulWidget {
  const PortalConversationScreen({super.key, required this.id});

  final String id;

  @override
  State<PortalConversationScreen> createState() =>
      _PortalConversationScreenState();
}

class _PortalConversationScreenState extends State<PortalConversationScreen> {
  PortalConversationThread? _thread;
  Object? _error;
  bool _loading = true;
  bool _sending = false;
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await AppScope.of(context).portal.conversation(widget.id);
      if (mounted) setState(() => _thread = t);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final c = AppScope.of(context);
    try {
      await c.comments.post(
        module: 'channel',
        recordId: widget.id,
        body: body,
        idempotencyKey: const Uuid().v4(),
      );
      _composer.clear();
      await _load();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_thread?.conversation.title ?? l.portalConversations),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<PortalConversationThread>(
              loading: _loading,
              error: _error,
              value: _thread,
              onRetry: _load,
              builder: (context, t) => t.messages.isEmpty
                  ? EmptyView(message: l.conversationEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: t.messages.length,
                      itemBuilder: (context, i) {
                        final m = t.messages[i];
                        final scheme = Theme.of(context).colorScheme;
                        return Align(
                          alignment: m.mine
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: m.mine
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!m.mine)
                                  Text(
                                    m.userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                Text(m.body),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      decoration: InputDecoration(
                        hintText: l.conversationWrite,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l.actionSend,
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}
