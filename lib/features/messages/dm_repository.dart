/// الرسائل المباشرة (§52) — المسار بمعرف الطرف الآخر؛ الخيط يُبنى خادمياً
/// (لا thread_key من العميل، ولا استعلام عن محادثات الغير).
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
import '../comments/reactions.dart';
import '../files/file_repository.dart';
import 'live_events.dart';

class DmThread {
  const DmThread({
    required this.userId,
    required this.userName,
    required this.unread,
    this.lastExcerpt,
    this.lastMine = false,
    this.lastAt,
  });

  factory DmThread.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final last = (j['last'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DmThread(
      userId: user['id']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      unread: (j['unread'] as num?)?.toInt() ?? 0,
      lastExcerpt: last['excerpt']?.toString(),
      lastMine: last['mine'] == true,
      lastAt: DateTime.tryParse(last['created_at']?.toString() ?? ''),
    );
  }

  final String userId;
  final String userName;
  final int unread;
  final String? lastExcerpt;
  final bool lastMine;
  final DateTime? lastAt;
}

class DmMessage {
  const DmMessage({
    required this.id,
    required this.mine,
    this.body,
    this.deleted = false,
    this.hasAttachment = false,
    this.attachment,
    this.edited = false,
    this.read = false,
    this.createdAt,
    this.reactions = const [],
  });

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
    id: j['id']?.toString() ?? '',
    mine: j['mine'] == true,
    body: j['body']?.toString(),
    deleted: j['deleted'] == true,
    hasAttachment: j['has_attachment'] == true,
    attachment: j['deleted'] == true
        ? null
        : MessageAttachmentRef.fromJson(j['attachment']),
    edited: j['edited'] == true,
    read: j['read'] == true,
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    reactions: j['deleted'] == true ? const [] : parseReactions(j['reactions']),
  );

  final String id;
  final bool mine;
  final String? body;
  final bool deleted;
  final bool hasAttachment;

  /// مقبض تنزيل المرفق (خلفية ≥ v2.618).
  final MessageAttachmentRef? attachment;

  /// حُرِّرت بعد إرسالها (يعيده الخادم بعد التحرير).
  final bool edited;
  final bool read;
  final DateTime? createdAt;

  /// ملخّص التفاعلات من الخادم (خلفية ≥ v2.617؛ فارغ لما قبلها وللمحذوفة).
  final List<CommentReaction> reactions;

  DmMessage copyWith({
    bool? deleted,
    List<CommentReaction>? reactions,
    String? body,
    bool? edited,
  }) {
    final gone = deleted ?? this.deleted;
    return DmMessage(
      id: id,
      mine: mine,
      body: gone ? null : (body ?? this.body),
      deleted: gone,
      hasAttachment: gone ? false : hasAttachment,
      attachment: gone ? null : attachment,
      edited: edited ?? this.edited,
      read: read,
      createdAt: createdAt,
      reactions: gone ? const [] : (reactions ?? this.reactions),
    );
  }
}

/// خيطي مع طرفٍ: اسمه ورسائله ومؤشر الذيل لبدء «منذ».
class DmThreadPage {
  const DmThreadPage({
    required this.userName,
    required this.messages,
    this.cursor,
  });

  final String userName;
  final List<DmMessage> messages;

  /// مؤشر آخر رسالة بترميز `since` ('' لخيطٍ فارغ؛ null من خادمٍ أقدم).
  final String? cursor;
}

class DmRepository {
  DmRepository(this.api);

  final ApiClient api;

  Future<({List<DmThread> threads, int unreadTotal})> threads() async {
    final data = await api.getData('dm/threads');
    return (
      threads: (data['threads'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DmThread.fromJson(e.cast<String, dynamic>()))
          .toList(),
      unreadTotal: (data['unread_total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<DmMessage>> messages(String otherUserId) async =>
      (await thread(otherUserId)).messages;

  /// `GET dm/threads/{user}/messages` بالاسم ومؤشر الذيل.
  Future<DmThreadPage> thread(String otherUserId) async {
    final data = await api.getData('dm/threads/$otherUserId/messages');
    return DmThreadPage(
      userName: ((data['user'] as Map?)?['name'])?.toString() ?? '',
      messages: (data['messages'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DmMessage.fromJson(e.cast<String, dynamic>()))
          .toList(),
      cursor: data['cursor']?.toString(),
    );
  }

  /// الإرسال قابل لإعادة المحاولة ⇒ مفتاح idempotency للرسالة الواحدة (§58).
  Future<DmMessage> send(
    String otherUserId,
    String body, {
    String? idempotencyKey,
  }) async {
    final data = await api.sendData(
      'POST',
      'dm/threads/$otherUserId/send',
      body: {'body': body},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return DmMessage.fromJson(
      (data['message'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<int> markRead(String otherUserId) async =>
      ((await api.sendData('POST', 'dm/threads/$otherUserId/read'))['marked']
              as num?)
          ?.toInt() ??
      0;

  /// `GET dm/threads/{user}/since?cursor=` — الجديد منذ مؤشرٍ مُعتَم + من يكتب.
  /// الخادم يختم الوارد الجديد مقروءاً (المحادثة مفتوحة). قراءة ⇒ إعادة آمنة.
  Future<DmSincePage> since(String otherUserId, {String cursor = ''}) async {
    final data = await api.getData(
      'dm/threads/$otherUserId/since',
      query: cursor.isEmpty ? const {} : {'cursor': cursor},
    );
    return SincePage.parse(data, DmLiveEvent.fromJson, previousCursor: cursor);
  }

  /// `POST dm/threads/{user}/typing` — نبضة عابرة؛ لا مفتاح ولا إعادة.
  Future<void> typing(String otherUserId) =>
      api.sendData('POST', 'dm/threads/$otherUserId/typing');

  /// `POST dm/messages/{id}/react` — تبديل تفاعلي على رسالةٍ أنا طرفٌ فيها.
  /// ليس عديم الأثر ⇒ لا مفتاح ولا إعادة تلقائية.
  Future<ReactionToggle> react(String messageId, String emoji) async =>
      ReactionToggle.fromJson(
        await api.sendData(
          'POST',
          'dm/messages/$messageId/react',
          body: {'emoji': emoji},
        ),
        'dm_message_id',
      );

  /// `PATCH dm/messages/{id}` — تحرير رسالتي (لصاحبها؛ المحذوفة ٤٢٢).
  Future<DmMessage> editMessage(String messageId, String body) async =>
      DmMessage.fromJson(
        jsonMap(
          (await api.sendData(
            'PATCH',
            'dm/messages/${Uri.encodeComponent(messageId)}',
            body: {'body': body},
          ))['message'],
        ),
      );

  /// `DELETE dm/messages/{id}` — سحب رسالتي (حذفٌ ناعم يبقى أثره).
  Future<DmMessage> deleteMessage(String messageId) async => DmMessage.fromJson(
    jsonMap(
      (await api.sendData(
        'DELETE',
        'dm/messages/${Uri.encodeComponent(messageId)}',
      ))['message'],
    ),
  );
}
