/// المرحلة ٣ (خلفية v2.618) — أفعال الميدان والموظف: الحضور، قرار الإجازة،
/// العهدة، الجرد، مرفقات السجل، نسخ السجل. عقد المستودع (مسارات، أجسام،
/// Idempotency وسياسة الإعادة، الأسباب الآلية) ثم الواجهات بحالاتٍ صادقة.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/core/errors/api_exception.dart';
import 'package:lynomia_hub_app/features/attendance/attendance_card.dart';
import 'package:lynomia_hub_app/features/attendance/attendance_repository.dart';
import 'package:lynomia_hub_app/features/comments/comments_panel.dart';
import 'package:lynomia_hub_app/features/custody/custody_screens.dart';
import 'package:lynomia_hub_app/features/files/attachments_panel.dart';
import 'package:lynomia_hub_app/features/inventory/inventory_screens.dart';
import 'package:lynomia_hub_app/features/leaves/leave_decision_card.dart';
import 'package:lynomia_hub_app/features/leaves/leave_repository.dart';
import 'package:lynomia_hub_app/features/modules/module_repository.dart';
import 'package:lynomia_hub_app/features/modules/module_schema.dart';
import 'package:lynomia_hub_app/features/records/versions_screen.dart';
import 'package:lynomia_hub_app/features/tracking/location_source.dart';

import '../fakes/fakes.dart';
import '../fakes/screen_harness.dart';

class _FakeLocation implements LocationSource {
  int asks = 0;

  @override
  Future<bool> ensurePermission() async {
    asks++;
    return true;
  }

  @override
  Stream<LocationFix> positions() => Stream.value(
    LocationFix(lat: 29.37, lng: 47.97, at: DateTime(2026), accuracy: 12),
  );
}

Map<String, dynamic> _today({
  String state = 'not_checked_in',
  bool geo = true,
}) => {
  'date': '2026-09-27',
  'employee': {'id': 'e1', 'name': 'موظف'},
  'attendance': state == 'not_checked_in'
      ? null
      : {
          'id': 'a1',
          'date': '2026-09-27',
          'time_in': '08:05',
          'time_out': state == 'checked_out' ? '16:10' : null,
          'hours': state == 'checked_out' ? 8.08 : null,
          'status': 'حاضر',
          'mode': 'مكتب',
          'overnight': false,
        },
  'state': state,
  'can': {
    'check_in': state == 'not_checked_in',
    'check_out': state == 'checked_in',
  },
  'modes': ['مكتب', 'عن بعد'],
  'location': {'recorded_by_server': geo, 'consent_required': true},
};

