/// التقويم الموحّد والتنبيهات (المرحلة ٤.٥) — `calendar?from&to` (≤٦٢ يوماً)
/// و`alerts` («ينتهي قريباً»). القراءة بعين المستخدم خادمياً (hub_can +
/// hub_scope + hub_field_mode)؛ الوجهات من الخادم.
library;

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
import '../my_work/work_repository.dart' show formatWorkDate;

class CalendarItem {
  const CalendarItem({
    required this.module,
    required this.moduleLabel,
    required this.fieldLabel,
    required this.id,
    this.name,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> j) {
    final target = jsonMap(j['target']);
    return CalendarItem(
      module: target['module']?.toString() ?? j['module']?.toString() ?? '',
      moduleLabel: j['module_label']?.toString() ?? '',
      fieldLabel: j['field_label']?.toString() ?? '',
      id: target['id']?.toString() ?? j['id']?.toString() ?? '',
      name: jsonStr(j['name']),
    );
  }

  final String module;
  final String moduleLabel;
  final String fieldLabel;
  final String id;
  final String? name;

  String get routePath => '/r/$module/$id';
}

class CalendarDay {
  const CalendarDay({required this.date, required this.items});

  factory CalendarDay.fromJson(Map<String, dynamic> j) => CalendarDay(
    date: DateTime.tryParse(j['date']?.toString() ?? ''),
    items: jsonMaps(j['items']).map(CalendarItem.fromJson).toList(),
  );

  final DateTime? date;
  final List<CalendarItem> items;
}

class CalendarRange {
  const CalendarRange({
    required this.from,
    required this.to,
    required this.days,
    required this.overflow,
  });

  factory CalendarRange.fromJson(Map<String, dynamic> j) => CalendarRange(
    from: DateTime.tryParse(j['from']?.toString() ?? ''),
    to: DateTime.tryParse(j['to']?.toString() ?? ''),
    days: jsonMaps(j['days']).map(CalendarDay.fromJson).toList(),
    overflow: jsonInt(j['overflow']),
  );

  final DateTime? from;
  final DateTime? to;
  final List<CalendarDay> days;

  /// عناصر لم تُعرض (سقف الحقل/اليوم) — تُذكر بصدق.
  final int overflow;

  bool get isEmpty => days.every((d) => d.items.isEmpty);
}

class AlertItem {
  const AlertItem({
    required this.module,
    required this.moduleLabel,
    required this.fieldLabel,
    required this.id,
    required this.name,
    required this.days,
    this.date,
    this.document = false,
    this.self = false,
    this.targetRoute,
    this.targetArgs = const [],
  });

  factory AlertItem.fromJson(Map<String, dynamic> j) {
    final target = jsonMap(j['target']);
    return AlertItem(
      module: j['module']?.toString() ?? '',
      moduleLabel: j['module_label']?.toString() ?? '',
      fieldLabel: j['field_label']?.toString() ?? '',
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      date: jsonStr(j['date']),
      days: jsonInt(j['days']),
      document: j['document'] == true,
      self: j['self'] == true,
      targetRoute: jsonStr(target['route']),
      targetArgs: jsonStrings(target['args']),
    );
  }

  final String module;
  final String moduleLabel;
  final String fieldLabel;
  final String id;
  final String name;
  final String? date;

  /// الأيام المتبقية (سالبة ⇒ متأخر).
  final int days;
  final bool document;

  /// صفّ صاحب الشأن (وثيقتي) — وجهته ملفّي لا سجل الوحدة.
  final bool self;
  final String? targetRoute;
  final List<String> targetArgs;

  /// الوجهة داخل التطبيق من وجهة الخادم: `portal.me` ⇒ وثائقي؛ `m.show` ⇒ السجل.
  String? get routePath {
    if (self || targetRoute == 'portal.me') return '/me/documents';
    if (targetRoute == 'm.show' && targetArgs.length >= 2) {
      return '/r/${targetArgs[0]}/${targetArgs[1]}';
    }
    if (module.isNotEmpty && id.isNotEmpty) return '/r/$module/$id';
    return null;
  }
}

class AlertsSnapshot {
  const AlertsSnapshot({
    required this.late,
    required this.week,
    required this.month,
    required this.total,
    required this.windowDays,
  });

  factory AlertsSnapshot.fromJson(Map<String, dynamic> j) => AlertsSnapshot(
    late: jsonMaps(j['late']).map(AlertItem.fromJson).toList(),
    week: jsonMaps(j['week']).map(AlertItem.fromJson).toList(),
    month: jsonMaps(j['month']).map(AlertItem.fromJson).toList(),
    total: jsonInt(j['total']),
    windowDays: jsonInt(j['window_days']),
  );

  final List<AlertItem> late;
  final List<AlertItem> week;
  final List<AlertItem> month;
  final int total;
  final int windowDays;
}

class CalendarRepository {
  CalendarRepository(this.api);

  final ApiClient api;

  /// أقصى نافذة يقبلها الخادم.
  static const maxSpanDays = 62;

  Future<CalendarRange> range({DateTime? from, DateTime? to}) async =>
      CalendarRange.fromJson(
        await api.getData(
          'calendar',
          query: {
            if (from != null) 'from': formatWorkDate(from),
            if (to != null) 'to': formatWorkDate(to),
          },
        ),
      );

  Future<AlertsSnapshot> alerts() async =>
      AlertsSnapshot.fromJson(await api.getData('alerts'));
}
