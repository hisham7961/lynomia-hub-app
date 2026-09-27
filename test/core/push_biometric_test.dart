/// مسجِّل الدفع وبوابة البصمة (المرحلة ١.٩) — بمزوّدٍ وبوابةٍ مزيّفين:
/// لا تسجيل بلا مزوّد مهيأ، والتسجيل/الإلغاء على العقد، والقفل المحلي يحجب
/// الجلسة المخزنة حتى الفتح، ولا يُطلب بلا تفضيلٍ أو عتاد.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/app/bootstrap/launch_controller.dart';
import 'package:lynomia_hub_app/core/push/push_registrar.dart';
import 'package:lynomia_hub_app/core/security/biometric_gate.dart';
import 'package:local_auth/local_auth.dart';

import '../fakes/fakes.dart';
import '../widget/rtl_app_test.dart' show appConfigPayload;

class FakePushProvider implements PushTokenProvider {
  FakePushProvider({this.token, this.configured = true});

  String? token;
  @override
  final bool configured;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get tokenRotations => const Stream.empty();

  @override
  String get providerName => 'fcm';
}

class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate({this.isAvailable = true, this.succeed = true});

  bool isAvailable;
  bool succeed;
  final List<String> reasons = [];

  @override
  Future<bool> get available async => isAvailable;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return succeed;
  }
}

/// بديل `LocalAuthentication` لاختبار المحوِّل دون قناة منصة.
class FakeLocalAuth extends LocalAuthentication {
  FakeLocalAuth({required this.supported, required this.canCheck});

  final bool supported;
  final bool canCheck;
  AuthenticationOptions? lastOptions;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    lastOptions = options;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushRegistrar', () {
    test('المزوّد الصفري: NOT_CONFIGURED بلا أي طلب (لا اختلاق)', () async {
      final h = TestHarness.create();
      await h.seedSession();
      final status = await h.container.push.registerIfPossible(
        platform: 'android',
      );
      expect(status, PushSetupStatus.notConfigured);
      expect(h.transport.requests, isEmpty);
      await h.container.push.unregisterQuietly();
      expect(h.transport.requests, isEmpty);
      h.dispose();
    });

    test('مزوّد مهيأ بلا رمز بعد ⇒ ready ولا تسجيل', () async {
      final h = TestHarness.create(pushProvider: FakePushProvider());
      await h.seedSession();
      expect(
        await h.container.push.registerIfPossible(platform: 'ios'),
        PushSetupStatus.ready,
      );
      expect(h.transport.sent('POST push/register'), isEmpty);
      h.dispose();
    });

    test('تسجيل الرمز على العقد ثم إلغاؤه عند الخروج', () async {
      final h = TestHarness.create(
        pushProvider: FakePushProvider(token: 'fcm-token-1'),
      );
      await h.seedSession();
      h.transport.onData('POST push/register', {'registered': true});
      h.transport.onData('POST push/unregister', {'unregistered': true});
      h.transport.onData('POST auth/logout', {'revoked': true});

      expect(
        await h.container.push.registerIfPossible(platform: 'android'),
        PushSetupStatus.registered,
      );
      final reg = h.transport.sent('POST push/register').single;
      expect(reg.jsonBody, {
        'token': 'fcm-token-1',
        'platform': 'android',
        'provider': 'fcm',
      });
      expect(reg.headers['Authorization'], startsWith('Bearer '));

      await h.container.signOut();
      expect(
        h.transport.sent('POST push/unregister').single.jsonBody['token'],
        'fcm-token-1',
      );
      expect(h.container.push.status, PushSetupStatus.ready);
      h.dispose();
    });

    test('فشل الإلغاء لا يحجب الخروج', () async {
      final h = TestHarness.create(
        pushProvider: FakePushProvider(token: 'fcm-token-2'),
      );
      await h.seedSession();
      h.transport.onData('POST push/register', {'registered': true});
      h.transport.on(
        'POST push/unregister',
        (_) => apiError('INTERNAL_ERROR', 500),
      );
      h.transport.onData('POST auth/logout', {'revoked': true});
      await h.container.push.registerIfPossible(platform: 'android');

      await h.container.signOut();
      expect(h.container.session.hasSession, isFalse);
      h.dispose();
    });
  });

  group('بوابة البصمة (قفل محلي §40)', () {
    Future<TestHarness> boot(FakeBiometricGate gate, {bool pref = true}) async {
      final h = TestHarness.create(biometricGate: gate);
      await h.seedSession();
      h.transport.onData('GET app-config', appConfigPayload());
      h.transport.onData('GET bootstrap', bootstrapPayload());
      await h.container.biometricPref.setEnabled(pref);
      await h.container.launch.start();
      return h;
    }

    test('مفعّل ومتاح ⇒ قفل قبل bootstrap، والفشل يُبقي القفل', () async {
      final gate = FakeBiometricGate(succeed: false);
      final h = await boot(gate);
      expect(h.container.launch.state, isA<LaunchLocked>());
      expect(h.transport.sent('GET bootstrap'), isEmpty);

      await h.container.launch.unlock('افتح');
      expect(h.container.launch.state, isA<LaunchLocked>());
      expect(gate.reasons, ['افتح']);

      gate.succeed = true;
      await h.container.launch.unlock('افتح');
      expect(h.container.launch.state, isA<LaunchReady>());
      expect(h.transport.sent('GET bootstrap'), hasLength(1));
      h.dispose();
    });

    test('غير مفعّل أو بلا عتاد ⇒ لا قفل', () async {
      final h1 = await boot(FakeBiometricGate(), pref: false);
      expect(h1.container.launch.state, isA<LaunchReady>());
      h1.dispose();

      final h2 = await boot(FakeBiometricGate(isAvailable: false));
      expect(h2.container.launch.state, isA<LaunchReady>());
      h2.dispose();
    });

    test('التفضيل محلي غير حساس ويثبت عبر القراءة', () async {
      final h = TestHarness.create();
      expect(await h.container.biometricPref.enabled, isFalse);
      await h.container.biometricPref.setEnabled(true);
      expect(await h.container.biometricPref.enabled, isTrue);
      h.dispose();
    });

    test(
      'LocalAuthBiometricGate: متاح بشرطَي الدعم والقدرة، وسقوط PIN مسموح',
      () async {
        expect(
          await LocalAuthBiometricGate(
            FakeLocalAuth(supported: true, canCheck: false),
          ).available,
          isFalse,
        );
        final auth = FakeLocalAuth(supported: true, canCheck: true);
        final gate = LocalAuthBiometricGate(auth);
        expect(await gate.available, isTrue);
        expect(await gate.authenticate('سبب'), isTrue);
        expect(auth.lastOptions!.biometricOnly, isFalse);
        expect(auth.lastOptions!.stickyAuth, isTrue);
      },
    );
  });
}