Map<String, dynamic> _attRow() => {
  'attendance': {
    'id': 'a1',
    'date': '2026-09-27',
    'time_in': '08:05',
    'overnight': false,
  },
  'message': 'سُجّل حضورك QWXZ',
  'location_recorded': true,
};

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
  });

  tearDown(() => h.dispose());

  group('المستودعات (العقد)', () {
    test('الحضور: today، ولا ملف موظف ⇒ null صادق', () async {
      h.transport.onData('GET attendance/today', _today(state: 'checked_in'));
      final t = await h.container.attendance.today();
      expect(t!.state, AttendanceState.checkedIn);
      expect(t.canCheckOut, isTrue);
      expect(t.row!.timeIn, '08:05');
      expect(t.serverRecordsLocation, isTrue);

      h.transport.on(
        'GET attendance/today',
        (_) => apiError(
          'BUSINESS_RULE_VIOLATION',
          422,
          details: {'reason': 'no_employee_profile'},
        ),
      );
      expect(await h.container.attendance.today(), isNull);
    });

    test(
      'الحضور: مفتاح ثابت عبر الإعادة، والموقع فقط بموافقةٍ صريحة',
      () async {
        h.transport.onData('POST attendance/check-in', _attRow());
        h.transport.failOnce.add('POST attendance/check-in');
        final r = await h.container.attendance.checkIn(mode: 'مكتب');
        expect(r.locationRecorded, isTrue);
        final sent = h.transport.sent('POST attendance/check-in');
        expect(sent, hasLength(2), reason: 'مفتاح Idempotency ⇒ إعادة آمنة');
        expect(
          sent[0].headers['Idempotency-Key'],
          sent[1].headers['Idempotency-Key'],
        );
        expect(sent.last.jsonBody, {'mode': 'مكتب'});

        await h.container.attendance.checkIn(
          consentedLocation: LocationFix(
            lat: 29.1,
            lng: 47.2,
            at: DateTime(2026),
            accuracy: 5,
          ),
        );
        final body = h.transport.sent('POST attendance/check-in').last.jsonBody;
        expect(body['lat'], 29.1);
        expect(body['lng'], 47.2);
        expect(body['accuracy'], 5);
        expect(body['location_consent'], isTrue);
      },
    );

    test('الانصراف: الرفض الدلالي بسببٍ آلي', () async {
      h.transport.on(
        'POST attendance/check-out',
        (_) => apiError(
          'BUSINESS_RULE_VIOLATION',
          422,
          details: {'reason': 'already_checked_out'},
        ),
      );
      await expectLater(
        h.container.attendance.checkOut(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.details['reason'],
            'reason',
            'already_checked_out',
          ),
        ),
      );
    });

    test('قرار الإجازة: الجسم والمفتاح، والسبب يُرسل للرفض', () async {
      h.transport.onData('POST leaves/l1/decide', {
        'id': 'l1',
        'status': 'مرفوض',
        'previous_status': 'مقدّم',
        'decision': 'reject',
        'message': 'رُفض',
      });
      final r = await h.container.leaves.decide(
        'l1',
        LeaveDecisionKind.reject,
        reason: '  تعارض  ',
      );
      expect(r.status, 'مرفوض');
      final req = h.transport.sent('POST leaves/l1/decide').single;
      expect(req.jsonBody, {'decision': 'reject', 'reason': 'تعارض'});
      expect(req.headers['Idempotency-Key'], isNotEmpty);
    });

    test('العهدة: عهدتي، التسليم والاسترداد، والإقرار بمسار الخادم', () async {
      h.transport.onData('GET me/custody', {
        'assets': [
          {
            'id': 'as1',
            'name': 'لابتوب',
            'code': 'LT-1',
            'serial': null,
            'receipt_pending': true,
            'station': {'id': 's1', 'name': 'المكتب'},
          },
        ],
        'moves': [
          {
            'id': 'm1',
            'asset_id': 'as1',
            'asset_name': 'لابتوب',
            'action': 'تسليم',
            'at': '2026-09-20',
          },
        ],
        'pending_receipts': [
          {
            'module': 'assets',
            'id': 'as1',
            'title': 'لابتوب',
            'label': 'إقرار',
            'why': 'سُلّم إليك',
            'ack': {
              'method': 'POST',
              'path': '/api/mobile/v1/assets/as1/actions/ack',
            },
          },
        ],
      });
      final mine = await h.container.custody.mine();
      expect(mine.assets.single.serial, isNull, reason: 'المحجوب لا يُعرض');
      expect(mine.assets.single.stationName, 'المكتب');
      expect(mine.moves.single.action, 'تسليم');

      h.transport.onData('POST assets/as1/actions/ack', {'ok': true});
      await h.container.custody.acknowledge(mine.pendingReceipts.single);
      expect(
        h.transport
            .sent('POST assets/as1/actions/ack')
            .single
            .headers['Idempotency-Key'],
        isNotEmpty,
      );

      final move = {
        'asset': {'id': 'as1', 'name': 'لابتوب', 'holder_id': 'u-2'},
        'movement': {'id': 'mv', 'action': 'تسليم', 'at': '2026-09-27'},
      };
      h.transport.onData('POST custody/as1/handover', move);
      final r = await h.container.custody.handover(
        'as1',
        userId: 'u-2',
        at: DateTime(2026, 9, 27),
        note: 'مع الشاحن',
      );
      expect(r.holderId, 'u-2');
      expect(h.transport.sent('POST custody/as1/handover').single.jsonBody, {
        'user_id': 'u-2',
        'at': '2026-09-27',
        'note': 'مع الشاحن',
      });
      h.transport.onData('POST custody/as1/recover', move);
      await h.container.custody.recover('as1', at: DateTime(2026, 9, 28));
      expect(h.transport.sent('POST custody/as1/recover').single.jsonBody, {
        'at': '2026-09-28',
      });
    });

    test(
      'الجرد: القائمة والتفصيل بالصفحة والتجميد والمسح والمصالحة والإغلاق',
      () async {
        h.transport.onData('GET inventory/sessions', {
          'sessions': [
            {
              'id': 's1',
              'status': 'مفتوحة',
              'open': true,
              'items_count': 3,
              'scans_count': 1,
            },
          ],
          'can': {
            'freeze': true,
            'scan': true,
            'reconcile': true,
            'close': true,
          },
        });
        final list = await h.container.inventory.sessions();
        expect(list.sessions.single.open, isTrue);
        expect(list.can.freeze, isTrue);

        h.transport.onData('GET inventory/sessions/s1', {
          'session': {
            'id': 's1',
            'status': 'مفتوحة',
            'open': true,
            'counts': {'معلّق': 2, 'موجود': 1},
            'total': 3,
          },
          'items': [
            {
              'asset_id': 'as1',
              'verdict': 'موجود',
              'code': 'LT-1',
              'name': 'لابتوب',
            },
          ],
          'page': 2,
          'last_page': 2,
          'items_total': 51,
          'scans': [
            {
              'id': 'sc1',
              'result': 'غير معروف',
              'asset_id': null,
              'code': null,
            },
          ],
          'can': {'scan': true},
        });
        final d = await h.container.inventory.session('s1', page: 2);
        expect(
          h.transport
              .sent('GET inventory/sessions/s1')
              .single
              .url
              .queryParameters,
          {'page': '2'},
        );
        expect(d.session.counts['معلّق'], 2);
        expect(d.scans.single.code, isNull, reason: 'الرمز الأجنبي لا يُخزَّن');

        h.transport.onData('POST inventory/sessions', {
          'session': {'id': 's2', 'status': 'مفتوحة', 'open': true},
          'frozen': 12,
        });
        final f = await h.container.inventory.freeze();
        expect(f.frozen, 12);
        expect(
          h.transport
              .sent('POST inventory/sessions')
              .single
              .headers['Idempotency-Key'],
          isNotEmpty,
        );

        h.transport.onData('POST inventory/sessions/s1/scan', {
          'result': 'معروف',
          'result_key': 'known',
          'message': 'مُسح',
          'asset': {'id': 'as1', 'code': 'LT-1', 'name': 'لابتوب'},
        });
        final sc = await h.container.inventory.scan('s1', 'LT-1');
        expect(sc.resultKey, 'known');
        expect(
          h.transport.sent('POST inventory/sessions/s1/scan').single.jsonBody,
          {'code': 'LT-1'},
        );

        h.transport.onData('POST inventory/sessions/s1/reconcile', {
          'id': 's1',
          'counts': {'موجود': 2, 'مفقود': 1},
        });
        expect(await h.container.inventory.reconcile('s1'), {
          'موجود': 2,
          'مفقود': 1,
        });
        h.transport.onData('POST inventory/sessions/s1/close', {
          'id': 's1',
          'status': 'مغلقة',
          'closed_now': true,
        });
        expect(await h.container.inventory.close('s1'), isTrue);
      },
    );

    test(
      'المرفقات: attachments (لا files) للقائمة والحذف، وتنزيل مرفق الرسالة',
      () async {
        h.transport.onData('GET attachments', {
          'module': 'tasks',
          'record_id': 't1',
          'count': 1,
          'files': [
            {
              'id': 'f1',
              'original_name': 'plan.pdf',
              'mime': 'application/pdf',
              'size': 4096,
              'uploaded_by': {'id': 'u-2', 'name': 'سارة'},
              'can': {'download': true, 'preview': false, 'delete': true},
              'download': '/api/mobile/v1/files/f1/download',
            },
          ],
        });
        final files = await h.container.files.recordFiles('tasks', 't1');
        expect(h.transport.sent('GET attachments').single.url.queryParameters, {
          'module': 'tasks',
          'record_id': 't1',
        });
        expect(files.single.canDelete, isTrue);
        expect(files.single.uploadedBy!.name, 'سارة');

        h.transport.onData('DELETE attachments/f1', {
          'id': 'f1',
          'deleted': true,
        });
        await h.container.files.deleteFile('f1');
        expect(h.transport.sent('DELETE attachments/f1'), hasLength(1));
        expect(
          h.transport.requests.where((r) => r.apiPath.startsWith('files')),
          isEmpty,
        );

        h.transport.on(
          'GET comments/c9/attachment',
          (_) => http.Response.bytes([1, 2, 3], 200),
        );
        expect(
          await h.container.files.downloadPath(
            '/api/mobile/v1/comments/c9/attachment',
          ),
          [1, 2, 3],
        );
      },
    );

    test('النسخ: versions بحدٍّ، والاستعادة من إجراء السجل القائم', () async {
      h.transport.onData('GET tasks/t1/versions', {
        'module': 'tasks',
        'id': 't1',
        'current_version': 3,
        'trashed': false,
        'versions': [
          {
            'version': 3,
            'current': true,
            'restorable': false,
            'changed': ['title'],
          },
          {'version': 1, 'current': false, 'restorable': true, 'changed': null},
        ],
        'restore': {
          'action': 'restore-version',
          'path': '/api/mobile/v1/tasks/t1/actions/restore-version',
          'needs': ['version'],
        },
      });
      final v = await h.container.modules.versions('tasks', 't1', limit: 5);
      expect(
        h.transport.sent('GET tasks/t1/versions').single.url.queryParameters,
        {'limit': '5'},
      );
      expect(v.currentVersion, 3);
      expect(v.versions.last.changed, isNull);
      expect(v.restoreAction, 'restore-version');
    });
  });

  group('الواجهات', () {
    testWidgets('بطاقة الحضور: حضورٌ بموافقة الموقع ثم حالة من الخادم', (
      tester,
    ) async {
      final loc = _FakeLocation();
      h.dispose();
      h = TestHarness.create(location: loc);
      await h.seedSession();
      var state = 'not_checked_in';
      h.transport.on(
        'GET attendance/today',
        (_) => okData(_today(state: state)),
      );
      h.transport.on('POST attendance/check-in', (_) {
        state = 'checked_in';
        return okData(_attRow());
      });
      await pumpScreen(
        tester,
        h,
        const Scaffold(body: SingleChildScrollView(child: AttendanceCard())),
      );
      expect(find.text('لم تسجّل حضورك اليوم'), findsOneWidget);
      expect(find.byKey(const Key('attendance-check-out')), findsNothing);

      // الموافقة الصريحة (المربّع) ⇒ إذنٌ وقراءةٌ واحدة تُرسل مع الضغطة.
      await tester.tap(find.byKey(const Key('attendance-consent')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attendance-check-in')));
      await tester.pumpAndSettle();
      expect(loc.asks, 1);
      final body = h.transport.sent('POST attendance/check-in').single.jsonBody;
      expect(body['location_consent'], isTrue);
      expect(body['mode'], 'مكتب');
      expect(find.text('سُجّل حضورك QWXZ'), findsOneWidget);
      expect(find.text('حاضر منذ 08:05'), findsOneWidget);
      expect(find.byKey(const Key('attendance-check-out')), findsOneWidget);
    });

    testWidgets('بطاقة الحضور: الخادم لا يحفظ الموقع ⇒ لا خيار موقع؛ '
        'والرفض الآلي برسالة محلية', (tester) async {
      h.transport.onData('GET attendance/today', _today(geo: false));
      h.transport.on(
        'POST attendance/check-in',
        (_) => apiError(
          'BUSINESS_RULE_VIOLATION',
          422,
          message: 'نص خادمي',
          details: {'reason': 'open_shift_previous_day'},
        ),
      );
      await pumpScreen(
        tester,
        h,
        const Scaffold(body: SingleChildScrollView(child: AttendanceCard())),
      );
      expect(find.byKey(const Key('attendance-consent')), findsNothing);
      await tester.tap(find.byKey(const Key('attendance-check-in')));
      await tester.pumpAndSettle();
      expect(find.textContaining('ورديةٌ مفتوحة من يومٍ سابق'), findsOneWidget);
    });

    testWidgets('بطاقة الحضور: بلا ملف موظف لا بطاقة', (tester) async {
      h.transport.on(
        'GET attendance/today',
        (_) => apiError(
          'BUSINESS_RULE_VIOLATION',
          422,
          details: {'reason': 'no_employee_profile'},
        ),
      );
      await pumpScreen(tester, h, const Scaffold(body: AttendanceCard()));
      expect(find.byKey(const Key('attendance-card')), findsNothing);
    });

    testWidgets('قرار الإجازة: الرفض يُلزم سبباً، وطلب النفس يُغلق البطاقة', (
      tester,
    ) async {
      var decided = 0;
      h.transport.on('POST leaves/l1/decide', (req) {
        if (req.jsonBody['decision'] == 'approve') {
          return apiError(
            'FORBIDDEN',
            403,
            details: {'reason': 'self_request'},
          );
        }
        decided++;
        return okData({'id': 'l1', 'status': 'مرفوض', 'message': 'رُفض QWXZ'});
      });
      await pumpScreen(
        tester,
        h,
        Scaffold(
          body: LeaveDecisionCard(leaveId: 'l1', onDecided: () {}),
        ),
      );
      await tester.tap(find.byKey(const Key('leave-reject')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
      expect(h.transport.sent('POST leaves/l1/decide'), isEmpty);
      await tester.enterText(find.byKey(const Key('prompt-input')), 'تعارض');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(decided, 1);
      expect(
        h.transport.sent('POST leaves/l1/decide').single.jsonBody['reason'],
        'تعارض',
      );

      await tester.tap(find.byKey(const Key('leave-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('leave-closed-note')), findsOneWidget);
      expect(find.byKey(const Key('leave-approve')), findsNothing);
    });

    testWidgets('عهدتي: الإقرار بالاستلام بمسار الخادم ثم إعادة التحميل', (
      tester,
    ) async {
      var acked = false;
      h.transport.on(
        'GET me/custody',
        (_) => okData({
          'assets': [
            {'id': 'as1', 'name': 'لابتوب', 'receipt_pending': !acked},
          ],
          'moves': <dynamic>[],
          'pending_receipts': acked
              ? <dynamic>[]
              : [
                  {
                    'module': 'assets',
                    'id': 'as1',
                    'title': 'لابتوب',
                    'label': 'إقرار',
                    'why': 'سُلّم إليك',
                    'ack': {
                      'method': 'POST',
                      'path': '/api/mobile/v1/assets/as1/actions/ack',
                    },
                  },
                ],
        }),
      );
      h.transport.on('POST assets/as1/actions/ack', (_) {
        acked = true;
        return okData({'ok': true});
      });
      await pumpScreen(tester, h, const MyCustodyScreen());
      expect(find.text('بانتظار إقرارك'), findsOneWidget);
      await tester.tap(find.byKey(const Key('custody-ack-as1')));
      await tester.pumpAndSettle();
      expect(find.text('سُجّل إقرار الاستلام'), findsOneWidget);
      expect(find.byKey(const Key('custody-ack-as1')), findsNothing);
    });

    testWidgets('الجرد: الإغلاق خلف التصعيد — 428 ⇒ تأكيد الهوية ⇒ إعادة '
        'بالمفتاح نفسه', (tester) async {
      var closeCalls = 0;
      h.transport.onData('GET inventory/sessions/s1', {
        'session': {'id': 's1', 'status': 'مفتوحة', 'open': true},
        'items': <dynamic>[],
        'page': 1,
        'last_page': 1,
        'items_total': 0,
        'scans': <dynamic>[],
        'can': {'scan': true, 'reconcile': true, 'close': true},
      });
      h.transport.on('POST inventory/sessions/s1/close', (_) {
        closeCalls++;
        if (closeCalls == 1) {
          return apiError(
            'STEP_UP_REQUIRED',
            428,
            details: {
              'purpose': 'action:inventory:close',
              'method': 'password',
            },
          );
        }
        return okData({'id': 's1', 'status': 'مغلقة', 'closed_now': true});
      });
      h.transport.on('POST auth/step-up', (req) {
        expect(req.jsonBody['purpose'], 'action:inventory:close');
        return okData({'granted': true});
      });
      await pumpScreen(
        tester,
        h,
        const InventorySessionScreen(sessionId: 's1'),
      );
      expect(find.byKey(const Key('inventory-scan')), findsOneWidget);
      await tester.tap(find.byKey(const Key('inventory-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.tap(find.text('تأكيد').last);
      await tester.pumpAndSettle();
      final sent = h.transport.sent('POST inventory/sessions/s1/close');
      expect(sent, hasLength(2));
      expect(
        sent[0].headers['Idempotency-Key'],
        sent[1].headers['Idempotency-Key'],
      );
      expect(find.text('أُغلقت الجلسة'), findsOneWidget);
    });

    testWidgets('الجرد: المسح المتتابع بعارضٍ مزيّف، والجلسة المغلقة سبب آلي', (
      tester,
    ) async {
      late void Function(String) emit;
      var n = 0;
      h.transport.on('POST inventory/sessions/s1/scan', (req) {
        n++;
        if (n == 2) {
          return apiError(
            'BUSINESS_RULE_VIOLATION',
            422,
            details: {'reason': 'session_closed'},
          );
        }
        return okData({
          'result': 'معروف',
          'result_key': 'known',
          'message': 'm',
          'asset': {'id': 'as1', 'code': 'LT-1', 'name': 'لابتوب'},
        });
      });
      await pumpScreen(
        tester,
        h,
        InventoryScanScreen(
          sessionId: 's1',
          scanView: (context, onCode) {
            emit = onCode;
            return const SizedBox.expand();
          },
        ),
      );
      emit('LT-1');
      await tester.pumpAndSettle();
      expect(find.text('✓ معروف: لابتوب'), findsOneWidget);
      emit('LT-1'); // الرمز نفسه خلال ثانيتين لا يُعاد إرساله
      await tester.pumpAndSettle();
      expect(n, 1);
      emit('LT-2');
      await tester.pumpAndSettle();
      expect(find.textContaining('الجلسة مغلقة'), findsOneWidget);
    });

    testWidgets('مرفقات السجل من الخادم: الحذف بإذن can.delete فقط', (
      tester,
    ) async {
      var deleted = false;
      h.transport.on(
        'GET attachments',
        (_) => okData({
          'files': [
            if (!deleted)
              {
                'id': 'f1',
                'original_name': 'plan.pdf',
                'mime': 'application/pdf',
                'size': 4096,
                'can': {'download': true, 'preview': false, 'delete': true},
              },
            {
              'id': 'f2',
              'original_name': 'other.pdf',
              'mime': 'application/pdf',
              'size': 10,
              'can': {'download': true, 'preview': false, 'delete': false},
            },
          ],
        }),
      );
      h.transport.on('DELETE attachments/f1', (_) {
        deleted = true;
        return okData({'id': 'f1', 'deleted': true});
      });
      await pumpScreen(
        tester,
        h,
        const Scaffold(
          body: AttachmentsPanel(
            module: 'tasks',
            recordId: 't1',
            schema: ModuleSchema(
              key: 'tasks',
              label: 'المهام',
              syncClass: 'ONLINE_ONLY',
              can: ModuleCan(v: true),
              fields: [],
            ),
            record: RecordData({'id': 't1'}),
          ),
        ),
      );
      expect(find.text('plan.pdf'), findsOneWidget);
      expect(find.byKey(const Key('attachment-delete-f2')), findsNothing);
      await tester.tap(find.byKey(const Key('attachment-delete-f1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(find.text('plan.pdf'), findsNothing);
      expect(find.text('حُذف المرفق'), findsOneWidget);
    });

    testWidgets('نسخ السجل: الاستعادة برقم النسخة عبر restore-version', (
      tester,
    ) async {
      h.transport.onData('GET tasks/t1/versions', {
        'current_version': 3,
        'versions': [
          {'version': 3, 'current': true, 'restorable': false, 'changed': []},
          {
            'version': 2,
            'current': false,
            'restorable': true,
            'by': {'id': 'u-2', 'name': 'سارة'},
            'changed': ['title'],
          },
        ],
        'restore': {'action': 'restore-version'},
      });
      h.transport.onData('POST tasks/t1/actions/restore-version', {'ok': true});
      await pumpScreen(
        tester,
        h,
        const RecordVersionsScreen(module: 'tasks', id: 't1'),
        extraRoutes: [
          GoRoute(path: '/approvals/:id', builder: (_, _) => const Text('A')),
        ],
      );
      expect(find.byKey(const Key('version-restore-3')), findsNothing);
      await tester.tap(find.byKey(const Key('version-restore-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      final req = h.transport
          .sent('POST tasks/t1/actions/restore-version')
          .single;
      expect(req.jsonBody, {'version': 2});
      expect(req.headers['Idempotency-Key'], isNotEmpty);
      expect(find.text('استُعيدت النسخة 2'), findsOneWidget);
    });

    testWidgets('مرفق التعليق: الصورة تُعرض من الذاكرة عبر مسار الخادم', (
      tester,
    ) async {
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      );
      h.transport.onData('GET comments', {
        'comments': [
          {
            'id': 'c1',
            'user': {'id': 'u-2', 'name': 'سارة'},
            'body': 'الصورة',
            'has_attachment': true,
            'attachment': {
              'id': 'c1',
              'name': 'site.png',
              'size': 70,
              'mime': 'image/png',
              'download': '/api/mobile/v1/comments/c1/attachment',
            },
            'replies': <dynamic>[],
          },
        ],
      });
      h.transport.on(
        'GET comments/c1/attachment',
        (_) => http.Response.bytes(
          png,
          200,
          headers: {'content-type': 'image/png'},
        ),
      );
      await pumpScreen(
        tester,
        h,
        const Scaffold(
          body: CommentsPanel(module: 'tasks', recordId: 't1'),
        ),
      );
      final before = h.tempDir.listSync(recursive: true).length;
      await tester.tap(find.byKey(const Key('comment-attachment-c1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attachment-image')), findsOneWidget);
      expect(h.transport.sent('GET comments/c1/attachment'), hasLength(1));
      expect(
        h.tempDir.listSync(recursive: true).length,
        before,
        reason: 'لا شيء يهبط القرص',
      );
    });
  });
}
