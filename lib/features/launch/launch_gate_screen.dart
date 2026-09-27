/// بوابة الإقلاع (§28 §46 §94) — كل حالة فشل صريحة، لا شاشة انتظار أبدية،
/// وتمييز صادق: صيانة ≠ انقطاع شبكة ≠ قفل ≠ تحديث إلزامي.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/bootstrap/launch_controller.dart';
import '../../app/di/app_scope.dart';
import '../../l10n/app_localizations.dart';

class LaunchGateScreen extends StatelessWidget {
  const LaunchGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final launch = AppScope.of(context).launch;
    final l = AppLocalizations.of(context)!;
    // رابط الدعم (§46) حين يهيّئه الخادم — على بوابات الحجب وحدها.
    Widget? support() {
      final uri = launch.appConfig?.supportUri;
      if (uri == null) return null;
      return TextButton.icon(
        key: const Key('launch-support'),
        onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.support_agent),
        label: Text(l.supportTitle),
      );
    }

    return Scaffold(
      body: ListenableBuilder(
        listenable: launch,
        builder: (context, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: switch (launch.state) {
              LaunchLoading() ||
              LaunchReady() ||
              LaunchLoggedOut() => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlutterLogo(size: 56),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
              LaunchConfigError(:final message) => _Gate(
                icon: Icons.settings_suggest_outlined,
                title: l.stateError,
                body: message,
              ),
              LaunchOffline() => _Gate(
                icon: Icons.cloud_off,
                title: l.serverUnavailable,
                body: l.errNetwork,
                action: FilledButton(
                  onPressed: launch.start,
                  child: Text(l.actionRetry),
                ),
                footer: support(),
              ),
              LaunchMaintenance(:final message, :final lockdown) => _Gate(
                icon: lockdown ? Icons.lock_outline : Icons.build_outlined,
                title: lockdown ? l.lockdownTitle : l.maintenanceTitle,
                body: (message?.isNotEmpty ?? false)
                    ? message!
                    : (lockdown ? l.lockdownBody : l.maintenanceBody),
                action: OutlinedButton(
                  onPressed: launch.start,
                  child: Text(l.actionRetry),
                ),
                footer: support(),
              ),
              LaunchUpdateRequired(:final config) => _Gate(
                icon: Icons.system_update_alt,
                title: l.updateRequiredTitle,
                body: l.updateRequiredBody,
                action: _StoreAction(
                  // لا يُدَّعى وجود متجر لم يُهيأ (§46).
                  iosUrl: config.storeUrlIos,
                  androidUrl: config.storeUrlAndroid,
                ),
                footer: support(),
              ),
              LaunchLocked() => _Gate(
                icon: Icons.fingerprint,
                title: l.biometricUnlockTitle,
                body: l.biometricUnlockReason,
                action: FilledButton.icon(
                  onPressed: () => launch.unlock(l.biometricUnlockReason),
                  icon: const Icon(Icons.lock_open),
                  label: Text(l.actionOpen),
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 56),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(body, textAlign: TextAlign.center),
      if (action != null) ...[const SizedBox(height: 24), action!],
      if (footer != null) ...[const SizedBox(height: 8), footer!],
    ],
  );
}

class _StoreAction extends StatelessWidget {
  const _StoreAction({this.iosUrl, this.androidUrl});

  final String? iosUrl;
  final String? androidUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final url = switch (theme.platform) {
      TargetPlatform.iOS => iosUrl,
      _ => androidUrl,
    };
    if (url == null || url.isEmpty) {
      // NOT_CONFIGURED صادقة — رسالة دعم حقيقية لا زر ميت (§46 §144).
      return Text(
        l.updateStoreNotConfigured,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      );
    }
    return FilledButton.icon(
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.open_in_new),
      label: Text(l.updateStoreButton),
    );
  }
}
