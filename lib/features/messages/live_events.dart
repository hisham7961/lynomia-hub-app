/// الجلب التدريجي «منذ» (§106) — أحداث القناة/المحادثة منذ مؤشرٍ مُعتَم، ومن
/// يكتب الآن. المؤشر يصنعه الخادم وحده ولا يُفكّ في التطبيق.
library;

import '../comments/reactions.dart';

/// سقف الصفحة الخادمي لكل نداء «منذ» — صفحةٌ أقصر ⇒ بلغنا الذيل.
const kSincePageSize = 50;

/// أنواع الأحداث (`Collaboration::EV_*`).
const kEvMessageCreated = 'message.created';
const kEvMessageUpdated = 'message.updated';
const kEvMessageDeleted = 'message.deleted';

/// حدث رسالة DM: نفس شكل بطاقة الرسالة مختصراً.
class DmLiveEvent {
  const DmLiveEvent({
    required this.type,
    required this.id,
    required this.mine,
    this.body,
    this.deleted = false,
    this.edited = false,
    this.createdAt,
    this.reactions = const [],
  });

  factory DmLiveEvent.fromJson(Map<String, dynamic> j) => DmLiveEvent(
    type: j['type']?.toString() ?? kEvMessageCreated,
    id: j['id']?.toString() ?? '',
    mine: j['mine'] == true,
    body: j['body']?.toString(),
    deleted: j['deleted'] == true || j['type'] == kEvMessageDeleted,
    edited: j['edited'] == true,
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    reactions: parseReactions(j['reactions']),
  );

  final String type;
  final String id;
  final bool mine;
  final String? body;
  final bool deleted;
  final bool edited;
  final DateTime? createdAt;

  /// ملخّص التفاعلات (خلفية ≥ v2.617؛ فارغ لما قبلها وللمحذوفة).
  final List<CommentReaction> reactions;
}

/// حدث رسالة قناة/مجموعة.
class ChannelLiveEvent {
  const ChannelLiveEvent({
    required this.type,
    required this.id,
    this.parentId,
    required this.userId,
    this.author,
    required this.body,
    this.edited = false,
    this.createdAt,
    this.reactions = const [],
  });

  factory ChannelLiveEvent.fromJson(Map<String, dynamic> j) => ChannelLiveEvent(
    type: j['type']?.toString() ?? kEvMessageCreated,
    id: j['id']?.toString() ?? '',
    parentId: j['parent_id']?.toString(),
    userId: j['user_id']?.toString() ?? '',
    author: j['author']?.toString(),
    body: j['body']?.toString() ?? '',
    edited: j['edited'] == true,
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    reactions: parseReactions(j['reactions']),
  );

  final String type;
  final String id;
  final String? parentId;
  final String userId;
  final String? author;
  final String body;
  final bool edited;
  final DateTime? createdAt;
  final List<CommentReaction> reactions;
}

/// صفحة «منذ»: الأحداث، والمؤشر التالي (أو نفسه إن لم يجد جديداً)، ومن يكتب.
class SincePage<E> {
  const SincePage({
    required this.events,
    required this.cursor,
    required this.typing,
  });

  final List<E> events;
  final String cursor;

  /// أسماء من يكتبون الآن (فارغة حين القدرة مطفأة خادمياً).
  final List<String> typing;

  /// صفحةٌ أقصر من السقف ⇒ لا مزيد الآن.
  bool get reachedTail => events.length < kSincePageSize;

  static SincePage<E> parse<E>(
    Map<String, dynamic> data,
    E Function(Map<String, dynamic>) itemOf, {
    required String previousCursor,
  }) {
    final c = data['cursor']?.toString() ?? '';
    return SincePage<E>(
      events: (data['events'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => itemOf(e.cast<String, dynamic>()))
          .toList(),
      cursor: c.isEmpty ? previousCursor : c,
      typing: (data['typing'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

typedef DmSincePage = SincePage<DmLiveEvent>;
typedef ChannelSincePage = SincePage<ChannelLiveEvent>;

/// ناتج سحبٍ واحد (قد يمتد صفحاتٍ حتى الذيل أو السقف).
class SinceBatch<E> {
  const SinceBatch({
    required this.events,
    required this.typing,
    required this.caughtUp,
  });

  final List<E> events;
  final List<String> typing;
  final bool caughtUp;
}

/// متتبّع مؤشرٍ واحد يتقدم بما يعيده الخادم. يُبذَر بمؤشر الذيل الذي يعيده
/// تحميل الخيط نفسه (خلفية ≥ v2.617 — backend-change-requests.md#4، محلول) فتبدأ
/// النبضات من «الآن». خادمٌ أقدم بلا مؤشر ⇒ يبدأ فارغاً (من أول الخيط) ويلحق
/// بالذيل صفحاتٍ محدودةً في كل نبضة — صحيحٌ وإن كان أكلف.
class SinceFeed<E> {
  SinceFeed(this.fetch);

  final Future<SincePage<E>> Function(String cursor) fetch;

  String _cursor = '';
  bool _caughtUp = false;

  String get cursor => _cursor;

  /// بذر المؤشر من تحميل الخيط (مؤشر الذيل): ما بعده «جديدٌ» حقاً.
  void seed(String cursor) {
    _cursor = cursor;
    _caughtUp = true;
  }

  /// هل بلغنا الذيل مرةً على الأقل (ما بعده «جديدٌ» حقاً).
  bool get caughtUp => _caughtUp;

  /// يسحب حتى الذيل أو [maxPages] صفحة.
  Future<SinceBatch<E>> pull({int maxPages = 20}) async {
    final events = <E>[];
    var typing = const <String>[];
    for (var i = 0; i < maxPages; i++) {
      final page = await fetch(_cursor);
      _cursor = page.cursor;
      events.addAll(page.events);
      typing = page.typing;
      if (page.reachedTail) {
        _caughtUp = true;
        return SinceBatch(events: events, typing: typing, caughtUp: true);
      }
    }
    return SinceBatch(events: events, typing: typing, caughtUp: false);
  }
}
