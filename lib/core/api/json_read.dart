/// قراءة حمولات الخادم بأمان (§31): مفاتيح غائبة أو أنواع غير متوقعة لا تُسقط
/// التطبيق — القيمة الغائبة `null` بصدق لا قيمةٌ مختلقة. والمال عشريٌّ لا double.
library;

import 'package:decimal/decimal.dart';

Map<String, dynamic> jsonMap(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

List<Map<String, dynamic>> jsonMaps(Object? v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

List<String> jsonStrings(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// نصٌّ غير فارغ أو null.
String? jsonStr(Object? v) {
  final s = v?.toString();
  return s == null || s.isEmpty ? null : s;
}

int jsonInt(Object? v, [int fallback = 0]) => switch (v) {
  final num n => n.toInt(),
  final String s => int.tryParse(s) ?? fallback,
  _ => fallback,
};

int? jsonIntOrNull(Object? v) => switch (v) {
  final num n => n.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};

DateTime? jsonDate(Object? v) => DateTime.tryParse(v?.toString() ?? '');

/// عشريٌّ من نصٍّ خادمي («2500.000») أو رقم — عرضٌ لا حساب (§81).
Decimal? jsonDecimal(Object? v) =>
    v == null ? null : Decimal.tryParse(v is num ? v.toString() : '$v');

/// مرجع مستخدم `{id, name}` كما يبثه الخادم.
class UserRef {
  const UserRef({required this.id, required this.name});

  static UserRef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return UserRef(id: id, name: raw['name']?.toString() ?? '');
  }

  final String id;
  final String name;
}

/// مسار نقطة مصادقة نسبي على `/api/mobile/v1` من مسارٍ يبثه الخادم
/// (`/api/mobile/v1/comments/1/attachment` ⇒ `comments/1/attachment`).
String mobileRelativePath(String path) {
  const prefix = '/api/mobile/v1/';
  var p = path;
  final uri = Uri.tryParse(p);
  if (uri != null && uri.hasScheme) p = uri.path;
  if (p.startsWith(prefix)) return p.substring(prefix.length);
  return p.replaceFirst(RegExp(r'^/+'), '');
}
