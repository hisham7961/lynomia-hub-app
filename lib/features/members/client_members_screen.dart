/// شاشة أعضاء العميل (§15) — للمدير الداخلي: قائمة، دعوة (سكّة B.1 — رسالة
/// تفعيل لا كلمة سر)، تغيير دور، سحب وصول. منح Owner والسحب خلف تصعيد
/// الجوال المربوط بالغرض عبر `runWithStepUp` (الرد 428 يفتح حوار الاعتماد).
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/step_up_flow.dart';
import '../../l10n/app_localizations.dart';
import 'client_members_repository.dart';

String roleLabel(AppLocalizations l, String role) => switch (role) {
  'owner' => l.roleOwner,
  'lead' => l.roleLead,
  'technical' => l.roleTechnical,
  'finance' => l.roleFinance,
  'viewer' => l.roleViewer,
  _ => role,
};

String statusLabel(AppLocalizations l, String status) => switch (status) {
  'invited' => l.membersStatusInvited,
  'active' => l.membersStatusActive,
  'suspended' => l.membersStatusSuspended,
  _ => status,
};

class ClientMembersScreen extends StatefulWidget {
  const ClientMembersScreen({
    super.key,
    required this.clientId,
    this.clientName,
  });

  final String clientId;
  final String? clientName;

  @override
  State<ClientMembersScreen> createState() => _ClientMembersScreenState();
}

class _ClientMembersScreenState extends State<ClientMembersScreen> {
  List<ClientMember>? _members;
  Object? _error;
  bool _loading = true;

  ClientMembersRepository get _repo => AppScope.of(context).clientMembers;

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
      final members = await _repo.list(widget.clientId);
      if (mounted) setState(() => _members = members);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final result =
        await showDialog<({String email, String? name, String role})>(
          context: context,
          builder: (ctx) => const _InviteDialog(),
        );
    if (result == null || !mounted) return;
    final opKey = const Uuid().v4();
    await _run(
      () => _repo.invite(
        clientId: widget.clientId,
        email: result.email,
        name: result.name,
        role: result.role,
        idempotencyKey: opKey,
      ),
      successMessage: AppLocalizations.of(context)!.membersInviteSent,
    );
  }

  Future<void> _changeRole(ClientMember m) async {
    final l = AppLocalizations.of(context)!;
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.membersChangeRole),
        children: clientMemberRoles
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(r),
                child: Text(roleLabel(l, r)),
              ),
            )
            .toList(),
      ),
    );
    if (role == null || role == m.role || !mounted) return;
    await _run(
      () => _repo.setRole(
        clientId: widget.clientId,
        membershipId: m.id,
        role: role,
      ),
    );
  }

  Future<void> _revoke(ClientMember m) async {
    final l = AppLocalizations.of(context)!;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.membersRevoke),
        content: Text(l.membersRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.actionConfirm),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run(
      () => _repo.revoke(clientId: widget.clientId, membershipId: m.id),
    );
  }

  /// تنفيذ عملية عضوية مع تصعيد عند 428 ثم إعادة تحميل القائمة.
  Future<void> _run(
    Future<ClientMember> Function() op, {
    String? successMessage,
  }) async {
    try {
      await runWithStepUp(context, op);
      if (!mounted) return;
      if (successMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
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
      appBar: AppBar(
        title: Text(
          widget.clientName?.isNotEmpty ?? false
              ? '${l.membersTitle} — ${widget.clientName}'
              : l.membersTitle,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _invite,
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.membersInvite),
      ),
      body: AsyncView<List<ClientMember>>(
        loading: _loading,
        error: _error,
        value: _members,
        onRetry: _load,
        emptyWhen: (m) => m.isEmpty,
        builder: (context, members) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = members[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    m.userName.isNotEmpty
                        ? m.userName.characters.first
                        : l.unknownInitial,
                  ),
                ),
                title: Text(m.userName.isNotEmpty ? m.userName : m.userEmail),
                subtitle: Text(
                  [
                    m.userEmail,
                    '${roleLabel(l, m.role)} · ${statusLabel(l, m.status)} · '
                        '${m.activated ? l.membersActivatedYes : l.membersActivatedNo}',
                  ].join('\n'),
                ),
                isThreeLine: true,
                trailing: m.status == 'suspended'
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (action) => switch (action) {
                          'role' => _changeRole(m),
                          'revoke' => _revoke(m),
                          _ => null,
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'role',
                            child: Text(l.membersChangeRole),
                          ),
                          PopupMenuItem(
                            value: 'revoke',
                            child: Text(l.membersRevoke),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  String _role = 'viewer';

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.membersInvite),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.membersEmail),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) =>
                  (v == null || !v.contains('@')) ? l.loginInvalidEmail : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.membersNameOptional),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(labelText: l.membersRole),
              items: clientMemberRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(roleLabel(l, r)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop((
              email: _email.text.trim(),
              name: _name.text.trim().isEmpty ? null : _name.text.trim(),
              role: _role,
            ));
          },
          child: Text(l.actionSend),
        ),
      ],
    );
  }
}
