/// عملي اليوم والتقرير اليومي (§93) — `work/today` و`work/daily-report`.
///
/// قراءة فقط لحال يومي كما يحسمه الخادم (`DailyWorkCompliance`): الحضور،
/// والتقرير المطلوب/المقدَّم، والمهلة، والبنود. لا حساب امتثالٍ في التطبيق —
/// التسميات العربية تأتي من الخادم (`labels`). التقديم = إنشاء بندٍ في وحدة
/// `updates` عبر CRUD العام (لا مسار مكرر).
library;

import 'package:decimal/decimal.dart';

import '../../core/api/api_client.dart';
import '../../core/errors/api_exception.dart';

/// الرمز الآلي الذي يرده الخادم حين لا ملفَ موظفٍ نشطاً مربوطاً بالحساب.
const kNoEmployeeProfile = 'no_employee_profile';

Decimal? _dec(Object? v) =>
    v == null ? null : Decimal.tryParse(v is num ? v.toString() : '$v');

class WorkCompliance {
  const WorkCompliance({
    required this.date,
    required this.checkedIn,
    required this.checkedOut,
    required this.onLeave,
    required this.reportRequired,
    required this.reportSubmitted,
    required this.reportCount,
    required this.pastDeadline,
    required this.late,
    required this.verdictPending,
    required this.needsReview,
    required this.finalized,
    required this.state,
    required this.compliance,
    required this.effectiveStatus,
    this.timeIn,
    this.timeOut,
    this.reportedHours,
    this.deadlineAt,
    this.graceRemainingMinutes,
    this.reason,
    this.physicalLabel,
    this.complianceLabel,
    this.effectiveLabel,
  });

  factory WorkCompliance.fromJson(Map<String, dynamic> j) {
    final labels = (j['labels'] as Map?)?.cast<String, dynamic>() ?? const {};
    return WorkCompliance(
      date: j['date']?.toString() ?? '',
      checkedIn: j['checked_in'] == true,
      checkedOut: j['checked_out'] == true,
      onLeave: j['on_leave'] == true,
      reportRequired: j['report_required'] == true,
      reportSubmitted: j['report_submitted'] == true,
      reportCount: (j['report_count'] as num?)?.toInt() ?? 0,
      pastDeadline: j['past_deadline'] == true,
      late: j['late'] == true,
      verdictPending: j['verdict_pending'] == true,
      needsReview: j['needs_review'] == true,
      finalized: j['finalized'] == true,
      state: j['state']?.toString() ?? '',
      compliance: j['compliance']?.toString() ?? '',
      effectiveStatus: j['effective_status']?.toString() ?? '',
      timeIn: j['time_in']?.toString(),
      timeOut: j['time_out']?.toString(),
      reportedHours: _dec(j['reported_hours']),
      deadlineAt: DateTime.tryParse(j['deadline_at']?.toString() ?? ''),
      graceRemainingMinutes: (j['grace_remaining_minutes'] as num?)?.toInt(),
      reason: j['reason']?.toString(),
      physicalLabel: labels['physical']?.toString(),
      complianceLabel: labels['compliance']?.toString(),
      effectiveLabel: labels['effective']?.toString(),
    );
  }

  final String date;
  final bool checkedIn;
  final bool checkedOut;
  final bool onLeave;
  final bool reportRequired;
  final bool reportSubmitted;
  final int reportCount;
  final bool pastDeadline;
  final bool late;

  /// لم يحِن وقت الحكم بعد (فلا يُقرأ «غائباً» في الفجر).
  final bool verdictPending;
  final bool needsReview;
  final bool finalized;
  final String state;
  final String compliance;
  final String effectiveStatus;
  final String? timeIn;
  final String? timeOut;
  final Decimal? reportedHours;
  final DateTime? deadlineAt;
  final int? graceRemainingMinutes;
  final String? reason;

  /// التسميات العربية كما يحسمها الخادم (مصدر الحقيقة للعرض).
  final String? physicalLabel;
  final String? complianceLabel;
  final String? effectiveLabel;

  /// تقرير مطلوب لم يُقدَّم بعد.
  bool get reportDue => reportRequired && !reportSubmitted;
}

class WorkEntry {
  const WorkEntry({
    required this.id,
    this.projectId,
    this.taskId,
    this.done,
    this.hours,
    this.progress,
    this.problems,
    this.submittedAt,
    required this.reviewStatus,
    this.reviewFeedback,
  });

  factory WorkEntry.fromJson(Map<String, dynamic> j) => WorkEntry(
    id: j['id']?.toString() ?? '',
    projectId: j['project_id']?.toString(),
    taskId: j['task_id']?.toString(),
    done: j['done']?.toString(),
    hours: _dec(j['hours']),
    progress: _dec(j['progress']),
    problems: j['problems']?.toString(),
    submittedAt: DateTime.tryParse(j['submitted_at']?.toString() ?? ''),
    reviewStatus: j['review_status']?.toString() ?? 'pending_review',
    reviewFeedback: j['review_feedback']?.toString(),
  );

  final String id;
  final String? projectId;
  final String? taskId;
  final String? done;
  final Decimal? hours;
  final Decimal? progress;
  final String? problems;
  final DateTime? submittedAt;

  /// `pending_review` · `accepted` · `needs_revision` (رمز آلي — ReportReview).
  final String reviewStatus;
  final String? reviewFeedback;
}

/// حال يوم: إما ملفّ موظف غائب (حالة صادقة لا خطأ) وإما الامتثال والبنود.
class WorkDay {
  const WorkDay({
    this.compliance,
    this.entries = const [],
    this.submitModule,
    this.noEmployeeProfile = false,
  });

  factory WorkDay.fromJson(Map<String, dynamic> j) {
    final hint = (j['submit_hint'] as Map?)?.cast<String, dynamic>();
    final path = hint?['path']?.toString() ?? '';
    const prefix = '/api/mobile/v1/';
    final module = path.startsWith(prefix) ? path.substring(prefix.length) : '';
    return WorkDay(
      compliance: WorkCompliance.fromJson(
        (j['compliance'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      entries: (j['entries'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => WorkEntry.fromJson(e.cast<String, dynamic>()))
          .toList(),
      submitModule: module.isEmpty || module.contains('/') ? null : module,
    );
  }

  static const noProfile = WorkDay(noEmployeeProfile: true);

  final WorkCompliance? compliance;
  final List<WorkEntry> entries;

  /// الوحدة التي يُقدَّم فيها التقرير (من `submit_hint` — الخادم يسمّيها).
  final String? submitModule;
  final bool noEmployeeProfile;
}

class WorkRepository {
  WorkRepository(this.api);

  final ApiClient api;

  /// `GET work/today` — يومي الآن.
  Future<WorkDay> today() => _fetch('work/today', const {});

  /// `GET work/daily-report?date=YYYY-MM-DD` — تقرير يومٍ بعينه.
  Future<WorkDay> dailyReport(DateTime date) =>
      _fetch('work/daily-report', {'date': formatWorkDate(date)});

  Future<WorkDay> _fetch(String path, Map<String, String> query) async {
    try {
      final resp = await api.send(ApiRequest('GET', path, query: query));
      // الرد بلا غلاف `data` (نقطة §93 الأقدم) — ونقبل الغلاف إن أُضيف لاحقاً.
      final env = resp.envelope;
      final body = env['data'] is Map
          ? (env['data'] as Map).cast<String, dynamic>()
          : env;
      return WorkDay.fromJson(body);
    } on ApiException catch (e) {
      if (e.rawCode == kNoEmployeeProfile) return WorkDay.noProfile;
      rethrow;
    }
  }
}

String formatWorkDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
