/// محرك الوحدات العام (§108) — مخطط، قوائم، CRUD، تعارض نسخة، إجراءات، 422.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
  });

  tearDown(() => h.dispose());

  test('المخطط يفكك كل أنواع الحقول والقدرات وتصنيف المزامنة (§20)', () async {
    h.transport.onData('GET schema', schemaPayload());

    final snapshot = await h.container.modules.schema();
    final tasks = snapshot.modules['tasks']!;

    expect(snapshot.version, 'abc123');
    expect(tasks.label, 'المهام');
    expect(tasks.syncClass, 'CACHEABLE_INCREMENTAL');
    expect(tasks.can.e, isTrue);
    expect(tasks.fields.map((f) => f.type).toSet(), {
      'text',
      'ta',
      'num',
      'date',
      'dt',
      'bool',
      'sel',
      'ref',
      'tags',
      'url',
      'file',
      'img',
      'sec',
    }, reason: 'التغطية الكاملة للأنواع المبثوثة — لا نوع مطلوب مجهول (§20)');
    expect(tasks.field('api_key')!.readonly, isTrue);
    expect(tasks.field('status')!.options, ['جديدة', 'جارية', 'منجزة']);
    expect(tasks.field('project_id')!.ref, 'projects');
  });

  test('القائمة تمرر البحث والفرز والترقيم (§19)', () async {
    h.transport.on('GET tasks', (req) {
      expect(req.url.queryParameters['q'], 'عاجل');
      expect(req.url.queryParameters['sort'], '-due');
      expect(req.url.queryParameters['page'], '2');
      expect(req.url.queryParameters['per'], '25');
      return okList(
        [
          {'id': 't1', 'title': 'مهمة', 'version': 3},
        ],
        total: 51,
        page: 2,
        lastPage: 3,
        hasMore: true,
      );
    });

    final page = await h.container.modules.list(
      'tasks',
      page: 2,
      q: 'عاجل',
      sort: '-due',
    );
    expect(page.items.single.id, 't1');
    expect(page.items.single.version, 3);
    expect(page.hasMore, isTrue);
    expect(page.total, 51);
  });

  test('الإنشاء يحمل Idempotency-Key ثابتاً (§58)', () async {
    h.transport.onData('POST tasks', {'id': 't-new', 'title': 'جديدة'});
    await h.container.modules.create('tasks', {
      'title': 'جديدة',
    }, idempotencyKey: 'create-1');
    expect(
      h.transport.sent('POST tasks').single.headers['Idempotency-Key'],
      'create-1',
    );
  });

  test('التعديل يبث If-Match وتعارضه مكتوب بنسخة الخادم (§57)', () async {
    h.transport.on(
      'PUT tasks/t1',
      (_) => apiError(
        'VERSION_CONFLICT',
        409,
        details: {'current_version': 7, 'your_version': 3},
      ),
    );

    try {
      await h.container.modules.update('tasks', 't1', {
        'title': 'معدلة',
      }, ifMatchVersion: 3);
      fail('كان يجب أن يرمي');
    } on ApiException catch (e) {
      expect(e.code, ApiErrorCode.versionConflict);
      expect(e.serverVersion, 7);
    }
    expect(h.transport.sent('PUT tasks/t1').single.headers['If-Match'], '"3"');
  });

  test('422: أخطاء الحقول تفكك للحقل المعني (§96)', () async {
    h.transport.on(
      'POST tasks',
      (_) => apiError(
        'VALIDATION_FAILED',
        422,
        details: {
          'errors': {
            'title': ['العنوان مطلوب'],
            'due': ['تاريخ غير صالح'],
          },
        },
      ),
    );
    try {
      await h.container.modules.create('tasks', {});
      fail('كان يجب أن يرمي');
    } on ApiException catch (e) {
      expect(e.fieldErrors['title'], ['العنوان مطلوب']);
      expect(e.fieldErrors['due'], ['تاريخ غير صالح']);
    }
  });

  test('الإجراءات: يعرض ما يعيده الخادم فقط وينفذ بمساره (§55)', () async {
    h.transport.onData('GET tasks/t1/actions', {
      'module': 'tasks',
      'id': 't1',
      'status': 'جديدة',
      'trashed': false,
      'version': 4,
      'actions': [
        {
          'action': 'status',
          'to': 'جارية',
          'label': 'نقل الحالة إلى: جارية',
          'requires_approval': false,
        },
        {'action': 'ack', 'label': 'إقرار'},
      ],
    });

    final envelope = await h.container.modules.actions('tasks', 't1');
    expect(envelope.actions, hasLength(2));
    expect(envelope.version, 4);

    h.transport.on('POST tasks/t1/actions/status', (req) {
      expect(req.jsonBody['to'], 'جارية');
      expect(req.headers['Idempotency-Key'], isNotEmpty);
      return okData({
        'module': 'tasks',
        'id': 't1',
        'changed': true,
        'status': 'جارية',
      });
    });
    final result = await h.container.modules.runAction(
      'tasks',
      't1',
      envelope.actions.first,
    );
    expect(result['changed'], true);
  });

  test('كتابة محمية بموافقة: APPROVAL_REQUIRED بوجهة الطلب (§54)', () async {
    h.transport.on(
      'PATCH tasks/t1',
      (_) => apiError(
        'APPROVAL_REQUIRED',
        202,
        details: {
          'approval': {'module': 'approvals', 'id': 'ap-9'},
        },
      ),
    );
    try {
      await h.container.modules.patch('tasks', 't1', {
        'status': 'منجزة',
      }, ifMatchVersion: 4);
      fail('كان يجب أن يرمي مكتوباً');
    } on ApiException catch (e) {
      expect(e.code, ApiErrorCode.approvalRequired);
      expect(e.approvalTarget?['id'], 'ap-9');
    }
  });

  test('الحذف يمرر ويستدعي DELETE', () async {
    h.transport.onData('DELETE tasks/t1', {'deleted': true});
    await h.container.modules.destroy('tasks', 't1', ifMatchVersion: 2);
    expect(
      h.transport.sent('DELETE tasks/t1').single.headers['If-Match'],
      '"2"',
    );
  });
}
