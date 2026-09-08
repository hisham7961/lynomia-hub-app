/// اختبارات RTL (§119) وواجهات الشاشات الحرجة (§120 §121) — التطبيق الكامل
/// بحاوية اختبار وناقل مبرمج: دخول، غلاف، بيت، قائمة وحدة، سجل، إشعارات،
/// ملاحة الرابط العميق، وشاشة التحديث الإلزامي (§122).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/features/shell/app_shell.dart';

import '../fakes/fakes.dart';

Map<String, dynamic> appConfigPayload({
  bool maintenance = false,
  bool updateRequired = false,
  bool force = false,
  String? storeAndroid,
}) => {
  'mobile_api_version': '1',
  'server_time': DateTime.now().toUtc().toIso8601String(),
  'timezone': 'Asia/Kuwait',
  'maintenance': maintenance,
  'maintenance_message': maintenance ? 'صيانة الليلة' : null,
  'lockdown': false,
  'login_available': !maintenance,
  'version_gate': {
    'ios': {'min': '', 'latest': ''},
    'android': {'min': updateRequired ? '9.0.0' : '', 'latest': ''},
    'force_update': force,
  },
  'update_required': updateRequired,
  'support_url': null,
  'store_urls': {'ios': null, 'android': storeAndroid},
};

void wireAuthenticatedRoutes(TestHarness h) {
  h.transport.onData('GET app-config', appConfigPayload());
  h.transport.onData('GET bootstrap', bootstrapPayload());
  h.transport.onData('GET schema', schemaPayload());
  h.transport.onData('GET home', {
    'my_work': {
      'count': 1,
      'items': [
        {
          'module': 'tasks',
          'id': 't1',
          'name': 'تجهيز العرض',
          'status': 'جارية',
          'due': '2026-09-10',
        },
      ],
    },
    'due': <dynamic>[],
    'approvals': {'count': 2},
    'attention': <dynamic>[],
    'recent': <dynamic>[],
    'projects': {'count': 0, 'items': <dynamic>[]},
    'notifications': {'unread': 2},
    'server_time': DateTime.now().toUtc().toIso8601String(),
  });
  h.transport.on(
    'GET tasks',
    (_) => okList([
      {'id': 't1', 'title': 'تجهيز العرض', 'status': 'جارية', 'version': 3},
      {'id': 't2', 'title': 'مراجعة العقد', 'status': 'جديدة', 'version': 1},
    ]),
  );
  h.transport.onData('GET tasks/t1', {
    'id': 't1',
    'title': 'تجهيز العرض',
    'details': 'تفاصيل المهمة',
    'estimate': '3.5',
    'due': '2026-09-10',
    'billable': true,
    'status': 'جارية',
    'tags': ['عاجل'],
    'link': 'https://example.com',
    'version': 3,
  });
  h.transport.onData('GET comments', {
    'module': 'tasks',
    'record': 't1',
    'comments': <dynamic>[],
  });
  h.transport.onData('GET tasks/t1/actions', {
    'module': 'tasks',
    'id': 't1',
    'status': 'جارية',
    'trashed': false,
    'version': 3,
    'actions': [
      {
        'action': 'status',
        'to': 'منجزة',
        'label': 'نقل الحالة إلى: منجزة',
        'requires_approval': false,
      },
    ],
  });
}

