/// مراجعة التقارير اليومية للفريق (المرحلة ٤.٤) — للمدير/الموارد البشرية: يومٌ
/// بعينه، والنطاق (فريقي/مشاريعي)، وتصفية بالحالة، وقبول/طلب تنقيح (ملاحظة
/// إلزامية)/إعادة فتح لكل بندٍ يجيزه الخادم (`can_review`). وقسم «امتثال
/// اليوم» (الحضور×التقرير لكل موظف) حين يبثّه الخادم — لحامل `hr:v` وحده.
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../core/ui/feedback.dart';
import '../../l10n/app_localizations.dart';
import 'team_reports_repository.dart';

/// تسمية رمز الامتثال من ARB — تفريعٌ على الرمز الآلي لا على `labels` العربية.
String complianceLabel(AppLocalizations l, ComplianceRow r) {
  if (r.verdictPending) return l.complianceVerdictPending;
  return switch (r.compliance) {
    ComplianceCode.compliant => l.complianceCompliant,
    ComplianceCode.pending => l.compliancePending,
    ComplianceCode.late => l.complianceLate,
    ComplianceCode.notRequired => l.complianceNotRequired,
    ComplianceCode.reported => l.complianceReported,
    _ => l.complianceMissing,
  };
}

String reviewStatusLabel(AppLocalizations l, String s) => switch (s) {
  ReviewStatus.accepted => l.reviewAccepted,
  ReviewStatus.needsRevision => l.reviewNeedsRevision,
  _ => l.reviewPending,
};

class TeamReportsScreen extends StatefulWidget {
  const TeamReportsScreen({super.key});

  @override
  State<TeamReportsScreen> createState() => _TeamReportsScreenState();
}

