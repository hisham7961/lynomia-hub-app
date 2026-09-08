/// الإشعارات والرسائل والتعليقات والاعتمادات والبحث (§112–§115).
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';
import 'package:lynomia_hub_app/features/tracking/tracking_repository.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
  });

  tearDown(() => h.dispose());

  group('الإشعارات (§113)', () {
    test('قائمة بمؤشر وعد غير المقروء', () async {
      h.transport.on('GET notifications', (req) {
        expect(req.url.queryParameters['per'], '25');
        return okData({
          'notifications': [
            {
              'id': 'n1',
              'kind': 'approval',
              'text': 'طلب موافقة جديد',
              'read': false,
              'target': {'module': 'approvals', 'id': 'ap-1', 'action': 'show'},
              'created_at': '2026-09-08T10:00:00Z',
            },
          ],
          'unread': 3,
          'cursor': {'next': 'cur-x', 'has_more': true, 'per': 25},
        });
      });

      final page = await h.container.notifications.list();
      expect(page.items.single.target!.module, 'approvals');
      expect(page.unread, 3);
      expect(page.nextCursor, 'cur-x');
      expect(page.hasMore, isTrue);
    });

    test('النقر يختم القراءة ويعيد الوجهة القانونية (§51)', () async {
      h.transport.onData('POST notifications/n1/read', {
        'id': 'n1',
        'read': true,
        'unread': 2,
        'target': {'module': 'tickets', 'id': 'tk-5', 'action': 'show'},
      });
      final target = await h.container.notifications.markRead('n1');
      expect(target!.routePath, '/r/tickets/tk-5');
    });

    test('target=null يعاد null — يبقى في القائمة لا انهيار', () async {
      h.transport.onData('POST notifications/n2/read', {
        'id': 'n2',
        'read': true,
        'unread': 1,
        'target': null,
      });
      expect(await h.container.notifications.markRead('n2'), isNull);
    });

    test('قراءة الكل', () async {
      h.transport.onData('POST notifications/read-all', {
        'marked': 7,
        'unread': 0,
      });
      expect(await h.container.notifications.markAllRead(), 7);
    });
  });

  group('الرسائل المباشرة (§114)', () {
    test('الخيوط والرسائل والإرسال idempotent (§52)', () async {
      h.transport.onData('GET dm/threads', {
        'threads': [
          {
            'user': {'id': 'u-2', 'name': 'زميل'},
            'unread': 2,
            'last': {
              'id': 'm9',
              'mine': false,
              'excerpt': 'مرحباً',
              'read': false,
              'created_at': '2026-09-08T09:00:00Z',
            },
          },
        ],
        'unread_total': 2,
      });
      final threads = await h.container.dm.threads();
      expect(threads.threads.single.userName, 'زميل');
      expect(threads.unreadTotal, 2);

      h.transport.onData('GET dm/threads/u-2/messages', {
        'user': {'id': 'u-2', 'name': 'زميل'},
        'messages': [
          {
            'id': 'm1',
            'from_id': 'u-2',
            'to_id': 'u-1',
            'mine': false,
            'body': 'أهلاً',
            'read': true,
            'created_at': '2026-09-08T08:00:00Z',
          },
        ],
      });
      final msgs = await h.container.dm.messages('u-2');
      expect(msgs.single.body, 'أهلاً');

      h.transport.on('POST dm/threads/u-2/send', (req) {
        expect(req.headers['Idempotency-Key'], isNotEmpty);
        return okData({
          'message': {
            'id': 'm2',
            'from_id': 'u-1',
            'to_id': 'u-2',
            'mine': true,
            'body': req.jsonBody['body'],
            'read': false,
            'created_at': '2026-09-08T10:00:00Z',
          },
        });
      });
      final sent = await h.container.dm.send('u-2', 'رد سريع');
      expect(sent.mine, isTrue);
      expect(sent.body, 'رد سريع');

      h.transport.onData('POST dm/threads/u-2/read', {
        'user': {'id': 'u-2'},
        'marked': 2,
        'unread_total': 0,
      });
      expect(await h.container.dm.markRead('u-2'), 2);
    });

    test('محادثة خارج النطاق: 404 بلا كشف وجود (§52)', () async {
      h.transport.on(
        'GET dm/threads/ghost/messages',
        (_) => apiError('RESOURCE_NOT_FOUND', 404),
      );
      await expectLater(
        h.container.dm.messages('ghost'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.resourceNotFound,
          ),
        ),
      );
    });
  });

  group('التعليقات (§114)', () {
    test('خيط بردود وتفاعلات، ونشر برد ومنشن (§53)', () async {
      h.transport.on('GET comments', (req) {
        expect(req.url.queryParameters['module'], 'tasks');
        expect(req.url.queryParameters['record'], 't1');
        return okData({
          'module': 'tasks',
          'record': 't1',
          'comments': [
            {
              'id': 'c1',
              'parent_id': null,
              'user': {'id': 'u-2', 'name': 'زميل'},
              'body': 'ملاحظة',
              'mentions': ['u-1'],
              'internal': false,
              'pinned': true,
              'resolved': false,
              'has_attachment': false,
              'reactions': [
                {'emoji': '👍', 'count': 2, 'mine': true},
              ],
              'created_at': '2026-09-08T08:00:00Z',
              'replies': [
                {
                  'id': 'c2',
                  'parent_id': 'c1',
                  'user': {'id': 'u-1', 'name': 'أنا'},
                  'body': 'رد',
                  'reactions': <dynamic>[],
                  'replies': <dynamic>[],
                },
              ],
            },
          ],
        });
      });

      final comments = await h.container.comments.forRecord('tasks', 't1');
      expect(comments.single.pinned, isTrue);
      expect(comments.single.reactions.single.mine, isTrue);
      expect(comments.single.replies.single.body, 'رد');

      h.transport.on('POST comments', (req) {
        expect(req.jsonBody['module'], 'tasks');
        expect(req.jsonBody['record'], 't1');
        expect(req.jsonBody['parent_id'], 'c1');
        expect(req.jsonBody['mention'], ['u-2']);
        expect(req.headers['Idempotency-Key'], isNotEmpty);
        return okData({
          'comment': {
            'id': 'c3',
            'parent_id': 'c1',
            'user': {'id': 'u-1', 'name': 'أنا'},
            'body': req.jsonBody['body'],
          },
        });
      });
      final posted = await h.container.comments.post(
        module: 'tasks',
        recordId: 't1',
        body: 'رد جديد',
        parentId: 'c1',
        mentions: ['u-2'],
      );
      expect(posted.body, 'رد جديد');
    });
  });

  group('الاعتمادات (§115)', () {
    test('الطابور والحسم idempotent والتقادم مكتوب (§54)', () async {
      h.transport.on(
        'GET approvals',
        (_) => okList([
          {
            'id': 'ap-1',
            'title': 'تعديل مبلغ عقد',
            'type': 'تعديل',
            'status': 'معلّق',
            'op': 'e',
            'amount': '1500.500',
            'currency': 'KWD',
            'due': '2026-09-10',
            'target': {'module': 'contracts', 'id': 'ct-1'},
            'record_version': '4',
            'created_at': '2026-09-08T07:00:00Z',
          },
        ]),
      );
      final page = await h.container.approvals.pending();
      expect(page.items.single.amount, '1500.500');
      expect(page.items.single.target!.module, 'contracts');

      h.transport.on('POST approvals/ap-1/approve', (req) {
        expect(req.headers['Idempotency-Key'], 'dec-1');
        return okData({
          'code': 'approved',
          'message': 'اعتُمد',
          'approval': {'id': 'ap-1', 'status': 'معتمد'},
        });
      });
      final decision = await h.container.approvals.decide(
        'ap-1',
        approve: true,
        idempotencyKey: 'dec-1',
      );
      expect(decision.status, 'معتمد');

      h.transport.on('POST approvals/ap-2/reject', (req) {
        expect(req.jsonBody['note'], 'مبلغ خاطئ');
        return apiError('VERSION_CONFLICT', 409, message: 'الطلب تقادم');
      });
      await expectLater(
        h.container.approvals.decide('ap-2', approve: false, note: 'مبلغ خاطئ'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.versionConflict,
          ),
        ),
      );
    });
  });

  group('البحث (§112)', () {
    test('نتائج بوجهات ومعامل q', () async {
      h.transport.on('GET search', (req) {
        expect(req.url.queryParameters['q'], 'عقد');
        return okData({
          'q': 'عقد',
          'results': [
            {
              'module': 'contracts',
              'id': 'ct-1',
              'name': 'عقد صيانة',
              'label': 'العقود',
            },
          ],
          'count': 1,
        });
      });
      final hits = await h.container.search.search('عقد');
      expect(hits.single.target.routePath, '/r/contracts/ct-1');
      expect(hits.single.label, 'العقود');
    });
  });

  group('الملفات (§116)', () {
    test('جلسة ← قطع مفهرسة ← إتمام idempotent (§67)', () async {
      h.transport.on('POST files/upload-session', (req) {
        expect(req.jsonBody['module'], 'tasks');
        expect(req.jsonBody['record_id'], 't1');
        expect(req.jsonBody['size'], 10);
        return okData({
          'token': 'up-1',
          'chunk_size': 4,
          'max_parts': 4096,
          'max_bytes': 999999,
        });
      });
      final session = await h.container.files.startUploadSession(
        module: 'tasks',
        recordId: 't1',
        filename: 'doc.pdf',
        mime: 'application/pdf',
        size: 10,
      );
      expect(session.token, 'up-1');

      h.transport.on('PUT files/upload-session/up-1/chunk', (req) {
        expect(req.headers['Content-Type'], contains('octet-stream'));
        return okData({'i': req.url.queryParameters['i']});
      });
      await h.container.files.uploadChunk(
        session.token,
        0,
        Uint8List.fromList([1, 2, 3, 4]),
      );

      h.transport.on('POST files/upload-session/up-1/complete', (req) {
        expect(req.headers['Idempotency-Key'], 'up-key');
        expect(req.jsonBody['parts'], 1);
        return okData({
          'attachments': [
            {
              'id': 'att-1',
              'name': 'doc.pdf',
              'size': 10,
              'download': '/api/mobile/v1/files/att-1/download',
            },
          ],
        });
      });
      final attachments = await h.container.files.completeUpload(
        session.token,
        parts: 1,
        idempotencyKey: 'up-key',
      );
      expect(attachments.single.id, 'att-1');
      expect(
        attachments.single.downloadPath,
        contains('/files/att-1/download'),
      );
    });
  });

  group('الماسح (§117)', () {
    test('الحل خادمي: كيان مخول أو 404', () async {
      h.transport.onData('GET identity/resolve/ABC-123', {
        'module': 'assets',
        'id': 'as-1',
        'action': 'show',
      });
      final target = await h.container.identity.resolve('ABC-123');
      expect(target!.routePath, '/r/assets/as-1');

      h.transport.on(
        'GET identity/resolve/GHOST',
        (_) => apiError('RESOURCE_NOT_FOUND', 404),
      );
      await expectLater(
        h.container.identity.resolve('GHOST'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('التتبع (§118)', () {
    test('بدء بموافقة صريحة ودفعات idempotent وإنهاء (§71)', () async {
      h.transport.on('POST tracking/start', (req) {
        expect(req.jsonBody['consent'], true, reason: 'لا تتبع بلا إقرار');
        return okData({'session': 'trk-1'});
      });
      final id = await h.container.tracking.start();
      expect(id, 'trk-1');

      h.transport.on('POST tracking/trk-1/points', (req) {
        expect(req.headers['Idempotency-Key'], 'batch-1');
        expect((req.jsonBody['points'] as List), hasLength(2));
        return okData({'accepted': 2});
      });
      await h.container.tracking.sendPoints('trk-1', [
        for (var i = 0; i < 2; i++)
          TrackPoint(
            lat: 29.3 + i / 100,
            lng: 47.9,
            at: DateTime.utc(2026, 9, 8, 10, 0, i),
            seq: i,
          ),
      ], idempotencyKey: 'batch-1');

      h.transport.onData('POST tracking/trk-1/end', {'ended': true});
      await h.container.tracking.end('trk-1');
    });
  });
}
