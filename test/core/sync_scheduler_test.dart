/// تشغيل المزامنة في الإنتاج (المرحلة ١.٢ · §60–§62): المخطط يقرر — لا طلب
/// `sync/{module}` ولا أثر على القرص إلا لصنف `CACHEABLE_*`، والحساس يُمحى،
/// والخروج يطهّر، والدورات مقيّدة التواتر.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/sync/sync_engine.dart';
import 'package:lynomia_hub_app/features/modules/module_schema.dart';
import 'package:lynomia_hub_app/features/modules/sync_scheduler.dart';

import '../fakes/fakes.dart';

/// مخطط بثلاث وحدات: قابلة للتخبئة، وحساسة، وحيّة فقط.
Map<String, dynamic> mixedSchema() => {
  'schema_version': 'v-mixed',
  'modules': [
    {
      'key': 'tasks',
      'label': 'المهام',
      'sync_class': 'CACHEABLE_INCREMENTAL',
      'can': {'v': true},
      'fields': [
        {'key': 'title', 'label': 'العنوان', 'type': 'text'},
      ],
    },
    {
      'key': 'vault',
      'label': 'الخزنة',
      'sync_class': 'SENSITIVE_NO_PERSIST',
      'can': {'v': true},
      'fields': [
        {'key': 'name', 'label': 'الاسم', 'type': 'text'},
      ],
    },
    {
      'key': 'live',
      'label': 'حيّة',
      'sync_class': 'ONLINE_ONLY',
      'can': {'v': true},
      'fields': [
        {'key': 'name', 'label': 'الاسم', 'type': 'text'},
      ],
    },
  ],
};

/// شجرة IA تجعل الوحدات الثلاث وجهاتٍ أساسيةً مناسبةً للجوال.
Map<String, dynamic> bootstrapWithModules(List<String> modules) {
  final b = bootstrapPayload();
  b['ia'] = {
    'surfaces': <Map<String, dynamic>>[],
    'domains': [
      {
        'key': 'work',
        'label': 'العمل',
        'plane': 'work',
        'sections': [
          {
            'key': 's',
            'label': 'قسم',
            'destinations': [
              for (final m in modules)
                {
                  'label': m,
                  'type': 'module',
                  'importance': 'primary',
                  'mobile': 'suitable',
                  'module': m,
                },
            ],
          },
        ],
      },
    ],
  };
  return b;
}

Map<String, dynamic> syncOk(
  String module, {
  String cls = 'CACHEABLE_INCREMENTAL',
}) => {
  'module': module,
  'sync_class': cls,
  'cacheable': true,
  'conflict_token': true,
  'records': [
    {'id': '$module-1', 'title': 'سجل $module', 'version': 1},
  ],
  'tombstones': <dynamic>[],
  'has_tombstones': true,
  'next_cursor': 'c1',
  'has_more': false,
  'sync_version': 'v1',
};

