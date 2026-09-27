/// مركز التواصل على الجوال (§106): قائمة الحاويات، «منذ» والكتابة في القناة،
/// الحضور، والمحفوظات — فوق سكك الخادم نفسها. العزل خادمي (العضوية/النطاق)،
/// والتطبيق يعرض ما يُعاد فقط. المركز داخلي: حساب العميل يُردّ ٤٠٤.
library;

import '../../core/api/api_client.dart';
import 'live_events.dart';

/// حالات الحضور الخشنة (`Presence::*`) — للتواصل لا للمراقبة.
enum PresenceState {
  online('online'),
  recent('recent'),
  away('away'),
  offline('offline');

  const PresenceState(this.wire);
  final String wire;

  static PresenceState parse(String? raw) => PresenceState.values.firstWhere(
    (p) => p.wire == raw,
    orElse: () => PresenceState.offline,
  );
}

/// قناة/غرفة/مجموعة من سكّتي.
class ConversationItem {
  const ConversationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.audience,
    required this.unread,
    required this.favorite,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> j) => ConversationItem(
    id: j['id']?.toString() ?? '',
    kind: j['kind']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    audience: j['audience']?.toString() ?? '',
    unread: (j['unread'] as num?)?.toInt() ?? 0,
    favorite: j['favorite'] == true,
  );

  final String id;

  /// `channel` · `room` · `group` (تصنيف عرضي من الخادم).
  final String kind;
  final String title;
  final String audience;
  final int unread;
  final bool favorite;
}

/// محادثة مباشرة في السكّة (مع حضور الطرف).
class ConversationDm {
  const ConversationDm({
    required this.userId,
    required this.title,
    required this.unread,
    required this.presence,
  });

  factory ConversationDm.fromJson(Map<String, dynamic> j) => ConversationDm(
    userId: j['user_id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    unread: (j['unread'] as num?)?.toInt() ?? 0,
    presence: PresenceState.parse(j['presence']?.toString()),
  );

  final String userId;
  final String title;
  final int unread;
  final PresenceState presence;
}

class ConversationsRail {
  const ConversationsRail({
    required this.channels,
    required this.rooms,
    required this.groups,
    required this.dms,
    required this.unreadTotal,
  });

