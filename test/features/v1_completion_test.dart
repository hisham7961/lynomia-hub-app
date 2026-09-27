/// v1.0.0 (خلفية v2.619) — إغلاق الفجوات الأخيرة: قراءات الأهلية بلا أثر
/// (قرار الإجازة، قدرات العهدة، خيارات الدفعة)، وإضافة مشاركين إلى مجموعة
/// (مجموعةٌ جديدة)، وقسم امتثال اليوم في مراجعة التقارير. عقد المستودع ثم
/// الواجهات بحالاتٍ صادقة (لا زرّ لمن لا فعل له).
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/features/custody/custody_repository.dart';
import 'package:lynomia_hub_app/features/custody/custody_screens.dart';
import 'package:lynomia_hub_app/features/finance/finance_actions_card.dart';
import 'package:lynomia_hub_app/features/finance/finance_repository.dart';
import 'package:lynomia_hub_app/features/leaves/leave_decision_card.dart';
import 'package:lynomia_hub_app/features/leaves/leave_repository.dart';
import 'package:lynomia_hub_app/features/messages/channels_screens.dart';
import 'package:lynomia_hub_app/features/my_work/team_reports_repository.dart';
import 'package:lynomia_hub_app/features/my_work/team_reports_screen.dart';

import '../fakes/fakes.dart';
import '../fakes/screen_harness.dart';

Map<String, dynamic> _decision({
  bool canDecide = true,
  String? reason,
  bool approve = true,
  bool reject = true,
  String? approveStatus = 'موافقة المدير',
}) => {
  'id': 'l1',
  'status': 'بانتظار',
  'can_decide': canDecide,
  'reason': reason,
  'can_approve': approve,
  'can_reject': reject,
  'approve_status': approveStatus,
  'reject_reason_required': true,
};

Map<String, dynamic> _abilities({
  bool handover = true,
  bool recover = true,
  String? reason,
}) => {
  'id': 'as1',
  'can_handover': handover,
  'can_recover': recover,
  'holder_id': recover ? 'u-9' : null,
  'reason': reason,
};

Map<String, dynamic> _payOptions({
  bool canPay = true,
  String? reason,
  String? remaining = '87.500',
}) => {
  'id': 'd1',
  'can_pay': canPay,
  'reason': reason,
  'remaining': remaining,
  'currency': 'KWD',
  'banks': [
    {'id': 'b1', 'name': 'بنك الخليج', 'currency': 'KWD'},
    {'id': 'b2', 'name': 'بنك الكويت الوطني', 'currency': null},
  ],
  'default_bank_id': 'b2',
  'step_up_purpose': 'action:fin:pay',
};

Map<String, dynamic> _compliance(
  String id,
  String code, {
  bool pending = false,
  String? timeIn,
}) => {
  'employee_id': id,
  'name': 'موظف $id',
  'dept': 'التشغيل',
  'compliance': {
    'date': '2026-09-27',
    'verdict_pending': pending,
    'late_arrival': false,
    'time_in': timeIn,
    'time_out': null,
    'on_leave': false,
    'report_submitted': code == 'compliant',
    'report_count': code == 'compliant' ? 1 : 0,
    'compliance': code,
    'effective_status': 'present',
    'labels': {'compliance': 'نصّ خادمي QWXZ'},
  },
};

Map<String, dynamic> _daily({List<Map<String, dynamic>>? compliance}) => {
  'date': '2026-09-27',
  'scope': 'team',
  'status': 'all',
  'summary': {'total': 0, 'pending': 0, 'accepted': 0, 'needs_revision': 0},
  'entries': <Object>[],
  'truncated': false,
  'compliance': compliance,
};

Map<String, dynamic> _members() => {
  'my_role': 'member',
  'can_post': true,
  'can_manage': false,
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
};

