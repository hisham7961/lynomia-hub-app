/// جدولة المزامنة في الإنتاج (§60 §61) — متى تُشغَّل [SyncEngine] ولأي وحدة.
///
/// القاعدة: **المخطط الخادمي يقرر** — لا تُطلب `sync/{module}` إلا لوحدةٍ صنفها
/// `CACHEABLE_*` في `GET schema` لهذا المستخدم. `SENSITIVE_NO_PERSIST` و
/// `ONLINE_ONLY` و`NOT_APPLICABLE` لا تُطلب أصلاً، ويُمحى أيُّ أثرٍ قديمٍ لها
/// (ترقية تصنيف خادمية). والمحرك نفسه والخبيئة يرفضان الكتابة دفاعاً في العمق.
///
/// المُشغِّلات:
///  • [syncOnOpen] عند فتح قائمة وحدة (تُحفظ في «المفتوحة مؤخراً» للجلسة).
///  • [syncBackground] عند الإقلاع والاستئناف: المفتوحة مؤخراً + الوجهات
///    الأساسية المناسبة للجوال في شجرة IA، بسقفٍ وبمهلةٍ بين الدورات.
library;

import 'dart:async';

import '../../core/sync/sync_engine.dart';
import '../workspaces/ia_models.dart';
import 'module_repository.dart';
import 'module_schema.dart';

class SyncScheduler {
  SyncScheduler({
    required this.engine,
    required this.modules,
    required this.iaOf,
    DateTime Function()? now,
    this.backgroundInterval = const Duration(minutes: 5),
    this.openInterval = const Duration(minutes: 2),
    this.maxBackgroundModules = 8,
  }) : _now = now ?? DateTime.now;

  final SyncEngine engine;
  final ModuleRepository modules;

  /// شجرة IA الحالية (من bootstrap) — مصدر الوجهات الأساسية.
  final IaTree Function() iaOf;
  final DateTime Function() _now;
  final Duration backgroundInterval;
  final Duration openInterval;
  final int maxBackgroundModules;

  final List<String> _recent = [];
  final Map<String, DateTime> _lastModuleSync = {};
  DateTime? _lastBackground;
  Future<void>? _backgroundRun;

  /// الوحدات المفتوحة مؤخراً في هذه الجلسة (للتشخيص والاختبار).
  List<String> get recentModules => List.unmodifiable(_recent);

  /// عند فتح قائمة وحدة — لا مزامنة إلا لصنف `CACHEABLE_*`، ومحوٌ لغيره.
  Future<void> syncOnOpen(String module, ModuleSchema? schema) async {
    if (schema == null) return;
    if (!isCacheableClass(schema.syncClass)) {
      await engine.purgeModule(module);
      return;
    }
    _remember(module);
    await _syncThrottled(module, openInterval);
  }

  /// عند الإقلاع/الاستئناف — دورة واحدة جارية على الأكثر، وبمهلة بين الدورات.
  Future<void> syncBackground({bool force = false}) {
    final running = _backgroundRun;
    if (running != null) return running;
    final last = _lastBackground;
    if (!force &&
        last != null &&
        _now().difference(last) < backgroundInterval) {
      return Future.value();
    }
    _lastBackground = _now();
    final run = _runBackground().whenComplete(() => _backgroundRun = null);
    _backgroundRun = run;
    return run;
  }

  Future<void> _runBackground() async {
    final SchemaSnapshot snapshot;
    try {
      snapshot = await modules.schema();
    } on Object {
      return; // بلا مخطط لا قرار — لا مزامنة عمياء.
    }
    final candidates = <String>{..._recent, ..._primaryModules()};
    var synced = 0;
    for (final module in candidates) {
      final schema = snapshot.modules[module];
      if (schema == null) continue; // غير مرئية لهذا المستخدم
      if (!isCacheableClass(schema.syncClass)) {
        await engine.purgeModule(module);
        continue;
      }
      if (synced >= maxBackgroundModules) break;
      synced++;
      await _syncThrottled(module, backgroundInterval);
    }
  }

  Iterable<String> _primaryModules() sync* {
    for (final domain in iaOf().domains) {
      for (final section in domain.sections) {
        for (final d in section.destinations) {
          final m = d.module;
          if (m != null &&
              m.isNotEmpty &&
              d.importance == 'primary' &&
              d.mobile != MobileFit.webOnly) {
            yield m;
          }
        }
      }
    }
  }

  Future<void> _syncThrottled(String module, Duration minGap) async {
    final last = _lastModuleSync[module];
    if (last != null && _now().difference(last) < minGap) return;
    _lastModuleSync[module] = _now();
    try {
      await engine.syncModule(module);
    } on Object {
      // المزامنة خلفية صامتة — الفشل لا يسقط شاشة (القائمة الحية تعرض خطأها).
      _lastModuleSync.remove(module);
    }
  }

  void _remember(String module) {
    _recent
      ..remove(module)
      ..insert(0, module);
    if (_recent.length > maxBackgroundModules) _recent.removeLast();
  }

  /// عند الخروج/تبديل المستخدم — لا تحمل الجلسة التالية ذاكرة السابقة.
  void reset() {
    _recent.clear();
    _lastModuleSync.clear();
    _lastBackground = null;
  }
}