  factory ConversationsRail.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) of) =>
        (j[k] as List? ?? const [])
            .whereType<Map>()
            .map((e) => of(e.cast<String, dynamic>()))
            .toList();
    return ConversationsRail(
      channels: list('channels', ConversationItem.fromJson),
      rooms: list('rooms', ConversationItem.fromJson),
      groups: list('groups', ConversationItem.fromJson),
      dms: list('dms', ConversationDm.fromJson),
      unreadTotal: (j['unread_total'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ConversationItem> channels;
  final List<ConversationItem> rooms;
  final List<ConversationItem> groups;
  final List<ConversationDm> dms;
  final int unreadTotal;

  bool get hasContainers =>
      channels.isNotEmpty || rooms.isNotEmpty || groups.isNotEmpty;
}

/// وجهة المحفوظة القانونية (خلفية ≥ v2.617) — null حين لم تعد متاحة.
class SavedTarget {
  const SavedTarget({
    required this.kind,
    this.module,
    this.recordId,
    this.commentId,
    this.parentId,
    this.userId,
    this.messageId,
  });

  static SavedTarget? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final kind = j['kind']?.toString();
    if (kind != 'comment' && kind != 'dm') return null;
    String? s(String k) {
      final v = j[k]?.toString();
      return v == null || v.isEmpty ? null : v;
    }

    return SavedTarget(
      kind: kind!,
      module: s('module'),
      recordId: s('record_id'),
      commentId: s('comment_id'),
      parentId: s('parent_id'),
      userId: s('user_id'),
      messageId: s('message_id'),
    );
  }

  /// `comment` أو `dm`.
  final String kind;
  final String? module;
  final String? recordId;
  final String? commentId;
  final String? parentId;
  final String? userId;
  final String? messageId;

  /// مسار الشاشة داخل التطبيق — أو null حين لا شاشة جوال لها (منشور `feed`
  /// بلا سجل مثلاً): لا وجهة مختلقة.
  String? get routePath {
    if (kind == 'dm') return userId == null ? null : '/messages/$userId';
    final m = module;
    final r = recordId;
    if (m == null || r == null) return null;
    if (m == 'channel') return '/conversations/$r';
    return '/r/$m/$r';
  }
}

/// محفوظة مُعادةُ التخويل عند كل فتح: ما لم يعد يُرى `available=false` بلا جسم.
class SavedItem {
  const SavedItem({
    required this.id,
    required this.type,
    required this.available,
    this.title,
    this.author,
    this.note,
    this.savedAt,
    this.target,
  });

  factory SavedItem.fromJson(Map<String, dynamic> j) => SavedItem(
    id: j['id']?.toString() ?? '',
    type: j['type']?.toString() ?? '',
    available: j['available'] == true,
    title: j['title']?.toString(),
    author: j['author']?.toString(),
    note: j['note']?.toString(),
    savedAt: DateTime.tryParse(j['saved_at']?.toString() ?? ''),
    target: j['available'] == true ? SavedTarget.fromJson(j['target']) : null,
  );

  final String id;

  /// `comment` أو `dm`.
  final String type;
  final bool available;
  final String? title;
  final String? author;
  final String? note;
  final DateTime? savedAt;

  /// الوجهة — حين `available` وحده.
  final SavedTarget? target;
}

class CollabRepository {
  CollabRepository(this.api);

  final ApiClient api;

  /// أقصى عدد معرّفات يقبله `presence` في نداء واحد (سقف خادمي).
  static const presenceBatch = 100;

  /// `GET conversations` — مرآة عضوياتي ضمن نطاقي.
  Future<ConversationsRail> conversations() async =>
      ConversationsRail.fromJson(await api.getData('conversations'));

  /// `GET conversations/{id}/since?cursor=` — غير العضو ٤٠٤.
  Future<ChannelSincePage> channelSince(
    String conversationId, {
    String cursor = '',
  }) async {
    final data = await api.getData(
      'conversations/$conversationId/since',
      query: cursor.isEmpty ? const {} : {'cursor': cursor},
    );
    return SincePage.parse(
      data,
      ChannelLiveEvent.fromJson,
      previousCursor: cursor,
    );
  }

  /// `POST conversations/{id}/typing` — نبضة عابرة؛ لا مفتاح ولا إعادة.
  /// القدرة المطفأة خادمياً ⇒ `RESOURCE_NOT_FOUND`.
  Future<void> channelTyping(String conversationId) =>
      api.sendData('POST', 'conversations/$conversationId/typing');

  /// `GET presence?users=` — حضور من أبلغهم فقط (الخادم يرشّح بالوصول).
  /// القدرة المطفأة ⇒ `RESOURCE_NOT_FOUND`.
  Future<Map<String, PresenceState>> presence(Iterable<String> userIds) async {
    final ids = userIds.where((e) => e.isNotEmpty).toSet().toList();
    final out = <String, PresenceState>{};
    for (var i = 0; i < ids.length; i += presenceBatch) {
      final chunk = ids.sublist(
        i,
        i + presenceBatch > ids.length ? ids.length : i + presenceBatch,
      );
      final data = await api.getData(
        'presence',
        query: {'users': chunk.join(',')},
      );
      for (final row
          in (data['presence'] as List? ?? const []).whereType<Map>()) {
        final id = row['user_id']?.toString();
        if (id != null) {
          out[id] = PresenceState.parse(row['presence']?.toString());
        }
      }
    }
    return out;
  }

  /// `GET saved` — محفوظاتي مُعادةَ التخويل.
  Future<List<SavedItem>> saved() async =>
      ((await api.getData('saved'))['saved'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SavedItem.fromJson(e.cast<String, dynamic>()))
          .toList();

  /// `POST saved` — حفظ رسالةٍ أراها الآن. **حفظٌ لا تبديل** خادمياً: الإعادة تعيد
  /// المحفوظة القائمة (200 · `created=false`) — فالإعادة التلقائية العابرة آمنة.
  /// ما لا أراه ⇒ `RESOURCE_NOT_FOUND`.
  Future<({SavedItem item, bool created})> save({
    required String targetType,
    required String targetId,
    String? note,
  }) async {
    final resp = await api.send(
      ApiRequest(
        'POST',
        'saved',
        jsonBody: {
          'target_type': targetType,
          'target_id': targetId,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
        retriable: true,
      ),
    );
    final data = resp.dataMap;
    return (
      item: SavedItem.fromJson(
        (data['saved'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      created: data['created'] == true,
    );
  }

  /// `DELETE saved/{id}` — إزالة محفوظتي (غيرها ٤٠٤). لا إعادة تلقائية.
  Future<void> unsave(String id) async {
    await api.send(ApiRequest('DELETE', 'saved/$id'));
  }
}
