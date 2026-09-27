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

  /// تلميح تحديث **اختياري** (لا يحجب): الخادم حسب التحديث مطلوباً بلا إجبار،
  /// أو `version_gate.<platform>.latest` أحدث من الإصدار الجاري.
  bool softUpdateAvailable({required String platform, String? current}) {
    if (blocksUsage) return false;
    if (updateRequired) return true;
    final latest = platform == 'ios' ? gate.iosLatest : gate.androidLatest;
    if (latest.isEmpty || current == null || current.isEmpty) return false;
    return compareVersions(latest, current) > 0;
  }

  String? storeUrlFor(String platform) {
    final url = platform == 'ios' ? storeUrlIos : storeUrlAndroid;
    return (url == null || url.isEmpty) ? null : url;
  }

  /// رابط الدعم إن هيّأه الخادم (`mobile.support_url`) — وإلا null (لا اختلاق).
  Uri? get supportUri {
    final raw = supportUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    return (uri != null && uri.hasScheme) ? uri : null;
  }
}

/// مقارنة إصدارين نقطيين (`1.2.10` > `1.2.9`) — الأجزاء غير الرقمية تُعامل صفراً
/// ولاحقة البناء (`+5`) والوسم (`-beta`) تُتجاهل.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[+-]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < 3 || i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// `GET health` — حالة التشغيل الحية عند الاستئناف (§45 §94).
class HealthStatus {
  const HealthStatus({
    required this.status,
    this.maintenance = false,
    this.lockdown = false,
    this.updateRequired = false,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> j) => HealthStatus(
    status: j['status']?.toString() ?? 'ok',
    maintenance: j['maintenance'] == true,
    lockdown: j['lockdown'] == true,
    updateRequired: j['update_required'] == true,
  );

  /// `ok | maintenance | lockdown | update_required`.
  final String status;
  final bool maintenance;
  final bool lockdown;
  final bool updateRequired;
}

class AppConfigRepository {
  AppConfigRepository(this.api);

  final ApiClient api;

  Future<AppConfig> fetch() async =>
      AppConfig.fromJson(await api.getData('app-config', auth: AuthMode.none));

  /// نقطة عامة خفيفة — تُستدعى عند الاستئناف (مقيّدة التواتر في المنسّق).
  Future<HealthStatus> health() async =>
      HealthStatus.fromJson(await api.getData('health', auth: AuthMode.none));
}
