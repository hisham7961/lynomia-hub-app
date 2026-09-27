/// «اسأل Hub» على الجوال — العقد، والتفرّع على الرمز لا على النص، ولا بابَ
/// بلا علَم الخادم، ولا سؤالٌ ثانٍ قبل ردّ الأول، ولا إعادةٌ تلقائيّة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/features/ask/ask_repository.dart';

import '../fakes/fakes.dart';
import '../widget/rtl_app_test.dart' show wireAuthenticatedRoutes;

Map<String, dynamic> _answer({
  bool ok = true,
  String? failure,
  String message = '',
}) => {
  'ok': ok,
  'answer': ok ? 'لديك مشروعان نشطان QWXZ' : null,
  'partial': false,
  'failure': failure,
  'message': message,
  'sources': [
    {
      'n': 1,
      'module': 'projects',
      'label': 'المشاريع',
      'rows': 2,
      'ids': ['p1', 'p2'],
      'complete': true,
    },
    {
      'n': 2,
      'module': 'tasks',
      'label': 'المهام',
      'rows': 1,
      'ids': ['t9'],
      'complete': true,
    },
  ],
  'thread': 'th-1',
  'request': 'corr-1',
};

void main() {
  group('المستودع (العقد)', () {
    late TestHarness h;
    setUp(() async {
      h = TestHarness.create();
      await h.seedSession();
    });
    tearDown(() => h.dispose());

    test(
      'السؤالُ والمتابعةُ بالخيط، والمصدرُ وجهةٌ حين يكون سجلاً واحداً',
      () async {
        h.transport.onData('POST ask', _answer());
        final a = await h.container.ask.ask('ما مشاريعي؟');
        expect(a.ok, isTrue);
        expect(a.thread, 'th-1');
        expect(
          a.sources.first.target,
          isNull,
          reason: 'سجلّان ⇒ لا وجهةَ مختلقة',
        );
        expect(a.sources.last.target!.routePath, '/r/tasks/t9');
        expect(h.transport.sent('POST ask').single.jsonBody, {
          'q': 'ما مشاريعي؟',
        });

        await h.container.ask.ask('وكم عددها؟', thread: 'th-1');
        expect(h.transport.sent('POST ask').last.jsonBody['thread'], 'th-1');
      },
    );

    test('الإخفاقُ يُصنَّف بالرمز الآليّ لا بالرسالة العربية', () async {
      h.transport.onData(
        'POST ask',
        _answer(
          ok: false,
          failure: 'BUDGET_EXCEEDED',
          message: 'تعذّر — ميزانيّة',
        ),
      );
      final a = await h.container.ask.ask('سؤال');
      expect(a.ok, isFalse);
      expect(a.failureKind, AskFailureKind.limit);
      expect(askFailureKind('رسالة عربية'), AskFailureKind.other);
      expect(askFailureKind('NO_ACCESSIBLE_DATA'), AskFailureKind.noData);
      expect(askFailureKind('GATEWAY_FAILURE'), AskFailureKind.unavailable);
    });

    test('فشلُ الشبكة لا يُعاد تلقائياً — السؤالُ نداءٌ مدفوع', () async {
      h.transport.failOnce.add('POST ask');
      h.transport.onData('POST ask', _answer());
      await expectLater(h.container.ask.ask('سؤال'), throwsA(anything));
      expect(h.transport.sent('POST ask'), hasLength(1));
    });

    test('المحادثاتُ والأدوارُ المحجوبةُ والحذف', () async {
      h.transport.onData('GET ask/threads', {
        'memory': true,
        'retention_days': 30,
        'threads': [
          {
            'id': 'th-1',
            'title': 'مشاريعي',
            'last_at': '2026-09-26T10:00:00+03:00',
          },
        ],
      });
      h.transport.onData('GET ask/threads/th-1', {
        'id': 'th-1',
        'title': 'مشاريعي',
        'turns': [
          {
            'question': 'س١',
            'answer': 'ج١',
            'ok': true,
            'hidden': false,
            'failure': null,
            'at': null,
          },
          {
            'question': 'س٢',
            'answer': null,
            'ok': true,
            'hidden': true,
            'failure': null,
            'at': null,
          },
        ],
      });
      h.transport.onData('DELETE ask/threads/th-1', {'deleted': 1});
      h.transport.onData('DELETE ask/threads', {'deleted': 3});

      final t = await h.container.ask.threads();
      expect(t.memory, isTrue);
      expect(t.retentionDays, 30);
      expect(t.threads.single.title, 'مشاريعي');
      final turns = await h.container.ask.turns('th-1');
      expect(turns.last.hidden, isTrue);
      expect(turns.last.answer, isNull);
      expect(await h.container.ask.deleteThread('th-1'), 1);
      expect(await h.container.ask.deleteAll(), 3);
    });
  });

  group('الواجهة', () {
    Future<TestHarness> pumpWithAsk(
      WidgetTester tester, {
      required bool canAsk,
    }) async {
      final h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      final boot = bootstrapPayload();
      boot['feature_flags'] = {
        ...(boot['feature_flags'] as Map).cast<String, dynamic>(),
        'can_ask': canAsk,
      };
      h.transport.onData('GET bootstrap', boot);
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('بلا علَم الخادم لا مدخلَ في الرئيسية', (tester) async {
      final h = await pumpWithAsk(tester, canAsk: false);
      expect(find.byKey(const Key('home-ask')), findsNothing);
      h.dispose();
    });

    testWidgets(
      'يسأل ويعرض الجوابَ والمصادر، والإخفاقُ بنصٍّ محليٍّ من الرمز',
      (tester) async {
        final h = await pumpWithAsk(tester, canAsk: true);
        await tester.tap(find.byKey(const Key('home-ask')));
        await tester.pumpAndSettle();
        expect(find.text('اسأل Hub'), findsWidgets);

        // خادمٌ أقدم بلا البثّ (٤٠٤) ⇒ الارتداد لـ`POST ask` (اختبار البثّ في
        // phase4_test).
        h.transport.on(
          'POST ask/stream',
          (_) => apiError('RESOURCE_NOT_FOUND', 404),
        );
        h.transport.onData('POST ask', _answer());
        await tester.enterText(
          find.byKey(const Key('ask-input')),
          'ما مشاريعي؟',
        );
        await tester.tap(find.byKey(const Key('ask-send')));
        await tester.pumpAndSettle();
        expect(find.text('لديك مشروعان نشطان QWXZ'), findsOneWidget);
        expect(find.text('المشاريع — 2 صفّاً'), findsOneWidget);

        h.transport.onData(
          'POST ask',
          _answer(
            ok: false,
            failure: 'RATE_LIMITED',
            message: 'نصٌّ خادميٌّ لا يُعرض QWXZ-MSG',
          ),
        );
        await tester.enterText(find.byKey(const Key('ask-input')), 'سؤالٌ آخر');
        await tester.tap(find.byKey(const Key('ask-send')));
        await tester.pumpAndSettle();
        expect(find.textContaining('بلغتَ حدّ الاستخدام'), findsOneWidget);
        expect(find.textContaining('QWXZ-MSG'), findsNothing);
        expect(
          h.transport.sent('POST ask').last.jsonBody['thread'],
          'th-1',
          reason: 'المتابعةُ في الخيط الذي أعاده الخادم',
        );
        h.dispose();
      },
    );
  });
}