Future<TestHarness> pumpAuthenticatedApp(WidgetTester tester) async {
  final h = TestHarness.create();
  await h.seedSession();
  wireAuthenticatedRoutes(h);
  await tester.pumpWidget(
    LynomiaApp(container: h.container, listenAppLinks: false),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('الدخول: عربي RTL بعناصر دلالية (§119 §120)', (tester) async {
    final h = TestHarness.create();
    h.transport.onData('GET app-config', appConfigPayload());
    await tester.pumpWidget(
      LynomiaApp(container: h.container, listenAppLinks: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول إلى Lynomia'), findsOneWidget);
    final ctx = tester.element(find.text('تسجيل الدخول إلى Lynomia'));
    expect(
      Directionality.of(ctx),
      TextDirection.rtl,
      reason: 'الاتجاه من اللغة لا قسراً (§24)',
    );
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    // زر الدخول عنصر دلالي قابل للنقر لا أيقونة صماء (§120)
    expect(find.widgetWithText(FilledButton, 'تسجيل الدخول'), findsOneWidget);
    h.dispose();
  });

  testWidgets('الصيانة حالة صريحة لا «خطأ إنترنت» (§94)', (tester) async {
    final h = TestHarness.create();
    h.transport.onData('GET app-config', appConfigPayload(maintenance: true));
    await tester.pumpWidget(
      LynomiaApp(container: h.container, listenAppLinks: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('صيانة مجدولة'), findsOneWidget);
    expect(find.text('صيانة الليلة'), findsOneWidget);
    h.dispose();
  });

  testWidgets('التحديث الإلزامي يحجب، وبلا متجر رسالة صادقة (§46 §122)', (
    tester,
  ) async {
    final h = TestHarness.create();
    await h.seedSession();
    h.transport.onData(
      'GET app-config',
      appConfigPayload(updateRequired: true, force: true),
    );
    await tester.pumpWidget(
      LynomiaApp(container: h.container, listenAppLinks: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('تحديث مطلوب'), findsOneWidget);
    expect(
      find.textContaining('رابط المتجر غير مهيأ'),
      findsOneWidget,
      reason: 'NOT_CONFIGURED لا زر متجر مزيف (§144)',
    );
    h.dispose();
  });

  testWidgets('الغلاف المصادق: خمس وجهات وشارة غير المقروء (§16)', (
    tester,
  ) async {
    final h = await pumpAuthenticatedApp(tester);

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('مهامي'), findsWidgets);
    expect(find.text('المجالات'), findsWidgets);
    expect(find.text('البحث'), findsWidgets);
    expect(find.text('حسابي'), findsWidgets);

    final ctx = tester.element(find.byType(AppShell));
    expect(Directionality.of(ctx), TextDirection.rtl);

    // الرئيسية حية من GET home — عنصر عمل حقيقي لا بيانات مختلقة (§104)
    expect(find.text('تجهيز العرض'), findsOneWidget);
    h.dispose();
  });

  testWidgets('المجالات من شجرة IA الخادمية ⇒ قائمة الوحدة العامة (§49 §19)', (
    tester,
  ) async {
    final h = await pumpAuthenticatedApp(tester);

    await tester.tap(find.text('المجالات'));
    await tester.pumpAndSettle();
    expect(find.text('الكيانات والعلاقات'), findsOneWidget);

    await tester.tap(find.text('الكيانات والعلاقات'));
    await tester.pumpAndSettle();
    expect(find.text('الشركات والمشاريع'), findsOneWidget);

    await tester.tap(find.text('المهام'));
    await tester.pumpAndSettle();
    // قائمة الوحدة العامة حية من GET tasks
    expect(find.text('تجهيز العرض'), findsOneWidget);
    expect(find.text('مراجعة العقد'), findsOneWidget);
    h.dispose();
  });

  testWidgets(
    'نقر عنصر البيت يفتح شاشة السجل العامة بحقولها وإجراءاتها (§21)',
    (tester) async {
      final h = await pumpAuthenticatedApp(tester);

      await tester.tap(find.text('تجهيز العرض'));
      await tester.pumpAndSettle();

      expect(find.text('الحقول'), findsOneWidget);
      expect(find.text('الإجراءات'), findsOneWidget);
      expect(find.text('التعليقات'), findsOneWidget);
      expect(find.text('تفاصيل المهمة'), findsOneWidget);
      expect(find.text('جارية'), findsWidgets);
      h.dispose();
    },
  );

  testWidgets(
    'الإشعارات: قائمة وقراءة وملاحة بالوجهة القانونية (§51 §113 §121)',
    (tester) async {
      final h = await pumpAuthenticatedApp(tester);
      h.transport.onData('GET notifications', {
        'notifications': [
          {
            'id': 'n1',
            'kind': 'task',
            'text': 'أسندت إليك مهمة',
            'read': false,
            'target': {'module': 'tasks', 'id': 't1', 'action': 'show'},
            'created_at': '2026-09-08T10:00:00Z',
          },
        ],
        'unread': 1,
        'cursor': {'next': null, 'has_more': false, 'per': 25},
      });
      h.transport.onData('POST notifications/n1/read', {
        'id': 'n1',
        'read': true,
        'unread': 0,
        'target': {'module': 'tasks', 'id': 't1', 'action': 'show'},
      });

      await tester.tap(find.byTooltip('الإشعارات').first);
      await tester.pumpAndSettle();
      expect(find.text('أسندت إليك مهمة'), findsOneWidget);

      await tester.tap(find.text('أسندت إليك مهمة'));
      await tester.pumpAndSettle();
      // الوجهة القانونية قادت لشاشة السجل — لا اسم شاشة صلب (§51)
      expect(find.text('تفاصيل المهمة'), findsOneWidget);
      expect(h.transport.sent('POST notifications/n1/read'), hasLength(1));
      h.dispose();
    },
  );

  testWidgets('البحث: نتيجة حية بعد الكتابة والمهلة (§50 §112)', (
    tester,
  ) async {
    final h = await pumpAuthenticatedApp(tester);
    h.transport.onData('GET search', {
      'q': 'عرض',
      'results': [
        {
          'module': 'tasks',
          'id': 't1',
          'name': 'تجهيز العرض',
          'label': 'المهام',
        },
      ],
      'count': 1,
    });

    await tester.tap(find.text('البحث'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'عرض');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('المهام'), findsWidgets);
    expect(
      h.transport.sent('GET search'),
      hasLength(1),
      reason: 'مهلة إبطال واحدة — لا وابل طلبات',
    );
    h.dispose();
  });
}
