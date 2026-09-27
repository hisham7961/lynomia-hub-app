/// المرحلة ٤ (خلفية v2.618) — التعاون والعميل وسير العمل: تذاكر العميل،
/// القنوات والمجموعات وتحرير الرسائل وبحثها، أفعال التعليق، مراجعة تقارير
/// الفريق، التقويم والتنبيهات، الأفعال المالية، و«اسأل Hub» بالبثّ.
library;

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';
import 'package:lynomia_hub_app/features/ask/ask_screen.dart';
import 'package:lynomia_hub_app/features/calendar/calendar_screens.dart';
import 'package:lynomia_hub_app/features/comments/comments_panel.dart';
import 'package:lynomia_hub_app/features/finance/finance_actions_card.dart';
import 'package:lynomia_hub_app/features/finance/finance_repository.dart';
import 'package:lynomia_hub_app/features/messages/channels_screens.dart';
import 'package:lynomia_hub_app/features/messages/messages_screens.dart';
import 'package:lynomia_hub_app/features/my_work/team_reports_repository.dart';
import 'package:lynomia_hub_app/features/my_work/team_reports_screen.dart';
import 'package:lynomia_hub_app/features/portal/portal_tickets_repository.dart';
import 'package:lynomia_hub_app/features/portal/portal_tickets_screens.dart';

import '../fakes/fakes.dart';
import '../fakes/screen_harness.dart';
import '../widget/rtl_app_test.dart' show wireAuthenticatedRoutes;

/// رد SSE كما يبثّه `ask/stream`.
http.Response sse(List<(String, Map<String, dynamic>)> events) =>
    http.Response.bytes(
      utf8.encode(
        events
            .map((e) => 'event: ${e.$1}\ndata: ${jsonEncode(e.$2)}\n\n')
            .join(),
      ),
      200,
      headers: {'content-type': 'text/event-stream; charset=UTF-8'},
    );

Map<String, dynamic> _answer({String text = 'جوابٌ مبثوث QWXZ'}) => {
  'ok': true,
  'answer': text,
  'partial': false,
  'failure': null,
  'message': '',
  'sources': <dynamic>[],
  'thread': 'th-9',
};

Map<String, dynamic> _ticket({bool done = false}) => {
  'id': 'tk1',
  'subject': 'الطابعة لا تعمل',
  'status': 'جديدة',
  'priority': 'عالية',
  'done': done,
  'created_at': '2026-09-27T08:00:00+03:00',
};

