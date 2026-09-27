/// المرحلة ١ على التطبيق الكامل: الخبيئة دون اتصال بيانات حقيقية (١.٢)، والإشعار
/// يفتح هدفه والشارة حيّة (١.٤)، والتفضيلات والمثبتات على الرئيسية (١.٥)،
/// و`health` عند الاستئناف (١.٦)، وتلميح الإصدار ورابط الدعم (١.٧).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/app/bootstrap/launch_controller.dart';
import 'package:lynomia_hub_app/features/shell/app_shell.dart';

import '../fakes/fakes.dart';
import '../fakes/screen_harness.dart';
import 'rtl_app_test.dart'
    show appConfigPayload, pumpAuthenticatedApp, wireAuthenticatedRoutes;

Map<String, dynamic> _syncTasks() => {
  'module': 'tasks',
  'sync_class': 'CACHEABLE_INCREMENTAL',
  'cacheable': true,
  'conflict_token': true,
  'records': [
    {'id': 't1', 'title': 'تجهيز العرض', 'status': 'جارية', 'version': 3},
    {'id': 't9', 'title': 'مهمة مخبأة', 'status': 'جديدة', 'version': 1},
  ],
  'tombstones': <dynamic>[],
  'has_tombstones': true,
  'next_cursor': 'c1',
  'has_more': false,
  'sync_version': 'v1',
};

Map<String, dynamic> _prefsPayload({List<String> pinned = const ['m:tasks']}) {
  Map<String, dynamic> target(String token, String label, {String? module}) => {
    'token': token,
    'label': label,
    'pinned': pinned.contains(token),
    'module': ?module,
  };
  final targets = [
    target('m:tasks', '📄 المهام', module: 'tasks'),
    target('m:projects', '📄 المشاريع', module: 'projects'),
  ];
  return {
    'notify': {
      'mute': ['react'],
      'muteable': [
        {'key': 'react', 'label': 'التفاعلات على منشوراتي', 'muted': true},
        {'key': 'mention', 'label': 'الإشارات إليّ (@)', 'muted': false},
      ],
    },
    'pins': {
      'pinned': targets.where((t) => t['pinned'] == true).toList(),
      'targets': targets,
      'max': 12,
    },
  };
}

BuildContext _shellCtx(WidgetTester tester) =>
    tester.element(find.byType(AppShell));

/// تمرير حتى يظهر العنصر في أول قائمة ظاهرة (الشاشة الحالية).
Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

