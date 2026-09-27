/// مهامي (§48) — تجميع قدرات المستخدم القائمة: مهامه، اعتماداته، إشعاراته،
/// رسائله، وحال يومه (§93) — عبر واجهات فعلية لا منطق أعمال مكرر.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../attendance/attendance_card.dart';
import '../home/home_repository.dart';
import '../shell/app_shell.dart';
import 'daily_report_screen.dart';
import 'work_repository.dart';

class MyWorkScreen extends StatefulWidget {
  const MyWorkScreen({super.key});

  @override
  State<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends State<MyWorkScreen> {
  HomeSnapshot? _snapshot;
  int _dmUnread = 0;
  WorkDay? _workDay;

  /// مداخل المرحلتين ٣/٤ — تظهر بما يعيده الخادم لهذا الدور (لا زرّ ميت).
  bool _canInventory = false;
  bool _canReview = false;
  int? _alertsTotal;
  Object? _error;
  bool _loading = true;

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
    final c = AppScope.of(context);
    try {
      final snap = await c.home.fetch();
      var dmUnread = 0;
      try {
        dmUnread = (await c.dm.threads()).unreadTotal;
      } on Object {
        // الرسائل ثانوية هنا — فشلها لا يسقط الشاشة.
      }
      WorkDay? workDay;
      try {
        // حال اليوم ثانوي: بلا ملف موظف (حالة صادقة) أو فشل ⇒ لا بطاقة.
        workDay = await c.work.today();
      } on Object {
        workDay = null;
      }
      // جلسات الجرد لمن يرى الأصول في مخططه.
      var canInventory = false;
      try {
        final schema = c.modules.lastSchema ?? await c.modules.schema();
        canInventory = schema.modules['assets']?.can.v ?? false;
      } on Object {
        canInventory = false;
      }
      // مراجعة تقارير الفريق: الخادم يحسم الأهلية (403 لغير المراجِع).
      var canReview = false;
      try {
        await c.teamReports.daily();
        canReview = true;
      } on ApiException {
        canReview = false;
      } on Object {
        canReview = false;
      }
      int? alertsTotal;
      try {
        alertsTotal = (await c.calendar.alerts()).total;
      } on Object {
        alertsTotal = null;
      }
      if (mounted) {
        setState(() {
          _snapshot = snap;
          _dmUnread = dmUnread;
          _workDay = workDay;
          _canInventory = canInventory;
          _canReview = canReview;
          _alertsTotal = alertsTotal;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.myWorkTitle),
        actions: shellHeaderActions(context),
      ),
      body: AsyncView<HomeSnapshot>(
        loading: _loading,
        error: _error,
        value: _snapshot,
        onRetry: _load,
        builder: (context, snap) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AttendanceCard(
                key: const Key('mywork-attendance'),
                onChanged: _load,
              ),
              if (_workDay?.compliance != null && !_workDay!.noEmployeeProfile)
                WorkDayCard(
                  key: const Key('mywork-today'),
                  day: _workDay!.compliance!,
                  onTap: () async {
                    await context.push('/work/daily-report');
                    if (mounted) _load();
                  },
                ),
              _EntryTile(
                icon: Icons.approval_outlined,
                title: l.myWorkApprovals,
                count: snap.approvalsCount,
                onTap: () => context.push('/approvals'),
              ),
              _EntryTile(
                icon: Icons.notifications_outlined,
                title: l.myWorkNotifications,
                count: snap.unreadNotifications,
                onTap: () => context.push('/notifications'),
              ),
              _EntryTile(
                icon: Icons.chat_bubble_outline,
                title: l.myWorkMessages,
                count: _dmUnread,
                onTap: () => context.push('/messages'),
              ),
              if (_alertsTotal != null)
                _EntryTile(
                  key: const Key('mywork-alerts'),
                  icon: Icons.notification_important_outlined,
                  title: l.alertsTitle,
                  count: _alertsTotal!,
                  onTap: () => context.push('/alerts'),
                ),
              _EntryTile(
                key: const Key('mywork-calendar'),
                icon: Icons.calendar_month_outlined,
                title: l.calendarTitle,
                count: 0,
                onTap: () => context.push('/calendar'),
              ),
              _EntryTile(
                key: const Key('mywork-custody'),
                icon: Icons.devices_other_outlined,
                title: l.custodyTitle,
                count: 0,
                onTap: () => context.push('/me/custody'),
              ),
              if (_canInventory)
                _EntryTile(
                  key: const Key('mywork-inventory'),
                  icon: Icons.inventory_outlined,
                  title: l.inventoryTitle,
                  count: 0,
                  onTap: () => context.push('/inventory'),
                ),
              if (_canReview)
                _EntryTile(
                  key: const Key('mywork-team-reports'),
                  icon: Icons.fact_check_outlined,
                  title: l.teamReportsTitle,
                  count: 0,
                  onTap: () => context.push('/reports/daily'),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  '${l.myWorkTasks} (${snap.myWorkCount})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (snap.myWork.isEmpty)
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyView(),
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: snap.myWork
                        .map(
                          (i) => ListTile(
                            title: Text(
                              i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                if (i.status != null) i.status!,
                                if (i.due != null) i.due!,
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(i.target.routePath),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) Badge(label: Text('$count')),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    ),
  );
}
