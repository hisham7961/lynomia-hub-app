/// الإشعارات (§51) — قائمة بمؤشر keyset، قراءة/قراءة الكل، وحل الوجهة القانونية.
library;

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';

class HubNotificationItem {
  const HubNotificationItem({
    required this.id,
    required this.kind,
    this.text,
    required this.read,
    this.target,
    this.createdAt,
  });

  factory HubNotificationItem.fromJson(Map<String, dynamic> j) =>
      HubNotificationItem(
        id: j['id']?.toString() ?? '',
        kind: j['kind']?.toString() ?? '',
        text: j['text']?.toString(),
        read: j['read'] == true,
        target: DeepTarget.fromJson(j['target']),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );

  final String id;
  final String kind;
  final String? text;
  final bool read;

  /// الوجهة القانونية `{module,id,action}` أو null (يبقى في القائمة).
  final DeepTarget? target;
  final DateTime? createdAt;
}

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.unread,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<HubNotificationItem> items;
  final int unread;
  final String? nextCursor;
  final bool hasMore;
}

class NotificationRepository {
  NotificationRepository(this.api);

  final ApiClient api;

  Future<NotificationsPage> list({
    String? cursor,
    bool unreadOnly = false,
    int per = 25,
  }) async {
    final data = await api.getData(
      'notifications',
      query: {'per': '$per', 'cursor': ?cursor, if (unreadOnly) 'unread': '1'},
    );
    final cur = (data['cursor'] as Map?)?.cast<String, dynamic>() ?? const {};
    return NotificationsPage(
      items: (data['notifications'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => HubNotificationItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      unread: (data['unread'] as num?)?.toInt() ?? 0,
      nextCursor: cur['next']?.toString(),
      hasMore: cur['has_more'] == true,
    );
  }

  Future<int> unreadCount() async =>
      ((await api.getData('notifications/unread-count'))['unread'] as num?)
          ?.toInt() ??
      0;

  /// يختم القراءة ويعيد الوجهة — نقرة الإشعار (§51).
  Future<DeepTarget?> markRead(String id) async => DeepTarget.fromJson(
    (await api.sendData('POST', 'notifications/$id/read'))['target'],
  );

  Future<DeepTarget?> target(String id) async => DeepTarget.fromJson(
    (await api.getData('notifications/$id/target'))['target'],
  );

  Future<int> markAllRead() async =>
      ((await api.sendData('POST', 'notifications/read-all'))['marked'] as num?)
          ?.toInt() ??
      0;
}
