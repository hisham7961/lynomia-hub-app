/// v0.5.0 فوق خلفية v2.617 (طلبات #4–#8 محلولة): «منذ» يبدأ من مؤشر الذيل،
/// وتفاعلات DM من القائمة والأحداث، والحفظ/الإزالة ووجهة المحفوظة، وأعلام
/// الكتابة/الحضور (مع بديل ٤٠٤ للخادم الأقدم)، و«لا ملف موظف» بالكود والسبب.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';
import 'package:lynomia_hub_app/features/launch/bootstrap_repository.dart';
import 'package:lynomia_hub_app/features/messages/collab_repository.dart';

import '../fakes/fakes.dart';
import '../widget/rtl_app_test.dart' show wireAuthenticatedRoutes;

Map<String, dynamic> _dmMsg(
  String id, {
  bool mine = false,
  String body = 'نص',
  List<Map<String, dynamic>> reactions = const [],
  bool deleted = false,
  String at = '2026-09-27T09:00:00+03:00',
}) => {
  'id': id,
  'from_id': mine ? 'u-1' : 'u-2',
  'to_id': mine ? 'u-2' : 'u-1',
  'mine': mine,
  'body': deleted ? null : body,
  'deleted': deleted,
  'has_attachment': false,
  'read': true,
  'created_at': at,
  'reactions': reactions,
};

Map<String, dynamic> _comment(String id) => {
  'id': id,
  'parent_id': null,
  'user': {'id': 'u-2', 'name': 'سارة'},
  'body': 'نص $id',
  'mentions': <dynamic>[],
  'internal': false,
  'pinned': false,
  'resolved': false,
  'has_attachment': false,
  'reactions': <dynamic>[],
  'created_at': '2026-09-27T09:00:00+03:00',
  'replies': <dynamic>[],
};

Map<String, dynamic> _savedCard(
  String id, {
  String type = 'comment',
  bool available = true,
  Map<String, dynamic>? target,
  String title = 'ملاحظة',
}) => {
  'id': id,
  'type': type,
  'available': available,
  'title': available ? title : null,
  'author': available ? 'سارة' : null,
  'note': null,
  'saved_at': '2026-09-26T10:00:00+03:00',
  'target': target,
};

