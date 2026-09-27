/// الدفع على التطبيق الكامل (المرحلة ٢.٣): الجاهزية ⇒ تسجيل الرمز، ورسالة
/// المقدّمة ⇒ شريطٌ داخلي بزر «فتح» يوصل إلى السجل، والتجريبي بلا زر ولا ملاحة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/app/app.dart';
import 'package:lynomia_hub_app/core/push/fcm_push_provider.dart';
import 'package:lynomia_hub_app/core/push/push_message.dart';
import 'package:lynomia_hub_app/features/records/record_screen.dart';

import '../fakes/fakes.dart';
import 'rtl_app_test.dart' show wireAuthenticatedRoutes;

void main() {
  Future<(TestHarness, FakeMessagingAdapter)> pump(WidgetTester tester) async {
    final adapter = FakeMessagingAdapter(token: 'fcm-w1');
    final h = TestHarness.create(pushProvider: FcmPushProvider(adapter));
    await h.seedSession();
    wireAuthenticatedRoutes(h);
    h.transport.onData('POST push/register', {'registered': true});
    h.transport.onData('GET notifications/unread-count', {'unread': 2});
    await tester.pumpWidget(
      LynomiaApp(container: h.container, listenAppLinks: false),
    );
    await tester.pumpAndSettle();
    return (h, adapter);
  }

  testWidgets('المقدّمة ⇒ شريط «فتح» ⇒ السجل، والشارة من الحمولة', (
    tester,
  ) async {
    final (h, adapter) = await pump(tester);
    expect(
      h.transport.sent('POST push/register').single.jsonBody['token'],
      'fcm-w1',
    );

    adapter.foreground.add(
      const PushMessage(
        title: 'مهمة مُسندة إليك',
        body: 'افتح التطبيق للتفاصيل',
        data: {
          'notification_id': 'n-1',
          'unread': '5',
          'module': 'tasks',
          'id': 't1',
          'action': 'show',
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('مهمة مُسندة إليك'), findsOneWidget);
    expect(h.container.account.unreadNotifications, 5);

    await tester.pumpAndSettle();
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordScreen), findsOneWidget);
    h.dispose();
  });

  testWidgets('التجريبي ⇒ شريطٌ بلا زر ولا ملاحة', (tester) async {
    final (h, adapter) = await pump(tester);
    adapter.opened.add(const PushMessage(data: {'category': 'test'}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('وصل إشعارٌ تجريبي من مركز منصة الجوال'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'فتح'), findsNothing);
    expect(find.byType(RecordScreen), findsNothing);
    // لا يُترك مؤقّت الشريط معلّقاً.
    await tester.pump(const Duration(seconds: 5));
    h.dispose();
  });
}
