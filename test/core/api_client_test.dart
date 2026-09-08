/// اختبارات عميل API (§100 §105 §106) — الترويسات، التدوير المتسلسل الواحد،
/// استمرار الزوج المدوّر، الأخطاء المكتوبة، الإعادة المحدودة.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/api/api_client.dart';
import 'package:lynomia_hub_app/core/auth/session_manager.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  group('الترويسات (§30 §106)', () {
    test('طلب مصادق يحمل ترويسات العقد كاملة ولا رمز في الرابط', () async {
      await h.seedSession();
      h.container.viewContext.setCompany('c-1', name: 'شركة');
      h.container.viewContext.setClient('k-9');
      h.transport.onData('GET home', {'x': 1});

      await h.container.api.getData('home');

      final req = h.transport.sent('GET home').single;
      expect(req.headers['Authorization'], 'Bearer lyma_access_1');
      expect(req.headers['X-Lynomia-App-Platform'], 'android');
      expect(req.headers['X-Lynomia-App-Version'], '0.1.0');
      expect(req.headers['X-Lynomia-App-Build'], '1');
      expect(req.headers['X-Lynomia-Installation-Id'], isNotEmpty);
      expect(req.headers['X-Request-Id'], isNotEmpty);
      expect(req.headers['X-Lynomia-Company'], 'c-1');
      expect(req.headers['X-Lynomia-Client'], 'k-9');
      expect(
        req.url.query.contains('lyma_'),
        isFalse,
        reason: 'لا رمز في رابط أبداً (§34)',
      );
    });

    test(
      'If-Match تُبث برقم مقتبس، وIdempotency-Key كما أعطي (§57 §58)',
      () async {
        await h.seedSession();
        h.transport.onData('PUT tasks/t1', {'id': 't1'});

        await h.container.api.sendData(
          'PUT',
          'tasks/t1',
          body: {'a': 1},
          ifMatchVersion: 3,
          idempotencyKey: 'op-key-1',
        );

        final req = h.transport.sent('PUT tasks/t1').single;
        expect(req.headers['If-Match'], '"3"');
        expect(req.headers['Idempotency-Key'], 'op-key-1');
      },
    );
  });

  group('التدوير المتسلسل (§36 §37 §105)', () {
    test(
      'انتهاء الوصول ⇒ تحديث واحد ثم إعادة — وتزامن 401 يتشارك التدوير',
      () async {
        await h.seedSession();

        var homeCalls = 0;
        h.transport.on('GET home', (req) {
          homeCalls++;
          if (req.headers['Authorization'] == 'Bearer lyma_access_1') {
            return apiError('UNAUTHENTICATED', 401);
          }
          return okData({'ok': true});
        });
        h.transport.on('GET search', (req) {
          if (req.headers['Authorization'] == 'Bearer lyma_access_1') {
            return apiError('UNAUTHENTICATED', 401);
          }
          return okData({'ok': true});
        });
        h.transport.on(
          'POST auth/refresh',
          (req) => okData(
            sessionPayload(access: 'lyma_access_2', refresh: 'lymr_refresh_2'),
          ),
        );

        // طلبان متزامنان يصطدمان بانتهاء الوصول معاً.
        await Future.wait([
          h.container.api.getData('home'),
          h.container.api.getData('search'),
        ]);

        expect(
          h.transport.sent('POST auth/refresh'),
          hasLength(1),
          reason: 'تحديث واحد لا خمسة — الرمز يستهلك لمرة (§36)',
        );
        expect(homeCalls, 2, reason: 'الفشل ثم الإعادة بالرمز الجديد');

        // §37: الزوج المدوّر استُبدل ذرياً في المخزن الآمن.
        final stored = jsonDecode(h.secureStore.values['lynomia.session']!);
        expect(stored['refresh_token'], 'lymr_refresh_2');
        expect(stored['access_token'], 'lyma_access_2');
      },
    );

    test('تحديث برمز باطل ⇒ مسح الاعتماد والعودة للمصادقة (§37)', () async {
      await h.seedSession();
      h.transport.on('GET home', (_) => apiError('UNAUTHENTICATED', 401));
      h.transport.on(
        'POST auth/refresh',
        (_) => apiError('REFRESH_TOKEN_INVALID', 401),
      );

      final ends = <SessionEndReason>[];
      h.container.session.endEvents.listen(ends.add);

      await expectLater(
        h.container.api.getData('home'),
        throwsA(isA<ApiException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(h.container.session.hasSession, isFalse);
      expect(h.secureStore.values.containsKey('lynomia.session'), isFalse);
      expect(ends, [SessionEndReason.expired]);
    });

    test('SESSION_REVOKED ينهي الجلسة فوراً (§38)', () async {
      await h.seedSession();
      h.transport.on('GET home', (_) => apiError('SESSION_REVOKED', 401));

      final ends = <SessionEndReason>[];
      h.container.session.endEvents.listen(ends.add);

      await expectLater(
        h.container.api.getData('home'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.sessionRevoked,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(h.container.session.hasSession, isFalse);
      expect(ends, [SessionEndReason.revoked]);
    });
  });

  group('الأخطاء المكتوبة (§31)', () {
    test('غلاف الخطأ يفكك إلى code/details/request_id', () async {
      await h.seedSession();
      h.transport.on(
        'PUT tasks/t1',
        (_) => apiError(
          'VERSION_CONFLICT',
          409,
          details: {'current_version': 5, 'your_version': 3},
        ),
      );

      try {
        await h.container.api.sendData(
          'PUT',
          'tasks/t1',
          body: {},
          ifMatchVersion: 3,
        );
        fail('كان يجب أن يرمي');
      } on ApiException catch (e) {
        expect(e.code, ApiErrorCode.versionConflict);
        expect(e.serverVersion, 5);
        expect(e.requestId, 'rid-err');
      }
    });

    test('كود مجهول لا يسقط التطبيق — unknown مع الخام (§93)', () async {
      await h.seedSession();
      h.transport.on('GET home', (_) => apiError('BRAND_NEW_CODE', 400));
      try {
        await h.container.api.getData('home');
        fail('كان يجب أن يرمي');
      } on ApiException catch (e) {
        expect(e.code, ApiErrorCode.unknown);
        expect(e.rawCode, 'BRAND_NEW_CODE');
      }
    });

    test('غلاف خطأ على 202 (APPROVAL_REQUIRED) يرمى مكتوباً بوجهته', () async {
      await h.seedSession();
      h.transport.on(
        'PUT tasks/t1',
        (_) => apiError(
          'APPROVAL_REQUIRED',
          202,
          details: {
            'approval': {'module': 'approvals', 'id': 'ap-1'},
          },
        ),
      );
      try {
        await h.container.api.sendData('PUT', 'tasks/t1', body: {});
        fail('كان يجب أن يرمي');
      } on ApiException catch (e) {
        expect(e.code, ApiErrorCode.approvalRequired);
        expect(e.approvalTarget?['id'], 'ap-1');
      }
    });
  });

  group('سياسة الإعادة (§59)', () {
    test('فشل شبكة عابر على GET يعاد آلياً', () async {
      await h.seedSession();
      h.transport.failOnce.add('GET home');
      h.transport.onData('GET home', {'ok': true});

      final data = await h.container.api.getData('home');
      expect(data['ok'], true);
      expect(h.transport.sent('GET home'), hasLength(2));
    });

    test('POST بلا Idempotency-Key لا يعاد آلياً', () async {
      await h.seedSession();
      h.transport.failOnce.add('POST comments');
      h.transport.onData('POST comments', {'ok': true});

      await expectLater(
        h.container.api.sendData('POST', 'comments', body: {'body': 'x'}),
        throwsA(isA<NetworkException>()),
      );
      expect(h.transport.sent('POST comments'), hasLength(1));
    });

    test('VALIDATION_FAILED لا يعاد أبداً', () async {
      await h.seedSession();
      var calls = 0;
      h.transport.on('POST tasks', (_) {
        calls++;
        return apiError('VALIDATION_FAILED', 422);
      });
      await expectLater(
        h.container.api.sendData(
          'POST',
          'tasks',
          body: {},
          idempotencyKey: 'k1',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    });

    test('RATE_LIMITED مع Retry-After يعاد مرة باحترام المهلة', () async {
      await h.seedSession();
      var calls = 0;
      h.transport.on('GET home', (_) {
        calls++;
        return calls == 1
            ? apiError('RATE_LIMITED', 429)
            : okData({'ok': true});
      });
      final data = await h.container.api.getData('home');
      expect(data['ok'], true);
      expect(calls, 2);
    });
  });

  group('ETag (§44)', () {
    test('304 تعاد notModified بلا حمولة', () async {
      await h.seedSession();
      h.transport.on('GET bootstrap', (req) {
        if (req.headers['If-None-Match'] == 'W/"abc"') {
          return okData({}, status: 304, headers: {'etag': 'W/"abc"'});
        }
        return okData({'v': 1}, headers: {'etag': 'W/"abc"'});
      });

      final first = await h.container.api.send(ApiRequest('GET', 'bootstrap'));
      expect(first.etag, 'W/"abc"');

      final second = await h.container.api.send(
        ApiRequest('GET', 'bootstrap', ifNoneMatch: first.etag),
      );
      expect(second.notModified, isTrue);
    });
  });
}
