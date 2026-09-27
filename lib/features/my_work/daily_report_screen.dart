/// «يومي» والتقرير اليومي (§93) — حال اليوم كما يحسمه الخادم، وبنوده، والتنقل
/// بين الأيام. التقديم إنشاء بندٍ في الوحدة التي يسمّيها الخادم (`submit_hint`)
/// ويظهر زرّه فقط إن كان للمستخدم صلاحية الإضافة فيها بحسب المخطط.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../l10n/app_localizations.dart';
import 'work_repository.dart';

String reviewStatusLabel(AppLocalizations l, String code) => switch (code) {
  'accepted' => l.workReviewAccepted,
  'needs_revision' => l.workReviewNeedsRevision,
  _ => l.workReviewPending,
};

/// بطاقة ملخّص اليوم — تُستعمل في «مهامي» وفي رأس التقرير.
class WorkDayCard extends StatelessWidget {
  const WorkDayCard({super.key, required this.day, this.onTap});

  final WorkCompliance day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final lines = <String>[
      if (day.physicalLabel != null)
        '${l.workAttendance}: ${day.physicalLabel}',
      if (day.complianceLabel != null)
        '${l.workReport}: ${day.complianceLabel}',
      if (day.timeIn != null) l.workCheckIn(day.timeIn!),
      if (day.timeOut != null) l.workCheckOut(day.timeOut!),
      if (day.reportedHours != null)
        l.workReportedHours(day.reportedHours!.toString()),
      if (day.reportDue && day.deadlineAt != null)
        l.workDeadline(formatShortTime(day.deadlineAt!, locale)),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.today_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.workTodayTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (day.effectiveLabel != null)
                    Chip(
                      key: const Key('work-effective'),
                      label: Text(day.effectiveLabel!),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(line, style: theme.textTheme.bodyMedium),
                ),
              if (day.verdictPending)
                Text(l.workVerdictPending, style: theme.textTheme.bodySmall),
              if (day.reportDue)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.workReportDue,
                    key: const Key('work-report-due'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: day.pastDeadline
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              if (day.needsReview)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.workNeedsReview,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  late DateTime _date;
  WorkDay? _day;
  Object? _error;
  bool _loading = true;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _load();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  Future<void> _load() async {
    final c = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
      _day = null;
    });
    try {
      final day = await c.work.dailyReport(_date);
      var canSubmit = false;
      final module = day.submitModule;
      if (module != null && !day.noEmployeeProfile) {
        try {
          // الزر فقط حين يقول المخطط إن للمستخدم الإضافة في الوحدة (لا باب ميت).
          canSubmit = (await c.modules.schema()).modules[module]?.can.a == true;
        } on Object {
          canSubmit = false;
        }
      }
      if (mounted) {
        setState(() {
          _day = day;
          _canSubmit = canSubmit;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shift(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.workDailyReport)),
      floatingActionButton: _canSubmit && _day?.submitModule != null
          ? FloatingActionButton.extended(
              key: const Key('work-submit'),
              icon: const Icon(Icons.add),
              label: Text(l.workSubmit),
              onPressed: () async {
                await context.push('/m/${_day!.submitModule}/new');
                if (mounted) _load();
              },
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  key: const Key('work-prev'),
                  tooltip: l.workPrevDay,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _loading ? null : () => _shift(-1),
                ),
                Expanded(
                  child: Text(
                    formatShortDate(_date, locale),
                    key: const Key('work-date'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('work-next'),
                  tooltip: l.workNextDay,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _loading || _isToday ? null : () => _shift(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<WorkDay>(
              loading: _loading,
              error: _error,
              value: _day,
              onRetry: _load,
              emptyWhen: (d) => d.noEmployeeProfile,
              emptyMessage: l.workNoProfile,
              builder: (context, day) => RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: [
                    if (day.compliance != null)
                      WorkDayCard(day: day.compliance!),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        l.workEntries(day.entries.length),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (day.entries.isEmpty)
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: EmptyView(message: l.workNoEntries),
                        ),
                      )
                    else
                      for (final e in day.entries) _EntryCard(entry: e),
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
  const _EntryCard({required this.entry});

  final WorkEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final e = entry;
    final meta = [
      if (e.hours != null) l.workEntryHours(e.hours!.toString()),
      if (e.progress != null) l.workEntryProgress(e.progress!.toString()),
      reviewStatusLabel(l, e.reviewStatus),
    ].join(' · ');
    return Card(
      key: Key('work-entry-${e.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.done != null && e.done!.isNotEmpty) Text(e.done!),
            const SizedBox(height: 4),
            Text(meta, style: theme.textTheme.bodySmall),
            if (e.problems != null && e.problems!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠ ${e.problems!}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (e.reviewFeedback != null && e.reviewFeedback!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '↩ ${e.reviewFeedback!}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