/// عودة من الشاشة المدفوعة عبر الموجّه (زر الرجوع يتبع المنصة).
Future<void> _back(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('١.٢ المزامنة في الإنتاج', () {
    testWidgets(
      'فتح القائمة يملأ الخبيئة، والانقطاع بعدها يعرض بيانات حقيقية مخبأة',
      (tester) async {
        final h = TestHarness.create();
        await h.seedSession();
        wireAuthenticatedRoutes(h);
        h.transport.onData('GET sync/tasks', _syncTasks());
        await tester.pumpWidget(
          LynomiaApp(container: h.container, listenAppLinks: false),
        );
        await tester.pumpAndSettle();

        GoRouter.of(_shellCtx(tester)).push('/m/tasks');
        await settleIo(tester);
        expect(find.text('مراجعة العقد'), findsOneWidget); // القائمة الحية
        expect(h.transport.sent('GET sync/tasks'), isNotEmpty);
        expect(
          await tester.runAsync(() => h.container.sync.hasDiskTrace('tasks')),
          isTrue,
        );

        // انقطاع: القائمة الحية تفشل ⇒ سقوط صادق للخبيئة بلافتة بائت.
        h.transport.on(
          'GET tasks',
          (_) => throw http.ClientException('offline'),
        );
        await _back(tester);
        GoRouter.of(_shellCtx(tester)).push('/m/tasks');
        await settleIo(tester);

        expect(find.text('أنت دون اتصال — تُعرض نسخة مخبأة'), findsOneWidget);
        expect(find.text('مهمة مخبأة'), findsOneWidget);
        expect(find.text('مراجعة العقد'), findsNothing);
        h.dispose();
      },
    );

    testWidgets('وحدة حساسة: لا مزامنة ولا خبيئة — الانقطاع خطأ صادق', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      final schema = schemaPayload();
      (schema['modules'] as List).add({
        'key': 'vault',
        'label': 'الخزنة',
        'sync_class': 'SENSITIVE_NO_PERSIST',
        'can': {'v': true},
        'fields': [
          {'key': 'name', 'label': 'الاسم', 'type': 'text'},
        ],
      });
      h.transport.onData('GET schema', schema);
      h.transport.on(
        'GET vault',
        (_) => okList([
          {'id': 'v1', 'name': 'سر حساس', 'version': 1},
        ]),
      );
      h.transport.onData('GET sync/vault', _syncTasks());
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();

      GoRouter.of(_shellCtx(tester)).push('/m/vault');
      await settleIo(tester);
      expect(find.text('سر حساس'), findsOneWidget);
      expect(h.transport.sent('GET sync/vault'), isEmpty);
      expect(
        await tester.runAsync(() => h.container.sync.hasDiskTrace('vault')),
        isFalse,
      );

      h.transport.on('GET vault', (_) => throw http.ClientException('x'));
      await _back(tester);
      GoRouter.of(_shellCtx(tester)).push('/m/vault');
      await settleIo(tester);
      expect(find.text('أنت دون اتصال — تُعرض نسخة مخبأة'), findsNothing);
      expect(find.text('سر حساس'), findsNothing);
      h.dispose();
    });
  });

  group('١.٤ الإشعار يفتح هدفه والشارة حيّة', () {
    testWidgets('المقروء سلفاً يُحلّ بـ GET target لا بقراءة ثانية', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.onData('GET notifications', {
        'notifications': [
          {
            'id': 'n1',
            'kind': 'task',
            'text': 'مهمة قديمة',
            'read': true,
            'target': null,
            'created_at': '2026-09-08T10:00:00Z',
          },
        ],
        'unread': 0,
        'cursor': {'next': null, 'has_more': false, 'per': 25},
      });
      h.transport.onData('GET notifications/n1/target', {
        'id': 'n1',
        'target': {'module': 'tasks', 'id': 't1', 'action': 'show'},
      });

      await tester.tap(find.byTooltip('الإشعارات').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('مهمة قديمة'));
      await tester.pumpAndSettle();

      expect(h.transport.sent('GET notifications/n1/target'), hasLength(1));
      expect(h.transport.sent('POST notifications/n1/read'), isEmpty);
      expect(find.text('تفاصيل المهمة'), findsOneWidget); // شاشة السجل
      h.dispose();
    });

    testWidgets('وجهة null ⇒ البقاء في القائمة، والشارة من رد القراءة', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      expect(h.container.account.unreadNotifications, 2);
      h.transport.onData('GET notifications', {
        'notifications': [
          {
            'id': 'n2',
            'kind': 'system',
            'text': 'تنبيه عام',
            'read': false,
            'target': null,
            'created_at': '2026-09-08T10:00:00Z',
          },
        ],
        'unread': 5,
        'cursor': {'next': null, 'has_more': false, 'per': 25},
      });
      h.transport.onData('POST notifications/n2/read', {
        'id': 'n2',
        'read': true,
        'unread': 4,
        'target': null,
      });

      await tester.tap(find.byTooltip('الإشعارات').first);
      await tester.pumpAndSettle();
      expect(h.container.account.unreadNotifications, 5);

      await tester.tap(find.text('تنبيه عام'));
      await tester.pumpAndSettle();
      expect(
        find.text('لا وجهة لهذا الإشعار — بقي في القائمة'),
        findsOneWidget,
      );
      expect(find.text('تنبيه عام'), findsOneWidget); // ما زلنا في القائمة
      expect(h.container.account.unreadNotifications, 4);
      h.dispose();
    });

    testWidgets('الاستئناف يحدّث الشارة من unread-count', (tester) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.onData('GET notifications/unread-count', {'unread': 9});
      h.transport.onData('GET health', {
        'status': 'ok',
        'maintenance': false,
        'lockdown': false,
        'update_required': false,
      });
      await h.container.resume.refreshBadge(force: true);
      await tester.pumpAndSettle();
      expect(find.text('9'), findsWidgets); // شارة الشريط والرأس
      h.dispose();
    });
  });

  group('١.٥ التفضيلات والمثبتات', () {
    testWidgets('الرئيسية تعرض مثبتاتي من الخادم وتفتح الوحدة', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      h.transport.onData('GET prefs', _prefsPayload());
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('مثبتاتي'), findsOneWidget);
      await tester.tap(find.byKey(const Key('home-pin-m:tasks')));
      await tester.pumpAndSettle();
      expect(find.text('مراجعة العقد'), findsOneWidget); // قائمة المهام
      h.dispose();
    });

    testWidgets('حسابي ← التفضيلات: كتم نوعٍ وتثبيت وجهة على الخادم', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      var pinned = <String>['m:tasks'];
      h.transport.on('GET prefs', (_) => okData(_prefsPayload(pinned: pinned)));
      h.transport.on('PUT prefs', (req) {
        return okData({
          'notify': {'mute': req.jsonBody['mute']},
        });
      });
      h.transport.on('POST prefs/pin', (req) {
        final token = req.jsonBody['token'] as String;
        pinned = pinned.contains(token)
            ? (pinned..remove(token))
            : [...pinned, token];
        return okData({
          'token': token,
          'pinned': pinned.contains(token),
          'pins': pinned,
          'message': 'تم',
        });
      });

      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-prefs')));
      await tester.pumpAndSettle();
      expect(find.text('التفاعلات على منشوراتي'), findsOneWidget);
      expect(find.text('مثبّت 1 من 12'), findsOneWidget);

      // إشعار الإشارات يُكتم ⇒ PUT بالقائمة الكاملة (استبدال).
      await tester.tap(find.byKey(const Key('mute-mention')));
      await tester.pumpAndSettle();
      final put = h.transport.sent('PUT prefs').single;
      expect((put.jsonBody['mute'] as List).toSet(), {'react', 'mention'});

      // تثبيت المشاريع ⇒ POST بمفتاح idempotency، والعرض من إعادة الجلب.
      await _scrollTo(tester, find.byKey(const Key('pin-m:projects')));
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('pin-m:projects')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      final pin = h.transport.sent('POST prefs/pin').single;
      expect(pin.jsonBody['token'], 'm:projects');
      expect(pin.headers['Idempotency-Key'], isNotEmpty);
      expect(find.text('مثبّت 2 من 12'), findsOneWidget);
      h.dispose();
    });

    testWidgets('بلوغ السقف: رسالة الخادم برمز BUSINESS_RULE_VIOLATION', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.onData('GET prefs', _prefsPayload());
      h.transport.on(
        'POST prefs/pin',
        (_) => apiError(
          'BUSINESS_RULE_VIOLATION',
          422,
          message: 'بلغت الحد الأقصى للمثبتات',
        ),
      );
      GoRouter.of(_shellCtx(tester)).go('/account/prefs');
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.byKey(const Key('pin-m:projects')));
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('pin-m:projects')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('بلغت الحد الأقصى للمثبتات'), findsOneWidget);
      h.dispose();
    });
  });

  group('١.٦ health عند الاستئناف', () {
    testWidgets('صيانة أثناء الاستعمال ⇒ شاشة الصيانة', (tester) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.onData('GET notifications/unread-count', {'unread': 0});
      h.transport.onData('GET health', {
        'status': 'maintenance',
        'maintenance': true,
        'lockdown': false,
        'update_required': false,
      });

      await h.container.resume.checkHealth(force: true);
      await tester.pumpAndSettle();
      expect(h.container.launch.state, isA<LaunchMaintenance>());
      expect(find.text('صيانة مجدولة'), findsOneWidget);
      h.dispose();
    });

    testWidgets('الإغلاق عبر 503 LOCKDOWN من health ⇒ شاشة الإغلاق', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.on('GET health', (_) => apiError('LOCKDOWN', 503));
      await h.container.resume.checkHealth(force: true);
      await tester.pumpAndSettle();
      final state = h.container.launch.state;
      expect(state, isA<LaunchMaintenance>());
      expect((state as LaunchMaintenance).lockdown, isTrue);
      h.dispose();
    });

    testWidgets('تحديث مطلوب مُجبر ⇒ شاشة حاجبة؛ غير مجبر ⇒ تلميح في حسابي', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.onData('GET health', {
        'status': 'update_required',
        'maintenance': false,
        'lockdown': false,
        'update_required': true,
      });
      // غير مجبر أولاً.
      h.transport.onData(
        'GET app-config',
        appConfigPayload(updateRequired: true, force: false),
      );
      await h.container.resume.checkHealth(force: true);
      await tester.pumpAndSettle();
      expect(h.container.launch.state, isA<LaunchReady>());
      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        find.byKey(const Key('account-update-available')),
      );
      expect(find.text('إصدار أحدث متاح'), findsOneWidget);

      // ثم مجبر ⇒ حجب.
      h.transport.onData(
        'GET app-config',
        appConfigPayload(updateRequired: true, force: true),
      );
      await h.container.resume.checkHealth(force: true);
      await tester.pumpAndSettle();
      expect(h.container.launch.state, isA<LaunchUpdateRequired>());
      expect(find.text('تحديث مطلوب'), findsOneWidget);
      h.dispose();
    });
  });

  group('١.٧ تلميح الإصدار ورابط الدعم', () {
    testWidgets('latest أحدث من الجاري + support_url ⇒ يظهران في حسابي', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      final cfg = appConfigPayload();
      cfg['version_gate'] = {
        'ios': {'min': '', 'latest': ''},
        'android': {'min': '', 'latest': '0.2.0'}, // الجاري 0.1.0
        'force_update': false,
      };
      cfg['support_url'] = 'https://support.example.com/help';
      h.transport.onData('GET app-config', cfg);
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.byKey(const Key('account-support')));
      expect(find.byKey(const Key('account-update-available')), findsOneWidget);
      expect(find.text('الدعم'), findsOneWidget);
      h.dispose();
    });

    testWidgets('بلا latest أحدث ولا دعم مهيأ ⇒ لا تلميح ولا زر ميت', (
      tester,
    ) async {
      final h = await pumpAuthenticatedApp(tester);
      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-update-available')), findsNothing);
      expect(find.byKey(const Key('account-support')), findsNothing);
      h.dispose();
    });

    testWidgets('بوابة الصيانة تعرض رابط الدعم حين يهيئه الخادم', (
      tester,
    ) async {
      final h = TestHarness.create();
      final cfg = appConfigPayload(maintenance: true);
      cfg['support_url'] = 'https://support.example.com';
      h.transport.onData('GET app-config', cfg);
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('launch-support')), findsOneWidget);
      h.dispose();
    });
  });
}