Map<String, dynamic> _entry({
  String status = 'pending_review',
  bool canReview = true,
}) => {
  'id': 'w1',
  'work_date': '2026-09-27',
  'author': {'id': 'u-5', 'name': 'خالد'},
  'project': {'id': 'p1', 'name': 'المشروع أ'},
  'task': null,
  'done': 'أنجزت التصميم',
  'hours': 6.5,
  'progress': 40,
  'problems': null,
  'next': 'المراجعة',
  'review_status': status,
  'can_review': canReview,
};

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
  });

  tearDown(() => h.dispose());

  group('المستودعات (العقد)', () {
    test('تذاكري: القائمة والتفصيل والفتح والتوأم والردّ', () async {
      h.transport.onData('GET portal/tickets', {
        'tickets': [_ticket()],
        'projects': [
          {'id': 'p1', 'name': 'موقع'},
        ],
        'clients': [
          {'id': 'c1', 'name': 'عميل'},
        ],
        'priorities': ['عادية', 'عالية'],
      });
      final list = await h.container.portalTickets.tickets();
      expect(list.tickets.single.subject, 'الطابعة لا تعمل');
      expect(list.priorities, ['عادية', 'عالية']);

      h.transport.onData('GET portal/tickets/tk1', {
        'ticket': {..._ticket(), 'body': 'تفاصيل', 'project_name': 'موقع'},
        'replies': [
          {
            'id': 'r1',
            'body': 'نعمل عليها',
            'user': {'id': 'u-9', 'name': 'الدعم'},
            'mine': false,
          },
        ],
      });
      final d = await h.container.portalTickets.ticket('tk1');
      expect(d.ticket.projectName, 'موقع');
      expect(d.replies.single.userName, 'الدعم');

      h.transport.on('POST portal/tickets', (req) {
        if (req.jsonBody['force'] != true) {
          return apiError(
            'CONFLICT',
            409,
            details: {'reason': 'duplicate_ticket', 'duplicate': _ticket()},
          );
        }
        return okData({
          'ticket': _ticket(),
          'replies': <dynamic>[],
        }, status: 201);
      });
      await expectLater(
        h.container.portalTickets.create(
          subject: 's',
          body: 'b',
          priority: 'عالية',
        ),
        throwsA(
          isA<DuplicateTicketException>().having(
            (e) => e.existing?.id,
            'existing',
            'tk1',
          ),
        ),
      );
      await h.container.portalTickets.create(
        subject: 's',
        body: 'b',
        priority: 'عالية',
        projectId: 'p1',
        force: true,
      );
      final created = h.transport.sent('POST portal/tickets').last;
      expect(created.jsonBody, {
        'subject': 's',
        'body': 'b',
        'priority': 'عالية',
        'project': 'p1',
        'force': true,
      });
      expect(created.headers['Idempotency-Key'], isNotEmpty);

      h.transport.onData('POST portal/tickets/tk1/reply', {
        'reply': {'id': 'r2', 'body': 'شكراً', 'mine': true},
        'ticket_id': 'tk1',
      });
      final r = await h.container.portalTickets.reply('tk1', 'شكراً');
      expect(r.mine, isTrue);
    });

    test(
      'القنوات: الدليل والإنشاء والانضمام (بلا إعادة) والأعضاء والتفضيلات',
      () async {
        h.transport.onData('GET conversations/directory', {
          'channels': [
            {
              'id': 'ch1',
              'title': 'عام',
              'visibility': 'company',
              'members': 9,
            },
          ],
        });
        expect((await h.container.collab.directory()).single.members, 9);

        h.transport.onData('POST conversations', {
          'conversation': {
            'id': 'ch2',
            'kind': 'channel',
            'title': 'جديدة',
            'my_role': 'owner',
          },
        });
        final c = await h.container.collab.createChannel(
          title: 'جديدة',
          visibility: 'members',
        );
        expect(c.myRole, 'owner');
        final create = h.transport.sent('POST conversations').single;
        expect(create.jsonBody, {'title': 'جديدة', 'visibility': 'members'});
        expect(create.headers['Idempotency-Key'], isNotEmpty);

        h.transport.failOnce.add('POST conversations/ch1/join');
        await expectLater(
          h.container.collab.join('ch1'),
          throwsA(isA<NetworkException>()),
        );
        expect(
          h.transport.sent('POST conversations/ch1/join'),
          hasLength(1),
          reason: 'فعلٌ بلا مفتاح ⇒ لا إعادة تلقائية',
        );

        h.transport.onData('GET conversations/ch1/members', {
          'conversation_id': 'ch1',
          'my_role': 'owner',
          'can_post': true,
          'can_manage': true,
          'members': [
            {
              'user': {'id': 'u-1', 'name': 'أنا'},
              'role': 'owner',
            },
            {
              'user': {'id': 'u-2', 'name': 'سارة'},
              'role': 'member',
            },
          ],
        });
        final m = await h.container.collab.members('ch1');
        expect(m.isOwner, isTrue);
        expect(m.members.last.name, 'سارة');

        final member = {
          'member': {
            'user': {'id': 'u-2', 'name': 'سارة'},
            'role': 'moderator',
          },
        };
        h.transport.onData('PUT conversations/ch1/members/u-2', member);
        expect(
          (await h.container.collab.setMemberRole(
            'ch1',
            'u-2',
            'moderator',
          )).role,
          'moderator',
        );
        h.transport.onData('POST conversations/ch1/members', member);
        await h.container.collab.addMember('ch1', 'u-2');
        expect(
          h.transport.sent('POST conversations/ch1/members').single.jsonBody,
          {'user_id': 'u-2'},
        );
        h.transport.onData('DELETE conversations/ch1/members/u-2', {
          'removed': true,
        });
        await h.container.collab.removeMember('ch1', 'u-2');

        h.transport.onData('POST conversations/ch1/favorite', {
          'favorite': true,
        });
        expect(await h.container.collab.toggleFavorite('ch1'), isTrue);
        h.transport.onData('POST conversations/ch1/archive', {
          'archived': true,
        });
        expect(await h.container.collab.toggleArchive('ch1'), isTrue);
        h.transport.onData('PUT conversations/ch1/notify', {
          'pref': 'mentions',
        });
        expect(
          await h.container.collab.setNotifyPref('ch1', 'mentions'),
          'mentions',
        );
      },
    );

    test('المجموعات والبحث وتحرير/سحب الرسالة المباشرة', () async {
      h.transport.onData('POST groups', {
        'conversation': {'id': 'g1', 'kind': 'group', 'my_role': 'owner'},
      });
      await h.container.collab.createGroup(['u-2', 'u-3'], title: 'فريق');
      expect(h.transport.sent('POST groups').single.jsonBody, {
        'participants': ['u-2', 'u-3'],
        'title': 'فريق',
      });
      h.transport.onData('POST groups/g1/leave', {'left': true});
      await h.container.collab.leaveGroup('g1');

      h.transport.onData('GET search/messages', {
        'q': 'عقد',
        'min_chars': 2,
        'total': 1,
        'results': [
          {
            'type': 'channel',
            'id': 'cm1',
            'author': 'سارة',
            'excerpt': 'مسودة العقد',
            'target': {
              'kind': 'comment',
              'module': 'channel',
              'record_id': 'ch1',
              'comment_id': 'cm1',
            },
          },
          {
            'type': 'dm',
            'id': 'dm1',
            'excerpt': 'العقد جاهز',
            'target': {'kind': 'dm', 'user_id': 'u-2', 'message_id': 'dm1'},
          },
        ],
      });
      final s = await h.container.collab.searchMessages('عقد');
      expect(s.hits.first.target!.routePath, '/conversations/ch1');
      expect(s.hits.last.target!.routePath, '/messages/u-2');

      h.transport.onData('PATCH dm/messages/dm1', {
        'message': {
          'id': 'dm1',
          'mine': true,
          'body': 'مُعدّل',
          'edited': true,
          'deleted': false,
        },
      });
      final e = await h.container.dm.editMessage('dm1', 'مُعدّل');
      expect(e.edited, isTrue);
      h.transport.onData('DELETE dm/messages/dm1', {
        'message': {'id': 'dm1', 'mine': true, 'body': null, 'deleted': true},
      });
      expect((await h.container.dm.deleteMessage('dm1')).deleted, isTrue);
    });

    test('أفعال التعليق: تحرير/حذف/تثبيت/حلّ/تحويل لمهمة', () async {
      Map<String, dynamic> card({bool pinned = false, bool resolved = false}) =>
          {
            'comment': {
              'id': 'c1',
              'body': 'نص',
              'pinned': pinned,
              'resolved': resolved,
              'edited': true,
            },
          };
      h.transport.onData('PATCH comments/c1', card());
      expect((await h.container.comments.edit('c1', 'نص')).edited, isTrue);
      h.transport.onData('POST comments/c1/pin', card(pinned: true));
      expect((await h.container.comments.togglePin('c1')).pinned, isTrue);
      h.transport.onData('POST comments/c1/resolve', card(resolved: true));
      expect((await h.container.comments.toggleResolve('c1')).resolved, isTrue);
      h.transport.onData('POST comments/c1/to-task', {
        'task': {'id': 'tk9', 'title': 'نص', 'status': 'جديدة'},
        ...card(),
      });
      expect(await h.container.comments.toTask('c1'), 'tk9');
      expect(
        h.transport
            .sent('POST comments/c1/to-task')
            .single
            .headers['Idempotency-Key'],
        isNotEmpty,
      );
      h.transport.onData('DELETE comments/c1', {'id': 'c1', 'deleted': true});
      await h.container.comments.delete('c1');
      // التبديلات بلا مفتاح ولا إعادة.
      expect(
        h.transport
            .sent('POST comments/c1/pin')
            .single
            .headers['Idempotency-Key'],
        isNull,
      );
    });

    test('تقارير الفريق: الاستعلام والمراجعة', () async {
      h.transport.onData('GET reports/daily', {
        'date': '2026-09-27',
        'scope': 'team',
        'status': 'pending',
        'summary': {
          'total': 3,
          'pending': 1,
          'accepted': 1,
          'needs_revision': 1,
        },
        'entries': [_entry()],
        'truncated': false,
      });
      final d = await h.container.teamReports.daily(
        date: DateTime(2026, 9, 27),
        scope: 'team',
        status: 'pending',
      );
      expect(h.transport.sent('GET reports/daily').single.url.queryParameters, {
        'date': '2026-09-27',
        'scope': 'team',
        'status': 'pending',
      });
      expect(d.entries.single.hours, Decimal.parse('6.5'));
      expect(d.entries.single.canReview, isTrue);

      h.transport.onData('POST reports/daily/w1/review', {
        'outcome': 'needs_revision',
        'entry': _entry(status: 'needs_revision'),
      });
      final r = await h.container.teamReports.review(
        'w1',
        ReviewAction.needsRevision,
        feedback: 'أضف التفاصيل',
      );
      expect(r.outcome, 'needs_revision');
      expect(h.transport.sent('POST reports/daily/w1/review').single.jsonBody, {
        'action': 'needs_revision',
        'feedback': 'أضف التفاصيل',
      });
    });

    test('التقويم والتنبيهات: النافذة ووجهات الخادم', () async {
      h.transport.onData('GET calendar', {
        'from': '2026-09-27',
        'to': '2026-10-26',
        'days': [
          {
            'date': '2026-09-30',
            'items': [
              {
                'module': 'tasks',
                'module_label': 'المهام',
                'field_label': 'الاستحقاق',
                'id': 't1',
                'name': 'تسليم',
                'target': {'module': 'tasks', 'id': 't1'},
              },
            ],
          },
        ],
        'overflow': 0,
      });
      final c = await h.container.calendar.range(
        from: DateTime(2026, 9, 27),
        to: DateTime(2026, 10, 26),
      );
      expect(h.transport.sent('GET calendar').single.url.queryParameters, {
        'from': '2026-09-27',
        'to': '2026-10-26',
      });
      expect(c.days.single.items.single.routePath, '/r/tasks/t1');

      h.transport.onData('GET alerts', {
        'late': [
          {
            'module': 'hr',
            'id': 'e1',
            'name': 'جواز',
            'days': -2,
            'self': true,
            'target': {'route': 'portal.me', 'args': <dynamic>[]},
          },
        ],
        'week': [
          {
            'module': 'assets',
            'id': 'as1',
            'name': 'ضمان',
            'days': 3,
            'target': {
              'route': 'm.show',
              'args': ['assets', 'as1'],
            },
          },
        ],
        'month': <dynamic>[],
        'total': 2,
        'window_days': 30,
      });
      final a = await h.container.calendar.alerts();
      expect(a.late.single.routePath, '/me/documents');
      expect(a.week.single.routePath, '/r/assets/as1');
      expect(a.total, 2);
    });

    test('المالية: الدفعة نصٌّ عشري بمفتاح، والعرض والاستلام', () async {
      expect(parseAmount('2500.5'), Decimal.parse('2500.5'));
      expect(parseAmount('١٢٫٥'), Decimal.parse('12.5'));
      expect(parseAmount('1,000'), isNull);
      expect(parseAmount('0'), isNull);
      expect(parseAmount('1.2345'), isNull);

      h.transport.onData('POST fin/d1/pay', {
        'amount': '100.000',
        'document': {
          'id': 'd1',
          'currency': 'KWD',
          'total': '300.000',
          'paid': '100.000',
          'remaining': '200.000',
        },
        'payment': {'amount': '100.000', 'seq': 1},
      });
      final p = await h.container.finance.pay(
        'd1',
        amount: Decimal.parse('100'),
        payRef: ' TRX-1 ',
      );
      expect(p.document.remaining, Decimal.parse('200'));
      final req = h.transport.sent('POST fin/d1/pay').single;
      expect(req.jsonBody, {'amount': '100', 'payRef': 'TRX-1'});
      expect(req.jsonBody['amount'], isA<String>(), reason: 'لا double');
      expect(req.headers['Idempotency-Key'], isNotEmpty);

      h.transport.onData('POST quotes/q1/send', {
        'outcome': 'escalated',
        'quote': {'id': 'q1', 'status': 'مراجعة'},
      });
      expect((await h.container.finance.sendQuote('q1')).outcome, 'escalated');
      h.transport.onData('POST quotes/q1/accept', {
        'accepted': false,
        'quote': {'id': 'q1'},
      });
      expect((await h.container.finance.acceptQuote('q1')).accepted, isFalse);
      h.transport.onData('POST purchases/po1/receive', {
        'moves': 3,
        'skipped': 1,
        'already': false,
        'purchase': {'id': 'po1', 'status': 'مستلم'},
      });
      final rc = await h.container.finance.receivePurchase('po1');
      expect(rc.moves, 3);
      expect(rc.status, 'مستلم');
    });

    test('اسأل بالبثّ: تقدّمٌ ثم done، وخطأ البثّ مكتوب', () async {
      h.transport.on(
        'POST ask/stream',
        (_) => sse([
          ('progress', {'stage': 'plan', 'text': 'أفهم السؤال…'}),
          ('progress', {'stage': 'read', 'text': 'أقرأ المشاريع…'}),
          ('done', {'data': _answer(), 'request_id': 'rid-s'}),
        ]),
      );
      final progress = <String>[];
      final a = await h.container.ask.askWithProgress(
        'سؤال',
        thread: 'th-1',
        onProgress: progress.add,
      );
      expect(progress, ['أفهم السؤال…', 'أقرأ المشاريع…']);
      expect(a.answer, 'جوابٌ مبثوث QWXZ');
      expect(a.thread, 'th-9');
      final req = h.transport.sent('POST ask/stream').single;
      expect(req.jsonBody, {'q': 'سؤال', 'thread': 'th-1'});
      expect(req.headers['Accept'], contains('text/event-stream'));
      expect(h.transport.sent('POST ask'), isEmpty);

      h.transport.on(
        'POST ask/stream',
        (_) => sse([
          (
            'error',
            {'code': 'INTERNAL_ERROR', 'text': 'خطأ', 'request_id': 'r'},
          ),
        ]),
      );
      await expectLater(
        h.container.ask.askWithProgress('سؤال'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.internalError,
          ),
        ),
      );
      expect(
        h.transport.sent('POST ask'),
        isEmpty,
        reason: 'لا ارتداد بعد البدء',
      );
    });

    test('اسأل بالبثّ: الارتداد لـPOST ask حين لا يُفتح البثّ فقط', () async {
      h.transport.onData('POST ask', _answer(text: 'جوابٌ عادي'));
      // خادمٌ أقدم (٤٠٤) ⇒ ارتداد.
      h.transport.on(
        'POST ask/stream',
        (_) => apiError('RESOURCE_NOT_FOUND', 404),
      );
      expect((await h.container.ask.askWithProgress('س')).answer, 'جوابٌ عادي');
      // فشل اتصالٍ قبل أي رد ⇒ ارتداد؛ والبثّ نفسه لا يُعاد.
      h.transport.failOnce.add('POST ask/stream');
      expect((await h.container.ask.askWithProgress('س')).answer, 'جوابٌ عادي');
      expect(h.transport.sent('POST ask'), hasLength(2));
      // رفضٌ قبل البثّ (٤٢٢) ⇒ لا ارتداد.
      h.transport.on(
        'POST ask/stream',
        (_) => apiError('VALIDATION_FAILED', 422),
      );
      await expectLater(
        h.container.ask.askWithProgress('س'),
        throwsA(isA<ApiException>()),
      );
      expect(h.transport.sent('POST ask'), hasLength(2));
    });
  });

  group('الواجهات', () {
    testWidgets('تذاكري: فتح بلاغ ⇒ توأم مفتوح ⇒ تأكيد ⇒ force', (
      tester,
    ) async {
      h.transport.onData('GET portal/tickets', {
        'tickets': [_ticket()],
        'projects': <dynamic>[],
        'clients': <dynamic>[],
        'priorities': ['عادية', 'عالية'],
      });
      h.transport.on('POST portal/tickets', (req) {
        if (req.jsonBody['force'] != true) {
          return apiError(
            'CONFLICT',
            409,
            details: {'reason': 'duplicate_ticket', 'duplicate': _ticket()},
          );
        }
        return okData({
          'ticket': {..._ticket(), 'id': 'tk2', 'subject': 'جديد'},
          'replies': <dynamic>[],
        }, status: 201);
      });
      await pumpScreen(
        tester,
        h,
        const PortalTicketsScreen(),
        extraRoutes: [
          GoRoute(
            path: '/portal/tickets/:id',
            builder: (_, s) => Text('TICKET:${s.pathParameters['id']}'),
          ),
        ],
      );
      expect(find.text('الطابعة لا تعمل'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('ticket-subject')), 'جديد');
      await tester.enterText(find.byKey(const Key('ticket-body')), 'وصف');
      await tester.tap(find.byKey(const Key('ticket-submit')));
      await tester.pumpAndSettle();
      expect(find.text('بلاغ مشابه مفتوح'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-dup-force')));
      await tester.pumpAndSettle();
      final sent = h.transport.sent('POST portal/tickets');
      expect(sent, hasLength(2));
      expect(sent.last.jsonBody['force'], isTrue);
      expect(sent.last.jsonBody['priority'], 'عادية');
      expect(find.text('TICKET:tk2'), findsOneWidget);
    });

    testWidgets('تفصيل التذكرة: الردّ، والمغلقة بلا حقل رد', (tester) async {
      var done = false;
      h.transport.on(
        'GET portal/tickets/tk1',
        (_) => okData({'ticket': _ticket(done: done), 'replies': <dynamic>[]}),
      );
      h.transport.on('POST portal/tickets/tk1/reply', (_) {
        done = true;
        return okData({
          'reply': {'id': 'r1', 'body': 'شكراً', 'mine': true},
        }, status: 201);
      });
      await pumpScreen(tester, h, const PortalTicketScreen(id: 'tk1'));
      await tester.enterText(
        find.byKey(const Key('ticket-reply-input')),
        'شكراً',
      );
      await tester.tap(find.byKey(const Key('ticket-reply-send')));
      await tester.pumpAndSettle();
      expect(
        h.transport.sent('POST portal/tickets/tk1/reply').single.jsonBody,
        {'body': 'شكراً'},
      );
      expect(find.byKey(const Key('ticket-reply-input')), findsNothing);
    });

    testWidgets('الأعضاء: المالك يغيّر الدور؛ لا قائمة على نفسه', (
      tester,
    ) async {
      h.transport.onData('GET bootstrap', bootstrapPayload());
      await h.container.account.loadBootstrap();
      h.transport.onData('GET conversations/ch1/members', {
        'my_role': 'owner',
        'can_post': true,
        'can_manage': true,
        'members': [
          {
            'user': {'id': 'u-1', 'name': 'أنا'},
            'role': 'owner',
          },
          {
            'user': {'id': 'u-2', 'name': 'سارة'},
            'role': 'member',
          },
        ],
      });
      h.transport.onData('PUT conversations/ch1/members/u-2', {
        'member': {
          'user': {'id': 'u-2', 'name': 'سارة'},
          'role': 'moderator',
        },
      });
      await pumpScreen(
        tester,
        h,
        const ConversationMembersScreen(conversationId: 'ch1'),
      );
      expect(find.byKey(const Key('member-menu-u-1')), findsNothing);
      await tester.tap(find.byKey(const Key('member-menu-u-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اجعله مشرف'));
      await tester.pumpAndSettle();
      expect(
        h.transport.sent('PUT conversations/ch1/members/u-2').single.jsonBody,
        {'role': 'moderator'},
      );
    });

    testWidgets('الدليل: الانضمام ثم فتح الحاوية', (tester) async {
      h.transport.onData('GET conversations/directory', {
        'channels': [
          {'id': 'ch1', 'title': 'عام', 'visibility': 'company', 'members': 4},
        ],
      });
      h.transport.onData('POST conversations/ch1/join', {
        'conversation': {
          'id': 'ch1',
          'kind': 'channel',
          'title': 'عام',
          'my_role': 'member',
        },
        'joined': true,
      });
      await pumpScreen(
        tester,
        h,
        const ChannelDirectoryScreen(),
        extraRoutes: [
          GoRoute(
            path: '/conversations/:id',
            builder: (_, s) => Text(
              'CONV:${s.pathParameters['id']}:${s.uri.queryParameters['kind']}',
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('join-ch1')));
      await tester.pumpAndSettle();
      expect(find.text('CONV:ch1:channel'), findsOneWidget);
    });

    testWidgets('الرسائل المباشرة: تحرير رسالتي من القائمة المطوّلة', (
      tester,
    ) async {
      h.transport.onData('GET dm/threads/u-2/messages', {
        'user': {'id': 'u-2', 'name': 'سارة'},
        'messages': [
          {'id': 'm1', 'mine': true, 'body': 'قديم', 'deleted': false},
          {'id': 'm2', 'mine': false, 'body': 'ردّها', 'deleted': false},
        ],
        'cursor': '',
      });
      h.transport.onData('POST dm/threads/u-2/read', {'marked': 0});
      h.transport.onData('GET dm/threads/u-2/since', {
        'events': <dynamic>[],
        'cursor': '',
        'has_more': false,
        'typing': <dynamic>[],
      });
      h.transport.onData('GET presence', {'presence': <dynamic>[]});
      h.transport.onData('PATCH dm/messages/m1', {
        'message': {
          'id': 'm1',
          'mine': true,
          'body': 'جديد',
          'edited': true,
          'deleted': false,
        },
      });
      await pumpScreen(
        tester,
        h,
        const DmChatScreen(otherUserId: 'u-2', otherName: 'سارة'),
      );
      await tester.longPress(find.byKey(const Key('dm-msg-m2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dm-edit')), findsNothing, reason: 'ليست لي');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('dm-msg-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dm-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('prompt-input')), 'جديد');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(find.text('جديد'), findsOneWidget);
      expect(find.text('(معدّلة)'), findsOneWidget);
    });

    testWidgets('لوحة التعليقات: تحرير تعليقي، وتعليق غيري بلا تحرير', (
      tester,
    ) async {
      h.transport.onData('GET bootstrap', bootstrapPayload());
      await h.container.account.loadBootstrap();
      h.transport.onData('GET schema', schemaPayload());
      var body = 'أصلي';
      h.transport.on(
        'GET comments',
        (_) => okData({
          'comments': [
            {
              'id': 'c1',
              'user': {'id': 'u-1', 'name': 'أنا'},
              'body': body,
              'replies': <dynamic>[],
            },
            {
              'id': 'c2',
              'user': {'id': 'u-2', 'name': 'سارة'},
              'body': 'لها',
              'replies': <dynamic>[],
            },
          ],
        }),
      );
      h.transport.on('PATCH comments/c1', (req) {
        body = req.jsonBody['body'] as String;
        return okData({
          'comment': {'id': 'c1', 'body': body, 'edited': true},
        });
      });
      await pumpScreen(
        tester,
        h,
        const Scaffold(
          body: CommentsPanel(module: 'tasks', recordId: 't1'),
        ),
      );
      await tester.tap(find.byKey(const Key('comment-menu-c2')));
      await tester.pumpAndSettle();
      expect(find.text('تحرير'), findsNothing);
      expect(find.text('تحويل لمهمة'), findsOneWidget, reason: 'tasks.can.a');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment-menu-c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحرير'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('prompt-input')), 'معدّل');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(find.text('معدّل'), findsOneWidget);
    });

    testWidgets('مراجعة التقارير: طلب التنقيح يُلزم ملاحظة', (tester) async {
      var status = 'pending_review';
      h.transport.on(
        'GET reports/daily',
        (_) => okData({
          'date': '2026-09-27',
          'scope': 'team',
          'status': 'all',
          'summary': {
            'total': 1,
            'pending': status == 'pending_review' ? 1 : 0,
            'accepted': 0,
            'needs_revision': status == 'needs_revision' ? 1 : 0,
          },
          'entries': [_entry(status: status)],
          'truncated': false,
        }),
      );
      h.transport.on('POST reports/daily/w1/review', (req) {
        status = 'needs_revision';
        return okData({
          'outcome': 'needs_revision',
          'entry': _entry(status: status),
        });
      });
      await pumpScreen(tester, h, const TeamReportsScreen());
      expect(find.text('أنجزت التصميم'), findsOneWidget);
      await tester.tap(find.byKey(const Key('review-revise-w1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('POST reports/daily/w1/review'), isEmpty);
      await tester.enterText(find.byKey(const Key('prompt-input')), 'فصّل');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('POST reports/daily/w1/review').single.jsonBody, {
        'action': 'needs_revision',
        'feedback': 'فصّل',
      });
      expect(find.byKey(const Key('review-revise-w1')), findsNothing);
      expect(find.byKey(const Key('review-reopen-w1')), findsOneWidget);
    });

    testWidgets('التنبيهات: صفّ صاحب الشأن يفتح وثائقي', (tester) async {
      h.transport.onData('GET alerts', {
        'late': [
          {
            'module': 'hr',
            'module_label': 'الموارد',
            'field_label': 'الجواز',
            'id': 'e1',
            'name': 'جوازي',
            'days': -1,
            'self': true,
            'target': {'route': 'portal.me', 'args': <dynamic>[]},
          },
        ],
        'week': <dynamic>[],
        'month': <dynamic>[],
        'total': 1,
        'window_days': 30,
      });
      await pumpScreen(tester, h, const AlertsScreen());
      expect(find.textContaining('متأخر 1 يوماً'), findsOneWidget);
      await tester.tap(find.text('جوازي'));
      await tester.pumpAndSettle();
      expect(find.text('NAV:/me/documents'), findsOneWidget);
    });

    testWidgets('التقويم: النافذة التالية تطلب from/to الجديدين', (
      tester,
    ) async {
      h.transport.on(
        'GET calendar',
        (req) => okData({
          'from': req.url.queryParameters['from'],
          'to': req.url.queryParameters['to'],
          'days': <dynamic>[],
          'overflow': 0,
        }),
      );
      await pumpScreen(tester, h, const CalendarScreen());
      expect(find.text('لا مواعيد في هذه النافذة'), findsOneWidget);
      await tester.tap(find.byKey(const Key('calendar-next')));
      await tester.pumpAndSettle();
      final reqs = h.transport.sent('GET calendar');
      expect(reqs, hasLength(2));
      final f0 = DateTime.parse(reqs[0].url.queryParameters['from']!);
      final f1 = DateTime.parse(reqs[1].url.queryParameters['from']!);
      expect(f1.difference(f0).inDays, 30);
    });

    testWidgets('الدفعة: تحققٌ عشري محلي، ثم التصعيد، والمفتاح ثابت', (
      tester,
    ) async {
      var calls = 0;
      h.transport.on('POST fin/d1/pay', (_) {
        calls++;
        if (calls == 1) {
          return apiError(
            'STEP_UP_REQUIRED',
            428,
            details: {'purpose': 'action:fin:pay', 'method': 'password'},
          );
        }
        return okData({
          'amount': '12.500',
          'document': {'id': 'd1', 'currency': 'KWD', 'remaining': '87.500'},
        });
      });
      h.transport.onData('POST auth/step-up', {'granted': true});
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: FinanceActionsCard(
            module: 'fin',
            recordId: 'd1',
            onChanged: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('fin-pay')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('pay-amount')), '1,000');
      await tester.tap(find.byKey(const Key('pay-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('بلا فواصل آلاف'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pay-amount')), '12.5');
      await tester.tap(find.byKey(const Key('pay-submit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'pw');
      await tester.tap(find.text('تأكيد').last);
      await tester.pumpAndSettle();
      final sent = h.transport.sent('POST fin/d1/pay');
      expect(sent, hasLength(2));
      expect(sent.last.jsonBody['amount'], '12.5');
      expect(
        sent[0].headers['Idempotency-Key'],
        sent[1].headers['Idempotency-Key'],
      );
      expect(find.textContaining('87.5'), findsOneWidget);
    });

    testWidgets('استلام أمر الشراء: 409 طابور اعتماد ⇒ رسالة صادقة', (
      tester,
    ) async {
      h.transport.on(
        'POST purchases/po1/receive',
        (_) =>
            apiError('APPROVAL_REQUIRED', 409, message: 'بانتظار اعتمادٍ QWXZ'),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: FinanceActionsCard(
            module: 'purchases',
            recordId: 'po1',
            onChanged: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('purchase-receive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(find.text('بانتظار اعتمادٍ QWXZ'), findsOneWidget);
    });

    testWidgets('بحث الرسائل: الحد الأدنى من الخادم، والنتيجة تفتح وجهتها', (
      tester,
    ) async {
      h.transport.onData('GET search/messages', {
        'q': 'عقد',
        'min_chars': 2,
        'total': 1,
        'results': [
          {
            'type': 'dm',
            'id': 'dm1',
            'excerpt': 'العقد جاهز',
            'target': {'kind': 'dm', 'user_id': 'u-2', 'message_id': 'dm1'},
          },
        ],
      });
      await pumpScreen(tester, h, const MessageSearchScreen());
      await tester.enterText(
        find.byKey(const Key('message-search-input')),
        'ع',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(h.transport.sent('GET search/messages'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('message-search-input')),
        'عقد',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('العقد جاهز'));
      await tester.pumpAndSettle();
      expect(find.text('NAV:/messages/u-2'), findsOneWidget);
    });

    testWidgets('اسأل Hub: السؤال يسلك البثّ ويعرض الجواب بلا POST ask', (
      tester,
    ) async {
      h.transport.on(
        'POST ask/stream',
        (_) => sse([
          ('progress', {'stage': 'read', 'text': 'أقرأ المهام'}),
          ('done', {'data': _answer(), 'request_id': 'r'}),
        ]),
      );
      await pumpScreen(tester, h, const AskScreen());
      await tester.enterText(find.byKey(const Key('ask-input')), 'ما مهامي؟');
      await tester.tap(find.byKey(const Key('ask-send')));
      await tester.pumpAndSettle();
      expect(find.text('جوابٌ مبثوث QWXZ'), findsOneWidget);
      expect(h.transport.sent('POST ask/stream'), hasLength(1));
      expect(h.transport.sent('POST ask'), isEmpty);
    });

    testWidgets('«مهامي»: بطاقة الحضور ومداخل التقويم/التنبيهات/التقارير '
        'بأهلية الخادم', (tester) async {
      h.dispose();
      h = TestHarness.create();
      await h.seedSession();
      wireAuthenticatedRoutes(h);
      h.transport.onData('GET dm/threads', {
        'threads': <dynamic>[],
        'unread_total': 0,
      });
      h.transport.on(
        'GET work/today',
        (_) => apiError(
          'BUSINESS_RULE_VIOLATION',
          422,
          details: {'reason': 'no_employee_profile'},
        ),
      );
      h.transport.onData('GET attendance/today', {
        'date': '2026-09-27',
        'state': 'not_checked_in',
        'can': {'check_in': true, 'check_out': false},
        'modes': <dynamic>[],
        'location': {'recorded_by_server': false},
      });
      h.transport.onData('GET alerts', {
        'late': <dynamic>[],
        'week': <dynamic>[],
        'month': <dynamic>[],
        'total': 4,
        'window_days': 30,
      });
      h.transport.on('GET reports/daily', (_) => apiError('FORBIDDEN', 403));
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('مهامي').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance-check-in')), findsOneWidget);
      expect(find.byKey(const Key('mywork-calendar')), findsOneWidget);
      expect(find.byKey(const Key('mywork-alerts')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(
        find.byKey(const Key('mywork-team-reports')),
        findsNothing,
        reason: '403 ⇒ لا مدخل',
      );
      expect(
        find.byKey(const Key('mywork-inventory')),
        findsNothing,
        reason: 'المخطط بلا assets',
      );
    });
  });
}
