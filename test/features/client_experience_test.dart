/// تجربة العميل (§10 §12 §13 §15 §17) — القشرة تُختار من `account_type`
/// الخادمي، وقشرة العميل لا تعرض وجهة داخلية، والتفعيل على السكة العامة
/// بلا كلمة سر في أي صادر، وإدارة الأعضاء تحمل مفتاح idempotency وتُظهر
/// غرض التصعيد المسمى من 428.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';
import 'package:lynomia_hub_app/features/launch/bootstrap_repository.dart';
import 'package:lynomia_hub_app/features/portal/client_shell.dart';
import 'package:lynomia_hub_app/features/shell/app_shell.dart';

import '../fakes/fakes.dart';

/// لقطة bootstrap لحساب عميل كما يبثها الخادم (§10): نمط client، عضويات،
/// شجرة بوابة، ولا وجهة داخلية تُسلسل أصلاً.
Map<String, dynamic> clientBootstrapPayload() => {
  'user': {
    'id': 'u-9',
    'name': 'مندوبة العميل',
    'email': 'client@ext.local',
    'role': null,
    'is_owner': false,
    'account_type': 'client',
  },
  'context': {
    'companies': {
      'restricted': true,
      'active': null,
      'count': 0,
      'has_more': false,
      'items': <Map<String, dynamic>>[],
    },
    'clients': {
      'restricted': true,
      'active': null,
      'count': 1,
      'has_more': false,
      'items': [
        {'id': 'cl-1', 'name': 'عميل ألف'},
      ],
    },
  },
  'feature_flags': {'can_approve': false, 'is_client': true},
  'memberships': [
    {'client_id': 'cl-1', 'client_name': 'عميل ألف', 'role': 'owner'},
  ],
  'timezone': 'Asia/Kuwait',
  'versions': {'app': '2.447.0', 'mobile_api': '1', 'schema': 'abc123'},
  'unread_notifications': 1,
  'nav': {'g': <dynamic>[], 'items': <dynamic>[]},
  'ia': {
    'surfaces': <Map<String, dynamic>>[],
    'domains': [
      {
        'key': 'portal',
        'label': 'مساحتك',
        'icon': '🤝',
        'plane': 'client',
        'sections': [
          {
            'key': 'portal',
            'label': 'بوابة العميل',
            'destinations': [
              {
                'label': 'الرئيسية',
                'type': 'portal',
                'importance': 'primary',
                'mobile': 'suitable',
                'portal': 'home',
              },
              {
                'label': 'المشاريع',
                'type': 'portal',
                'importance': 'primary',
                'mobile': 'suitable',
                'portal': 'projects',
              },
            ],
          },
        ],
      },
    ],
  },
  'schema_version': 'abc123',
};

Map<String, dynamic> portalHomePayload() => {
  'mode': 'client',
  'clients': [
    {'id': 'cl-1', 'name': 'عميل ألف'},
  ],
  'engagements': [
    {'id': 'e-1', 'name': 'ارتباط ألف', 'status': 'نشط'},
  ],
  'projects': [
    {'id': 'p-1', 'name': 'مشروع ألف', 'status': 'قيد التنفيذ', 'progress': 40},
  ],
  'documents': [
    {'id': 'd-1', 'name': 'عرض ألف', 'cat': 'عروض'},
  ],
  'invoices': [
    {
      'id': 'i-1',
      'doc_no': 'INV-A1',
      'kind': 'فاتورة مبيعات',
      'total': '1500.500',
      'paid': '500',
      'currency': 'KWD',
      'state': 'مرسلة',
    },
  ],
  'conversations': [
    {'id': 'cv-1', 'kind': 'channel', 'title': 'غرفة مشروع ألف'},
  ],
  'notifications': {'unread': 1},
  'server_time': DateTime.now().toUtc().toIso8601String(),
};

Map<String, dynamic> _appConfig() => {
  'mobile_api_version': '1',
  'server_time': DateTime.now().toUtc().toIso8601String(),
  'timezone': 'Asia/Kuwait',
  'maintenance': false,
  'maintenance_message': null,
  'lockdown': false,
  'login_available': true,
  'version_gate': {
    'ios': {'min': '', 'latest': ''},
    'android': {'min': '', 'latest': ''},
    'force_update': false,
  },
  'update_required': false,
  'support_url': null,
  'store_urls': {'ios': null, 'android': null},
};

