/// منسّق الاستئناف (المرحلة ١.٤ و١.٦): فحص `health` مقيّد التواتر، والشارة الحية،
/// وتطبيق الصيانة/الإغلاق/التحديث على آلة الإقلاع — بساعةٍ محقونة.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/app/bootstrap/launch_controller.dart';
import 'package:lynomia_hub_app/app/bootstrap/resume_coordinator.dart';
import 'package:lynomia_hub_app/features/launch/app_config_repository.dart';

import '../fakes/fakes.dart';
import '../widget/rtl_app_test.dart' show appConfigPayload;

Map<String, dynamic> health(String status) => {
  'status': status,
  'maintenance': status == 'maintenance',
  'lockdown': status == 'lockdown',
  'update_required': status == 'update_required',
  'server_time': '2026-09-27T10:00:00Z',
};

void main() {
  late TestHarness h;
  late DateTime clock;
  late ResumeCoordinator coordinator;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
    h.transport.onData('GET app-config', appConfigPayload());
    h.transport.onData('GET bootstrap', bootstrapPayload());
    h.transport.onData('GET schema', schemaPayload());
    h.transport.onData('GET notifications/unread-count', {'unread': 3});
    h.transport.onData('GET health', health('ok'));
    h.transport.onData('GET sync/tasks', {
      'module': 'tasks',
      'sync_class': 'CACHEABLE_INCREMENTAL',
      'cacheable': true,
      'records': <dynamic>[],
      'tombstones': <dynamic>[],
      'next_cursor': null,
      'has_more': false,
      'sync_version': 'v1',
    });
    await h.container.launch.start();
    expect(h.container.launch.state, isA<LaunchReady>());
    clock = DateTime(2026, 9, 27, 10);
    coordinator = ResumeCoordinator(
      launch: h.container.launch,
      account: h.container.account,
      appConfigRepo: h.container.appConfig,
      notifications: h.container.notifications,
      syncScheduler: h.container.syncScheduler,
      now: () => clock,
    );
  });

  tearDown(() => h.dispose());

  test('onReady: شارة حية فوراً ولا فحص صحة مكرر بعد app-config', () async {
    await coordinator.onReady();
    expect(h.container.account.unreadNotifications, 3);
    expect(h.transport.sent('GET health'), isEmpty);
  });

  test('الاستئناف: health مقيّد بدقيقة، والشارة بمهلتها', () async {
    await coordinator.onReady();
    clock = clock.add(const Duration(seconds: 30));
    await coordinator.onResumed();
    expect(h.transport.sent('GET health'), isEmpty, reason: 'ضمن الدقيقة');
    expect(h.transport.sent('GET notifications/unread-count'), hasLength(2));

    clock = clock.add(const Duration(seconds: 5));
    await coordinator.onResumed();
    expect(
      h.transport.sent('GET notifications/unread-count'),
      hasLength(2),
      reason: 'مهلة الشارة ١٥ث',
    );

    clock = clock.add(const Duration(seconds: 61));
    await coordinator.onResumed();
    expect(h.transport.sent('GET health'), hasLength(1));
    expect(
      h.transport.sent('GET health').single.headers['Authorization'],
      isNull,
    );
  });

  test('health=maintenance ⇒ LaunchMaintenance، وlockdown ⇒ إغلاق', () async {
    h.transport.onData('GET health', health('maintenance'));
    await coordinator.checkHealth(force: true);
    expect(h.container.launch.state, isA<LaunchMaintenance>());

    await h.container.launch.start();
    h.transport.onData('GET health', health('lockdown'));
    await coordinator.checkHealth(force: true);
    final s = h.container.launch.state as LaunchMaintenance;
    expect(s.lockdown, isTrue);
  });

  test('update_required مُجبر ⇒ حاجبة؛ وغير مجبر ⇒ تبقى جاهزة', () async {
    h.transport.onData('GET health', health('update_required'));
    h.transport.onData(
      'GET app-config',
      appConfigPayload(updateRequired: true, force: false),
    );
    await coordinator.checkHealth(force: true);
    expect(h.container.launch.state, isA<LaunchReady>());
    expect(
      h.container.launch.appConfig!.softUpdateAvailable(platform: 'android'),
      isTrue,
    );

    h.transport.onData(
      'GET app-config',
      appConfigPayload(updateRequired: true, force: true),
    );
    await coordinator.checkHealth(force: true);
    expect(h.container.launch.state, isA<LaunchUpdateRequired>());
  });

  test('انقطاع أثناء health لا يغيّر الحالة (شريط الاتصال يتكفّل)', () async {
    h.transport.on('GET health', (_) => throw http.ClientException('offline'));
    await coordinator.checkHealth(force: true);
    expect(h.container.launch.state, isA<LaunchReady>());
  });

  test('الاستئناف خارج الجاهزية لا يطلب شيئاً', () async {
    h.container.launch.onSignedOut();
    await coordinator.onResumed();
    expect(h.transport.sent('GET health'), isEmpty);
    expect(h.transport.sent('GET notifications/unread-count'), isEmpty);
  });

  group('مقارنة الإصدارات وتلميح latest', () {
    test('compareVersions', () {
      expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
      expect(compareVersions('0.6.0', '0.6.0+6'), 0);
      expect(compareVersions('0.5.9', '0.6.0'), lessThan(0));
      expect(compareVersions('2', '1.9.9'), greaterThan(0));
    });

    test('latest أحدث ⇒ تلميح؛ مساوٍ أو فارغ ⇒ لا', () {
      AppConfig cfg(String latest) {
        final j = appConfigPayload();
        j['version_gate'] = {
          'ios': {'min': '', 'latest': latest},
          'android': {'min': '', 'latest': latest},
          'force_update': false,
        };
        return AppConfig.fromJson(j);
      }

      expect(
        cfg('0.7.0').softUpdateAvailable(platform: 'ios', current: '0.6.0'),
        isTrue,
      );
      expect(
        cfg('0.6.0').softUpdateAvailable(platform: 'ios', current: '0.6.0'),
        isFalse,
      );
      expect(
        cfg('').softUpdateAvailable(platform: 'android', current: '0.6.0'),
        isFalse,
      );
    });

    test('support_url: رابط صالح فقط', () {
      final j = appConfigPayload();
      j['support_url'] = 'https://s.example.com';
      expect(
        AppConfig.fromJson(j).supportUri,
        Uri.parse('https://s.example.com'),
      );
      j['support_url'] = '  ';
      expect(AppConfig.fromJson(j).supportUri, isNull);
    });
  });
}
