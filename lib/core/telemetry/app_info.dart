/// هوية العميل للترويسات التليمترية (§30) — منصة/إصدار/بناء.
///
/// **وسم لا تخويل:** الخادم لا يثق بشيء منها؛ بوابة الإصدار تُحسب عليها عرضاً.
library;

import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  const AppInfo({
    required this.platform,
    required this.version,
    required this.build,
  });

  /// `ios` أو `android` (عقد `X-Lynomia-App-Platform`).
  final String platform;
  final String version;
  final String build;

  static Future<AppInfo> load() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(
      platform: Platform.isIOS ? 'ios' : 'android',
      version: info.version,
      build: info.buildNumber,
    );
  }
}
