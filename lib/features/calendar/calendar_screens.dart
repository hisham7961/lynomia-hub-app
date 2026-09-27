/// شاشتا التقويم والتنبيهات (المرحلة ٤.٥) — نافذة ٣٠ يوماً تتنقّل للأمام
/// والخلف، وأقسام «متأخر · خلال أسبوع · خلال النافذة». كل عنصر يفتح وجهته.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/dates.dart';
import '../../l10n/app_localizations.dart';
import 'calendar_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _window = 30;
  late DateTime _from;
  CalendarRange? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await AppScope.of(context).calendar.range(
        from: _from,
        to: _from.add(const Duration(days: _window - 1)),
      );
      if (mounted) setState(() => _data = d);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shift(int windows) {
    setState(() {
      _from = _from.add(Duration(days: _window * windows));
      _data = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final to = _from.add(const Duration(days: _window - 1));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.calendarTitle),
        actions: [
          IconButton(
            key: const Key('calendar-alerts'),
            tooltip: l.alertsTitle,
            icon: const Icon(Icons.notification_important_outlined),
            onPressed: () => context.push('/alerts'),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('calendar-prev'),
                tooltip: l.calendarPrev,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  '${formatShortDate(_from, locale)} — ${formatShortDate(to, locale)}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: const Key('calendar-next'),
                tooltip: l.calendarNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          Expanded(
            child: AsyncView<CalendarRange>(
              loading: _loading,
              error: _error,
              value: _data,
              onRetry: _load,
              emptyWhen: (d) => d.isEmpty,
              emptyMessage: l.calendarEmpty,
              builder: (context, d) => RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  children: [
                    for (final day in d.days)
                      if (day.items.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            12,
                            16,
                            4,
                          ),
                          child: Text(
                            day.date == null
                                ? ''
                                : formatShortDate(day.date!, locale),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        for (final it in day.items)
                          ListTile(
                            key: Key('calendar-item-${it.module}-${it.id}'),
                            dense: true,
                            leading: const Icon(Icons.event_outlined),
                            title: Text(it.name ?? it.id),
                            subtitle: Text(
                              '${it.moduleLabel} · ${it.fieldLabel}',
                            ),
                            onTap: () => context.push(it.routePath),
                          ),
                      ],
                    if (d.overflow > 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.calendarOverflow(d.overflow)),
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

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertsSnapshot? _data;
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
    try {
      final d = await AppScope.of(context).calendar.alerts();
      if (mounted) setState(() => _data = d);
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
      appBar: AppBar(title: Text(l.alertsTitle)),
      body: AsyncView<AlertsSnapshot>(
        loading: _loading,
        error: _error,
        value: _data,
        onRetry: _load,
        emptyWhen: (d) => d.total == 0,
        emptyMessage: l.alertsEmpty,
        builder: (context, d) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              for (final (title, items) in [
                (l.alertsLate, d.late),
                (l.alertsWeek, d.week),
                (l.alertsWindow(d.windowDays), d.month),
              ])
                if (items.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      16,
                      16,
                      4,
                    ),
                    child: Text(
                      '$title (${items.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final a in items)
                    ListTile(
                      key: Key('alert-${a.module}-${a.id}-${a.fieldLabel}'),
                      leading: Icon(
                        a.document
                            ? Icons.description_outlined
                            : Icons.event_busy_outlined,
                        color: a.days < 0
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      title: Text(a.name.isEmpty ? a.id : a.name),
                      subtitle: Text(
                        [
                          a.moduleLabel,
                          a.fieldLabel,
                          ?a.date,
                          a.days < 0
                              ? l.alertsDaysLate(-a.days)
                              : l.alertsDaysLeft(a.days),
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      onTap: switch (a.routePath) {
                        final String p => () => context.push(p),
                        _ => null,
                      },
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
