/// صندوق الملاحة الواردة (رابط عميق/نقرة إشعار) — يُسلَّم فوراً إن كانت
/// الجلسة جاهزة، وإلا يُحفظ آخرُ واحدٍ حتى `LaunchReady` (بعد الدخول أو فتح
/// القفل البيومتري) كي لا يضيع الهدف في إعادة التوجيه إلى الدخول.
library;

import 'dart:async';

import 'launch_controller.dart';

/// يحلّ الوجهة عند التسليم (قد يحتاج الخادم — لذا بعد الجاهزية) أو null.
typedef LocationResolver = Future<String?> Function();

class NavigationInbox {
  NavigationInbox({required this.launch}) {
    launch.addListener(_onLaunch);
  }

  final LaunchController launch;

  void Function(String location)? _navigator;
  LocationResolver? _pending;
  bool _delivering = false;

  bool get hasPending => _pending != null;

  /// يربطه جذر التطبيق بالموجّه.
  void attachNavigator(void Function(String location) navigator) {
    _navigator = navigator;
    _flush();
  }

  void deliverLocation(String location) => deliver(() async => location);

  void deliver(LocationResolver resolve) {
    _pending = resolve; // الأحدث يغلب
    _flush();
  }

  void _onLaunch() => _flush();

  Future<void> _flush() async {
    final nav = _navigator;
    final resolve = _pending;
    if (_delivering ||
        nav == null ||
        resolve == null ||
        launch.state is! LaunchReady) {
      return;
    }
    _pending = null;
    _delivering = true;
    try {
      // بعد دورة الإعادة الحالية: إعادة توجيه الجاهزية (`/home`) تسبق الدفع.
      await Future<void>.delayed(Duration.zero);
      final location = await resolve();
      if (location != null && launch.state is LaunchReady) nav(location);
    } on Object {
      // حلٌّ فشل (شبكة) — لا ملاحة؛ الإشعار يبقى في صندوقه.
    } finally {
      _delivering = false;
    }
    if (_pending != null) unawaited(_flush());
  }

  void dispose() => launch.removeListener(_onLaunch);
}
