/// محرك المزامنة التزايدية (§60–§66) — يطيع `sync_class` الخادمي ولا يتجاوزه.
///
/// لكل وحدة قابلة للتخبئة: مؤشر keyset معتم + سجلات بنسخها + شواهد حذف،
/// معزولة بنيوياً بمفتاح `(user, company, client, module)` — مؤشر شركة لا
/// يخدم أخرى أبداً (§64). تغير `sync_version` ⇒ إعادة مزامنة كاملة من الصفر.
/// `SENSITIVE_NO_PERSIST`/`ONLINE_ONLY`/`NOT_APPLICABLE` لا تُكتب إطلاقاً —
/// وتُمحى بقاياها إن وُجدت (ترقية تصنيف خادمية).
library;

import '../api/api_client.dart';
import '../api/view_context.dart';
import '../storage/encrypted_cache.dart';

class SyncResult {
  const SyncResult({
    required this.module,
    required this.syncClass,
    required this.cacheable,
    this.recordCount = 0,
    this.fullResync = false,
  });

  final String module;
  final String syncClass;
  final bool cacheable;
  final int recordCount;
  final bool fullResync;
}

class SyncEngine {
  SyncEngine({
    required this.api,
    required this.cache,
    required this.viewContext,
    required this.userIdOf,
  });

  final ApiClient api;
  final EncryptedJsonCache cache;
  final ViewContext viewContext;

  /// هوية المستخدم الحالية — تدخل مفتاح العزل (§64).
  final String Function() userIdOf;

  String _ns(String module) =>
      'sync_u_${userIdOf()}_${viewContext.cacheKey}_$module';

  /// مزامنة وحدة واحدة حتى نفاد الصفحات (أو أول صفحة فقط عند [singlePage]).
  Future<SyncResult> syncModule(
    String module, {
    bool singlePage = false,
  }) async {
    var state = await cache.read(_ns(module)) ?? <String, dynamic>{};
    var cursor = state['cursor'] as String?;
    var storedVersion = state['sync_version'] as String?;
    var records = (state['records'] as Map?)?.cast<String, dynamic>() ?? {};
    var fullResync = false;
    var syncClass = 'ONLINE_ONLY';

    while (true) {
      final data = await api.getData(
        'sync/$module',
        query: {'cursor': ?cursor},
      );
      syncClass = data['sync_class']?.toString() ?? 'ONLINE_ONLY';

      if (data['cacheable'] != true) {
        // سياسة صادقة بلا سجلات — ولا أثر قديماً على القرص (§61 §62).
        await cache.delete(_ns(module));
        return SyncResult(
          module: module,
          syncClass: syncClass,
          cacheable: false,
        );
      }

      final serverVersion = data['sync_version']?.toString();
      if (storedVersion != null && serverVersion != storedVersion) {
        // المخطط تبدل ⇒ إعادة كاملة من الصفر (§61).
        records = {};
        cursor = null;
        storedVersion = serverVersion;
        fullResync = true;
        continue;
      }
      storedVersion = serverVersion;

      for (final rec in (data['records'] as List? ?? const [])) {
        if (rec is Map) {
          final id = rec['id']?.toString();
          if (id != null) records[id] = rec.cast<String, dynamic>();
        }
      }
      for (final tomb in (data['tombstones'] as List? ?? const [])) {
        if (tomb is Map) records.remove(tomb['id']?.toString()); // §65
      }

      cursor = data['next_cursor']?.toString();
      state = {
        'cursor': cursor,
        'sync_version': storedVersion,
        'conflict_token': data['conflict_token'] == true,
        'has_tombstones': data['has_tombstones'] == true,
        'records': records,
        'synced_at': DateTime.now().toUtc().toIso8601String(),
      };
      await cache.write(_ns(module), state, syncClass: syncClass);

      if (data['has_more'] != true || singlePage) {
        return SyncResult(
          module: module,
          syncClass: syncClass,
          cacheable: true,
          recordCount: records.length,
          fullResync: fullResync,
        );
      }
    }
  }

  /// قراءة اللقطة المخبأة (قد تكون بائتة — تُعلَّم واجهةً بحالتها §83).
  Future<CachedModule?> readCached(String module) async {
    final state = await cache.read(_ns(module));
    if (state == null) return null;
    return CachedModule(
      records: ((state['records'] as Map?)?.values ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      syncedAt: DateTime.tryParse(state['synced_at']?.toString() ?? ''),
      conflictToken: state['conflict_token'] == true,
    );
  }

  /// إسقاط خبيئة السياق الحالي كله (تبديل سياق §43 أو خروج §39).
  Future<void> purgeCurrentUser() =>
      cache.deleteByPrefix('sync_u_${userIdOf()}_');
}

class CachedModule {
  const CachedModule({
    required this.records,
    this.syncedAt,
    this.conflictToken = false,
  });

  final List<Map<String, dynamic>> records;
  final DateTime? syncedAt;
  final bool conflictToken;
}
