/// مركز التواصل على الجوال (§106): قائمة الحاويات، «منذ» والكتابة في القناة،
/// الحضور، والمحفوظات — فوق سكك الخادم نفسها. العزل خادمي (العضوية/النطاق)،
/// والتطبيق يعرض ما يُعاد فقط. المركز داخلي: حساب العميل يُردّ ٤٠٤.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
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

/// قناةٌ في الدليل (قابلة للاكتشاف ولستُ عضواً فيها).
class DirectoryChannel {
  const DirectoryChannel({
    required this.id,
    required this.title,
    required this.visibility,
    required this.members,
    this.updatedAt,
  });

  factory DirectoryChannel.fromJson(Map<String, dynamic> j) => DirectoryChannel(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    visibility: j['visibility']?.toString() ?? '',
    members: jsonInt(j['members']),
    updatedAt: jsonDate(j['updated_at']),
  );

  final String id;
  final String title;
  final String visibility;
  final int members;
  final DateTime? updatedAt;
}

/// بطاقة الحاوية بعد إنشاء/انضمام (`ConversationCard`).
class ConversationCard {
  const ConversationCard({
    required this.id,
    required this.kind,
    required this.title,
    required this.myRole,
    this.archived = false,
  });

  factory ConversationCard.fromJson(Map<String, dynamic> j) => ConversationCard(
    id: j['id']?.toString() ?? '',
    kind: j['kind']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    myRole: j['my_role']?.toString() ?? '',
    archived: j['archived'] == true,
  );

  final String id;
  final String kind;
  final String title;
  final String myRole;
  final bool archived;
}

/// أدوار العضوية كما يعلنها العقد.
abstract final class ConversationRoles {
  static const owner = 'owner';
  static const moderator = 'moderator';
  static const member = 'member';
  static const guest = 'guest';
  static const all = [owner, moderator, member, guest];
}

/// تفضيلات إشعار الحاوية (`Collaboration::NOTIFY_PREFS`).
const kNotifyPrefs = ['all', 'mentions', 'muted'];

class ConversationMember {
  const ConversationMember({
    required this.userId,
    required this.name,
    required this.role,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> j) {
    final u = UserRef.fromJson(j['user']);
    return ConversationMember(
      userId: u?.id ?? '',
      name: u?.name ?? '',
      role: j['role']?.toString() ?? ConversationRoles.member,
    );
  }

  final String userId;
  final String name;
  final String role;
}

class ConversationMembers {
  const ConversationMembers({
    required this.myRole,
    required this.canPost,
    required this.canManage,
    required this.members,
  });

  factory ConversationMembers.fromJson(Map<String, dynamic> j) =>
      ConversationMembers(
        myRole: j['my_role']?.toString() ?? '',
        canPost: j['can_post'] == true,
        canManage: j['can_manage'] == true,
        members: jsonMaps(j['members'])
            .map(ConversationMember.fromJson)
            .toList(),
      );

  final String myRole;
  final bool canPost;

  /// إدارة الأعضاء (مشرف فأعلى) — عرضٌ يعيد الخادم فحصه.
  final bool canManage;
  final List<ConversationMember> members;

  bool get isOwner => myRole == ConversationRoles.owner;
}

/// نتيجة بحث الرسائل بوجهةٍ قانونية (شكل وجهة المحفوظة نفسه).
class MessageSearchHit {
  const MessageSearchHit({
    required this.type,
    required this.id,
    required this.excerpt,
    this.author,
    this.createdAt,
    this.target,
  });

  factory MessageSearchHit.fromJson(Map<String, dynamic> j) => MessageSearchHit(
    type: j['type']?.toString() ?? '',
    id: j['id']?.toString() ?? '',
    excerpt: j['excerpt']?.toString() ?? '',
    author: jsonStr(j['author']),
    createdAt: jsonDate(j['created_at']),
    target: SavedTarget.fromJson(j['target']),
  );

  /// `feed` · `channel` · `dm`.
  final String type;
  final String id;
  final String excerpt;
  final String? author;
  final DateTime? createdAt;
  final SavedTarget? target;
}

class MessageSearchResult {
  const MessageSearchResult({
    required this.minChars,
    required this.total,
    required this.hits,
  });

  final int minChars;
  final int total;
  final List<MessageSearchHit> hits;
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

  // ── إدارة القنوات والمجموعات (المرحلة ٤.٢) — الحرّاس خادمية
  // (ChannelService/GroupService). التبديلات والإضافات ليست عديمة الأثر ⇒ لا
  // إعادة تلقائية؛ والإنشاء بمفتاح Idempotency للفعل الواحد.

