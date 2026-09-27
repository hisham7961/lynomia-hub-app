/// اختبارات واجهة الشاشات التي كانت بلا اختبار (المرحلة ١.٩): الاعتمادات،
/// الماسح (بعارضٍ مزيّف بدل الكاميرا)، التتبّع (بمصدر موقعٍ مزيّف)، لوحة المرفقات
/// (بمنتقٍ مزيّف)، الأعضاء، تفاصيل البوابة، نموذج السجل، الجلسات، التشخيص.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/features/approvals/approvals_screen.dart';
import 'package:lynomia_hub_app/features/files/attachments_panel.dart';
import 'package:lynomia_hub_app/features/members/client_members_screen.dart';
import 'package:lynomia_hub_app/features/modules/module_repository.dart';
import 'package:lynomia_hub_app/features/modules/module_schema.dart';
import 'package:lynomia_hub_app/features/portal/portal_screens.dart';
import 'package:lynomia_hub_app/features/profile/diagnostics_screen.dart';
import 'package:lynomia_hub_app/features/profile/sessions_screen.dart';
import 'package:lynomia_hub_app/features/records/record_form_screen.dart';
import 'package:lynomia_hub_app/features/scanner/scanner_screen.dart';
import 'package:lynomia_hub_app/features/tracking/location_source.dart';
import 'package:lynomia_hub_app/features/tracking/tracking_screen.dart';

import '../fakes/fakes.dart';
import '../fakes/screen_harness.dart';

/// مصدر موقع مزيّف: إذنٌ مبرمج وبثٌّ يتحكم به الاختبار.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({this.granted = true});

  final bool granted;
  final controller = StreamController<LocationFix>();
  int permissionAsks = 0;

  @override
  Future<bool> ensurePermission() async {
    permissionAsks++;
    return granted;
  }

  @override
  Stream<LocationFix> positions() => controller.stream;
}

/// بايتات PNG صالحة ١×١ — تُعرض من الذاكرة.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Map<String, dynamic> _approval({bool canDecide = true}) => {
  'id': 'a1',
  'title': 'تعديل عقد المورد',
  'type': 'تعديل',
  'status': 'pending',
  'op': 'e',
  'amount': '1250.500',
  'currency': 'KWD',
  'target': {'module': 'tasks', 'id': 't1'},
  'can_decide': canDecide,
};

