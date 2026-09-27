/// مراجعة التقارير اليومية للفريق (المرحلة ٤.٤) — `reports/daily` و
/// `reports/daily/{id}/review`. الأهلية خادمية (`ReportReview`): غير المراجِع
/// ⇒ 403، والعميل ⇒ 404؛ `can_review` لكل بندٍ عرضٌ يعيد الخادم فحصه.
library;

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
import 'work_repository.dart' show formatWorkDate;

/// حالات المراجعة الآلية.
abstract final class ReviewStatus {
  static const pending = 'pending_review';
  static const accepted = 'accepted';
  static const needsRevision = 'needs_revision';
}

/// أفعال المراجعة (`ReportReview::ACTIONS`).
enum ReviewAction {
  accept('accept'),
  needsRevision('needs_revision'),
  reopen('reopen');

  const ReviewAction(this.wire);
  final String wire;
}

class ReviewEntry {
  const ReviewEntry({
    required this.id,
    required this.reviewStatus,
    this.workDate,
    this.author,
    this.projectName,
    this.taskTitle,
    this.done,
    this.hours,
    this.progress,
    this.problems,
    this.next,
    this.submittedAt,
    this.reviewFeedback,
    this.canReview = false,
  });

  factory ReviewEntry.fromJson(Map<String, dynamic> j) => ReviewEntry(
    id: j['id']?.toString() ?? '',
    workDate: jsonStr(j['work_date']),
    author: UserRef.fromJson(j['author']),
    projectName: jsonStr(jsonMap(j['project'])['name']),
    taskTitle: jsonStr(jsonMap(j['task'])['title']),
    done: jsonStr(j['done']),
    hours: jsonDecimal(j['hours']),
    progress: jsonDecimal(j['progress']),
    problems: jsonStr(j['problems']),
    next: jsonStr(j['next']),
    submittedAt: jsonDate(j['submitted_at']),
    reviewStatus: j['review_status']?.toString() ?? ReviewStatus.pending,
    reviewFeedback: jsonStr(j['review_feedback']),
    canReview: j['can_review'] == true,
  );

  final String id;
  final String? workDate;
  final UserRef? author;

  /// null حين لا يرى القارئ المشروع/المهمة أو يُحجب الحقل.
  final String? projectName;
  final String? taskTitle;
  final String? done;
  final Decimal? hours;
  final Decimal? progress;
  final String? problems;
  final String? next;
  final DateTime? submittedAt;
  final String reviewStatus;
  final String? reviewFeedback;
  final bool canReview;
}

class TeamDaily {
  const TeamDaily({
    required this.date,
    required this.scope,
    required this.status,
    required this.total,
    required this.pending,
    required this.accepted,
    required this.needsRevision,
    required this.entries,
    required this.truncated,
  });

  factory TeamDaily.fromJson(Map<String, dynamic> j) {
    final sum = jsonMap(j['summary']);
    return TeamDaily(
      date: j['date']?.toString() ?? '',
      scope: j['scope']?.toString() ?? 'mine',
      status: j['status']?.toString() ?? 'all',
      total: jsonInt(sum['total']),
      pending: jsonInt(sum['pending']),
      accepted: jsonInt(sum['accepted']),
      needsRevision: jsonInt(sum['needs_revision']),
      entries: jsonMaps(j['entries']).map(ReviewEntry.fromJson).toList(),
      truncated: j['truncated'] == true,
    );
  }

  final String date;

  /// النطاق كما حسمه الخادم (`team`|`mine`).
  final String scope;
  final String status;
  final int total;
  final int pending;
  final int accepted;
  final int needsRevision;
  final List<ReviewEntry> entries;
  final bool truncated;
}

class TeamReportsRepository {
  TeamReportsRepository(this.api);

  final ApiClient api;

  Future<TeamDaily> daily({
    DateTime? date,
    String? scope,
    String status = 'all',
  }) async => TeamDaily.fromJson(
    await api.getData(
      'reports/daily',
      query: {
        if (date != null) 'date': formatWorkDate(date),
        'scope': ?scope,
        'status': status,
      },
    ),
  );

  /// مراجعة بند — `needs_revision` تتطلب ملاحظة (وإلا 422).
  Future<({String outcome, ReviewEntry entry})> review(
    String entryId,
    ReviewAction action, {
    String? feedback,
    String? idempotencyKey,
  }) async {
    final d = await api.sendData(
      'POST',
      'reports/daily/${Uri.encodeComponent(entryId)}/review',
      body: {
        'action': action.wire,
        if (feedback != null && feedback.trim().isNotEmpty)
          'feedback': feedback.trim(),
      },
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return (
      outcome: d['outcome']?.toString() ?? '',
      entry: ReviewEntry.fromJson(jsonMap(d['entry'])),
    );
  }
}
