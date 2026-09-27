/// بطاقة الحضور على «مهامي» (المرحلة ٣.١): الحالة من الخادم، وزرّا الحضور
/// والانصراف بحسب `can`، وموقعٌ اختياريٌّ بموافقةٍ صريحة (مربّع يختاره المستخدم
/// لكل ضغطة — لا يُطلب إذن الموقع إلا حينها). بلا ملف موظف أو المسار غير متاح
/// لهذا الدور (٤٠٤) ⇒ لا بطاقة أصلاً.
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/feedback.dart';
import '../../l10n/app_localizations.dart';
import '../tracking/location_source.dart';
import 'attendance_repository.dart';

/// نص سبب الرفض الآلي — وإلا رسالة الخادم.
String attendanceReasonText(AppLocalizations l, ApiException e) =>
    switch (e.details['reason']?.toString()) {
      AttendanceReason.alreadyCheckedIn => l.attendanceAlreadyIn,
      AttendanceReason.openShiftPreviousDay => l.attendanceOpenShift,
      AttendanceReason.notCheckedIn => l.attendanceNotIn,
      AttendanceReason.alreadyCheckedOut => l.attendanceAlreadyOut,
      AttendanceReason.locationConsentRequired => l.attendanceConsentRequired,
      AttendanceReason.noEmployeeProfile => l.attendanceNoProfile,
      _ => e.message.isNotEmpty ? e.message : l.stateError,
    };

class AttendanceCard extends StatefulWidget {
  const AttendanceCard({super.key, this.onChanged});

  /// يُستدعى بعد حضور/انصراف ناجح (لتحديث حال اليوم في الشاشة الحاوية).
  final VoidCallback? onChanged;

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  AttendanceToday? _today;
  bool _hidden = false;
  bool _loading = true;
  bool _busy = false;
  bool _shareLocation = false;
  String? _mode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await AppScope.of(context).attendance.today();
      if (!mounted) return;
      setState(() {
        _today = t;
        _hidden = t == null;
        _mode ??= t != null && t.modes.isNotEmpty ? t.modes.first : null;
      });
    } on ApiException catch (e) {
      // المسار غير متاح لهذا الدور ⇒ لا بطاقة (لا زرّ ميت).
      if (mounted && e.code == ApiErrorCode.resourceNotFound) {
        setState(() => _hidden = true);
      }
    } on Object {
      // ثانوي على «مهامي» — الفشل العابر لا يسقط الشاشة؛ تبقى البطاقة بلا حال.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// قراءة موقع واحدة بعد موافقة المستخدم الصريحة — أو null (إذن مرفوض/مهلة).
  Future<LocationFix?> _consentedFix() async {
    if (!_shareLocation) return null;
    final source = AppScope.of(context).location;
    if (!await source.ensurePermission()) return null;
    try {
      return await source.positions().first.timeout(
        const Duration(seconds: 15),
      );
    } on Object {
      return null;
    }
  }

  Future<void> _act({required bool checkIn}) async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).attendance;
    setState(() => _busy = true);
    // مفتاحٌ واحد للضغطة — ثابت عبر إعادة المحاولة العابرة (§58).
    final key = const Uuid().v4();
    try {
      final fix = await _consentedFix();
      if (_shareLocation && fix == null && mounted) {
        showSnack(context, l.attendanceLocationUnavailable);
      }
      final res = checkIn
          ? await repo.checkIn(
              mode: _mode,
              consentedLocation: fix,
              idempotencyKey: key,
            )
          : await repo.checkOut(consentedLocation: fix, idempotencyKey: key);
      if (!mounted) return;
      showSnack(
        context,
        res.message.isNotEmpty
            ? res.message
            : (checkIn ? l.attendanceCheckedIn : l.attendanceCheckedOut),
      );
      await _load();
      widget.onChanged?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      final reason = e.details['reason']?.toString();
      showSnack(
        context,
        reason == null ? describeError(context, e) : attendanceReasonText(l, e),
      );
      await _load();
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_hidden) return const SizedBox.shrink();
    final t = _today;
    if (t == null) {
      return _loading
          ? const Card(
              margin: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 56,
                child: Center(child: LinearProgressIndicator()),
              ),
            )
          : const SizedBox.shrink();
    }
    final row = t.row;
    final stateText = switch (t.state) {
      AttendanceState.notCheckedIn => l.attendanceStateNotIn,
      AttendanceState.checkedIn => l.attendanceStateIn(row?.timeIn ?? ''),
      AttendanceState.checkedOut => l.attendanceStateOut(
        row?.timeIn ?? '',
        row?.timeOut ?? '',
      ),
    };
    return Card(
      key: const Key('attendance-card'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fingerprint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.attendanceTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (row?.hours != null)
                  Chip(label: Text(l.attendanceHours(row!.hours.toString()))),
              ],
            ),
            const SizedBox(height: 4),
            Text(stateText, key: const Key('attendance-state')),
            if (row?.overnight ?? false)
              Text(
                l.attendanceOvernight,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (t.canCheckIn && t.modes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: InputDecoration(
                    labelText: l.attendanceMode,
                    isDense: true,
                  ),
                  items: [
                    for (final m in t.modes)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => setState(() => _mode = v),
                ),
              ),
            // الموقع: فقط حين يحفظه الخادم، وبموافقةٍ صريحة لكل ضغطة.
            if (t.serverRecordsLocation && (t.canCheckIn || t.canCheckOut))
              CheckboxListTile(
                key: const Key('attendance-consent'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _shareLocation,
                onChanged: (v) => setState(() => _shareLocation = v ?? false),
                title: Text(l.attendanceShareLocation),
                subtitle: Text(l.attendanceShareLocationHint),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (t.canCheckIn)
                  FilledButton.icon(
                    key: const Key('attendance-check-in'),
                    onPressed: _busy ? null : () => _act(checkIn: true),
                    icon: const Icon(Icons.login),
                    label: Text(l.attendanceCheckIn),
                  ),
                if (t.canCheckOut)
                  FilledButton.tonalIcon(
                    key: const Key('attendance-check-out'),
                    onPressed: _busy ? null : () => _act(checkIn: false),
                    icon: const Icon(Icons.logout),
                    label: Text(l.attendanceCheckOut),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