  /// `GET conversations/directory`.
  Future<List<DirectoryChannel>> directory() async =>
      jsonMaps((await api.getData('conversations/directory'))['channels'])
          .map(DirectoryChannel.fromJson)
          .toList();

  /// `POST conversations` — قناةٌ أنا مالكها.
  Future<ConversationCard> createChannel({
    required String title,
    String? audience,
    String? visibility,
    String? body,
    String? idempotencyKey,
  }) async => ConversationCard.fromJson(
    jsonMap(
      (await api.sendData(
        'POST',
        'conversations',
        body: {
          'title': title,
          'audience': ?audience,
          'visibility': ?visibility,
          if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
        },
        idempotencyKey: idempotencyKey ?? const Uuid().v4(),
      ))['conversation'],
    ),
  );

  /// `POST conversations/{id}/join` — `joined=false` إن كنت عضواً.
  Future<({ConversationCard conversation, bool joined})> join(String id) async {
    final d = await api.sendData(
      'POST',
      'conversations/${Uri.encodeComponent(id)}/join',
      body: const {},
    );
    return (
      conversation: ConversationCard.fromJson(jsonMap(d['conversation'])),
      joined: d['joined'] == true,
    );
  }

  Future<ConversationMembers> members(String id) async =>
      ConversationMembers.fromJson(
        await api.getData('conversations/${Uri.encodeComponent(id)}/members'),
      );

  Future<ConversationMember> addMember(
    String id,
    String userId, {
    String? role,
  }) async => ConversationMember.fromJson(
    jsonMap(
      (await api.sendData(
        'POST',
        'conversations/${Uri.encodeComponent(id)}/members',
        body: {'user_id': userId, 'role': ?role},
      ))['member'],
    ),
  );

  Future<ConversationMember> setMemberRole(
    String id,
    String userId,
    String role,
  ) async => ConversationMember.fromJson(
    jsonMap(
      (await api.sendData(
        'PUT',
        'conversations/${Uri.encodeComponent(id)}/members/${Uri.encodeComponent(userId)}',
        body: {'role': role},
      ))['member'],
    ),
  );

  Future<void> removeMember(String id, String userId) => api.sendData(
    'DELETE',
    'conversations/${Uri.encodeComponent(id)}/members/${Uri.encodeComponent(userId)}',
  );

  /// تبديل نجمة المفضّلة — يعيد الحالة الخادمية.
  Future<bool> toggleFavorite(String id) async =>
      (await api.sendData(
        'POST',
        'conversations/${Uri.encodeComponent(id)}/favorite',
        body: const {},
      ))['favorite'] ==
      true;

  /// أرشفة/إعادة — لمالك القناة وحده (403).
  Future<bool> toggleArchive(String id) async =>
      (await api.sendData(
        'POST',
        'conversations/${Uri.encodeComponent(id)}/archive',
        body: const {},
      ))['archived'] ==
      true;

  /// `PUT conversations/{id}/notify` — `all|mentions|muted`.
  Future<String> setNotifyPref(String id, String pref) async =>
      (await api.sendData(
        'PUT',
        'conversations/${Uri.encodeComponent(id)}/notify',
        body: {'pref': pref},
      ))['pref']?.toString() ??
      pref;

  /// `POST groups` — مجموعة رسائل بمشاركين داخليين ضمن نطاقي.
  Future<ConversationCard> createGroup(
    List<String> participants, {
    String? title,
    String? body,
    String? idempotencyKey,
  }) async => ConversationCard.fromJson(
    jsonMap(
      (await api.sendData(
        'POST',
        'groups',
        body: {
          'participants': participants,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
        },
        idempotencyKey: idempotencyKey ?? const Uuid().v4(),
      ))['conversation'],
    ),
  );

  /// `POST groups/{id}/leave` — عضويتي وحدها.
  Future<void> leaveGroup(String id) => api.sendData(
    'POST',
    'groups/${Uri.encodeComponent(id)}/leave',
    body: const {},
  );

  /// `GET search/messages?q=` — ما يراه القارئ وحده (≤50 مع العدد الكلي).
  Future<MessageSearchResult> searchMessages(String q) async {
    final d = await api.getData('search/messages', query: {'q': q});
    return MessageSearchResult(
      minChars: jsonInt(d['min_chars'], 2),
      total: jsonInt(d['total']),
      hits: jsonMaps(d['results']).map(MessageSearchHit.fromJson).toList(),
    );
  }
}
