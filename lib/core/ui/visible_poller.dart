/// استطلاعٌ دوريٌّ لا يعمل إلا والشاشةُ مرئية (§106 · الجلب التدريجي).
///
/// يتوقف كلياً حين يذهب التطبيق للخلفية (لا مؤقّت ولا نداء)، ويستأنف بنبضةٍ
/// فورية عند العودة. وبين النبضات يُسأل [isVisible] (مثلاً: أهي المسارُ الحالي؟)
/// فلا نداءَ لشاشةٍ غطّتها أخرى. ولا نبضتان متداخلتان أبداً.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

class VisiblePoller {
  VisiblePoller({
    required this.interval,
    required this.onTick,
    required this.isVisible,
  });

  final Duration interval;
  final Future<void> Function() onTick;
  final bool Function() isVisible;

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _inFlight = false;
  bool _foreground = true;
  bool _disposed = false;

  /// هل المؤقّت يعمل الآن (للاختبار والتشخيص).
  bool get running => _timer != null;

  void start() {
    if (_disposed) return;
    _lifecycle ??= AppLifecycleListener(onStateChange: _onLifecycle);
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = _foreground && !_disposed
        ? Timer.periodic(interval, (_) => tick())
        : null;
  }

  void _onLifecycle(AppLifecycleState s) {
    final fg = s == AppLifecycleState.resumed;
    if (fg == _foreground) return;
    _foreground = fg;
    _arm();
    if (fg) tick();
  }

  /// نبضةٌ واحدة الآن (إن كانت الشاشة مرئية ولا نبضة جارية).
  Future<void> tick() async {
    if (_disposed || _inFlight || !_foreground || !isVisible()) return;
    _inFlight = true;
    try {
      await onTick();
    } on Object {
      // الاستطلاع لا يُسقط الشاشة — الخطأ يُعالَج في onTick إن لزم.
    } finally {
      _inFlight = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    stop();
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}

/// أداةٌ لـ«أهذه الشاشة هي المسار الظاهر؟» — غطاءٌ (مسارٌ/ورقةٌ فوقها) ⇒ لا.
bool routeIsCurrent(BuildContext context) {
  if (!context.mounted) return false;
  return ModalRoute.of(context)?.isCurrent ?? true;
}

/// نبضةُ «أكتب الآن» مخنوقة: نداءٌ واحدٌ كل [every] على الأكثر، وتتوقف نهائياً
/// حين يقول الخادم إن القدرة مطفأة (يُبلَّغ عبر [disable]).
class TypingThrottle {
  TypingThrottle(this.send, {this.every = const Duration(seconds: 4)});

  final Future<void> Function() send;
  final Duration every;
  DateTime? _last;
  bool _disabled = false;

  bool get disabled => _disabled;

  void disable() => _disabled = true;

  /// يُنادى عند كل تغيّر في حقل الكتابة.
  void onInput({DateTime? now}) {
    if (_disabled) return;
    final t = now ?? DateTime.now();
    if (_last != null && t.difference(_last!) < every) return;
    _last = t;
    unawaited(send().catchError((Object _) {}));
  }
}