void main() {
  group('الاعتمادات', () {
    testWidgets('الطابور ⇒ التفصيل ⇒ اعتماد بمفتاح idempotency', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.on('GET approvals', (_) => okList([_approval()]));
      h.transport.onData('GET approvals/a1', {'approval': _approval()});
      h.transport.onData('POST approvals/a1/approve', {
        'code': 'approved',
        'message': 'اعتُمد',
        'approval': {'id': 'a1', 'status': 'approved'},
      });
      await pumpScreen(
        tester,
        h,
        const ApprovalsScreen(),
        extraRoutes: [
          GoRoute(
            path: '/approvals/:id',
            builder: (c, s) =>
                ApprovalDetailScreen(id: s.pathParameters['id']!),
          ),
        ],
      );

      expect(find.text('تعديل عقد المورد'), findsOneWidget);
      // المبلغ عرضٌ عشري من نص الخادم (Decimal) لا double.
      expect(find.textContaining('1250.5 KWD'), findsOneWidget);
      await tester.tap(find.text('تعديل عقد المورد'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('اعتماد'));
      await tester.pumpAndSettle();
      final req = h.transport.sent('POST approvals/a1/approve').single;
      expect(req.headers['Idempotency-Key'], isNotEmpty);
      expect(find.text('قرارك سُجل'), findsOneWidget);
      h.dispose();
    });

    testWidgets('الرفض يطلب سبباً يُرسل في الجسم؛ والتقادم رسالة صريحة', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET approvals/a1', {'approval': _approval()});
      h.transport.on(
        'POST approvals/a1/reject',
        (_) => apiError('VERSION_CONFLICT', 409),
      );
      await pumpScreen(tester, h, const ApprovalDetailScreen(id: 'a1'));

      await tester.tap(find.widgetWithText(OutlinedButton, 'رفض'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'المبلغ غير مبرر');
      await tester.tap(find.widgetWithText(FilledButton, 'رفض'));
      await tester.pumpAndSettle();

      final req = h.transport.sent('POST approvals/a1/reject').single;
      expect(req.jsonBody['note'], 'المبلغ غير مبرر');
      expect(find.textContaining('تقادم'), findsOneWidget);
      expect(h.transport.sent('GET approvals/a1'), hasLength(2)); // إعادة تحميل
      h.dispose();
    });

    testWidgets('بلا can_decide لا أزرار حسم (عرضٌ من الخادم)', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET approvals/a1', {
        'approval': _approval(canDecide: false),
      });
      await pumpScreen(tester, h, const ApprovalDetailScreen(id: 'a1'));
      expect(find.text('اعتماد'), findsNothing);
      expect(find.text('رفض'), findsNothing);
      h.dispose();
    });
  });

  group('الماسح (عارضٌ مزيّف بدل الكاميرا)', () {
    Widget fakeScanView(BuildContext context, void Function(String) onCode) =>
        Column(
          children: [
            TextButton(
              onPressed: () => onCode('SN-001'),
              child: const Text('SCAN-OK'),
            ),
            TextButton(
              onPressed: () => onCode('SN-404'),
              child: const Text('SCAN-MISS'),
            ),
          ],
        );

    testWidgets('رمز يحلّه الخادم ⇒ ملاحة لسجل الكيان المخوّل', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET identity/resolve/SN-001', {
        'module': 'assets',
        'id': 'as-1',
      });
      await pumpScreen(
        tester,
        h,
        ScannerScreen(scanView: fakeScanView),
        extraRoutes: [
          GoRoute(
            path: '/r/:module/:id',
            builder: (c, s) => Text(
              'RECORD:${s.pathParameters['module']}/${s.pathParameters['id']}',
            ),
          ),
        ],
      );
      await tester.tap(find.text('SCAN-OK'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('RECORD:assets/as-1'), findsOneWidget);
      h.dispose();
    });

    testWidgets('رمز غير معروف (٤٠٤) ⇒ «غير موجود» ولا ملاحة', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.on(
        'GET identity/resolve/SN-404',
        (_) => apiError('RESOURCE_NOT_FOUND', 404),
      );
      await pumpScreen(tester, h, ScannerScreen(scanView: fakeScanView));
      await tester.tap(find.text('SCAN-MISS'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('SCAN-OK'), findsOneWidget); // ما زلنا في الماسح
      expect(find.textContaining('لا سجل مطابق'), findsOneWidget);
      h.dispose();
    });
  });

  group('التتبّع (مصدر موقع مزيّف)', () {
    testWidgets('لا بدء بلا موافقة؛ بعدها جلسة ظاهرة ودفعة وإنهاء', (
      tester,
    ) async {
      final loc = FakeLocationSource();
      final h = TestHarness.create(location: loc);
      await h.seedSession();
      h.transport.onData('POST tracking/start', {'session': 'trk-1'});
      h.transport.onData('POST tracking/trk-1/points', {'accepted': 1});
      h.transport.onData('POST tracking/trk-1/end', {'ended': true});
      await pumpScreen(tester, h, const TrackingScreen());

      final start = find.widgetWithText(FilledButton, 'بدء التتبع');
      expect(tester.widget<FilledButton>(start).onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(
        h.transport.sent('POST tracking/start').single.jsonBody['consent'],
        isTrue,
      );
      expect(find.text('جلسة تتبع نشطة'), findsOneWidget);

      loc.controller.add(
        LocationFix(lat: 29.37, lng: 47.97, at: DateTime.utc(2026, 9, 27)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('إنهاء التتبع'));
      // إلغاء الاشتراك يُستأنف في منطقة الجذر ⇒ جولة وقت حقيقي.
      await settleIo(tester);

      final points = h.transport.sent('POST tracking/trk-1/points').single;
      expect((points.jsonBody['points'] as List).single['lat'], 29.37);
      expect(points.headers['Idempotency-Key'], isNotEmpty);
      expect(h.transport.sent('POST tracking/trk-1/end'), hasLength(1));
      expect(find.text('جلسة تتبع نشطة'), findsNothing);
      h.dispose();
    });

    testWidgets('إذن الموقع مرفوض ⇒ رسالة ولا جلسة خادمية', (tester) async {
      final loc = FakeLocationSource(granted: false);
      final h = TestHarness.create(location: loc);
      await h.seedSession();
      await pumpScreen(tester, h, const TrackingScreen());
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'بدء التتبع'));
      await tester.pumpAndSettle();
      expect(loc.permissionAsks, 1);
      expect(h.transport.sent('POST tracking/start'), isEmpty);
      expect(find.textContaining('الموقع'), findsWidgets);
      h.dispose();
    });
  });

  group('لوحة المرفقات (منتقٍ مزيّف)', () {
    const schema = ModuleSchema(
      key: 'tasks',
      label: 'المهام',
      syncClass: 'CACHEABLE_INCREMENTAL',
      can: ModuleCan(v: true, e: true),
      fields: [FieldSpec(key: 'spec', label: 'الملف', type: 'file')],
    );

    Future<TestHarness> pumpPanel(
      WidgetTester tester, {
      required String filename,
      required String mime,
    }) async {
      final h = TestHarness.create();
      await h.seedSession();
      final file = File('${h.tempDir.path}/pick_$filename')
        ..writeAsBytesSync(_png);
      h.transport.onData('POST files/upload-session', {
        'token': 'up-1',
        'chunk_size': 65536,
        'max_parts': 10,
        'max_bytes': 1000000,
      });
      h.transport.onData('PUT files/upload-session/up-1/chunk', {'ok': true});
      h.transport.onData('POST files/upload-session/up-1/complete', {
        'module': 'tasks',
        'record_id': 't1',
        'count': 1,
        'files': [
          {
            'id': 'f1',
            'original_name': filename,
            'mime': mime,
            'size': 2048,
            'download': '/api/mobile/v1/files/f1/download',
            'stream': '/api/mobile/v1/files/f1/stream',
          },
        ],
      });
      h.transport.on(
        'GET files/f1/download',
        (_) => http.Response.bytes(_png, 200, headers: {'content-type': mime}),
      );
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: AttachmentsPanel(
            module: 'tasks',
            recordId: 't1',
            schema: schema,
            record: const RecordData({'id': 't1'}),
            picker: (_) async => PickedAttachment(file, filename),
          ),
        ),
      );
      await tester.tap(find.text('المستندات'));
      await settleIo(tester);
      return h;
    }

    testWidgets('رفع مقطّع ثم فتح صورة من الذاكرة (download بلا قرص)', (
      tester,
    ) async {
      final h = await pumpPanel(
        tester,
        filename: 'site.png',
        mime: 'image/png',
      );
      final complete = h.transport
          .sent('POST files/upload-session/up-1/complete')
          .single;
      expect(complete.headers['Idempotency-Key'], isNotEmpty);
      // الاسم من `original_name` الخادمي، والحجم بصيغة مقروءة من ARB.
      expect(find.text('site.png'), findsOneWidget);
      expect(find.text('2.0 ك.ب'), findsOneWidget);

      final before = h.tempDir.listSync(recursive: true).length;
      await tester.tap(find.byKey(const Key('attachment-open-f1')));
      await tester.pumpAndSettle();
      expect(h.transport.sent('GET files/f1/download'), hasLength(1));
      expect(find.byKey(const Key('attachment-image')), findsOneWidget);
      expect(
        h.tempDir.listSync(recursive: true).length,
        before,
        reason: 'المعاينة من الذاكرة — لا ملف يهبط القرص',
      );
      h.dispose();
    });

    testWidgets(
      'غير الصورة ⇒ لا تنزيل ولا ملف مؤقت، بل «افتح على الويب» صادق',
      (tester) async {
        final h = await pumpPanel(
          tester,
          filename: 'contract.pdf',
          mime: 'application/pdf',
        );
        await tester.tap(find.byKey(const Key('attachment-open-f1')));
        await tester.pumpAndSettle();
        expect(h.transport.sent('GET files/f1/download'), isEmpty);
        expect(find.text('افتح على الويب'), findsOneWidget);
        await tester.tap(find.text('إغلاق'));
        await tester.pumpAndSettle();
        h.dispose();
      },
    );

    testWidgets('مرفق مصاب (٤٢٣ LOCKED) ⇒ حالة محجوبة لا صورة', (tester) async {
      final h = await pumpPanel(tester, filename: 'x.jpg', mime: 'image/jpeg');
      h.transport.on('GET files/f1/download', (_) => apiError('LOCKED', 423));
      await tester.tap(find.byKey(const Key('attachment-open-f1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('مصاب'), findsOneWidget);
      expect(find.byKey(const Key('attachment-image')), findsNothing);
      h.dispose();
    });
  });

  group('أعضاء العميل', () {
    testWidgets('القائمة والدعوة بمفتاح idempotency وتغيير الدور', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      Map<String, dynamic> member(String id, String role) => {
        'id': id,
        'role': role,
        'status': 'active',
        'user': {
          'name': 'سارة',
          'email': 'sara@client.example',
          'activated': true,
        },
      };
      h.transport.onData('GET clients/cl-1/members', {
        'members': [member('m1', 'viewer')],
      });
      h.transport.onData('POST clients/cl-1/members', {
        'member': member('m2', 'lead'),
      });
      h.transport.onData('PUT clients/cl-1/members/m1', {
        'member': member('m1', 'finance'),
      });
      await pumpScreen(
        tester,
        h,
        const ClientMembersScreen(clientId: 'cl-1', clientName: 'عميل ألف'),
      );
      expect(find.text('سارة'), findsOneWidget);
      expect(find.textContaining('sara@client.example'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'new@client.example',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'إرسال'));
      await tester.pumpAndSettle();
      final invite = h.transport.sent('POST clients/cl-1/members').single;
      expect(invite.jsonBody['email'], 'new@client.example');
      expect(invite.jsonBody.containsKey('password'), isFalse);
      expect(invite.headers['Idempotency-Key'], isNotEmpty);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تغيير الدور').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('مالي'));
      await tester.pumpAndSettle();
      expect(
        h.transport.sent('PUT clients/cl-1/members/m1').single.jsonBody['role'],
        'finance',
      );
      h.dispose();
    });
  });

  group('تفاصيل بوابة العميل', () {
    testWidgets('المشروع: التقدم والحقول', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET portal/projects/p-1', {
        'project': {
          'id': 'p-1',
          'name': 'مشروع ألف',
          'status': 'قيد التنفيذ',
          'progress': 40,
          'client_name': 'عميل ألف',
          'description': 'وصف المشروع',
        },
      });
      await pumpScreen(tester, h, const PortalProjectScreen(id: 'p-1'));
      expect(find.text('مشروع ألف'), findsOneWidget);
      expect(find.textContaining('40٪'), findsOneWidget);
      expect(find.text('قيد التنفيذ'), findsOneWidget);
      expect(find.text('وصف المشروع'), findsOneWidget);
      h.dispose();
    });

    testWidgets('الفاتورة: المبالغ عرضٌ عشري من نص الخادم', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET portal/invoices/i-1', {
        'invoice': {
          'id': 'i-1',
          'doc_no': 'INV-A1',
          'kind': 'فاتورة مبيعات',
          'total': '1500.500',
          'paid': '0.100',
          'currency': 'KWD',
          'state': 'مرسلة',
        },
      });
      await pumpScreen(tester, h, const PortalInvoiceScreen(id: 'i-1'));
      expect(find.text('INV-A1'), findsOneWidget);
      expect(find.text('1500.5 KWD'), findsOneWidget);
      expect(find.text('0.1 KWD'), findsOneWidget);
      h.dispose();
    });

    testWidgets('الوثيقة: الحقول، والخطأ حالة صريحة بإعادة محاولة', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.on(
        'GET portal/documents/d-1',
        (_) => apiError('RESOURCE_NOT_FOUND', 404),
      );
      await pumpScreen(tester, h, const PortalDocumentScreen(id: 'd-1'));
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      h.transport.onData('GET portal/documents/d-1', {
        'document': {
          'id': 'd-1',
          'name': 'عرض ألف',
          'cat': 'عروض',
          'doc_no': 'Q-7',
        },
      });
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('عرض ألف'), findsWidgets);
      expect(find.text('Q-7'), findsOneWidget);
      h.dispose();
    });
  });

  group('نموذج السجل', () {
    Map<String, dynamic> formSchema() => {
      'schema_version': 'f1',
      'modules': [
        {
          'key': 'tasks',
          'label': 'المهام',
          'sync_class': 'CACHEABLE_INCREMENTAL',
          'can': {'v': true, 'a': true, 'e': true, 'd': true},
          'fields': [
            {
              'key': 'title',
              'label': 'العنوان',
              'type': 'text',
              'required': true,
            },
            {'key': 'details', 'label': 'التفاصيل', 'type': 'ta'},
          ],
        },
      ],
    };

    testWidgets(
      'إنشاء: تحقق عميل ثم POST بمفتاح idempotency، و422 بجانب الحقل',
      (tester) async {
        final h = TestHarness.create();
        await h.seedSession();
        h.transport.onData('GET schema', formSchema());
        var calls = 0;
        h.transport.on('POST tasks', (req) {
          calls++;
          return calls == 1
              ? apiError(
                  'VALIDATION_FAILED',
                  422,
                  details: {
                    'errors': {
                      'title': ['العنوان مستخدم سلفاً'],
                    },
                  },
                )
              : okData({
                  'id': 't5',
                  'title': req.jsonBody['title'],
                }, status: 201);
        });
        await pumpScreen(tester, h, const RecordFormScreen(module: 'tasks'));

        await tester.tap(find.text('حفظ'));
        await tester.pumpAndSettle();
        expect(h.transport.sent('POST tasks'), isEmpty, reason: 'مطلوب فارغ');

        await tester.enterText(find.byType(TextFormField).first, 'مهمة جديدة');
        await tester.tap(find.text('حفظ'));
        await tester.pumpAndSettle();
        expect(find.text('العنوان مستخدم سلفاً'), findsOneWidget);

        await tester.tap(find.text('حفظ'));
        await tester.pumpAndSettle();
        final posts = h.transport.sent('POST tasks');
        expect(posts, hasLength(2));
        expect(
          posts[0].headers['Idempotency-Key'],
          posts[1].headers['Idempotency-Key'],
          reason: 'المحاولة الثانية للعملية نفسها بالمفتاح نفسه',
        );
        expect(find.text('OPEN'), findsOneWidget); // عاد بعد النجاح
        h.dispose();
      },
    );

    testWidgets(
      'تعديل محمي: 202 APPROVAL_REQUIRED ⇒ «صُفَّ للمعتمدين» لا «حُفظ»',
      (tester) async {
        final h = TestHarness.create();
        await h.seedSession();
        h.transport.onData('GET schema', formSchema());
        h.transport.onData('GET tasks/t1', {
          'id': 't1',
          'title': 'قديمة',
          'version': 4,
        });
        h.transport.on(
          'PUT tasks/t1',
          (_) => apiError(
            'APPROVAL_REQUIRED',
            202,
            message: 'صُفَّ طلبك',
            details: {
              'approval': {'module': 'approvals', 'id': 'ap-9'},
            },
          ),
        );
        await pumpScreen(
          tester,
          h,
          const RecordFormScreen(module: 'tasks', recordId: 't1'),
        );
        await tester.enterText(find.byType(TextFormField).first, 'معدّلة');
        await tester.tap(find.text('حفظ'));
        await tester.pumpAndSettle();

        final put = h.transport.sent('PUT tasks/t1').single;
        expect(put.headers['If-Match'], '"4"');
        expect(
          find.text('العملية محمية بالموافقات — صُفَّ طلبك للمعتمدين'),
          findsOneWidget,
        );
        expect(find.text('حُفظ'), findsNothing);
        h.dispose();
      },
    );
  });

  group('الجلسات والتشخيص', () {
    testWidgets('الجلسات: الحالية معلَّمة، وإبطال أخرى ثم إعادة تحميل', (
      tester,
    ) async {
      final h = TestHarness.create();
      await h.seedSession();
      h.transport.onData('GET auth/sessions', {
        'sessions': [
          {
            'id': 'sess-1',
            'platform': 'android',
            'app_version': '0.6.0',
            'last_used_at': '2026-09-27T09:00:00Z',
          },
          {
            'id': 'sess-2',
            'platform': 'ios',
            'app_version': '0.5.0',
            'last_used_at': '2026-09-20T09:00:00Z',
          },
        ],
      });
      h.transport.onData('DELETE auth/sessions/sess-2', {'revoked': true});
      await pumpScreen(tester, h, const SessionsScreen());

      expect(find.textContaining('الجلسة الحالية'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.link_off));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(h.transport.sent('DELETE auth/sessions/sess-2'), hasLength(1));
      expect(h.transport.sent('GET auth/sessions'), hasLength(2));
      h.dispose();
    });

    testWidgets('التشخيص: معلومات آمنة، ولا رمز ولا سر', (tester) async {
      final h = TestHarness.create();
      await h.seedSession();
      await pumpScreen(tester, h, const DiagnosticsScreen());
      expect(find.text('NOT_CONFIGURED'), findsOneWidget);
      expect(find.text('hub.test.local'), findsOneWidget);
      expect(find.textContaining('sess-1'), findsOneWidget);
      expect(find.textContaining('lyma_'), findsNothing);
      expect(find.textContaining('lymr_'), findsNothing);
      h.dispose();
    });
  });
}