void main() {
  group('المستودعات (خلفية v2.617)', () {
    late TestHarness h;
    setUp(() async {
      h = TestHarness.create();
      await h.seedSession();
    });
    tearDown(() => h.dispose());

    test(
      'مؤشر الذيل: القناة في comments، وDM في messages مع اسم الطرف',
      () async {
        h.transport.onData('GET comments', {
          'module': 'channel',
          'record': 'cv1',
          'comments': [_comment('c1')],
          'cursor': 'TAIL-C',
        });
        final t = await h.container.comments.thread('channel', 'cv1');
        expect(t.cursor, 'TAIL-C');
        expect(t.comments.single.id, 'c1');

        h.transport.onData('GET comments', {
          'module': 'tasks',
          'record': 't1',
          'comments': <dynamic>[],
          'cursor': null,
        });
        expect(
          (await h.container.comments.thread('tasks', 't1')).cursor,
          isNull,
        );

        h.transport.onData('GET dm/threads/u-2/messages', {
          'user': {'id': 'u-2', 'name': 'سارة'},
          'messages': [
            _dmMsg(
              'm1',
              reactions: [
                {'emoji': '👍', 'count': 2, 'mine': true},
              ],
            ),
            _dmMsg(
              'm2',
              deleted: true,
              reactions: [
                {'emoji': '🎉', 'count': 1, 'mine': false},
              ],
            ),
          ],
          'cursor': 'TAIL-D',
        });
        final page = await h.container.dm.thread('u-2');
        expect(page.cursor, 'TAIL-D');
        expect(page.userName, 'سارة');
        expect(page.messages.first.reactions.single.count, 2);
        expect(page.messages.first.reactions.single.mine, isTrue);
        expect(
          page.messages.last.reactions,
          isEmpty,
          reason: 'المحذوفة بلا تفاعلات',
        );
      },
    );

    test('أحداث «منذ» تحمل التفاعلات (DM والقناة)', () async {
      h.transport.onData('GET dm/threads/u-2/since', {
        'events': [
          {
            'type': 'message.created',
            'id': 'm3',
            'mine': false,
            'body': 'جديد',
            'created_at': '2026-09-27T09:10:00+03:00',
            'reactions': [
              {'emoji': '❤️', 'count': 1, 'mine': false},
            ],
          },
        ],
        'cursor': 'N1',
        'typing': <dynamic>[],
      });
      final p = await h.container.dm.since('u-2', cursor: 'TAIL-D');
      expect(p.events.single.reactions.single.emoji, '❤️');
      expect(
        h.transport
            .sent('GET dm/threads/u-2/since')
            .single
            .url
            .queryParameters['cursor'],
        'TAIL-D',
      );

      h.transport.onData('GET conversations/cv1/since', {
        'events': [
          {
            'type': 'message.created',
            'id': 'c2',
            'user_id': 'u-2',
            'body': 'x',
            'reactions': [
              {'emoji': '👍', 'count': 3, 'mine': true},
            ],
          },
        ],
        'cursor': 'N2',
        'typing': <dynamic>[],
      });
      final c = await h.container.collab.channelSince('cv1', cursor: 'TAIL-C');
      expect(c.events.single.reactions.single.count, 3);
    });

    test(
      'الحفظ: الجسم، 201 منشأة و200 قائمة، وإعادةٌ عابرةٌ آمنة (حفظٌ لا تبديل)',
      () async {
        var n = 0;
        h.transport.on('POST saved', (req) {
          expect(req.jsonBody, {'target_type': 'dm', 'target_id': 'm1'});
          n++;
          return okData({
            'saved': _savedCard(
              's1',
              type: 'dm',
              target: {'kind': 'dm', 'user_id': 'u-2', 'message_id': 'm1'},
            ),
            'created': n == 1,
          }, status: n == 1 ? 201 : 200);
        });
        final first = await h.container.collab.save(
          targetType: 'dm',
          targetId: 'm1',
        );
        expect(first.created, isTrue);
        expect(first.item.target!.routePath, '/messages/u-2');
        final again = await h.container.collab.save(
          targetType: 'dm',
          targetId: 'm1',
        );
        expect(again.created, isFalse);

        h.transport.failOnce.add('POST saved');
        await h.container.collab.save(targetType: 'dm', targetId: 'm1');
        expect(
          h.transport.sent('POST saved'),
          hasLength(4),
          reason: 'فشل شبكة واحد ثم إعادة واحدة',
        );

        h.transport.on(
          'POST saved',
          (_) => apiError('RESOURCE_NOT_FOUND', 404),
        );
        await expectLater(
          h.container.collab.save(targetType: 'comment', targetId: 'ghost'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.resourceNotFound,
            ),
          ),
        );
      },
    );

    test('الإزالة DELETE saved/{id} بلا إعادة تلقائية', () async {
      h.transport.onData('DELETE saved/s1', {'id': 's1', 'deleted': true});
      await h.container.collab.unsave('s1');
      expect(h.transport.sent('DELETE saved/s1'), hasLength(1));

      h.transport.failOnce.add('DELETE saved/s2');
      h.transport.onData('DELETE saved/s2', {'id': 's2', 'deleted': true});
      await expectLater(h.container.collab.unsave('s2'), throwsA(anything));
      expect(h.transport.sent('DELETE saved/s2'), hasLength(1));
    });

    test('وجهة المحفوظة: من الخادم وحده، ولا وجهة مختلقة', () {
      SavedItem card(Map<String, dynamic>? target, {bool available = true}) =>
          SavedItem.fromJson(
            _savedCard('s', available: available, target: target),
          );
      expect(
        card({
          'kind': 'comment',
          'module': 'tasks',
          'record_id': 't1',
          'comment_id': 'c1',
          'parent_id': null,
        }).target!.routePath,
        '/r/tasks/t1',
      );
      expect(
        card({
          'kind': 'comment',
          'module': 'channel',
          'record_id': 'cv1',
          'comment_id': 'c1',
        }).target!.routePath,
        '/conversations/cv1',
      );
      expect(
        card({
          'kind': 'comment',
          'module': 'feed',
          'record_id': null,
          'comment_id': 'c1',
        }).target!.routePath,
        isNull,
        reason: 'منشور القناة العامة بلا شاشة جوال',
      );
      expect(card(null).target, isNull, reason: 'خادمٌ أقدم بلا target');
      expect(
        card({
          'kind': 'dm',
          'user_id': 'u-2',
          'message_id': 'm1',
        }, available: false).target,
        isNull,
        reason: 'غير المتاح لا وجهة له',
      );
    });

    test(
      '«لا ملف موظف» بالكود وdetails.reason، والغلاف data مقروء، والأقدم باقٍ',
      () async {
        h.transport.on(
          'GET work/today',
          (_) => http.Response(
            jsonEncode({
              'error': 'no_employee_profile',
              'code': 'BUSINESS_RULE_VIOLATION',
              'message': 'لا ملفَ موظّفٍ نشطاً مربوطاً بحسابك',
              'details': {'reason': 'no_employee_profile'},
              'request_id': 'rid-1',
            }),
            422,
            headers: {
              'content-type': 'application/json',
              'x-error-code': 'BUSINESS_RULE_VIOLATION',
            },
          ),
        );
        expect((await h.container.work.today()).noEmployeeProfile, isTrue);

        // الكود نفسه بسببٍ آخر يبقى خطأً (لا تعميم على الكود وحده)
        h.transport.on(
          'GET work/today',
          (_) => apiError(
            'BUSINESS_RULE_VIOLATION',
            422,
            details: {'reason': 'other'},
          ),
        );
        await expectLater(
          h.container.work.today(),
          throwsA(isA<ApiException>()),
        );

        // الرسالة المعروضة عربية حين يكون `error` رمزاً آلياً
        h.transport.on(
          'GET me/documents',
          (_) => http.Response(
            jsonEncode({
              'error': 'no_employee_profile',
              'code': 'BUSINESS_RULE_VIOLATION',
              'message': 'نص عربي',
            }),
            422,
            headers: {'content-type': 'application/json'},
          ),
        );
        try {
          await h.container.api.getData('me/documents');
          fail('يجب أن يرمي');
        } on ApiException catch (e) {
          expect(e.code, ApiErrorCode.businessRuleViolation);
          expect(e.message, 'نص عربي');
        }

        // الرد بالغلاف data بجانب المفاتيح القديمة
        final payload = {
          'compliance': {
            'date': '2026-09-27',
            'report_required': true,
            'report_submitted': true,
            'labels': {'effective': 'حاضر'},
          },
          'entries': <dynamic>[],
          'submit_hint': {'path': '/api/mobile/v1/updates'},
        };
        h.transport.on(
          'GET work/today',
          (_) => http.Response(
            jsonEncode({...payload, 'data': payload, 'request_id': 'r'}),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );
        final day = await h.container.work.today();
        expect(day.compliance!.reportSubmitted, isTrue);
        expect(day.submitModule, 'updates');
      },
    );

    test('العلم الاختياري: false صريح يحجب، والغياب يُجرَّب', () {
      Bootstrap boot(Map<String, dynamic> flags) =>
          Bootstrap.fromJson({...bootstrapPayload(), 'feature_flags': flags});
      expect(
        boot({'collab_typing': false}).optionalFlag('collab_typing'),
        false,
      );
      expect(boot({'collab_typing': true}).optionalFlag('collab_typing'), true);
      expect(boot(const {}).optionalFlag('collab_typing'), isNull);
    });
  });

  group('الواجهات', () {
    Future<TestHarness> pumpApp(
      WidgetTester tester, {
      Map<String, dynamic> flags = const {},
    }) async {
      final h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      final boot = bootstrapPayload();
      boot['feature_flags'] = {
        ...(boot['feature_flags'] as Map).cast<String, dynamic>(),
        ...flags,
      };
      h.transport.onData('GET bootstrap', boot);
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();
      return h;
    }

    GoRouter router(WidgetTester tester) =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));

    void wireDm(TestHarness h, {List<Map<String, dynamic>>? events}) {
      h.transport.onData('GET dm/threads/u-2/messages', {
        'user': {'id': 'u-2', 'name': 'سارة'},
        'messages': [
          _dmMsg(
            'm1',
            body: 'رسالة قديمة',
            reactions: [
              {'emoji': '👍', 'count': 2, 'mine': false},
            ],
          ),
        ],
        'cursor': 'TAIL-D',
      });
      h.transport.onData('POST dm/threads/u-2/read', {'marked': 0});
      h.transport.onData('GET presence', {
        'presence': [
          {'user_id': 'u-2', 'presence': 'online'},
        ],
      });
      h.transport.on(
        'GET dm/threads/u-2/since',
        (req) => okData({
          'events': req.url.queryParameters['cursor'] == 'TAIL-D'
              ? (events ?? const [])
              : const <dynamic>[],
          'cursor': 'N1',
          'typing': <dynamic>[],
        }),
      );
      h.transport.onData('POST dm/threads/u-2/typing', {'ok': true});
    }

    testWidgets('DM: «منذ» من مؤشر الذيل لا من أول الخيط، والتفاعلات من القائمة والأحداث، '
        'والحفظ بتراجع', (tester) async {
      final h = await pumpApp(tester);
      wireDm(
        h,
        events: [
          {
            'type': 'message.created',
            'id': 'm2',
            'mine': false,
            'body': 'رسالة جديدة',
            'created_at': '2026-09-27T09:10:00+03:00',
            'reactions': [
              {'emoji': '🎉', 'count': 1, 'mine': false},
            ],
          },
        ],
      );
      h.transport.onData('POST saved', {
        'saved': _savedCard('s9', type: 'dm'),
        'created': true,
      });
      h.transport.onData('DELETE saved/s9', {'id': 's9', 'deleted': true});

      // بلا اسم في الرابط (وجهة محفوظة) ⇒ الاسم من الخادم
      router(tester).push('/messages/u-2');
      await tester.pumpAndSettle();
      expect(find.text('سارة'), findsOneWidget);
      expect(find.text('👍 2'), findsOneWidget);
      expect(find.text('رسالة جديدة'), findsOneWidget);
      expect(find.text('🎉 1'), findsOneWidget);
      final cursors = h.transport
          .sent('GET dm/threads/u-2/since')
          .map((r) => r.url.queryParameters['cursor'])
          .toList();
      expect(cursors.first, 'TAIL-D', reason: 'لا نداء بمؤشر فارغ');
      expect(cursors, isNot(contains(null)));

      await tester.longPress(find.byKey(const Key('dm-msg-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dm-save')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('POST saved').single.jsonBody, {
        'target_type': 'dm',
        'target_id': 'm1',
      });
      expect(find.text('حُفظت في المحفوظات'), findsOneWidget);
      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();
      expect(h.transport.sent('DELETE saved/s9'), hasLength(1));
      h.dispose();
    });

    testWidgets('أعلام false: لا نداء حضور ولا نبضة كتابة', (tester) async {
      final h = await pumpApp(
        tester,
        flags: {'collab_typing': false, 'collab_presence': false},
      );
      wireDm(h);
      router(tester).push('/messages/u-2?name=%D8%B3%D8%A7%D8%B1%D8%A9');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dm-input')), 'مرحبا');
      await tester.pump();
      expect(h.transport.sent('GET presence'), isEmpty);
      expect(h.transport.sent('POST dm/threads/u-2/typing'), isEmpty);
      expect(find.text('متصل الآن'), findsNothing);
      h.dispose();
    });

    testWidgets('أعلام true: الحضور والكتابة يعملان', (tester) async {
      final h = await pumpApp(
        tester,
        flags: {'collab_typing': true, 'collab_presence': true},
      );
      wireDm(h);
      router(tester).push('/messages/u-2?name=%D8%B3%D8%A7%D8%B1%D8%A9');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dm-input')), 'مرحبا');
      await tester.pump();
      expect(find.text('متصل الآن'), findsOneWidget);
      expect(h.transport.sent('POST dm/threads/u-2/typing'), hasLength(1));
      h.dispose();
    });

    testWidgets(
      'القناة: «منذ» يبدأ من cursor القائمة، والحفظ «محفوظة سلفاً» بلا تراجع',
      (tester) async {
        final h = await pumpApp(tester);
        h.transport.onData('GET comments', {
          'module': 'channel',
          'record': 'cv1',
          'comments': [_comment('c1')],
          'cursor': 'TAIL-C',
        });
        h.transport.onData('GET conversations/cv1/since', {
          'events': <dynamic>[],
          'cursor': 'TAIL-C',
          'typing': <dynamic>[],
        });
        h.transport.on('POST saved', (req) {
          expect(req.jsonBody, {'target_type': 'comment', 'target_id': 'c1'});
          return okData({'saved': _savedCard('s1'), 'created': false});
        });
        router(tester).push('/conversations/cv1?title=x');
        await tester.pumpAndSettle();
        expect(
          h.transport
              .sent('GET conversations/cv1/since')
              .first
              .url
              .queryParameters['cursor'],
          'TAIL-C',
        );

        await tester.tap(find.byKey(const Key('save-c1')));
        await tester.pumpAndSettle();
        expect(find.text('محفوظة سلفاً'), findsOneWidget);
        expect(find.text('تراجع'), findsNothing);
        h.dispose();
      },
    );

    testWidgets('المحفوظات: تُفتح وجهتها، وتُزال، وغير المتاح بلا فتح', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      h.transport.onData('GET saved', {
        'saved': [
          _savedCard(
            's1',
            title: 'تعليق على المهمة',
            target: {
              'kind': 'comment',
              'module': 'tasks',
              'record_id': 't1',
              'comment_id': 'c1',
              'parent_id': null,
            },
          ),
          _savedCard('s2', type: 'dm', available: false),
        ],
      });
      h.transport.onData('DELETE saved/s2', {'id': 's2', 'deleted': true});
      router(tester).push('/saved');
      await tester.pumpAndSettle();

      // غير المتاح: نقرٌ لا ينقل
      await tester.tap(find.text('لم يعد هذا متاحاً لك'));
      await tester.pumpAndSettle();
      expect(find.text('لم يعد هذا متاحاً لك'), findsOneWidget);

      await tester.tap(find.byKey(const Key('unsave-s2')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('DELETE saved/s2'), hasLength(1));
      expect(find.text('لم يعد هذا متاحاً لك'), findsNothing);

      final before = h.transport.sent('GET tasks/t1').length;
      await tester.tap(find.text('تعليق على المهمة'));
      await tester.pumpAndSettle();
      expect(h.transport.sent('GET tasks/t1').length, before + 1);
      expect(find.text('تجهيز العرض'), findsWidgets);
      h.dispose();
    });
  });
}
