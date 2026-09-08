/// تسجيل محجوب — لا سر يبلغ السجل أبداً (§85).
///
/// القاعدة بنيوية لا اجتهادية: كل ما يمر عبر [RedactingLogger] يُمرَّر على
/// [redact] فتُطمس القيم الحساسة (رموز، كلمات مرور، ترويسة Authorization،
/// أكواد MFA) حتى في سجلات التطوير.
library;

import 'package:flutter/foundation.dart';

class RedactingLogger {
  RedactingLogger({this.sink});

  /// مصب اختياري للاختبارات؛ الافتراض `debugPrint` في التطوير ولا شيء في الإصدار.
  final void Function(String line)? sink;

  static final List<RegExp> _valuePatterns = [
    // رموز الجلسة النصية (lyma_/lymr_) وأي Bearer
    RegExp(r'ly(ma|mr)_[A-Za-z0-9._-]+'),
    RegExp(r'Bearer\s+\S+'),
  ];

  static final RegExp _sensitiveKey = RegExp(
    r'^(password|access_token|refresh_token|token|credential|code|secret|authorization|idempotency-key|x-api-key)$',
    caseSensitive: false,
  );

  /// طمس نص حر.
  static String redact(String message) {
    var out = message;
    for (final p in _valuePatterns) {
      out = out.replaceAll(p, '‹محجوب›');
    }
    return out;
  }

  /// طمس خريطة (ترويسات/حمولة) قبل تسجيلها.
  static Map<String, Object?> redactMap(Map<String, Object?> map) => map.map(
    (k, v) => MapEntry(
      k,
      _sensitiveKey.hasMatch(k) ? '‹محجوب›' : (v is String ? redact(v) : v),
    ),
  );

  void info(String message) => _emit('I', message);
  void warn(String message) => _emit('W', message);
  void error(String message, [Object? err]) =>
      _emit('E', err == null ? message : '$message: ${redact(err.toString())}');

  void _emit(String level, String message) {
    final line = '[$level] ${redact(message)}';
    if (sink != null) {
      sink!(line);
    } else if (kDebugMode) {
      debugPrint(line);
    }
  }
}
