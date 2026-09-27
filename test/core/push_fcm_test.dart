/// الدفع عبر FCM (المرحلة ٢.٣) — بمحوِّل مراسلةٍ مزيّف، بلا Firebase ولا منصة:
/// خيارات `--dart-define`، المزوّد، قراءة الحمولة، والمنسّق مع دورة الجلسة
/// (إذن ⇒ تسجيل ⇒ تدوير ⇒ خروج) والملاحة والشارة والإشعار التجريبي.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/app/bootstrap/launch_controller.dart';
import 'package:lynomia_hub_app/app/bootstrap/push_coordinator.dart';
import 'package:lynomia_hub_app/core/push/fcm_push_provider.dart';
import 'package:lynomia_hub_app/core/push/firebase_env.dart';
import 'package:lynomia_hub_app/core/push/push_message.dart';
import 'package:lynomia_hub_app/core/push/push_registrar.dart';

import '../fakes/fakes.dart';
import '../widget/rtl_app_test.dart' show appConfigPayload;

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('FirebaseEnv (--dart-define)', () {
    const full = {
      'FIREBASE_PROJECT_ID': 'lynomia-hub',
      'FIREBASE_MESSAGING_SENDER_ID': '1234567890',
      'FIREBASE_ANDROID_API_KEY': 'AIza-android',
      'FIREBASE_ANDROID_APP_ID': '1:1234567890:android:abc',
      'FIREBASE_IOS_API_KEY': 'AIza-ios',
      'FIREBASE_IOS_APP_ID': '1:1234567890:ios:def',
      'FIREBASE_IOS_BUNDLE_ID': 'com.example.hub',
    };

    test('البناء الافتراضي بلا defines ⇒ غير مهيأ (NOT_CONFIGURED)', () {
      expect(FirebaseEnv.resolve(FirebasePlatform.android), isNull);
      expect(FirebaseEnv.resolve(FirebasePlatform.ios), isNull);
    });

    test('مكتمل ⇒ خيارات المنصة الجارية وحدها', () {
      final a = FirebaseEnv.resolve(FirebasePlatform.android, defines: full)!;
      expect(a.apiKey, 'AIza-android');
      expect(a.appId, '1:1234567890:android:abc');
      expect(a.iosBundleId, isNull);
      final i = FirebaseEnv.resolve(FirebasePlatform.ios, defines: full)!;
      expect(i.apiKey, 'AIza-ios');
      expect(i.iosBundleId, 'com.example.hub');
      expect(i.projectId, 'lynomia-hub');
    });

    test('حقلٌ إلزاميٌّ ناقص أو فارغ ⇒ غير مهيأ', () {
      for (final key in FirebaseEnv.requiredKeys(FirebasePlatform.android)) {
        final d = Map.of(full)..[key] = '  ';
        expect(
          FirebaseEnv.resolve(FirebasePlatform.android, defines: d),
          isNull,
          reason: key,
        );
      }
    });

    test('قيم القالب (REPLACE_BEFORE_STORE_RELEASE) ⇒ غير مهيأ', () {
      final d = Map.of(full)
        ..['FIREBASE_ANDROID_API_KEY'] = 'REPLACE_BEFORE_STORE_RELEASE';
      expect(FirebaseEnv.resolve(FirebasePlatform.android, defines: d), isNull);
    });

    test('معرّف تطبيقٍ لمنصةٍ أخرى ⇒ رفض (خطأ إعداد لا فشل SDK)', () {
      final d = Map.of(full)
        ..['FIREBASE_ANDROID_APP_ID'] = '1:1234567890:ios:def';
      expect(FirebaseEnv.resolve(FirebasePlatform.android, defines: d), isNull);
    });
  });

  group('PushPayload', () {
    test('وجهة قانونية + عدّاد', () {
      final p = PushPayload.of(
        const PushMessage(
          title: 'مهمة',
          data: {
            'notification_id': 'n-1',
            'category': 'task',
            'unread': '4',
            'module': 'tasks',
            'id': '42',
            'action': 'show',
          },
        ),
      );
      expect(p.target!.routePath, '/r/tasks/42');
      expect(p.unread, 4);
      expect(p.isTest, isFalse);
      expect(p.navigable, isTrue);
    });

    test('notification_id وحده ⇒ قابل للحلّ بلا وجهة مباشرة', () {
      final p = PushPayload.of(
        const PushMessage(data: {'notification_id': 'n-2', 'unread': 'x'}),
      );
      expect(p.target, isNull);
      expect(p.unread, isNull);
      expect(p.navigable, isTrue);
    });

    test('التجريبي لا يُنقل منه', () {
      final p = PushPayload.of(const PushMessage(data: {'category': 'test'}));
      expect(p.isTest, isTrue);
      expect(p.navigable, isFalse);
    });
  });

  group('FcmPushProvider', () {
    test('رمز فارغ/خطأ APNs ⇒ لا رمز بعد (لا عطل)', () async {
      final a = FakeMessagingAdapter(token: '');
      final p = FcmPushProvider(a);
      expect(p.configured, isTrue);
      expect(p.providerName, 'fcm');
      expect(await p.currentToken(), isNull);
      a.tokenError = StateError('apns-token-not-set');
      expect(await p.currentToken(), isNull);
    });
  });

  group('PushCoordinator', () {
    Future<(TestHarness, FakeMessagingAdapter, List<String>)> boot({
      FakeMessagingAdapter? adapter,
      bool start = true,
    }) async {
      final a = adapter ?? FakeMessagingAdapter(token: 'fcm-1');
      final h = TestHarness.create(pushProvider: FcmPushProvider(a));
      await h.seedSession();
      h.transport.onData('GET app-config', appConfigPayload());
      h.transport.onData('GET bootstrap', bootstrapPayload());
      h.transport.onData('POST push/register', {'registered': true});
      h.transport.onData('POST push/unregister', {'revoked': 1});
      h.transport.onData('POST auth/logout', {'revoked': true});
      final nav = <String>[];
      h.container.inbox.attachNavigator(nav.add);
      await h.container.pushCoordinator.attach();
      if (start) {
        await h.container.launch.start();
        await settle();
      }
      return (h, a, nav);
    }

    test('الجاهزية ⇒ إذن ثم push/register بالعقد', () async {
      final (h, a, _) = await boot();
      expect(h.container.launch.state, isA<LaunchReady>());
      expect(a.permissionRequests, 1);
      final reg = h.transport.sent('POST push/register').single;
      expect(reg.jsonBody['platform'], anyOf('android', 'ios'));
      expect(reg.jsonBody['provider'], 'fcm');
      expect(reg.jsonBody['token'], 'fcm-1');
      expect(h.container.push.status, PushSetupStatus.registered);
      h.dispose();
    });

    test('رفض الإذن ⇒ حالة صادقة ولا تسجيل', () async {
      final (h, _, _) = await boot(
        adapter: FakeMessagingAdapter(token: 'fcm-1', grant: false),
      );
      expect(h.transport.sent('POST push/register'), isEmpty);
      expect(h.container.push.status, PushSetupStatus.permissionDenied);
      h.dispose();
    });

    test('فشل التسجيل خادمياً لا يكسر الإقلاع', () async {
      final a = FakeMessagingAdapter(token: 'fcm-1');
      final h = TestHarness.create(pushProvider: FcmPushProvider(a));
      await h.seedSession();
      h.transport.onData('GET app-config', appConfigPayload());
      h.transport.onData('GET bootstrap', bootstrapPayload());
      h.transport.on(
        'POST push/register',
        (_) => apiError('INTERNAL_ERROR', 500),
      );
      await h.container.pushCoordinator.attach();
      await h.container.launch.start();
      await settle();
      expect(h.container.launch.state, isA<LaunchReady>());
      expect(h.container.push.status, isNot(PushSetupStatus.registered));
      h.dispose();
    });

    test('تدوير الرمز ⇒ تسجيل الجديد وإلغاء القديم', () async {
      final (h, a, _) = await boot();
      a.refresh.add('fcm-2');
      await settle();
      final regs = h.transport.sent('POST push/register');
      expect(regs.map((r) => r.jsonBody['token']), ['fcm-1', 'fcm-2']);
      expect(
        h.transport.sent('POST push/unregister').single.jsonBody['token'],
        'fcm-1',
      );
      // الخروج يلغي الرمز الحالي لا القديم.
      await h.container.signOut();
      expect(
        h.transport.sent('POST push/unregister').last.jsonBody['token'],
        'fcm-2',
      );
      h.dispose();
    });

    test('رمز iOS يصل متأخراً عبر التدوير ⇒ يُسجَّل', () async {
      final (h, a, _) = await boot(adapter: FakeMessagingAdapter(token: null));
      expect(h.container.push.status, PushSetupStatus.ready);
      a.refresh.add('fcm-late');
      await settle();
      expect(
        h.transport.sent('POST push/register').single.jsonBody['token'],
        'fcm-late',
      );
      h.dispose();
    });

    test('المقدّمة ⇒ شريط + الشارة من data.unread', () async {
      final (h, a, nav) = await boot();
      final banners = <PushBanner>[];
      h.container.pushCoordinator.banners.listen(banners.add);
      a.foreground.add(
        const PushMessage(
          title: 'موافقة',
          data: {
            'notification_id': 'n-9',
            'unread': '7',
            'module': 'tasks',
            'id': '5',
          },
        ),
      );
      await settle();
      expect(banners.single.openable, isTrue);
      expect(h.container.account.unreadNotifications, 7);
      expect(nav, isEmpty, reason: 'المقدّمة لا تنقل تلقائياً');

      h.container.pushCoordinator.open(banners.single.payload);
      await settle();
      expect(nav, ['/r/tasks/5']);
      h.dispose();
    });

    test('نقرة بوجهة ⇒ /r/{module}/{id}', () async {
      final (h, a, nav) = await boot();
      a.opened.add(
        const PushMessage(
          data: {'notification_id': 'n-1', 'module': 'crm', 'id': '12'},
        ),
      );
      await settle();
      expect(nav, ['/r/crm/12']);
      expect(h.transport.sent('GET notifications/n-1/target'), isEmpty);
      h.dispose();
    });

    test('notification_id وحده ⇒ notifications/{id}/target', () async {
      final (h, a, nav) = await boot();
      h.transport.onData('GET notifications/n-3/target', {
        'target': {'module': 'leaves', 'id': '8', 'action': 'show'},
      });
      h.transport.onData('GET notifications/n-4/target', {'target': null});
      a.opened.add(const PushMessage(data: {'notification_id': 'n-3'}));
      await settle();
      expect(nav, ['/r/leaves/8']);
      a.opened.add(const PushMessage(data: {'notification_id': 'n-4'}));
      await settle();
      expect(nav.last, '/notifications', reason: 'بلا وجهة ⇒ الصندوق');
      h.dispose();
    });

    test('التجريبي ⇒ يُعرض بلا ملاحة ولا طلب', () async {
      final (h, a, nav) = await boot();
      final banners = <PushBanner>[];
      h.container.pushCoordinator.banners.listen(banners.add);
      final before = h.transport.requests.length;
      a.opened.add(
        const PushMessage(title: 'اختبار', data: {'category': 'test'}),
      );
      await settle();
      expect(nav, isEmpty);
      expect(banners.single.payload.isTest, isTrue);
      expect(banners.single.openable, isFalse);
      expect(h.transport.requests.length, before);
      h.dispose();
    });

    test('إشعار الإطلاق من الإغلاق ⇒ يُنتظر حتى الجاهزية ثم يُفتح', () async {
      final a = FakeMessagingAdapter(
        token: 'fcm-1',
        initial: const PushMessage(data: {'module': 'tasks', 'id': '3'}),
      );
      final (h, _, nav) = await boot(adapter: a, start: false);
      await settle();
      expect(nav, isEmpty, reason: 'لا ملاحة قبل الجاهزية');
      expect(h.container.inbox.hasPending, isTrue);
      await h.container.launch.start();
      await settle();
      expect(nav, ['/r/tasks/3']);
      h.dispose();
    });

    test('المزوّد الصفري ⇒ لا إذن ولا طلب ولا بثّ', () async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET app-config', appConfigPayload());
      h.transport.onData('GET bootstrap', bootstrapPayload());
      await h.container.pushCoordinator.attach();
      await h.container.launch.start();
      await settle();
      expect(h.transport.sent('POST push/register'), isEmpty);
      expect(h.container.push.status, PushSetupStatus.notConfigured);
      h.dispose();
    });
  });

  group('NavigationInbox (رابط عميق)', () {
    test('رابطٌ قبل الدخول يُحفظ ثم يُسلَّم بعد الجاهزية', () async {
      final h = TestHarness.create();
      final nav = <String>[];
      h.container.inbox.attachNavigator(nav.add);
      h.container.inbox.deliverLocation('/m/tasks/1');
      await settle();
      expect(nav, isEmpty);

      await h.seedSession();
      h.transport.onData('GET app-config', appConfigPayload());
      h.transport.onData('GET bootstrap', bootstrapPayload());
      await h.container.launch.start();
      await settle();
      expect(nav, ['/m/tasks/1']);
      expect(h.container.inbox.hasPending, isFalse);
      h.dispose();
    });
  });
}
