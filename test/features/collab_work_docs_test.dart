/// النقاط الثلاث عشرة المضافة في v0.4.0 — التفاعلات، و«منذ» والكتابة، والحضور،
/// والمحفوظات، وعملي اليوم/التقرير اليومي، ووثائقي: عقد المستودع (مسارات،
/// أجسام، سياسة الإعادة، أكواد الأخطاء) ثم الواجهات بأعلام الخادم وحالاتٍ صادقة
/// واستطلاعٍ لا يعمل إلا والشاشة ظاهرة.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';
import 'package:lynomia_hub_app/core/ui/visible_poller.dart';
import 'package:lynomia_hub_app/features/comments/comment_repository.dart';
import 'package:lynomia_hub_app/features/comments/reactions.dart';
import 'package:lynomia_hub_app/features/messages/collab_repository.dart';
import 'package:lynomia_hub_app/features/messages/live_events.dart';
import 'package:lynomia_hub_app/features/my_work/work_repository.dart';

import '../fakes/fakes.dart';
import '../widget/rtl_app_test.dart' show wireAuthenticatedRoutes;

/// رد `work/today` كما يبثه الخادم فعلاً: **بلا** غلاف `data`.
http.Response workTodayResponse({
  bool reportSubmitted = false,
  List<Map<String, dynamic>> entries = const [],
}) => http.Response(
  jsonEncode({
    'compliance': {
      'date': '2026-09-27',
      'open_shift': null,
      'verdict_pending': false,
      'late_arrival': false,
      'checked_in': true,
      'checked_out': false,
      'time_in': '08:05',
      'time_out': null,
      'attendance_hours': null,
      'physical_status': 'حاضر',
      'on_leave': false,
      'report_required': true,
      'report_submitted': reportSubmitted,
      'report_count': entries.length,
      'submitted_at': null,
      'reported_hours': 7.5,
      'projects': <dynamic>[],
      'has_non_project': false,
      'deadline_at': '2026-09-27T20:00:00+03:00',
      'grace_remaining_minutes': 120,
      'past_deadline': false,
      'late': false,
      'compliance': reportSubmitted ? 'compliant' : 'pending',
      'state': 'present_pending',
      'effective_status': 'present',
      'finalized': false,
      'needs_review': false,
      'review': {'pending': 0, 'accepted': 0, 'needs_revision': 0},
      'reason': null,
      'labels': {
        'physical': 'حاضر',
        'compliance': reportSubmitted ? 'مقدَّم' : 'بانتظار التقديم',
        'effective': 'حاضر QWXZ',
      },
    },
    'entries': entries,
    'submit_hint': {
      'method': 'POST',
      'path': '/api/mobile/v1/updates',
      'note': 'تقديمُ التقرير = إنشاءُ بندِ عملٍ للوحدة updates',
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

/// 422 الأقدم لنقطة §93: `{error: رمز, message}` بلا `code`.
http.Response noProfileResponse() => http.Response(
  jsonEncode({
    'error': 'no_employee_profile',
    'message': 'لا ملفَ موظّفٍ نشطاً مربوطاً بحسابك',
  }),
  422,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _comment(
  String id, {
  List<Map<String, dynamic>> reactions = const [],
  List<Map<String, dynamic>> replies = const [],
}) => {
  'id': id,
  'parent_id': null,
  'user': {'id': 'u-2', 'name': 'سارة'},
  'body': 'نص $id',
  'mentions': <dynamic>[],
  'internal': false,
  'pinned': false,
  'resolved': false,
  'has_attachment': false,
  'reactions': reactions,
  'created_at': '2026-09-27T09:00:00+03:00',
  'replies': replies,
};

void main() {
  group('المستودعات (العقد)', () {
    late TestHarness h;
    setUp(() async {
      h = TestHarness.create();
      await h.seedSession();
    });
    tearDown(() => h.dispose());

    test(
      'تفاعل التعليق: الجسم {emoji} بلا مفتاح تكرار، ولا إعادة عند الفشل',
      () async {
        h.transport.on('POST comments/c1/react', (req) {
          expect(req.jsonBody, {'emoji': '👍'});
          expect(req.headers.containsKey('Idempotency-Key'), isFalse);
          return okData({
            'comment_id': 'c1',
            'emoji': '👍',
            'mine': true,
            'count': 3,
          });
        });
        final t = await h.container.comments.react('c1', '👍');
        expect(t.targetId, 'c1');
        expect(t.mine, isTrue);
        expect(t.count, 3);

        // التبديل ليس عديم الأثر: فشل الشبكة لا يُعاد (وإلا انعكس التبديل)
        h.transport.failOnce.add('POST comments/c1/react');
        await expectLater(
          h.container.comments.react('c1', '👍'),
          throwsA(anything),
        );
        expect(h.transport.sent('POST comments/c1/react'), hasLength(2));
      },
    );

    test('تفاعل رسالة DM: الحالة من الخادم، والمحذوفة رمزُها آلي', () async {
      h.transport.onData('POST dm/messages/m1/react', {
        'dm_message_id': 'm1',
        'emoji': '❤️',
        'mine': false,
        'count': 0,
      });
      final t = await h.container.dm.react('m1', '❤️');
      expect(t.targetId, 'm1');
      expect(t.count, 0);

      h.transport.on(
        'POST dm/messages/m2/react',
        (_) => apiError('BUSINESS_RULE_VIOLATION', 422),
      );
      await expectLater(
        h.container.dm.react('m2', '👍'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.businessRuleViolation,
          ),
        ),
      );
      expect(h.transport.sent('POST dm/messages/m2/react'), hasLength(1));
    });

    test(
      '«منذ» في DM: المؤشر مُعتَم يُمرَّر كما أعاده الخادم، والكتابة',
      () async {
        h.transport.on('GET dm/threads/u-2/since', (req) {
          final cursor = req.url.queryParameters['cursor'];
          if (cursor == null) {
            return okData({
              'events': [
                {
                  'type': 'message.created',
                  'id': 'm1',
                  'mine': false,
                  'body': 'أهلاً',
                  'deleted': false,
                  'edited': false,
                  'created_at': '2026-09-27T09:00:00+03:00',
                },
                {
                  'type': 'message.deleted',
                  'id': 'm0',
                  'mine': true,
                  'body': null,
                  'deleted': true,
                  'edited': false,
                  'created_at': '2026-09-27T08:00:00+03:00',
                },
              ],
              'cursor': 'CUR-1',
              'typing': ['سارة'],
            });
          }
          expect(cursor, 'CUR-1');
          // لا جديد ⇒ الخادم يعيد المؤشر نفسه
          return okData({
            'events': <dynamic>[],
            'cursor': 'CUR-1',
            'typing': <dynamic>[],
          });
        });
        final p1 = await h.container.dm.since('u-2');
        expect(p1.events.first.body, 'أهلاً');
        expect(p1.events.last.deleted, isTrue);
        expect(p1.cursor, 'CUR-1');
        expect(p1.typing, ['سارة']);
        expect(p1.reachedTail, isTrue);
        final p2 = await h.container.dm.since('u-2', cursor: p1.cursor);
        expect(p2.events, isEmpty);
        expect(p2.cursor, 'CUR-1');

        h.transport.onData('POST dm/threads/u-2/typing', {'ok': true});
        await h.container.dm.typing('u-2');
        expect(
          h.transport.sent('POST dm/threads/u-2/typing').single.headers,
          isNot(contains('Idempotency-Key')),
        );
      },
    );

    test('الكتابة: القدرة المطفأة 404 مكتوبة، والنبضة لا تُعاد', () async {
      h.transport.on(
        'POST dm/threads/u-2/typing',
        (_) => apiError('RESOURCE_NOT_FOUND', 404),
      );
      await expectLater(
        h.container.dm.typing('u-2'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.resourceNotFound,
          ),
        ),
      );
      h.transport.failOnce.add('POST conversations/cv1/typing');
      h.transport.onData('POST conversations/cv1/typing', {'ok': true});
      await expectLater(
        h.container.collab.channelTyping('cv1'),
        throwsA(anything),
      );
      expect(h.transport.sent('POST conversations/cv1/typing'), hasLength(1));
    });

    test('قائمة الحاويات: قنوات/غرف/مجموعات/مباشرة بحضورها', () async {
      h.transport.onData('GET conversations', {
        'channels': [
          {
            'id': 'cv1',
            'kind': 'channel',
            'title': 'عام',
            'audience': 'internal',
            'unread': 2,
            'favorite': true,
          },
        ],
        'rooms': [
          {
            'id': 'cv2',
            'kind': 'room',
            'title': 'غرفة المشروع',
            'audience': 'internal',
            'unread': 0,
            'favorite': false,
          },
        ],
        'groups': <dynamic>[],
        'dms': [
          {'user_id': 'u-2', 'title': 'سارة', 'unread': 1, 'presence': 'away'},
        ],
        'unread_total': 3,
      });
      final rail = await h.container.collab.conversations();
      expect(rail.channels.single.favorite, isTrue);
      expect(rail.rooms.single.kind, 'room');
      expect(rail.dms.single.presence, PresenceState.away);
      expect(rail.unreadTotal, 3);
      expect(rail.hasContainers, isTrue);
    });

    test('«منذ» في القناة يحمل الكاتب والأب', () async {
      h.transport.onData('GET conversations/cv1/since', {
        'events': [
          {
            'type': 'message.created',
            'id': 'c9',
            'parent_id': 'c1',
            'user_id': 'u-2',
            'author': 'سارة',
            'body': 'رد',
            'edited': true,
            'created_at': '2026-09-27T09:00:00+03:00',
          },
        ],
        'cursor': 'C9',
        'typing': <dynamic>[],
      });
      final p = await h.container.collab.channelSince('cv1');
      expect(p.events.single.parentId, 'c1');
      expect(p.events.single.author, 'سارة');
      expect(p.events.single.edited, isTrue);
      expect(p.cursor, 'C9');
      expect(
        h.transport.sent('GET conversations/cv1/since').single.url.query,
        isEmpty,
        reason: 'المؤشر الفارغ لا يُرسل',
      );
    });

    test('الحضور: دفعات ≤100 معرّف، ولا نداء لقائمة فارغة', () async {
      h.transport.on('GET presence', (req) {
        final ids = req.url.queryParameters['users']!.split(',');
        expect(ids.length, lessThanOrEqualTo(100));
        return okData({
          'presence': [
            for (final id in ids) {'user_id': id, 'presence': 'online'},
          ],
        });
      });
      expect(await h.container.collab.presence(const []), isEmpty);
      expect(h.transport.sent('GET presence'), isEmpty);

      final ids = [for (var i = 0; i < 130; i++) 'u$i'];
      final p = await h.container.collab.presence(ids);
      expect(p, hasLength(130));
      expect(p['u5'], PresenceState.online);
      expect(h.transport.sent('GET presence'), hasLength(2));
      expect(PresenceState.parse('غريب'), PresenceState.offline);
    });

    test('المحفوظات: ما لم يعد يُرى بلا جسم', () async {
      h.transport.onData('GET saved', {
        'saved': [
          {
            'id': 's1',
            'type': 'comment',
            'available': true,
            'title': 'ملاحظة مهمة',
            'author': 'سارة',
            'note': 'راجِع',
            'saved_at': '2026-09-26T10:00:00+03:00',
          },
          {
            'id': 's2',
            'type': 'dm',
            'available': false,
            'title': null,
            'author': null,
            'note': null,
            'saved_at': '2026-09-25T10:00:00+03:00',
          },
        ],
      });
      final s = await h.container.collab.saved();
      expect(s.first.available, isTrue);
      expect(s.first.note, 'راجِع');
      expect(s.last.available, isFalse);
      expect(s.last.title, isNull);
    });

    test(
      'عملي اليوم: رد بلا غلاف، ساعات Decimal، ووحدة التقديم من submit_hint',
      () async {
        h.transport.on(
          'GET work/today',
          (_) => workTodayResponse(
            entries: [
              {
                'id': 'w1',
                'project_id': 'p1',
                'task_id': null,
                'done': 'مراجعة العقد',
                'hours': 2.25,
                'progress': 40,
                'problems': null,
                'submitted_at': '2026-09-27T12:00:00+03:00',
                'review_status': 'needs_revision',
                'review_feedback': 'أضف التفاصيل',
              },
            ],
          ),
        );
        final day = await h.container.work.today();
        expect(day.noEmployeeProfile, isFalse);
        expect(day.compliance!.reportDue, isTrue);
        expect(day.compliance!.effectiveLabel, 'حاضر QWXZ');
        expect(day.compliance!.reportedHours.toString(), '7.5');
        expect(day.entries.single.hours.toString(), '2.25');
        expect(day.entries.single.reviewStatus, 'needs_revision');
        expect(day.submitModule, 'updates');
      },
    );

    test(
      'بلا ملف موظف: حالة صادقة من الرمز الآلي لا خطأ، والتقرير بتاريخ',
      () async {
        h.transport.on('GET work/today', (_) => noProfileResponse());
        final day = await h.container.work.today();
        expect(day.noEmployeeProfile, isTrue);

        h.transport.on('GET work/daily-report', (req) {
          expect(req.url.queryParameters['date'], '2026-09-05');
          return workTodayResponse(reportSubmitted: true);
        });
        final r = await h.container.work.dailyReport(DateTime(2026, 9, 5));
        expect(r.compliance!.reportSubmitted, isTrue);

        // خطأ آخر يبقى خطأً مكتوباً
        h.transport.on(
          'GET work/today',
          (_) => apiError('RESOURCE_NOT_FOUND', 404),
        );
        await expectLater(
          h.container.work.today(),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('وثائقي: القائمة، والبايتات في الذاكرة، و403/423 مكتوبان', () async {
      h.transport.onData('GET me/documents', {
        'items': [
          {
            'id': 'd1',
            'kind': 'passport',
            'label': 'جواز السفر',
            'name': 'passport.jpg',
            'doc_no': 'A123456',
            'mime': 'image/jpeg',
            'size': 1234,
            'date': '2026-10-01',
            'days': 4,
            'infected': false,
            'tone': 'wn',
          },
        ],
      });
      final docs = await h.container.myDocuments.list();
      expect(docs.single.isImage, isTrue);
      expect(docs.single.tone, 'wn');
      expect(docs.single.daysLeft, 4);

      h.transport.on(
        'GET me/documents/d1/file',
        (_) => http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      );
      expect(
        await h.container.myDocuments.file('d1'),
        Uint8List.fromList([1, 2, 3]),
      );

      h.transport.on(
        'GET me/documents/d2/file',
        (_) => apiError('FORBIDDEN', 403),
      );
      h.transport.on(
        'GET me/documents/d3/file',
        (_) => apiError('LOCKED', 423),
      );
      await expectLater(
        h.container.myDocuments.file('d2'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'c',
            ApiErrorCode.forbidden,
          ),
        ),
      );
      await expectLater(
        h.container.myDocuments.file('d3'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'c', ApiErrorCode.locked),
        ),
      );
    });

    test(
      'رمز الخطأ الخام من `error` حين يكون آلياً — لا من نصٍّ عربي',
      () async {
        h.transport.on('GET work/today', (_) => noProfileResponse());
        h.transport.on(
          'GET me/documents',
          (_) => http.Response(
            jsonEncode({'error': 'نص عربي', 'message': 'x'}),
            500,
            headers: {'content-type': 'application/json'},
          ),
        );
        try {
          await h.container.api.getData('work/today');
          fail('يجب أن يرمي');
        } on ApiException catch (e) {
          expect(e.rawCode, kNoEmployeeProfile);
          expect(e.message, 'لا ملفَ موظّفٍ نشطاً مربوطاً بحسابك');
        }
        try {
          await h.container.api.getData('me/documents');
          fail('يجب أن يرمي');
        } on ApiException catch (e) {
          expect(e.rawCode, isNull);
          expect(e.message, 'نص عربي');
        }
      },
    );
  });

  group('وحدات بلا شبكة', () {
    test('SinceFeed يسحب حتى الذيل ثم يتقدم بالمؤشر', () async {
      final seen = <String>[];
      var calls = 0;
      final feed = SinceFeed<int>((cursor) async {
        seen.add(cursor);
        calls++;
        final full = calls < 3;
        return SincePage(
          events: List.filled(full ? kSincePageSize : 3, calls),
          cursor: 'c$calls',
          typing: const [],
        );
      });
      final b = await feed.pull();
      expect(b.caughtUp, isTrue);
      expect(b.events, hasLength(kSincePageSize * 2 + 3));
      expect(seen, ['', 'c1', 'c2']);
      expect(feed.cursor, 'c3');

      // سقف الصفحات يوقف السحب قبل الذيل
      var n = 0;
      final endless = SinceFeed<int>(
        (c) async => SincePage(
          events: List.filled(kSincePageSize, 0),
          cursor: 'x${n++}',
          typing: const [],
        ),
      );
      final e = await endless.pull(maxPages: 2);
      expect(e.caughtUp, isFalse);
      expect(endless.caughtUp, isFalse);
      expect(n, 2);
    });

    test('تطبيق حالة تفاعل: العدد من الخادم، والصفر يزيل، والرد يُطال', () {
      final c = RecordComment.fromJson(
        _comment(
          'c1',
          reactions: [
            {'emoji': '👍', 'count': 1, 'mine': true},
          ],
          replies: [_comment('r1')],
        ),
      );
      final off = c.applyReaction(
        const ReactionToggle(
          targetId: 'c1',
          emoji: '👍',
          mine: false,
          count: 0,
        ),
      );
      expect(off.reactions, isEmpty);
      final reply = off.applyReaction(
        const ReactionToggle(targetId: 'r1', emoji: '🎉', mine: true, count: 2),
      );
      expect(reply.reactions, isEmpty);
      expect(reply.replies.single.reactions.single.count, 2);
      expect(reply.replies.single.reactions.single.mine, isTrue);
    });

    test('نبضة الكتابة مخنوقة وتتوقف نهائياً بعد التعطيل', () async {
      var sent = 0;
      final t = TypingThrottle(() async => sent++);
      final t0 = DateTime(2026, 9, 27, 10);
      t.onInput(now: t0);
      t.onInput(now: t0.add(const Duration(seconds: 1)));
      t.onInput(now: t0.add(const Duration(seconds: 3)));
      expect(sent, 1);
      t.onInput(now: t0.add(const Duration(seconds: 5)));
      expect(sent, 2);
      t.disable();
      t.onInput(now: t0.add(const Duration(seconds: 30)));
      expect(sent, 2);
      expect(kReactionEmojis, contains('👍'));
    });
  });

  group('الواجهات', () {
    Future<TestHarness> pumpApp(WidgetTester tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();
      return h;
    }

    GoRouter router(WidgetTester tester) =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));

    testWidgets(
      'القناة: تفاعل يحسمه الخادم، ومؤشر كتابة، واستطلاع يتوقف حين تُغطّى الشاشة',
      (tester) async {
        final h = await pumpApp(tester);
        var comments = [_comment('c1')];
        h.transport.on('GET comments', (req) {
          expect(req.url.queryParameters['module'], 'channel');
          expect(req.url.queryParameters['record'], 'cv1');
          return okData({
            'module': 'channel',
            'record': 'cv1',
            'comments': comments,
          });
        });
        var newEvent = false;
        h.transport.on(
          'GET conversations/cv1/since',
          (req) => okData({
            'events': [
              if (req.url.queryParameters['cursor'] == null)
                {
                  'type': 'message.created',
                  'id': 'c1',
                  'user_id': 'u-2',
                  'author': 'سارة',
                  'body': 'نص c1',
                  'created_at': '2026-09-27T09:00:00+03:00',
                },
              if (newEvent && req.url.queryParameters['cursor'] != null)
                {
                  'type': 'message.created',
                  'id': 'c2',
                  'user_id': 'u-2',
                  'author': 'سارة',
                  'body': 'نص c2',
                  'created_at': '2026-09-27T09:05:00+03:00',
                },
            ],
            'cursor': newEvent ? 'K2' : 'K1',
            'typing': ['سارة'],
          }),
        );
        h.transport.on('POST comments/c1/react', (req) {
          return okData({
            'comment_id': 'c1',
            'emoji': req.jsonBody['emoji'],
            'mine': true,
            'count': 1,
          });
        });
        h.transport.onData('POST conversations/cv1/typing', {'ok': true});

        router(tester).push('/conversations/cv1?title=%D8%B9%D8%A7%D9%85');
        await tester.pumpAndSettle();
        expect(find.text('نص c1'), findsOneWidget);
        expect(find.text('سارة يكتب…'), findsOneWidget);

        // تفاعل: الورقة ثم الرمز ⇒ الشريحة بعدد الخادم
        await tester.tap(find.byKey(const Key('react-c1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('react-👍')));
        await tester.pumpAndSettle();
        expect(find.text('👍 1'), findsOneWidget);
        expect(h.transport.sent('POST comments/c1/react').single.jsonBody, {
          'emoji': '👍',
        });

        // الكتابة: نبضة واحدة لعدة أحرف متتالية
        await tester.enterText(find.byKey(const Key('comment-input')), 'أ');
        await tester.enterText(find.byKey(const Key('comment-input')), 'أه');
        await tester.enterText(find.byKey(const Key('comment-input')), 'أهل');
        expect(h.transport.sent('POST conversations/cv1/typing'), hasLength(1));

        // حدث جديد في النبضة التالية ⇒ إعادة جلب هادئة
        newEvent = true;
        comments = [_comment('c1'), _comment('c2')];
        final before = h.transport.sent('GET comments').length;
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(h.transport.sent('GET comments').length, before + 1);
        expect(find.text('نص c2'), findsOneWidget);

        // شاشة فوقها ⇒ لا استطلاع
        h.transport.onData('GET saved', {'saved': <dynamic>[]});
        router(tester).push('/saved');
        await tester.pumpAndSettle();
        final polls = h.transport.sent('GET conversations/cv1/since').length;
        await tester.pump(const Duration(seconds: 20));
        expect(
          h.transport.sent('GET conversations/cv1/since').length,
          polls,
          reason: 'الشاشة المغطّاة لا تستطلع',
        );
        h.dispose();
      },
    );

    testWidgets('المحادثة المباشرة: حضور، تفاعل بالضغط المطوّل، واستطلاع يُلحق '
        'الجديد ويتوقف في الخلفية', (tester) async {
      final h = await pumpApp(tester);
      h.transport.onData('GET dm/threads/u-2/messages', {
        'user': {'id': 'u-2', 'name': 'سارة'},
        'messages': [
          {
            'id': 'm1',
            'from_id': 'u-2',
            'to_id': 'u-1',
            'mine': false,
            'body': 'رسالة قديمة',
            'read': true,
            'created_at': '2026-09-27T09:00:00+03:00',
          },
        ],
      });
      h.transport.onData('POST dm/threads/u-2/read', {'marked': 0});
      h.transport.onData('GET presence', {
        'presence': [
          {'user_id': 'u-2', 'presence': 'online'},
        ],
      });
      var fresh = false;
      h.transport.on(
        'GET dm/threads/u-2/since',
        (req) => okData({
          'events': [
            if (req.url.queryParameters['cursor'] == null)
              {
                'type': 'message.created',
                'id': 'm1',
                'mine': false,
                'body': 'رسالة قديمة',
                'created_at': '2026-09-27T09:00:00+03:00',
              },
            if (fresh && req.url.queryParameters['cursor'] != null)
              {
                'type': 'message.created',
                'id': 'm2',
                'mine': false,
                'body': 'رسالة جديدة',
                'created_at': '2026-09-27T09:10:00+03:00',
              },
          ],
          'cursor': fresh ? 'D2' : 'D1',
          'typing': <dynamic>[],
        }),
      );
      h.transport.onData('POST dm/messages/m1/react', {
        'dm_message_id': 'm1',
        'emoji': '❤️',
        'mine': true,
        'count': 1,
      });
      h.transport.onData('POST dm/threads/u-2/typing', {'ok': true});

      router(tester).push('/messages/u-2?name=%D8%B3%D8%A7%D8%B1%D8%A9');
      await tester.pumpAndSettle();
      expect(find.text('رسالة قديمة'), findsOneWidget);
      expect(find.text('متصل الآن'), findsOneWidget);

      await tester.longPress(find.byKey(const Key('dm-msg-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('react-❤️')));
      await tester.pumpAndSettle();
      expect(find.text('❤️ 1'), findsOneWidget);
      expect(h.transport.sent('POST dm/messages/m1/react'), hasLength(1));

      await tester.enterText(find.byKey(const Key('dm-input')), 'م');
      await tester.enterText(find.byKey(const Key('dm-input')), 'مر');
      expect(h.transport.sent('POST dm/threads/u-2/typing'), hasLength(1));

      fresh = true;
      await tester.pump(kPollStep);
      await tester.pumpAndSettle();
      expect(find.text('رسالة جديدة'), findsOneWidget);
      expect(find.text('رسالة قديمة'), findsOneWidget, reason: 'لا تكرار');

      // الخلفية ⇒ لا مؤقّت ولا نداء
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final polls = h.transport.sent('GET dm/threads/u-2/since').length;
      await tester.pump(const Duration(seconds: 30));
      expect(h.transport.sent('GET dm/threads/u-2/since').length, polls);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        h.transport.sent('GET dm/threads/u-2/since').length,
        polls + 1,
        reason: 'العودة ⇒ نبضة فورية',
      );
      h.dispose();
    });

    testWidgets(
      'الرسائل: نقاط حضور، والقدرة المطفأة بلا نقاط ولا خطأ، وتبويب القنوات والمحفوظات',
      (tester) async {
        final h = await pumpApp(tester);
        h.transport.onData('GET dm/threads', {
          'threads': [
            {
              'user': {'id': 'u-2', 'name': 'سارة'},
              'unread': 0,
              'last': {
                'id': 'm1',
                'mine': false,
                'excerpt': 'أهلاً',
                'read': true,
                'created_at': '2026-09-27T09:00:00+03:00',
              },
            },
          ],
          'unread_total': 0,
        });
        h.transport.on(
          'GET presence',
          (_) => apiError('RESOURCE_NOT_FOUND', 404),
        );
        h.transport.onData('GET conversations', {
          'channels': [
            {
              'id': 'cv1',
              'kind': 'channel',
              'title': 'القناة العامة',
              'audience': 'internal',
              'unread': 4,
              'favorite': false,
            },
          ],
          'rooms': <dynamic>[],
          'groups': <dynamic>[],
          'dms': <dynamic>[],
          'unread_total': 4,
        });
        h.transport.onData('GET saved', {
          'saved': [
            {
              'id': 's2',
              'type': 'dm',
              'available': false,
              'title': null,
              'author': null,
              'note': null,
              'saved_at': '2026-09-25T10:00:00+03:00',
            },
          ],
        });

        router(tester).push('/messages');
        await tester.pumpAndSettle();
        expect(find.text('سارة'), findsOneWidget);
        expect(find.byKey(const Key('presence-u-2')), findsNothing);
        expect(find.byType(ErrorWidget), findsNothing);

        await tester.tap(find.text('القنوات'));
        await tester.pumpAndSettle();
        expect(find.text('القناة العامة'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);

        await tester.tap(find.byKey(const Key('open-saved')));
        await tester.pumpAndSettle();
        expect(find.text('لم يعد هذا متاحاً لك'), findsOneWidget);
        h.dispose();
      },
    );

    testWidgets('الحضور المفعّل يظهر نقطةً للطرف', (tester) async {
      final h = await pumpApp(tester);
      h.transport.onData('GET dm/threads', {
        'threads': [
          {
            'user': {'id': 'u-2', 'name': 'سارة'},
            'unread': 1,
            'last': {'id': 'm1', 'mine': false, 'excerpt': 'أهلاً'},
          },
        ],
        'unread_total': 1,
      });
      h.transport.onData('GET presence', {
        'presence': [
          {'user_id': 'u-2', 'presence': 'recent'},
        ],
      });
      h.transport.onData('GET conversations', {
        'channels': <dynamic>[],
        'rooms': <dynamic>[],
        'groups': <dynamic>[],
        'dms': <dynamic>[],
        'unread_total': 0,
      });
      router(tester).push('/messages');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('presence-u-2')), findsOneWidget);
      expect(
        h.transport.sent('GET presence').single.url.queryParameters['users'],
        'u-2',
      );
      h.dispose();
    });

    testWidgets(
      'مهامي: بطاقة «يومي» بتسمية الخادم، والتقرير اليومي بزر تقديمٍ من المخطط',
      (tester) async {
        final h = TestHarness.create();
        await h.seedSession();
        wireAuthenticatedRoutes(h);
        final schema = schemaPayload();
        (schema['modules'] as List).add({
          'key': 'updates',
          'label': 'تحديثات العمل',
          'sync_class': 'ONLINE_ONLY',
          'can': {'v': true, 'a': true, 'e': false, 'd': false},
          'fields': [
            {'key': 'done', 'label': 'المنجز', 'type': 'ta', 'required': true},
          ],
        });
        h.transport.onData('GET schema', schema);
        h.transport.onData('GET dm/threads', {
          'threads': <dynamic>[],
          'unread_total': 0,
        });
        h.transport.on('GET work/today', (_) => workTodayResponse());
        h.transport.on(
          'GET work/daily-report',
          (_) => workTodayResponse(
            entries: [
              {
                'id': 'w1',
                'done': 'مراجعة العقد',
                'hours': 2.5,
                'progress': null,
                'problems': null,
                'submitted_at': null,
                'review_status': 'accepted',
                'review_feedback': null,
              },
            ],
          ),
        );
        await tester.pumpWidget(
          LynomiaApp(container: h.container, listenAppLinks: false),
        );
        await tester.pumpAndSettle();
        router(tester).go('/mywork');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mywork-today')), findsOneWidget);
        expect(find.text('حاضر QWXZ'), findsOneWidget);
        expect(find.byKey(const Key('work-report-due')), findsOneWidget);

        await tester.tap(find.byKey(const Key('mywork-today')));
        await tester.pumpAndSettle();
        expect(find.text('مراجعة العقد'), findsOneWidget);
        expect(find.textContaining('مقبول'), findsOneWidget);
        expect(find.byKey(const Key('work-submit')), findsOneWidget);
        expect(
          h.transport
              .sent('GET work/daily-report')
              .single
              .url
              .queryParameters['date'],
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
        );

        // اليوم السابق ⇒ نداء بتاريخ مختلف؛ والتالي معطّل على اليوم
        await tester.tap(find.byKey(const Key('work-prev')));
        await tester.pumpAndSettle();
        final dates = h.transport
            .sent('GET work/daily-report')
            .map((r) => r.url.queryParameters['date'])
            .toList();
        expect(dates, hasLength(2));
        expect(dates.first, isNot(dates.last));
        h.dispose();
      },
    );

    testWidgets(
      'مهامي بلا ملف موظف: لا بطاقة، والتقرير يقول ذلك بصدق بلا زر تقديم',
      (tester) async {
        final h = await pumpApp(tester);
        h.transport.onData('GET dm/threads', {
          'threads': <dynamic>[],
          'unread_total': 0,
        });
        h.transport.on('GET work/today', (_) => noProfileResponse());
        h.transport.on('GET work/daily-report', (_) => noProfileResponse());
        router(tester).go('/mywork');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mywork-today')), findsNothing);

        router(tester).push('/work/daily-report');
        await tester.pumpAndSettle();
        expect(find.textContaining('لا ملفَّ موظفٍ نشطاً'), findsOneWidget);
        expect(find.byKey(const Key('work-submit')), findsNothing);
        h.dispose();
      },
    );

    testWidgets(
      'وثائقي: من حسابي، معاينة صورة من الذاكرة، وغير الصورة بلا فتحٍ موهوم',
      (tester) async {
        final h = await pumpApp(tester);
        h.transport.onData('GET me/documents', {
          'items': [
            {
              'id': 'd1',
              'kind': 'passport',
              'label': 'جواز السفر',
              'name': 'passport.png',
              'doc_no': 'A123456',
              'mime': 'image/png',
              'size': 70,
              'date': '2026-01-01',
              'days': -10,
              'infected': false,
              'tone': 'bad',
            },
            {
              'id': 'd2',
              'kind': 'contract',
              'label': 'عقد العمل',
              'name': 'contract.pdf',
              'doc_no': null,
              'mime': 'application/pdf',
              'size': 2048,
              'date': null,
              'days': null,
              'infected': false,
              'tone': '',
            },
          ],
        });
        h.transport.on(
          'GET me/documents/d1/file',
          (_) => http.Response.bytes(
            _png1x1,
            200,
            headers: {'content-type': 'image/png'},
          ),
        );
        router(tester).go('/account');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('account-my-documents')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('account-my-documents')));
        await tester.pumpAndSettle();

        expect(find.text('جواز السفر'), findsOneWidget);
        expect(find.text('انتهت 2026-01-01'), findsOneWidget);
        expect(find.textContaining('للصور فقط'), findsOneWidget);

        // غير الصورة: لا نداء ملف عند النقر
        await tester.tap(find.text('عقد العمل'));
        await tester.pumpAndSettle();
        expect(h.transport.sent('GET me/documents/d2/file'), isEmpty);

        await tester.tap(find.text('جواز السفر'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mydoc-image')), findsOneWidget);
        expect(h.transport.sent('GET me/documents/d1/file'), hasLength(1));
        h.dispose();
      },
    );

    testWidgets('وثيقة مقيّدة (403): نص محلي من الرمز لا رسالة الخادم', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      h.transport.onData('GET me/documents', {
        'items': [
          {
            'id': 'd9',
            'kind': 'id',
            'label': 'البطاقة المدنية',
            'name': 'civil.jpg',
            'mime': 'image/jpeg',
            'size': 1,
            'infected': false,
            'tone': '',
          },
        ],
      });
      h.transport.on(
        'GET me/documents/d9/file',
        (_) => apiError('FORBIDDEN', 403, message: 'رسالة خادمية QWXZ'),
      );
      router(tester).push('/me/documents');
      await tester.pumpAndSettle();
      await tester.tap(find.text('البطاقة المدنية'));
      await tester.pumpAndSettle();
      expect(find.text('وصول هذه الوثيقة مقيَّد بقاعدة صريحة'), findsOneWidget);
      expect(find.textContaining('QWXZ'), findsNothing);
      h.dispose();
    });
  });
}

/// خطوة استطلاع المحادثة في الاختبار.
const kPollStep = Duration(seconds: 4);

/// صورة PNG صالحة 1×1.
final _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