class _TeamReportsScreenState extends State<TeamReportsScreen> {
  DateTime _date = DateTime.now();
  String? _scope;
  String _status = 'all';
  TeamDaily? _data;
  Object? _error;
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await AppScope.of(context).teamReports
          .daily(date: _date, scope: _scope, status: _status);
      if (mounted) {
        setState(() {
          _data = d;
          _scope = d.scope;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(ReviewEntry e, ReviewAction a) async {
    final l = AppLocalizations.of(context)!;
    String? feedback;
    if (a == ReviewAction.needsRevision) {
      feedback = await promptTextDialog(
        context,
        title: l.reviewFeedbackTitle,
        hint: l.reviewFeedbackHint,
        required: true,
        maxLength: 2000,
      );
      if (feedback == null) return;
    }
    if (!mounted) return;
    setState(() => _busy.add(e.id));
    try {
      await AppScope.of(context).teamReports.review(
        e.id,
        a,
        feedback: feedback,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      showSnack(context, l.actionDone);
      await _load();
    } on Object catch (err) {
      if (mounted) showErrorSnack(context, err);
    } finally {
      if (mounted) setState(() => _busy.remove(e.id));
    }
  }

  void _shiftDay(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: Text(l.teamReportsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: l.previousDay,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftDay(-1),
                ),
                Expanded(
                  child: Text(
                    formatShortDate(_date, locale),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l.nextDay,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftDay(1),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'team',
                      label: Text(l.reviewScopeTeam),
                    ),
                    ButtonSegment(
                      value: 'mine',
                      label: Text(l.reviewScopeMine),
                    ),
                  ],
                  selected: {_scope ?? 'mine'},
                  onSelectionChanged: (v) {
                    setState(() => _scope = v.first);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                for (final (key, label) in [
                  ('all', l.reviewAll),
                  ('pending', l.reviewPending),
                  ('needs_revision', l.reviewNeedsRevision),
                  ('accepted', l.reviewAccepted),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      key: Key('review-filter-$key'),
                      label: Text(label),
                      selected: _status == key,
                      onSelected: (_) {
                        setState(() => _status = key);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (d != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l.reviewSummary(
                  d.total,
                  d.pending,
                  d.accepted,
                  d.needsRevision,
                ),
                key: const Key('review-summary'),
              ),
            ),
          Expanded(
            child: AsyncView<TeamDaily>(
              loading: _loading,
              error: _error,
              value: d,
              onRetry: _load,
              emptyWhen: (d) =>
                  d.entries.isEmpty && (d.compliance?.isEmpty ?? true),
              emptyMessage: l.reviewEmpty,
              builder: (context, d) => RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (d.compliance case final rows? when rows.isNotEmpty)
                      _ComplianceSection(rows: rows),
                    for (final e in d.entries)
                      _EntryCard(
                        entry: e,
                        busy: _busy.contains(e.id),
                        onAction: (a) => _review(e, a),
                      ),
                    if (d.truncated)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(l.reviewTruncated),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.busy,
    required this.onAction,
  });

  final ReviewEntry entry;
  final bool busy;
  final void Function(ReviewAction) onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = entry;
    final small = Theme.of(context).textTheme.bodySmall;
    return Card(
      key: Key('review-entry-${e.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.author?.name ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(label: Text(reviewStatusLabel(l, e.reviewStatus))),
              ],
            ),
            Text(
              [
                ?e.projectName,
                ?e.taskTitle,
                if (e.hours != null) l.reviewHours(e.hours.toString()),
                if (e.progress != null) l.reviewProgress(e.progress.toString()),
              ].join(' · '),
              style: small,
            ),
            if (e.done != null) ...[const SizedBox(height: 6), Text(e.done!)],
            if (e.problems != null)
              Text(l.reviewProblems(e.problems!), style: small),
            if (e.next != null) Text(l.reviewNext(e.next!), style: small),
            if (e.reviewFeedback != null)
              Text(l.reviewFeedback(e.reviewFeedback!), style: small),
            if (e.canReview)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (e.reviewStatus != ReviewStatus.accepted)
                      FilledButton.tonal(
                        key: Key('review-accept-${e.id}'),
                        onPressed: busy
                            ? null
                            : () => onAction(ReviewAction.accept),
                        child: Text(l.reviewAccept),
                      ),
                    if (e.reviewStatus != ReviewStatus.needsRevision)
                      OutlinedButton(
                        key: Key('review-revise-${e.id}'),
                        onPressed: busy
                            ? null
                            : () => onAction(ReviewAction.needsRevision),
                        child: Text(l.reviewRequestRevision),
                      ),
                    if (e.reviewStatus != ReviewStatus.pending)
                      TextButton(
                        key: Key('review-reopen-${e.id}'),
                        onPressed: busy
                            ? null
                            : () => onAction(ReviewAction.reopen),
                        child: Text(l.reviewReopen),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// امتثال اليوم لموظفي النطاق — ملخّصٌ بالرموز ثم صفٌّ لكل موظف (مطويٌّ افتراضاً).
class _ComplianceSection extends StatelessWidget {
  const _ComplianceSection({required this.rows});

  final List<ComplianceRow> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final small = Theme.of(context).textTheme.bodySmall;
    int count(bool Function(ComplianceRow) f) => rows.where(f).length;
    final done = count(
      (r) =>
          !r.verdictPending &&
          (r.compliance == ComplianceCode.compliant ||
              r.compliance == ComplianceCode.late ||
              r.compliance == ComplianceCode.reported),
    );
    final pending = count(
      (r) => r.verdictPending || r.compliance == ComplianceCode.pending,
    );
    final missing = count(
      (r) => !r.verdictPending && r.compliance == ComplianceCode.missing,
    );
    return Card(
      key: const Key('compliance-section'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(l.complianceTitle(rows.length)),
        subtitle: Text(
          l.complianceSummary(done, pending, missing),
          key: const Key('compliance-summary'),
        ),
        children: [
          for (final r in rows)
            ListTile(
              key: Key('compliance-${r.employeeId}'),
              dense: true,
              title: Text(r.name ?? '—'),
              subtitle: Text(
                [
                  ?r.dept,
                  if (r.onLeave) l.complianceOnLeave,
                  if (r.timeIn != null) l.complianceTimeIn(r.timeIn!),
                  if (r.timeOut != null) l.complianceTimeOut(r.timeOut!),
                  if (r.lateArrival) l.complianceLateArrival,
                ].join(' · '),
                style: small,
              ),
              trailing: Chip(
                visualDensity: VisualDensity.compact,
                label: Text(complianceLabel(l, r)),
              ),
            ),
        ],
      ),
    );
  }
}
