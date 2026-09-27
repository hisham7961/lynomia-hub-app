/// الحضور والانصراف (المرحلة ٣.١) — `attendance/today|check-in|check-out`.
///
/// الخادم (`Workday`) يحسم كل شيء: الحالة والساعات والوردية المفتوحة. التطبيق
/// يعرض ما يجوز الآن (`can`) ويرسل الموقع **فقط** بموافقةٍ صريحة من المستخدم
/// (`location_consent=true`) — لحظة الضغط لا تتبّعاً. الرفض الدلالي يتفرّع على
/// `details.reason` الآلي لا على الرسالة.
library;

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
import '../../core/errors/api_exception.dart';
import '../my_work/work_repository.dart' show isNoEmployeeProfile;
import '../tracking/location_source.dart';

enum AttendanceState {
  notCheckedIn('not_checked_in'),
  checkedIn('checked_in'),
  checkedOut('checked_out');

  const AttendanceState(this.wire);
  final String wire;

  static AttendanceState parse(String? raw) => values.firstWhere(
    (s) => s.wire == raw,
    orElse: () => AttendanceState.notCheckedIn,
  );
}

/// أسباب الرفض الآلية (`details.reason`) كما يعلنها العقد.
abstract final class AttendanceReason {
  static const alreadyCheckedIn = 'already_checked_in';
  static const openShiftPreviousDay = 'open_shift_previous_day';
  static const noEmployeeProfile = 'no_employee_profile';
  static const locationConsentRequired = 'location_consent_required';
  static const notCheckedIn = 'not_checked_in';
  static const alreadyCheckedOut = 'already_checked_out';
}

class AttendanceRow {
  const AttendanceRow({
    required this.id,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.hours,
    this.status,
    this.mode,
    this.overnight = false,
  });

  factory AttendanceRow.fromJson(Map<String, dynamic> j) => AttendanceRow(
    id: j['id']?.toString() ?? '',
    date: j['date']?.toString() ?? '',
    timeIn: jsonStr(j['time_in']),
    timeOut: jsonStr(j['time_out']),
    hours: jsonDecimal(j['hours']),
    status: jsonStr(j['status']),
    mode: jsonStr(j['mode']),
    overnight: j['overnight'] == true,
  );

  final String id;
  final String date;
  final String? timeIn;
  final String? timeOut;

  /// الساعات كما حسبها الخادم — عرضٌ عشري لا حساب.
  final Decimal? hours;
  final String? status;
  final String? mode;
  final bool overnight;
}

class AttendanceToday {
  const AttendanceToday({
    required this.date,
    required this.state,
    required this.canCheckIn,
    required this.canCheckOut,
    required this.modes,
    required this.serverRecordsLocation,
    this.row,
    this.employeeName,
  });

  factory AttendanceToday.fromJson(Map<String, dynamic> j) {
    final can = jsonMap(j['can']);
    final loc = jsonMap(j['location']);
    final att = j['attendance'];
    return AttendanceToday(
      date: j['date']?.toString() ?? '',
      employeeName: jsonStr(jsonMap(j['employee'])['name']),
      row: att is Map ? AttendanceRow.fromJson(jsonMap(att)) : null,
      state: AttendanceState.parse(j['state']?.toString()),
      canCheckIn: can['check_in'] == true,
      canCheckOut: can['check_out'] == true,
      modes: jsonStrings(j['modes']),
      serverRecordsLocation: loc['recorded_by_server'] == true,
    );
  }

  final String date;
  final String? employeeName;
  final AttendanceRow? row;
  final AttendanceState state;
  final bool canCheckIn;
  final bool canCheckOut;

  /// أوضاع العمل التي يقبلها الخادم (قائمة زرّ الويب نفسها).
  final List<String> modes;

  /// الخادم يحفظ الموقع (`work.geo`) — وإلا فلا معنى لطلبه أصلاً.
  final bool serverRecordsLocation;
}

class AttendanceResult {
  const AttendanceResult({
    required this.row,
    required this.message,
    this.locationRecorded = false,
    this.reportState,
    this.reportDeadlineAt,
  });

  factory AttendanceResult.fromJson(Map<String, dynamic> j) => AttendanceResult(
    row: AttendanceRow.fromJson(jsonMap(j['attendance'])),
    message: j['message']?.toString() ?? '',
    locationRecorded: j['location_recorded'] == true,
    reportState: jsonStr(j['report_state']),
    reportDeadlineAt: jsonDate(j['report_deadline_at']),
  );

  final AttendanceRow row;

  /// رسالة الخادم العربية — للعرض فقط.
  final String message;
  final bool locationRecorded;
  final String? reportState;
  final DateTime? reportDeadlineAt;
}

class AttendanceRepository {
  AttendanceRepository(this.api);

  final ApiClient api;

  /// `GET attendance/today` — null ⇒ لا ملف موظف (حالة صادقة لا خطأ).
  Future<AttendanceToday?> today() async {
    try {
      return AttendanceToday.fromJson(await api.getData('attendance/today'));
    } on ApiException catch (e) {
      if (isNoEmployeeProfile(e)) return null;
      rethrow;
    }
  }

  /// `POST attendance/check-in` — المفتاح ثابت للضغطة الواحدة (§58)؛ الموقع
  /// يُرسل فقط حين يمرّره المستدعي بعد موافقةٍ صريحة.
  Future<AttendanceResult> checkIn({
    String? mode,
    LocationFix? consentedLocation,
    String? idempotencyKey,
  }) async => AttendanceResult.fromJson(
    await api.sendData(
      'POST',
      'attendance/check-in',
      body: {'mode': ?mode, ..._location(consentedLocation)},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  /// `POST attendance/check-out`.
  Future<AttendanceResult> checkOut({
    LocationFix? consentedLocation,
    String? idempotencyKey,
  }) async => AttendanceResult.fromJson(
    await api.sendData(
      'POST',
      'attendance/check-out',
      body: _location(consentedLocation),
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  static Map<String, dynamic> _location(LocationFix? fix) => fix == null
      ? const {}
      : {
          'lat': fix.lat,
          'lng': fix.lng,
          if (fix.accuracy != null) 'accuracy': fix.accuracy,
          'location_consent': true,
        };
}
