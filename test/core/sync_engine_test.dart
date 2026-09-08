/// اختبارات المزامنة (§110) — مؤشر، شواهد حذف، عزل سياق، سياسة حساسة، إعادة كاملة.
library;

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;

  setUp(() async {
    h = TestHarness.create();
    await h.seedSession();
    h.container.account.user = null;
  });

  tearDown(() => h.dispose());

  Map<String, dynamic> syncPage({
    List<Map<String, dynamic>> records = const [],
    List<Map<String, dynamic>> tombstones = const [],
    String? nextCursor,
    bool hasMore = false,
    String syncVersion = 'v1',
    String syncClass = 'CACHEABLE_INCREMENTAL',
    bool cacheable = true,
  }) => {
    'module': 'tasks',
    'sync_class': syncClass,
    'cacheable': cacheable,
    'conflict_token': true,
    'records': records,
    'tombstones': tombstones,
    'has_tombstones': true,
    'next_cursor': nextCursor,
    'has_more': hasMore,
    'sync_version': syncVersion,
    'server_time': DateTime.now().toUtc().toIso8601String(),
  };

  test('مزامنة تزايدية بمؤشر: صفحتان بلا فقد، والمؤشر يثبت', () async {
    var call = 0;
    h.transport.on('GET sync/tasks', (req) {
      call++;
      if (call == 1) {
        expect(req.url.queryParameters.containsKey('cursor'), isFalse);
        return okData(
          syncPage(
            records: [
              {'id': 'a', 'title': 'أولى', 'version': 1},
              {'id': 'b', 'title': 'ثانية', 'version': 2},
            ],
            nextCursor: 'cur-1',
            hasMore: true,
          ),
        );
      }
      expect(req.url.queryParameters['cursor'], 'cur-1');
      return okData(
        syncPage(
          records: [
            {'id': 'c', 'title': 'ثالثة', 'version': 1},
          ],
          nextCursor: 'cur-2',
        ),
      );
    });

    final result = await h.container.sync.syncModule('tasks');
    expect(result.cacheable, isTrue);
    expect(result.recordCount, 3);

    final cached = await h.container.sync.readCached('tasks');
    expect(cached!.records.map((r) => r['id']), containsAll(['a', 'b', 'c']));
    expect(cached.conflictToken, isTrue);
  });

  test('شواهد الحذف تسقط السجل من الخبيئة (§65)', () async {
    var call = 0;
    h.transport.on('GET sync/tasks', (_) {
      call++;
      return call == 1
          ? okData(
              syncPage(
                records: [
                  {'id': 'a', 'title': 'حية', 'version': 1},
                  {'id': 'b', 'title': 'ستحذف', 'version': 1},
                ],
                nextCursor: 'c1',
              ),
            )
          : okData(
              syncPage(
                tombstones: [
                  {'id': 'b', 'deleted_at': '2026-09-08T00:00:00Z'},
                ],
                nextCursor: 'c2',
              ),
            );
    });

    await h.container.sync.syncModule('tasks');
    await h.container.sync.syncModule('tasks');

    final cached = await h.container.sync.readCached('tasks');
    expect(cached!.records.map((r) => r['id']), ['a']);
  });

  test('تغير sync_version ⇒ إعادة مزامنة كاملة من الصفر (§61)', () async {
    var call = 0;
    h.transport.on('GET sync/tasks', (req) {
      call++;
      if (call == 1) {
        return okData(
          syncPage(
            records: [
              {'id': 'old', 'title': 'قديمة', 'version': 1},
            ],
            nextCursor: 'c1',
          ),
        );
      }
      // النسخة تغيرت — الرد الأول بالنسخة الجديدة، ثم صفحة البداية
      if (req.url.queryParameters.containsKey('cursor') && call == 2) {
        return okData(
          syncPage(
            syncVersion: 'v2',
            records: [
              {'id': 'ignored', 'title': 'x', 'version': 1},
            ],
          ),
        );
      }
      return okData(
        syncPage(
          syncVersion: 'v2',
          records: [
            {'id': 'fresh', 'title': 'جديدة', 'version': 1},
          ],
        ),
      );
    });

    await h.container.sync.syncModule('tasks');
    final second = await h.container.sync.syncModule('tasks');

    expect(second.fullResync, isTrue);
    final cached = await h.container.sync.readCached('tasks');
    expect(cached!.records.map((r) => r['id']), [
      'fresh',
    ], reason: 'السجلات القديمة صفّرت مع النسخة الجديدة');
  });

  test('SENSITIVE_NO_PERSIST: لا سجل يبث ولا أثر يبقى (§62 §111)', () async {
    // أولاً وحدة كانت مخبأة ثم صارت حساسة — البقايا تمحى.
    h.transport.on(
      'GET sync/vault',
      (_) => okData(
        syncPage(
          syncClass: 'SENSITIVE_NO_PERSIST',
          cacheable: false,
          records: [],
        ),
      ),
    );

    final result = await h.container.sync.syncModule('vault');
    expect(result.cacheable, isFalse);
    expect(result.syncClass, 'SENSITIVE_NO_PERSIST');
    expect(
      await h.container.cache.existsOnDisk('sync_u_-_c_-_k_-_vault'),
      isFalse,
    );
    expect(await h.container.sync.readCached('vault'), isNull);
  });

  test('عزل السياق: مؤشر شركة لا يخدم أخرى (§64 §107)', () async {
    h.transport.on('GET sync/tasks', (req) {
      final company = req.headers['X-Lynomia-Company'];
      return okData(
        syncPage(
          records: [
            {'id': 'rec-${company ?? 'all'}', 'title': 'x', 'version': 1},
          ],
        ),
      );
    });

    h.container.viewContext.setCompany('A');
    await h.container.sync.syncModule('tasks');
    h.container.viewContext.setCompany('B');
    await h.container.sync.syncModule('tasks');

    final cachedB = await h.container.sync.readCached('tasks');
    expect(cachedB!.records.single['id'], 'rec-B');

    h.container.viewContext.setCompany('A');
    final cachedA = await h.container.sync.readCached('tasks');
    expect(
      cachedA!.records.single['id'],
      'rec-A',
      reason: 'كل سياق بخبيئته — لا تسرب عبر الشركات',
    );
  });
}
