/// حسابي (§78) — الهوية، سياق العرض، الجلسات، الأمان، التفضيلات، الخروج.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/di/app_scope.dart';
import '../../core/push/push_registrar.dart';
import '../../l10n/app_localizations.dart';
import '../launch/bootstrap_repository.dart';
import '../shell/app_shell.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final c = AppScope.of(context);
    final enabled = await c.biometricPref.enabled;
    final available = await c.biometricGate.available;
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _biometricAvailable = available;
      });
    }
  }

  Future<void> _pickContext({required bool company}) async {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);
    final dim = company
        ? c.account.bootstrap?.companies
        : c.account.bootstrap?.clients;
    if (dim == null) return;

    final choice = await showModalBottomSheet<({String? id, String? name})>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l.accountContextAll),
              leading: const Icon(Icons.all_inclusive),
              onTap: () => Navigator.pop(ctx, (id: null, name: null)),
            ),
            for (final item in dim.items)
              ListTile(
                title: Text(item.name),
                leading: const Icon(Icons.business_outlined),
                selected: item.id == dim.active,
                onTap: () => Navigator.pop(ctx, (id: item.id, name: item.name)),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    // تبديل السياق (§43): ترويسات + إبطال + إعادة جلب.
    if (company) {
      await c.account.switchCompany(choice.id, name: choice.name);
    } else {
      await c.account.switchClient(choice.id, name: choice.name);
    }
  }

  Future<void> _logout({required bool everywhere}) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(everywhere ? l.confirmLogoutAll : l.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(everywhere ? l.actionLogoutAll : l.actionLogout),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppScope.of(context).signOut(everywhere: everywhere);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppScope.of(context);
    final account = c.account;
    // نمط الحساب يقود العرض: لا سياق شركات ولا أدوات داخلية لحساب العميل،
    // ومسارات القشرة (الجلسات/التشخيص) تتبع قشرته (§10 §12).
    final isClient = account.isClient;
    final accountBase = isClient ? '/portal/account' : '/account';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.accountTitle),
        actions: isClient ? null : shellHeaderActions(context),
      ),
      body: ListenableBuilder(
        listenable: account,
        builder: (context, _) {
          final user = account.user;
          final bootstrap = account.bootstrap;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // الهوية
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name.characters.first
                          : '؟',
                    ),
                  ),
                  title: Text(user?.name ?? ''),
                  subtitle: Text(
                    [
                      user?.email ?? '',
                      if (user?.role != null) user!.role!,
                    ].where((s) => s.isNotEmpty).join(' · '),
                  ),
                ),
              ),

              // سياق العرض (§42) — مفهوم داخلي؛ نطاق العميل عضويته الخادمية.
              if (!isClient) ...[
                Text(
                  l.accountContext,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: Text(l.accountContextCompany),
                        subtitle: Text(
                          c.viewContext.companyName ?? l.accountContextAll,
                        ),
                        trailing: const Icon(Icons.unfold_more),
                        onTap: () => _pickContext(company: true),
                      ),
                      if (_hasClients(bootstrap))
                        ListTile(
                          leading: const Icon(Icons.handshake_outlined),
                          title: Text(l.accountContextClient),
                          subtitle: Text(
                            c.viewContext.clientName ?? l.accountContextAll,
                          ),
                          trailing: const Icon(Icons.unfold_more),
                          onTap: () => _pickContext(company: false),
                        ),
                    ],
                  ),
                ),
              ],

              // الأمان والجلسات (§39 §40)
              Text(
                l.accountSecurity,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.devices_outlined),
                      title: Text(l.accountSessions),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('$accountBase/sessions'),
                    ),
                    if (_biometricAvailable)
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: Text(l.biometricPrefTitle),
                        subtitle: Text(l.biometricPrefSubtitle),
                        value: _biometricEnabled,
                        onChanged: (v) async {
                          await c.biometricPref.setEnabled(v);
                          setState(() => _biometricEnabled = v);
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(l.accountPushStatus),
                      subtitle: Text(
                        c.push.status == PushSetupStatus.registered
                            ? l.pushRegistered
                            : l.pushNotConfigured,
                      ),
                    ),
                  ],
                ),
              ),

              // المظهر واللغة (تفضيل محلي §79)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l.accountLanguage),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ar', label: Text('عربي')),
                          ButtonSegment(value: 'en', label: Text('EN')),
                        ],
                        selected: {
                          Localizations.localeOf(context).languageCode,
                        },
                        onSelectionChanged: (s) =>
                            context.setAppLocale(Locale(s.first)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: Text(l.accountTheme),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.brightness_auto, size: 18),
                            tooltip: l.accountThemeSystem,
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode, size: 18),
                            tooltip: l.accountThemeLight,
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode, size: 18),
                            tooltip: l.accountThemeDark,
                          ),
                        ],
                        selected: {_currentThemeMode(context)},
                        onSelectionChanged: (s) =>
                            context.setAppThemeMode(s.first),
                      ),
                    ),
                  ],
                ),
              ),

              // أدوات — التتبع قدرة ميدانية داخلية (خارج قائمة العميل البيضاء).
              if (!isClient || kDebugMode)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      if (!isClient)
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(l.trackingTitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/tracking'),
                        ),
                      if (kDebugMode)
                        ListTile(
                          leading: const Icon(Icons.bug_report_outlined),
                          title: Text(l.diagnosticsTitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('$accountBase/diagnostics'),
                        ),
                    ],
                  ),
                ),

              // الخروج (§39)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(l.actionLogout),
                      onTap: () => _logout(everywhere: false),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phonelink_erase),
                      title: Text(l.actionLogoutAll),
                      onTap: () => _logout(everywhere: true),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasClients(Bootstrap? b) => (b?.clients.items.isNotEmpty ?? false);

  ThemeMode _currentThemeMode(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    if (brightness == platformBrightness) return ThemeMode.system;
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
