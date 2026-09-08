/// تدفقات المصادقة (§105) — دخول/اعتماد خاطئ/MFA/تقييد/خروج/تصعيد/جلسات.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/auth/auth_repository.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  test('دخول ناجح بلا MFA: جسم العقد كامل وجلسة تتبنى', () async {
    h.transport.on('POST auth/login', (req) {
      final body = req.jsonBody;
      expect(body['email'], 'user@example.com');
      expect(body['installation_uuid'], isNotEmpty);
      expect(body['platform'], 'android');
      expect(body['app_version'], '0.1.0');
      return okData(sessionPayload());
    });

    final outcome = await h.container.auth.login(
      email: 'user@example.com',
      password: 'secret',
    );

    expect(outcome, isA<LoginSession>());
    final session = outcome as LoginSession;
    expect(session.user.name, 'مستخدم الاختبار');
    await h.container.session.adopt(session.tokens);
    expect(h.container.session.hasSession, isTrue);
  });

  test('اعتماد خاطئ: UNAUTHENTICATED واحدة لا تمييز فيها', () async {
    h.transport.on(
      'POST auth/login',
      (_) =>
          apiError('UNAUTHENTICATED', 401, message: 'بيانات الدخول غير صحيحة'),
    );
    await expectLater(
      h.container.auth.login(email: 'x@y.z', password: 'bad'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.unauthenticated,
        ),
      ),
    );
  });

  test('MFA: تحدٍ ثم تحقق ناجح (§33)', () async {
    h.transport.on(
      'POST auth/login',
      (_) => apiError(
        'MFA_REQUIRED',
        401,
        details: {
          'challenge_id': 'ch-1',
          'methods': ['totp'],
          'expires_at': DateTime.now()
              .add(const Duration(minutes: 5))
              .toIso8601String(),
        },
      ),
    );
    h.transport.on('POST auth/mfa/verify', (req) {
      expect(req.jsonBody['challenge_id'], 'ch-1');
      expect(req.jsonBody['code'], '123456');
      return okData(sessionPayload());
    });

    final outcome = await h.container.auth.login(email: 'a@b.c', password: 'p');
    expect(outcome, isA<LoginMfaChallenge>());
    final challenge = outcome as LoginMfaChallenge;
    expect(challenge.methods, ['totp']);

    final session = await h.container.auth.mfaVerify(
      challengeId: challenge.challengeId,
      code: '123456',
    );
    expect(session.tokens.accessToken, startsWith('lyma_'));
  });

  test('حساب مقيد بعد إثبات الاعتماد: ACCOUNT_RESTRICTED (§95)', () async {
    h.transport.on(
      'POST auth/login',
      (_) => apiError('ACCOUNT_RESTRICTED', 403, message: 'الحساب موقوف'),
    );
    await expectLater(
      h.container.auth.login(email: 'a@b.c', password: 'p'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.accountRestricted,
        ),
      ),
    );
  });

  test(
    'الصيانة قبل الدخول: MAINTENANCE مميزة عن انقطاع الشبكة (§94)',
    () async {
      h.transport.on('GET app-config', (_) => apiError('MAINTENANCE', 503));
      await expectLater(
        h.container.appConfig.fetch(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.maintenance,
          ),
        ),
      );
    },
  );

  test('الخروج والخروج الشامل يستدعيان العقد ويمسحان محلياً (§39)', () async {
    await h.seedSession();
    h.transport.onData('POST auth/logout', {'ok': true});
    await h.container.signOut();
    expect(h.transport.sent('POST auth/logout'), hasLength(1));
    expect(h.container.session.hasSession, isFalse);
    expect(h.secureStore.values.containsKey('lynomia.session'), isFalse);
  });

  test('قائمة الجلسات وإبطال جلسة (§39)', () async {
    await h.seedSession();
    h.transport.onData('GET auth/sessions', {
      'sessions': [
        {'id': 'sess-1', 'platform': 'android', 'app_version': '0.1.0'},
        {'id': 'sess-2', 'platform': 'ios', 'app_version': '0.1.0'},
      ],
    });
    h.transport.onData('DELETE auth/sessions/sess-2', {'revoked': true});

    final sessions = await h.container.auth.sessions(
      currentId: h.container.session.sessionId,
    );
    expect(sessions, hasLength(2));
    expect(sessions.first.current, isTrue);

    await h.container.auth.revokeSession('sess-2');
    expect(h.transport.sent('DELETE auth/sessions/sess-2'), hasLength(1));
  });

  test('التصعيد يرسل الغرض والاعتماد (§41)', () async {
    await h.seedSession();
    h.transport.on('POST auth/step-up', (req) {
      expect(req.jsonBody['purpose'], 'action:tasks:status');
      expect(req.jsonBody['credential'], '123456');
      return okData({'granted': true, 'purpose': 'action:tasks:status'});
    });
    await h.container.auth.stepUp(
      purpose: 'action:tasks:status',
      credential: '123456',
    );
  });
}
