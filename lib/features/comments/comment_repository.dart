/// تعليقات السجلات (§53) — قراءة بردود وتفاعلات، ونشر برد/منشن (idempotent).
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import 'reactions.dart';

class CommentReaction {
  const CommentReaction({
    required this.emoji,
    required this.count,
    required this.mine,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> j) => CommentReaction(
    emoji: j['emoji']?.toString() ?? '',
    count: (j['count'] as num?)?.toInt() ?? 0,
    mine: j['mine'] == true,
  );

  final String emoji;
  final int count;
  final bool mine;
}

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
      reactions: (j['reactions'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CommentReaction.fromJson(e.cast<String, dynamic>()))
          .toList(),
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
  final List<CommentReaction> reactions;
  final List<RecordComment> replies;
  final DateTime? createdAt;

  /// نسخةٌ بعد تطبيق حالة رمزٍ أعادها الخادم (عليه أو على أحد ردوده) —
  /// العدد من الخادم لا حساباً محلياً.
  RecordComment applyReaction(ReactionToggle t) {
    List<CommentReaction> updated() {
      final out = <CommentReaction>[];
      var seen = false;
      for (final r in reactions) {
        if (r.emoji == t.emoji) {
          seen = true;
          if (t.count > 0) {
            out.add(
              CommentReaction(emoji: t.emoji, count: t.count, mine: t.mine),
            );
          }
        } else {
          out.add(r);
        }
      }
      if (!seen && t.count > 0) {
        out.add(CommentReaction(emoji: t.emoji, count: t.count, mine: t.mine));
      }
      return out;
    }

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
      reactions: t.targetId == id ? updated() : reactions,
      replies: [for (final r in replies) r.applyReaction(t)],
      createdAt: createdAt,
    );
  }
}

class CommentRepository {
  CommentRepository(this.api);

  final ApiClient api;

  Future<List<RecordComment>> forRecord(String module, String recordId) async {
    final data = await api.getData(
      'comments',
      query: {'module': module, 'record': recordId},
    );
    return (data['comments'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => RecordComment.fromJson(e.cast<String, dynamic>()))
        .toList();
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
}
