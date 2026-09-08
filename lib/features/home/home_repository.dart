/// `GET home` (§47) — لوحة عمل الجوال: عناصر بوجهات `{module,id}`، لا اختلاق.
library;

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';

class HomeItem {
  const HomeItem({
    required this.target,
    required this.name,
    this.status,
    this.due,
    this.label,
    this.field,
    this.days,
  });

  factory HomeItem.fromJson(Map<String, dynamic> j) => HomeItem(
    target:
        DeepTarget.fromJson(j) ??
        DeepTarget(
          module: j['module']?.toString() ?? '',
          id: j['id']?.toString() ?? '',
        ),
    name: j['name']?.toString() ?? '',
    status: j['status']?.toString(),
    due: (j['due'] ?? j['date'])?.toString(),
    label: j['label']?.toString(),
    field: j['field']?.toString(),
    days: (j['days'] as num?)?.toInt(),
  );

  final DeepTarget target;
  final String name;
  final String? status;
  final String? due;
  final String? label;
  final String? field;
  final int? days;
}

class HomeActivity {
  const HomeActivity({
    required this.action,
    this.who,
    this.name,
    this.when,
    this.target,
  });

  factory HomeActivity.fromJson(Map<String, dynamic> j) => HomeActivity(
    action: j['action']?.toString() ?? '',
    who: j['who']?.toString(),
    name: j['name']?.toString(),
    when: j['when']?.toString(),
    target: DeepTarget.fromJson(j['target']),
  );

  final String action;
  final String? who;
  final String? name;
  final String? when;
  final DeepTarget? target;
}

class HomeSnapshot {
  const HomeSnapshot({
    required this.myWorkCount,
    required this.myWork,
    required this.due,
    required this.approvalsCount,
    required this.attention,
    required this.recent,
    required this.projectsCount,
    required this.projects,
    required this.unreadNotifications,
  });

  factory HomeSnapshot.fromJson(Map<String, dynamic> j) {
    List<HomeItem> items(Object? node) =>
        (node is Map ? node['items'] : node) is List
        ? ((node is Map ? node['items'] : node) as List)
              .whereType<Map>()
              .map((e) => HomeItem.fromJson(e.cast<String, dynamic>()))
              .toList()
        : const [];
    int count(Object? node, List list) => node is Map
        ? ((node['count'] as num?)?.toInt() ?? list.length)
        : list.length;

    final myWork = items(j['my_work']);
    final projects = items(j['projects']);
    return HomeSnapshot(
      myWorkCount: count(j['my_work'], myWork),
      myWork: myWork,
      due: items(j['due']),
      approvalsCount:
          (((j['approvals'] as Map?) ?? const {})['count'] as num?)?.toInt() ??
          0,
      attention: items(j['attention']),
      recent: (j['recent'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => HomeActivity.fromJson(e.cast<String, dynamic>()))
          .toList(),
      projectsCount: count(j['projects'], projects),
      projects: projects,
      unreadNotifications:
          (((j['notifications'] as Map?) ?? const {})['unread'] as num?)
              ?.toInt() ??
          0,
    );
  }

  final int myWorkCount;
  final List<HomeItem> myWork;
  final List<HomeItem> due;
  final int approvalsCount;
  final List<HomeItem> attention;
  final List<HomeActivity> recent;
  final int projectsCount;
  final List<HomeItem> projects;
  final int unreadNotifications;
}

class HomeRepository {
  HomeRepository(this.api);

  final ApiClient api;

  Future<HomeSnapshot> fetch() async =>
      HomeSnapshot.fromJson(await api.getData('home'));
}