Future<TestHarness> pumpClientApp(WidgetTester tester) async {
  final h = TestHarness.create();
  await h.seedSession();
  h.transport.onData('GET app-config', _appConfig());
  h.transport.onData('GET bootstrap', clientBootstrapPayload());
  h.transport.onData('GET portal/home', portalHomePayload());
  await tester.pumpWidget(
    LynomiaApp(container: h.container, listenAppLinks: false),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('اختيار القشرة من نمط الحساب الخادمي (§10 §12)', () {
    testWidgets('حساب العميل يقلع على بيت البوابة لا اللوحة الداخلية', (
      tester,
    ) async {
      final h = pumpClientApp(tester);
      final harness = await h;

      // قشرة العميل ظاهرة، والداخلية غائبة تماماً.
      expect(find.byType(ClientShell), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      // بيت البوابة يعرض عالم العميل الذي بثه الخادم.
      expect(find.text('عميل ألف'), findsWidgets);
      expect(find.text('مشروع ألف'), findsOneWidget);
      // لا وجهة داخلية في الشريط السفلي (مهامي/المجالات لا تظهر).
      expect(find.text('مهامي'), findsNothing);
      expect(find.text('المجالات'), findsNothing);
      // البيت طلب `portal/home` لا `home` الداخلية.
      expect(harness.transport.sent('GET portal/home'), isNotEmpty);
      expect(harness.transport.sent('GET home'), isEmpty);
      harness.dispose();
    });

    testWidgets(
      'مسار داخلي يُعاد توجيهه لبوابة العميل — عرضاً فوق حرس الخادم',
      (tester) async {
        final harness = await pumpClientApp(tester);

        // محاولة ملاحة يدوية لمسار داخلي (نظير رابط قديم).
        final ctx = tester.element(find.byType(ClientShell));
        GoRouter.of(ctx).go('/mywork');
        await tester.pumpAndSettle();

        expect(find.byType(ClientShell), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
        // لم يُطلب أي مورد داخلي.
        expect(harness.transport.sent('GET approvals'), isEmpty);
        harness.dispose();
      },
    );

    testWidgets('الحساب الداخلي لا يبلغ مسارات البوابة', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET app-config', _appConfig());
      h.transport.onData('GET bootstrap', bootstrapPayload());
      h.transport.onData('GET schema', schemaPayload());
      h.transport.onData('GET home', {
        'my_work': {'count': 0, 'items': <dynamic>[]},
        'due': <dynamic>[],
        'approvals': {'count': 0},
        'attention': <dynamic>[],
        'recent': <dynamic>[],
        'projects': {'count': 0, 'items': <dynamic>[]},
        'notifications': {'unread': 0},
        'server_time': DateTime.now().toUtc().toIso8601String(),
      });
      await tester.pumpWidget(
        LynomiaApp(container: h.container, listenAppLinks: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      final ctx = tester.element(find.byType(AppShell));
      GoRouter.of(ctx).go('/portal');
      await tester.pumpAndSettle();

      expect(find.byType(ClientShell), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
      expect(h.transport.sent('GET portal/home'), isEmpty);
      h.dispose();
    });
  });

  group('نماذج العقد العميلي', () {
    test('bootstrap يفكك نمط الحساب والعضويات', () {
      final b = Bootstrap.fromJson(clientBootstrapPayload());
      expect(b.user.accountType, 'client');
      expect(b.user.isClient, isTrue);
      expect(b.memberships, hasLength(1));
      expect(b.memberships.first.clientName, 'عميل ألف');
      expect(b.memberships.first.role, 'owner');
      expect(b.flag('is_client'), isTrue);
    });

    test('bootstrap الداخلي: النمط internal افتراضاً وعضويات فارغة', () {
      final b = Bootstrap.fromJson(bootstrapPayload());
      expect(b.user.isClient, isFalse);
      expect(b.memberships, isEmpty);
    });
  });

  group('تفعيل الحساب (§13) — السكة العامة', () {
    test('الفحص عام بلا Authorization ويعيد الحالة والبريد المقنع', () async {
      final h = TestHarness.create();
      h.transport.onData('GET activation/tok1', {
        'status': 'pending',
        'email_masked': 'n***@d***.com',
      });

      final s = await h.container.activation.check('tok1');
      expect(s.pending, isTrue);
      expect(s.emailMasked, 'n***@d***.com');
      final req = h.transport.sent('GET activation/tok1').single;
      expect(
        req.headers.containsKey('Authorization'),
        isFalse,
        reason: 'نقطة عامة تسبق الدخول — لا رمز يُبث (§13)',
      );
      h.dispose();
    });

    test('الإتمام يرسل الرمز والكلمة وتأكيدها ويعيد البريد الكامل', () async {
      final h = TestHarness.create();
      h.transport.onData('POST activation/tok1/complete', {
        'activated': true,
        'email': 'newbie@ext.local',
      });

      final r = await h.container.activation.complete(
        token: 'tok1',
        otp: '123456',
        password: 'Www!55ord#2026x',
      );
      expect(r.activated, isTrue);
      expect(r.email, 'newbie@ext.local');
      final body = h.transport
          .sent('POST activation/tok1/complete')
          .single
          .jsonBody;
      expect(body['otp'], '123456');
      expect(body['password_confirmation'], body['password']);
      h.dispose();
    });

    test('الانتهاء الصادق يصل كما هو (details.reason=expired)', () async {
      final h = TestHarness.create();
      h.transport.on(
        'POST activation/tok1/complete',
        (_) => apiError(
          'VALIDATION_FAILED',
          422,
          message: 'انتهت صلاحية التفعيل',
          details: {'reason': 'expired'},
        ),
      );

      try {
        await h.container.activation.complete(
          token: 'tok1',
          otp: '123456',
          password: 'Www!55ord#2026x',
        );
        fail('كان يجب أن يرمي ApiException');
      } on ApiException catch (e) {
        expect(e.details['reason'], 'expired');
      }
      h.dispose();
    });
  });

  group('إدارة أعضاء العميل (§15)', () {
    test('الدعوة تحمل مفتاح Idempotency وتفكك بطاقة العضو الآمنة', () async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('POST clients/cl-1/members', {
        'member': {
          'id': 'm-1',
          'role': 'finance',
          'status': 'invited',
          'invited_at': '2026-09-08T10:00:00+03:00',
          'activated_at': null,
          'user': {
            'id': 'u-77',
            'name': 'عضو جديد',
            'email': 'member@ext.local',
            'activated': false,
          },
        },
      });

      final m = await h.container.clientMembers.invite(
        clientId: 'cl-1',
        email: 'member@ext.local',
        name: 'عضو جديد',
        role: 'finance',
        idempotencyKey: 'op-inv-1',
      );
      expect(m.status, 'invited');
      expect(m.activated, isFalse, reason: 'حضور التفعيل فقط — لا أثر كلمة سر');
      final req = h.transport.sent('POST clients/cl-1/members').single;
      expect(req.headers['Idempotency-Key'], 'op-inv-1');
      h.dispose();
    });

    test('428 يصل بغرض التصعيد المسمى — منحة مربوطة لا عامة', () async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.on(
        'DELETE clients/cl-1/members/m-1',
        (_) => apiError(
          'STEP_UP_REQUIRED',
          428,
          message: 'تصعيد مطلوب',
          details: {
            'purpose': 'action:clients:member_revoke',
            'method': 'password',
          },
        ),
      );

      try {
        await h.container.clientMembers.revoke(
          clientId: 'cl-1',
          membershipId: 'm-1',
        );
        fail('كان يجب أن يرمي ApiException');
      } on ApiException catch (e) {
        expect(e.code, ApiErrorCode.stepUpRequired);
        expect(e.details['purpose'], 'action:clients:member_revoke');
      }
      h.dispose();
    });
  });

  group('قارئ البوابة (§17 §18)', () {
    test('غرفة المحادثة تفكك الرسائل بأسمائها ومِلكيتها', () async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET portal/conversations/cv-1', {
        'conversation': {
          'id': 'cv-1',
          'kind': 'channel',
          'title': 'غرفة مشروع ألف',
          'audience': 'client',
        },
        'messages': [
          {
            'id': '1',
            'body': 'مرحباً بالعميل',
            'user': {'id': 'u-2', 'name': 'موظفة'},
            'mine': false,
            'created_at': '2026-09-08T10:00:00+03:00',
          },
        ],
      });

      final t = await h.container.portal.conversation('cv-1');
      expect(t.conversation.title, 'غرفة مشروع ألف');
      expect(t.messages.single.body, 'مرحباً بالعميل');
      expect(t.messages.single.mine, isFalse);
      h.dispose();
    });

    test('الفاتورة مبالغها نصوص عشرية كما بثها الخادم — لا double', () async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET portal/invoices/i-1', {
        'invoice': {
          'id': 'i-1',
          'doc_no': 'INV-A1',
          'kind': 'فاتورة مبيعات',
          'total': '1500.500',
          'paid': '500',
          'currency': 'KWD',
          'state': 'مرسلة',
        },
      });

      final inv = await h.container.portal.invoice('i-1');
      expect(inv.total, '1500.500');
      expect(inv.paid, '500');
      h.dispose();
    });
  });
}