Map<String, dynamic> _threads() => {
  'threads': [
    for (final (id, name) in [('u-2', 'سارة'), ('u-3', 'خالد'), ('u-4', 'منى')])
      {
        'user': {'id': id, 'name': name},
        'unread': 0,
        'last': {'id': 'm-$id', 'mine': false, 'excerpt': 'أهلاً'},
      },
  ],
  'unread_total': 0,
};

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
  });

  tearDown(() => h.dispose());

  group('المستودعات (العقد)', () {
    test('قرار الإجازة: GET leaves/{id}/decision بلا أثر', () async {
      h.transport.onData(
        'GET leaves/l%2F1/decision',
        _decision(canDecide: false, reason: 'self_request', approve: false),
      );
      final a = await h.container.leaves.decision('l/1');
      expect(a.canDecide, isFalse);
      expect(a.reason, LeaveDenyReason.selfRequest);
      expect(a.canApprove, isFalse);
      expect(a.canReject, isTrue);
      expect(a.approveStatus, 'موافقة المدير');
      expect(a.rejectReasonRequired, isTrue);
      final sent = h.transport.sent('GET leaves/l%2F1/decision').single;
      expect(sent.headers['Idempotency-Key'], isNull, reason: 'قراءةٌ لا فعل');
    });

    test('قدرات العهدة: GET custody/{id}/abilities', () async {
      h.transport.onData(
        'GET custody/as1/abilities',
        _abilities(recover: false, reason: 'not_held'),
      );
      final a = await h.container.custody.abilities('as1');
      expect(a.canHandover, isTrue);
      expect(a.canRecover, isFalse);
      expect(a.holderId, isNull);
      expect(a.reason, CustodyDenyReason.notHeld);
    });

    test(
      'خيارات الدفعة: عشري لا double، والبنك الافتراضي من المعروض فقط',
      () async {
        h.transport.onData('GET fin/d1/pay-options', _payOptions());
        final o = await h.container.finance.payOptions('d1');
        expect(o.canPay, isTrue);
        expect(o.remaining, Decimal.parse('87.5'));
        expect(o.currency, 'KWD');
        expect(o.banks.map((b) => b.id), ['b1', 'b2']);
        expect(o.banks.last.currency, isNull);
        expect(o.defaultBankId, 'b2');
        expect(o.stepUpPurpose, 'action:fin:pay');

        // بنكٌ افتراضي خارج المعروض لا يُعتمد، والمتبقي المحجوب null صادق.
        h.transport.onData('GET fin/d1/pay-options', {
          ..._payOptions(canPay: false, reason: 'settled', remaining: null),
          'default_bank_id': 'b-hidden',
        });
        final o2 = await h.container.finance.payOptions('d1');
        expect(o2.defaultBankId, isNull);
        expect(o2.remaining, isNull);
        expect(o2.reason, PayDenyReason.settled);
      },
    );

    test('الدفعة ترسل bankId حين يُختار بنك، ولا ترسله بدونه', () async {
      h.transport.onData('POST fin/d1/pay', {
        'amount': '5.000',
        'document': {'id': 'd1'},
      });
      await h.container.finance.pay(
        'd1',
        amount: Decimal.parse('5'),
        bankId: 'b1',
      );
      await h.container.finance.pay('d1', amount: Decimal.parse('5'));
      final sent = h.transport.sent('POST fin/d1/pay');
      expect(sent.first.jsonBody, {'amount': '5', 'bankId': 'b1'});
      expect(sent.last.jsonBody, {'amount': '5'});
    });

    test(
      'إضافة مشاركين: POST groups/{id}/participants ⇒ مجموعةٌ جديدة',
      () async {
        h.transport.on(
          'POST groups/g1/participants',
          (_) => okData({
            'conversation': {'id': 'g2', 'title': 'الفريق', 'kind': 'group'},
            'forked_from': 'g1',
            ..._members(),
          }, status: 201),
        );
        h.transport.failOnce.add('POST groups/g1/participants');
        final r = await h.container.collab.forkGroup('g1', ['u-3']);
        expect(r.conversation.id, 'g2');
        expect(r.forkedFrom, 'g1');
        final sent = h.transport.sent('POST groups/g1/participants');
        expect(sent, hasLength(2), reason: 'مفتاح Idempotency ⇒ إعادة آمنة');
        expect(
          sent[0].headers['Idempotency-Key'],
          sent[1].headers['Idempotency-Key'],
        );
        expect(sent.last.jsonBody, {
          'participants': ['u-3'],
        });
      },
    );

    test('تقارير الفريق: قسم الامتثال حين يُبثّ، وnull لغير hr:v', () async {
      h.transport.onData(
        'GET reports/daily',
        _daily(
          compliance: [
            _compliance('e1', 'compliant', timeIn: '08:01'),
            _compliance('e2', 'missing'),
          ],
        ),
      );
      final d = await h.container.teamReports.daily();
      expect(d.compliance, hasLength(2));
      expect(d.compliance!.first.compliance, ComplianceCode.compliant);
      expect(d.compliance!.first.timeIn, '08:01');
      expect(d.compliance!.first.reportCount, 1);
      expect(d.compliance!.last.name, 'موظف e2');

      h.transport.onData('GET reports/daily', _daily());
      expect((await h.container.teamReports.daily()).compliance, isNull);
    });
  });

  group('الواجهات', () {
    testWidgets(
      'قرار الإجازة: الأزرار بحسب can_approve/can_reject وحالة الموافقة',
      (tester) async {
        h.transport.onData(
          'GET leaves/l1/decision',
          _decision(approve: false, approveStatus: null),
        );
        await pumpScreen(
          tester,
          h,
          Scaffold(
            body: LeaveDecisionCard(leaveId: 'l1', onDecided: () {}),
          ),
        );
        expect(find.byKey(const Key('leave-decision')), findsOneWidget);
        expect(find.byKey(const Key('leave-approve')), findsNothing);
        expect(find.byKey(const Key('leave-reject')), findsOneWidget);
        expect(find.byKey(const Key('leave-approve-status')), findsNothing);
      },
    );

    testWidgets('قرار الإجازة: المدير يرى ما تصير إليه الحالة', (tester) async {
      h.transport.onData('GET leaves/l1/decision', _decision());
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: LeaveDecisionCard(leaveId: 'l1', onDecided: () {}),
        ),
      );
      expect(find.byKey(const Key('leave-approve')), findsOneWidget);
      expect(find.textContaining('موافقة المدير'), findsOneWidget);
    });

    testWidgets('قرار الإجازة: غير المقرِّر يرى سبب الخادم من ARB بلا أزرار', (
      tester,
    ) async {
      h.transport.onData(
        'GET leaves/l1/decision',
        _decision(canDecide: false, reason: 'already_decided'),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: LeaveDecisionCard(leaveId: 'l1', onDecided: () {}),
        ),
      );
      expect(find.byKey(const Key('leave-decision')), findsNothing);
      expect(find.byKey(const Key('leave-decision-note')), findsOneWidget);
      expect(find.text('هذا الطلب محسومٌ مسبقاً'), findsOneWidget);
    });

    testWidgets('قرار الإجازة: 403 ⇒ لا بطاقة؛ عطل شبكة ⇒ إعادة المحاولة', (
      tester,
    ) async {
      h.transport.on(
        'GET leaves/l1/decision',
        (_) => apiError('FORBIDDEN', 403),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: LeaveDecisionCard(leaveId: 'l1', onDecided: () {}),
        ),
      );
      expect(find.byKey(const Key('leave-decision')), findsNothing);
      expect(find.byKey(const Key('eligibility-retry')), findsNothing);

      h.transport.on(
        'GET leaves/l2/decision',
        (_) => apiError('INTERNAL_ERROR', 500),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: LeaveDecisionCard(leaveId: 'l2', onDecided: () {}),
        ),
      );
      expect(find.byKey(const Key('eligibility-retry')), findsOneWidget);
      h.transport.onData('GET leaves/l2/decision', _decision());
      await tester.tap(find.byKey(const Key('eligibility-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('leave-approve')), findsOneWidget);
    });

    testWidgets('العهدة: الأزرار من القدرات لا من can.e (حامل custodyAssign)', (
      tester,
    ) async {
      h.transport.onData('GET custody/as1/abilities', _abilities());
      h.transport.onData('POST custody/as1/recover', {
        'movement': {'id': 'mv1', 'asset_id': 'as1', 'action': 'recover'},
      });
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: CustodyActionsCard(
            assetId: 'as1',
            canPickUsers: true,
            onChanged: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('custody-handover')), findsOneWidget);
      expect(find.byKey(const Key('custody-recover')), findsOneWidget);
      await tester.tap(find.byKey(const Key('custody-recover')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('POST custody/as1/recover'), hasLength(1));
      expect(
        h.transport.sent('GET custody/as1/abilities'),
        hasLength(2),
        reason: 'القدرات تُعاد قراءتها بعد الفعل',
      );
    });

    testWidgets('العهدة: ليست بيد أحد ⇒ لا استرداد؛ ولا منتقي ⇒ ملاحظة صادقة', (
      tester,
    ) async {
      h.transport.onData(
        'GET custody/as1/abilities',
        _abilities(recover: false, reason: 'not_held'),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: CustodyActionsCard(
            assetId: 'as1',
            canPickUsers: false,
            onChanged: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('custody-actions')), findsNothing);
      expect(find.byKey(const Key('custody-note')), findsOneWidget);
    });

    testWidgets('العهدة: not_permitted ⇒ لا بطاقة ولا ملاحظة', (tester) async {
      h.transport.onData(
        'GET custody/as1/abilities',
        _abilities(handover: false, recover: false, reason: 'not_permitted'),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: CustodyActionsCard(
            assetId: 'as1',
            canPickUsers: true,
            onChanged: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('custody-actions')), findsNothing);
      expect(find.byKey(const Key('custody-note')), findsNothing);
    });

    testWidgets('الدفعة: المتبقي بعملته، والبنك الافتراضي مختار ويُرسَل', (
      tester,
    ) async {
      h.transport.onData('GET fin/d1/pay-options', _payOptions());
      h.transport.onData('POST fin/d1/pay', {
        'amount': '10.000',
        'document': {'id': 'd1', 'currency': 'KWD', 'remaining': '77.500'},
      });
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
      expect(find.byKey(const Key('fin-remaining')), findsOneWidget);
      expect(find.text('المتبقي: 87.5 KWD'), findsOneWidget);
      await tester.tap(find.byKey(const Key('fin-pay')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pay-bank')), findsOneWidget);
      expect(find.text('بنك الكويت الوطني'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pay-amount')), '10');
      await tester.tap(find.byKey(const Key('pay-submit')));
      await tester.pumpAndSettle();
      final body = h.transport.sent('POST fin/d1/pay').single.jsonBody;
      expect(body['amount'], '10');
      expect(body['bankId'], 'b2');
    });

    testWidgets('الدفعة: اختيار «بلا بنك» لا يرسل bankId', (tester) async {
      h.transport.onData('GET fin/d1/pay-options', _payOptions());
      h.transport.onData('POST fin/d1/pay', {
        'amount': '1.000',
        'document': {'id': 'd1'},
      });
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
      await tester.tap(find.byKey(const Key('pay-bank')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بلا بنك').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('pay-amount')), '1');
      await tester.tap(find.byKey(const Key('pay-submit')));
      await tester.pumpAndSettle();
      final body = h.transport.sent('POST fin/d1/pay').single.jsonBody;
      expect(body.containsKey('bankId'), isFalse);
    });

    testWidgets('الدفعة: مسدَّد ⇒ لا زرّ، وسبب الخادم نصّاً', (tester) async {
      h.transport.onData(
        'GET fin/d1/pay-options',
        _payOptions(canPay: false, reason: 'settled', remaining: '0.000'),
      );
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
      expect(find.byKey(const Key('fin-pay')), findsNothing);
      expect(find.byKey(const Key('fin-pay-note')), findsOneWidget);
      expect(find.textContaining('مسدَّد بالكامل'), findsOneWidget);
    });

    testWidgets('المجموعة: زرّ إضافة مشاركين يفتح شاشة التوسيع', (
      tester,
    ) async {
      h.transport.onData('GET conversations/g1/members', _members());
      await pumpScreen(
        tester,
        h,
        const ConversationMembersScreen(conversationId: 'g1', kind: 'group'),
      );
      expect(find.byKey(const Key('member-add')), findsNothing);
      await tester.tap(find.byKey(const Key('group-add-participants')));
      await tester.pumpAndSettle();
      expect(find.text('NAV:/conversations/g1/expand'), findsOneWidget);
    });

    testWidgets('التوسيع: المرشّحون من جهاتي عدا الأعضاء، ثم مجموعةٌ جديدة', (
      tester,
    ) async {
      h.transport.onData('GET conversations/g1/members', _members());
      h.transport.onData('GET dm/threads', _threads());
      h.transport.on(
        'POST groups/g1/participants',
        (_) => okData({
          'conversation': {'id': 'g2', 'title': 'الفريق', 'kind': 'group'},
          'forked_from': 'g1',
          ..._members(),
        }, status: 201),
      );
      await pumpScreen(tester, h, const NewGroupScreen(forkFrom: 'g1'));
      expect(find.byKey(const Key('group-fork-explain')), findsOneWidget);
      expect(find.byKey(const Key('group-pick-u-2')), findsNothing);
      expect(find.byKey(const Key('group-pick-u-3')), findsOneWidget);
      await tester.tap(find.byKey(const Key('group-pick-u-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('group-create')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('POST groups/g1/participants').single.jsonBody, {
        'participants': ['u-4'],
      });
      expect(h.transport.sent('POST groups'), isEmpty);
      expect(find.textContaining('NAV:/conversations/g2'), findsOneWidget);
    });

    testWidgets('مراجعة التقارير: قسم الامتثال بالرموز لا بنصّ الخادم', (
      tester,
    ) async {
      h.transport.onData(
        'GET reports/daily',
        _daily(
          compliance: [
            _compliance('e1', 'compliant', timeIn: '08:01'),
            _compliance('e2', 'missing'),
            _compliance('e3', 'missing', pending: true),
          ],
        ),
      );
      await pumpScreen(tester, h, const TeamReportsScreen());
      expect(find.byKey(const Key('compliance-section')), findsOneWidget);
      expect(find.text('امتثال اليوم (3)'), findsOneWidget);
      expect(find.text('مقدَّم 1 · بانتظار 1 · غير مقدَّم 1'), findsOneWidget);
      await tester.tap(find.text('امتثال اليوم (3)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compliance-e1')), findsOneWidget);
      expect(find.textContaining('دخول 08:01'), findsOneWidget);
      expect(find.text('لم يحن الحكم بعد'), findsOneWidget);
      expect(find.textContaining('QWXZ'), findsNothing);
    });

    testWidgets('مراجعة التقارير: بلا امتثال (غير hr:v) لا قسم', (
      tester,
    ) async {
      h.transport.onData('GET reports/daily', _daily());
      await pumpScreen(tester, h, const TeamReportsScreen());
      expect(find.byKey(const Key('compliance-section')), findsNothing);
    });
  });
}
