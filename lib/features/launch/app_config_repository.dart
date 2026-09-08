/// `GET app-config` قبل المصادقة (§45) — صيانة/قفل/بوابة إصدار/روابط متجر.
library;

import '../../core/api/api_client.dart';

class VersionGate {
  const VersionGate({
    this.iosMin = '',
    this.iosLatest = '',
    this.androidMin = '',
    this.androidLatest = '',
    this.forceUpdate = false,
  });

  factory VersionGate.fromJson(Map<String, dynamic> j) {
    final ios = (j['ios'] as Map?)?.cast<String, dynamic>() ?? const {};
    final android = (j['android'] as Map?)?.cast<String, dynamic>() ?? const {};
    return VersionGate(
      iosMin: ios['min']?.toString() ?? '',
      iosLatest: ios['latest']?.toString() ?? '',
      androidMin: android['min']?.toString() ?? '',
      androidLatest: android['latest']?.toString() ?? '',
      forceUpdate: j['force_update'] == true,
    );
  }

  final String iosMin;
  final String iosLatest;
  final String androidMin;
  final String androidLatest;
  final bool forceUpdate;
}

class AppConfig {
  const AppConfig({
    required this.mobileApiVersion,
    required this.maintenance,
    this.maintenanceMessage,
    required this.lockdown,
    required this.loginAvailable,
    required this.updateRequired,
    required this.gate,
    this.supportUrl,
    this.storeUrlIos,
    this.storeUrlAndroid,
    this.timezone,
  });

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
    mobileApiVersion: j['mobile_api_version']?.toString() ?? '1',
    maintenance: j['maintenance'] == true,
    maintenanceMessage: j['maintenance_message']?.toString(),
    lockdown: j['lockdown'] == true,
    loginAvailable: j['login_available'] != false,
    updateRequired: j['update_required'] == true,
    gate: VersionGate.fromJson(
      (j['version_gate'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    supportUrl: j['support_url']?.toString(),
    storeUrlIos: ((j['store_urls'] as Map?) ?? const {})['ios']?.toString(),
    storeUrlAndroid: ((j['store_urls'] as Map?) ?? const {})['android']
        ?.toString(),
    timezone: j['timezone']?.toString(),
  );

  final String mobileApiVersion;
  final bool maintenance;
  final String? maintenanceMessage;
  final bool lockdown;
  final bool loginAvailable;

  /// محسوب خادمياً لإصدار هذا العميل من ترويسات التليمتري — إشارة عرض لا تخويل.
  final bool updateRequired;
  final VersionGate gate;
  final String? supportUrl;
  final String? storeUrlIos;
  final String? storeUrlAndroid;
  final String? timezone;

  /// التحديث الحاجب: الخادم حسبه مطلوباً + علم الإجبار (§46).
  bool get blocksUsage => updateRequired && gate.forceUpdate;
}

class AppConfigRepository {
  AppConfigRepository(this.api);

  final ApiClient api;

  Future<AppConfig> fetch() async =>
      AppConfig.fromJson(await api.getData('app-config', auth: AuthMode.none));
}
