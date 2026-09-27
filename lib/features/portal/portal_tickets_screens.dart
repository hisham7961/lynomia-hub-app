/// «تذاكري» في قشرة العميل (المرحلة ٤.١): القائمة، وفتح بلاغ (التوأم المفتوح
/// ⇒ تأكيدٌ ثم `force`)، والتفصيل بالردود العامة والردّ.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../core/ui/feedback.dart';
import '../../l10n/app_localizations.dart';
import 'portal_tickets_repository.dart';

class PortalTicketsScreen extends StatefulWidget {
  const PortalTicketsScreen({super.key});

  @override
  State<PortalTicketsScreen> createState() => _PortalTicketsScreenState();
}

class _PortalTicketsScreenState extends State<PortalTicketsScreen> {
  PortalTicketList? _data;
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
      final d = await AppScope.of(context).portalTickets.tickets();
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _new() async {
    final d = _data;
    if (d == null) return;
    final created = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => PortalTicketNewScreen(options: d)),
    );
    if (!mounted) return;
    await _load();
    if (created != null && mounted) {
      await context.push('/portal/tickets/$created');
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.ticketsTitle)),
      floatingActionButton: _data == null || _data!.priorities.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('ticket-new'),
              onPressed: _new,
              icon: const Icon(Icons.add),
              label: Text(l.ticketsNew),
            ),
      body: AsyncView<PortalTicketList>(
        loading: _loading,
        error: _error,
        value: _data,
        onRetry: _load,
        emptyWhen: (d) => d.tickets.isEmpty,
        emptyMessage: l.ticketsEmpty,
        builder: (context, d) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: d.tickets.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = d.tickets[i];
              return ListTile(
                key: Key('ticket-${t.id}'),
                leading: Icon(
                  t.done ? Icons.check_circle_outline : Icons.support_agent,
                ),
                title: Text(t.subject),
                subtitle: Text(
                  [
                    ?t.status,
                    ?t.priority,
                    if (t.createdAt != null)
                      formatShortDate(t.createdAt!, locale),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/portal/tickets/${t.id}');
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

class PortalTicketNewScreen extends StatefulWidget {
  const PortalTicketNewScreen({super.key, required this.options});

  final PortalTicketList options;

  @override
  State<PortalTicketNewScreen> createState() => _PortalTicketNewScreenState();
}

class _PortalTicketNewScreenState extends State<PortalTicketNewScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String? _priority;
  String? _project;
  String? _client;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final p = widget.options.priorities;
    _priority = p.isEmpty ? null : p.first;
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit({bool force = false}) async {
    if (!(_form.currentState?.validate() ?? false) || _sending) return;
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).portalTickets;
    setState(() => _sending = true);
    try {
      final d = await repo.create(
        subject: _subject.text.trim(),
        body: _body.text.trim(),
        priority: _priority!,
        projectId: _project,
        clientId: _client,
        force: force,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      showSnack(context, l.ticketsCreated);
      Navigator.of(context).pop(d.ticket.id);
    } on DuplicateTicketException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.ticketsDuplicateTitle),
          content: Text(l.ticketsDuplicateBody(e.existing?.subject ?? '')),
          actions: [
            if (e.existing != null)
              TextButton(
                key: const Key('ticket-dup-open'),
                onPressed: () => Navigator.pop(ctx, 'open'),
                child: Text(l.ticketsOpenExisting),
              ),
            FilledButton(
              key: const Key('ticket-dup-force'),
              onPressed: () => Navigator.pop(ctx, 'force'),
              child: Text(l.ticketsSubmitAnyway),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'force') {
        await _submit(force: true);
      } else if (choice == 'open' && e.existing != null) {
        Navigator.of(context).pop(e.existing!.id);
      }
      return;
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final o = widget.options;
    return Scaffold(
      appBar: AppBar(title: Text(l.ticketsNew)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('ticket-subject'),
              controller: _subject,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.ticketsSubject),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.fieldValueRequired : null,
            ),
            TextFormField(
              key: const Key('ticket-body'),
              controller: _body,
              minLines: 3,
              maxLines: 8,
              maxLength: 5000,
              decoration: InputDecoration(labelText: l.ticketsBody),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.fieldValueRequired : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: InputDecoration(labelText: l.ticketsPriority),
              items: [
                for (final p in o.priorities)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _priority = v),
              validator: (v) => v == null ? l.fieldValueRequired : null,
            ),
            if (o.projects.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: _project,
                decoration: InputDecoration(labelText: l.ticketsProject),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.ticketsNone)),
                  for (final p in o.projects)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _project = v),
              ),
            if (o.clients.length > 1)
              DropdownButtonFormField<String?>(
                initialValue: _client,
                decoration: InputDecoration(labelText: l.ticketsOrg),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.ticketsNone)),
                  for (final c in o.clients)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _client = v),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('ticket-submit'),
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.actionSend),
            ),
          ],
        ),
      ),
    );
  }
}

class PortalTicketScreen extends StatefulWidget {
  const PortalTicketScreen({super.key, required this.id});

  final String id;

  @override
  State<PortalTicketScreen> createState() => _PortalTicketScreenState();
}

class _PortalTicketScreenState extends State<PortalTicketScreen> {
  final _input = TextEditingController();
  PortalTicketDetail? _data;
  Object? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await AppScope.of(context).portalTickets.ticket(widget.id);
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reply() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await AppScope.of(context).portalTickets
          .reply(widget.id, body, idempotencyKey: const Uuid().v4());
      if (!mounted) return;
      _input.clear();
      await _load();
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(_data?.ticket.subject ?? l.ticketsTitle)),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<PortalTicketDetail>(
              loading: _loading,
              error: _error,
              value: _data,
              onRetry: _load,
              builder: (context, d) => RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              children: [
                                if (d.ticket.status != null)
                                  Chip(label: Text(d.ticket.status!)),
                                if (d.ticket.priority != null)
                                  Chip(label: Text(d.ticket.priority!)),
                                if (d.ticket.projectName != null)
                                  Chip(label: Text(d.ticket.projectName!)),
                              ],
                            ),
                            if (d.ticket.body != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(d.ticket.body!),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (d.replies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.ticketsNoReplies),
                      ),
                    for (final r in d.replies)
                      Align(
                        alignment: r.mine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Card(
                          key: Key('ticket-reply-${r.id}'),
                          color: r.mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    r.mine ? l.ticketsYou : (r.userName ?? ''),
                                    if (r.createdAt != null)
                                      formatShortDate(r.createdAt!, locale),
                                  ].join(' · '),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(r.body),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_data != null && !_data!.ticket.done)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('ticket-reply-input'),
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 4000,
                        decoration: InputDecoration(
                          hintText: l.ticketsReplyHint,
                          counterText: '',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('ticket-reply-send'),
                      tooltip: l.actionSend,
                      onPressed: _sending ? null : _reply,
                      icon: const Icon(Icons.send),
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