Future<List<String>> cacheFiles(TestHarness h) async {
  final dir = Directory('${h.tempDir.path}/cache');
  if (!dir.existsSync()) return const [];
  return dir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .toList();
}

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
    h.transport.onData('GET schema', mixedSchema());
    h.transport.onData(
      'GET bootstrap',
      bootstrapWithModules(['tasks', 'vault', 'live']),
    );
    await h.container.account.loadBootstrap();
    h.transport.onData('GET sync/tasks', syncOk('tasks'));
    // لو طُلبت الحساسة لأعادت سجلاتٍ — الاختبار يثبت أنها لا تُطلب أصلاً.
    h.transport.onData('GET sync/vault', syncOk('vault'));
    h.transport.onData('GET sync/live', syncOk('live'));
  });

  tearDown(() => h.dispose());

  test('الخلفية: تُطلب القابلة للتخبئة وحدها ويمتلئ قرصها المشفّر', () async {
    await h.container.syncScheduler.syncBackground();

    expect(h.transport.sent('GET sync/tasks'), hasLength(1));
    expect(h.transport.sent('GET sync/vault'), isEmpty);
    expect(h.transport.sent('GET sync/live'), isEmpty);

    expect(await h.container.sync.hasDiskTrace('tasks'), isTrue);
    expect(await h.container.sync.hasDiskTrace('vault'), isFalse);
    expect(await h.container.sync.hasDiskTrace('live'), isFalse);
    final cached = await h.container.sync.readCached('tasks');
    expect(cached!.records.single['title'], 'سجل tasks');

    // لا ملف على القرص يخص غير tasks.
    final files = await cacheFiles(h);
    expect(files, hasLength(1));
    expect(files.single, contains('tasks'));
  });

  test(
    'الحساس لا يهبط القرص ولو ادّعى الخادم cacheable (دفاع في العمق)',
    () async {
      h.transport.onData(
        'GET sync/vault',
        syncOk('vault', cls: 'SENSITIVE_NO_PERSIST'),
      );
      final r = await h.container.sync.syncModule('vault');
      expect(r.cacheable, isFalse);
      expect(await h.container.sync.hasDiskTrace('vault'), isFalse);
      expect(await cacheFiles(h), isEmpty);
    },
  );

  test('فتح وحدة حساسة: لا طلب مزامنة، وأثرها القديم يُمحى', () async {
    // أثر قديم (يوم كانت الوحدة قابلة للتخبئة) في مساحة السياق نفسها.
    h.transport.onData('GET sync/vault', syncOk('vault'));
    await h.container.sync.syncModule('vault');
    expect(await h.container.sync.hasDiskTrace('vault'), isTrue);
    h.transport.requests.clear();

    final snapshot = await h.container.modules.schema();
    await h.container.syncScheduler.syncOnOpen(
      'vault',
      snapshot.modules['vault'],
    );
    expect(h.transport.sent('GET sync/vault'), isEmpty);
    expect(await h.container.sync.hasDiskTrace('vault'), isFalse);

    await h.container.syncScheduler.syncOnOpen(
      'live',
      snapshot.modules['live'],
    );
    expect(h.transport.sent('GET sync/live'), isEmpty);
  });

  test(
    'فتح وحدة قابلة: مزامنة واحدة ضمن المهلة، وتُحفظ في المفتوحة مؤخراً',
    () async {
      final snapshot = await h.container.modules.schema();
      final tasks = snapshot.modules['tasks'];
      await h.container.syncScheduler.syncOnOpen('tasks', tasks);
      await h.container.syncScheduler.syncOnOpen('tasks', tasks);
      expect(h.transport.sent('GET sync/tasks'), hasLength(1));
      expect(h.container.syncScheduler.recentModules, ['tasks']);
    },
  );

  test('دورة الخلفية مقيّدة التواتر وبلا تداخل', () async {
    var clock = DateTime(2026, 9, 27, 10);
    final scheduler = SyncScheduler(
      engine: h.container.sync,
      modules: h.container.modules,
      iaOf: () => h.container.account.ia,
      now: () => clock,
    );
    await Future.wait([scheduler.syncBackground(), scheduler.syncBackground()]);
    expect(h.transport.sent('GET sync/tasks'), hasLength(1));

    clock = clock.add(const Duration(minutes: 1));
    await scheduler.syncBackground();
    expect(h.transport.sent('GET sync/tasks'), hasLength(1));

    clock = clock.add(const Duration(minutes: 10));
    await scheduler.syncBackground();
    expect(h.transport.sent('GET sync/tasks'), hasLength(2));
  });

  test('الخروج يطهّر خبيئة المستخدم كلها (§39)', () async {
    h.transport.onData('POST auth/logout', {'revoked': true});
    await h.container.syncScheduler.syncBackground();
    expect(await cacheFiles(h), isNotEmpty);

    await h.container.signOut();
    expect(await cacheFiles(h), isEmpty);
    expect(h.container.syncScheduler.recentModules, isEmpty);
  });

  test('isCacheableClass: CACHEABLE_* فقط', () {
    expect(isCacheableClass('CACHEABLE_INCREMENTAL'), isTrue);
    expect(isCacheableClass('CACHEABLE_SNAPSHOT'), isTrue);
    expect(isCacheableClass('SENSITIVE_NO_PERSIST'), isFalse);
    expect(isCacheableClass('ONLINE_ONLY'), isFalse);
    expect(isCacheableClass('NOT_APPLICABLE'), isFalse);
    expect(
      const ModuleSchema(
        key: 'x',
        label: 'x',
        syncClass: 'ONLINE_ONLY',
        can: ModuleCan(),
        fields: [],
      ).cacheable,
      isFalse,
    );
  });

  test('حساب العميل: لا مزامنة خلفية (البوابة عالمٌ حيّ)', () async {
    final b = bootstrapWithModules(['tasks']);
    (b['user'] as Map)['account_type'] = 'client';
    h.transport.onData('GET bootstrap', b);
    await h.container.account.loadBootstrap(force: true);
    expect(h.container.account.isClient, isTrue);
    h.transport.onData('GET notifications/unread-count', {'unread': 4});

    await h.container.resume.onReady();
    expect(
      h.transport.requests.where((r) => r.apiPath.startsWith('sync/')),
      isEmpty,
    );
    expect(h.container.account.unreadNotifications, 4);
  });

  test('الحساب الداخلي عند الجاهزية: شارة حية + مزامنة القابل وحده', () async {
    h.transport.onData('GET notifications/unread-count', {'unread': 7});
    await h.container.resume.onReady();
    expect(h.container.account.unreadNotifications, 7);
    expect(h.transport.sent('GET sync/tasks'), hasLength(1));
    expect(h.transport.sent('GET sync/vault'), isEmpty);
    expect(h.transport.sent('GET sync/live'), isEmpty);
  });
}
