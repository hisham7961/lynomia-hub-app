/// تعليقات السجلات (§53) — قراءة بردود وتفاعلات، ونشر برد/منشن (idempotent).
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
import '../files/file_repository.dart';
import 'reactions.dart';

export 'reactions.dart' show CommentReaction, ReactionToggle;

class RecordComment {
  const RecordComment({
    required this.id,
    this.parentId,
    required this.userId,
    required this.userName,
    required this.body,
    this.mentions = const [],
    this.internal = false,
    this.pinned = false,
    this.resolved = false,
    this.hasAttachment = false,
    this.attachment,
    this.reactions = const [],
    this.replies = const [],
    this.createdAt,
  });

  factory RecordComment.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    return RecordComment(
      id: j['id']?.toString() ?? '',
      parentId: j['parent_id']?.toString(),
      userId: user['id']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      body: j['body']?.toString() ?? '',
      mentions: (j['mentions'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      internal: j['internal'] == true,
      pinned: j['pinned'] == true,
      resolved: j['resolved'] == true,
      hasAttachment: j['has_attachment'] == true,
      attachment: MessageAttachmentRef.fromJson(j['attachment']),
      reactions: parseReactions(j['reactions']),
      replies: (j['replies'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RecordComment.fromJson(e.cast<String, dynamic>()))
          .toList(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }

  final String id;
  final String? parentId;
  final String userId;
  final String userName;
  final String body;
  final List<String> mentions;
  final bool internal;
  final bool pinned;
  final bool resolved;
  final bool hasAttachment;

  /// مقبض تنزيل المرفق (للداخلي — خلفية ≥ v2.618)؛ null لغيره.
  final MessageAttachmentRef? attachment;
  final List<CommentReaction> reactions;
  final List<RecordComment> replies;
  final DateTime? createdAt;

  /// نسخةٌ بعد تطبيق حالة رمزٍ أعادها الخادم (عليه أو على أحد ردوده) —
  /// العدد من الخادم لا حساباً محلياً.
  RecordComment applyReaction(ReactionToggle t) {
    return RecordComment(
      id: id,
      parentId: parentId,
      userId: userId,
      userName: userName,
      body: body,
      mentions: mentions,
      internal: internal,
      pinned: pinned,
      resolved: resolved,
      hasAttachment: hasAttachment,
      attachment: attachment,
      reactions: t.targetId == id ? applyToggle(reactions, t) : reactions,
      replies: [for (final r in replies) r.applyReaction(t)],
      createdAt: createdAt,
    );
  }
}

class CommentThread {
  const CommentThread({required this.comments, this.cursor});

  final List<RecordComment> comments;

  /// مؤشر الذيل المُعتَم (القناة وحدها)؛ '' لخيطٍ فارغ؛ null حين لا يعيده الخادم.
  final String? cursor;
}

class CommentRepository {
  CommentRepository(this.api);

  final ApiClient api;

  Future<List<RecordComment>> forRecord(String module, String recordId) async =>
      (await thread(module, recordId)).comments;

  /// `GET comments` بمؤشر الذيل: للقناة (`module=channel`) يعيد الخادم `cursor`
  /// بترميز `conversations/{id}/since` — نقطة بدء الاستطلاع (خلفية ≥ v2.617)؛
  /// null لغيرها أو لخادمٍ أقدم.
  Future<CommentThread> thread(String module, String recordId) async {
    final data = await api.getData(
      'comments',
      query: {'module': module, 'record': recordId},
    );
    return CommentThread(
      comments: (data['comments'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RecordComment.fromJson(e.cast<String, dynamic>()))
          .toList(),
      cursor: data['cursor']?.toString(),
    );
  }

  Future<RecordComment> post({
    required String module,
    required String recordId,
    required String body,
    String? parentId,
    List<String> mentions = const [],
    bool internal = false,
    String? idempotencyKey,
  }) async {
    final data = await api.sendData(
      'POST',
      'comments',
      body: {
        'module': module,
        'record': recordId,
        'body': body,
        'parent_id': ?parentId,
        if (mentions.isNotEmpty) 'mention': mentions,
        if (internal) 'internal': true,
      },
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return RecordComment.fromJson(
      (data['comment'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// `POST comments/{id}/react` — تبديل تفاعلي على تعليقٍ أراه. التبديل ليس
  /// عديمَ الأثر (الإعادة تعكسه) والخادم لا يقبل مفتاح تكرارٍ له ⇒ لا مفتاح ولا
  /// إعادة تلقائية أبداً.
  Future<ReactionToggle> react(String commentId, String emoji) async =>
      ReactionToggle.fromJson(
        await api.sendData(
          'POST',
          'comments/$commentId/react',
          body: {'emoji': emoji},
        ),
        'comment_id',
      );

  // ── أفعال التعليق (المرحلة ٤.٣ · `mobile.comment_actions.*`) — الحرّاس خادمية
  // (`CommentActions`): التحرير لصاحبه، والحذف له أو للمالك، والتثبيت لمعدّل
  // الوحدة/مشرف القناة، والحلّ لصاحبه أو مديره، والتحويل لمهمة `tasks:a`.
  // التبديلات ليست عديمة الأثر ⇒ لا مفتاح ولا إعادة تلقائية.

  /// `PATCH comments/{id}` — تحرير تعليقي.
  Future<CommentCard> edit(String commentId, String body) async =>
      CommentCard.fromJson(
        jsonMap(
          (await api.sendData(
            'PATCH',
            'comments/${Uri.encodeComponent(commentId)}',
            body: {'body': body},
          ))['comment'],
        ),
      );

  /// `DELETE comments/{id}`.
  Future<void> delete(String commentId) =>
      api.sendData('DELETE', 'comments/${Uri.encodeComponent(commentId)}');

  /// `POST comments/{id}/pin` — تبديل التثبيت.
  Future<CommentCard> togglePin(String commentId) async => CommentCard.fromJson(
    jsonMap(
      (await api.sendData(
        'POST',
        'comments/${Uri.encodeComponent(commentId)}/pin',
        body: const {},
      ))['comment'],
    ),
  );

  /// `POST comments/{id}/resolve` — تبديل الحلّ.
  Future<CommentCard> toggleResolve(String commentId) async =>
      CommentCard.fromJson(
        jsonMap(
          (await api.sendData(
            'POST',
            'comments/${Uri.encodeComponent(commentId)}/resolve',
            body: const {},
          ))['comment'],
        ),
      );

  /// `POST comments/{id}/to-task` — مرّة واحدة؛ Idempotency للفعل الواحد.
  /// يعيد معرّف المهمة المنشأة.
  Future<String> toTask(String commentId, {String? idempotencyKey}) async {
    final d = await api.sendData(
      'POST',
      'comments/${Uri.encodeComponent(commentId)}/to-task',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return jsonMap(d['task'])['id']?.toString() ?? '';
  }
}

/// بطاقة التعليق بعد فعلٍ عليه (`CommentCard`).
class CommentCard {
  const CommentCard({
    required this.id,
    required this.body,
    this.pinned = false,
    this.resolved = false,
    this.edited = false,
    this.taskId,
  });

  factory CommentCard.fromJson(Map<String, dynamic> j) => CommentCard(
    id: j['id']?.toString() ?? '',
    body: j['body']?.toString() ?? '',
    pinned: j['pinned'] == true,
    resolved: j['resolved'] == true,
    edited: j['edited'] == true,
    taskId: jsonStr(j['task_id']),
  );

  final String id;
  final String body;
  final bool pinned;
  final bool resolved;
  final bool edited;
  final String? taskId;
}
