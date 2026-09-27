/// منسّق الدفع (§73–§75) — يربط المزوّد بدورة الجلسة والملاحة والشارة:
///
///  • الجاهزية (دخول/إقلاع مصادق) ⇒ طلب الإذن مرةً ثم `push/register`
///    `{platform, provider:'fcm', token}`؛ رفض الإذن ⇒ حالة صادقة بلا تسجيل.
///  • تدوير الرمز ⇒ إعادة التسجيل (والقديم يُلغى بهدوء).
///  • الخروج ⇒ `push/unregister` (في `AppContainer.signOut`)؛ إبطال الجلسة ⇒ نسيانٌ محلي.
///  • رسالة في المقدّمة ⇒ شريطٌ داخلي + الشارة من `data.unread`.
///  • نقرة إشعار (خلفية/إغلاق) ⇒ `data.module/id` ⇒ `/r/{module}/{id}`، أو
///    `notifications/{id}/target` حين لا يحمل إلا `notification_id`؛
///    والتجريبي (`category:'test'`) يُعرض ولا يُنقل منه.
///
/// الحمولة **عرضٌ** لا تخويل: شاشة السجل تطلبه من الخادم الذي يعيد الفحص.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/push/push_message.dart';
import '../../core/push/push_registrar.dart';
import '../../core/security/redacting_logger.dart';
import '../../features/notifications/notification_repository.dart';
import 'account_state.dart';
import 'launch_controller.dart';
import 'navigation_inbox.dart';

/// ما يعرضه الجذر شريطاً داخلياً.
class PushBanner {
  const PushBanner(this.payload);

  final PushPayload payload;

  /// يُعرض زر «فتح» حين للإشعار وجهةٌ (لا للتجريبي).
  bool get openable => payload.navigable;
}

class PushCoordinator {
  PushCoordinator({
    required this.launch,
    required this.account,
    required this.registrar,
    required this.provider,
    required this.notifications,
    required this.inbox,
    String Function()? platform,
    RedactingLogger? log,
  }) : _platform = platform ?? _defaultPlatform,
       _log = log ?? RedactingLogger();

  final LaunchController launch;
  final AccountState account;
  final PushRegistrar registrar;
  final PushTokenProvider provider;
  final NotificationRepository notifications;
  final NavigationInbox inbox;
  final String Function() _platform;
  final RedactingLogger _log;

  final _banners = StreamController<PushBanner>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  bool _attached = false;
  bool _wasReady = false;
  bool? _permissionGranted;

  Stream<PushBanner> get banners => _banners.stream;

  static String _defaultPlatform() =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// مرة واحدة من جذر التطبيق. المزوّد الصفري لا يبثّ شيئاً ولا يُطلب منه شيء.
  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    launch.addListener(_onLaunchChanged);
    if (!provider.configured) return;
    _subs
      ..add(provider.foregroundMessages.listen(onForeground))
      ..add(provider.openedMessages.listen(onOpened))
      ..add(
        provider.tokenRotations.listen((t) {
          if (launch.state is LaunchReady) {
            unawaited(_quiet(() => registrar.onTokenRotated(t)));
          }
        }),
      );
    _onLaunchChanged();
    final initial = await provider.initialMessage();
    if (initial != null) onOpened(initial);
  }

  void detach() {
    launch.removeListener(_onLaunchChanged);
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _attached = false;
  }

  void _onLaunchChanged() {
    final state = launch.state;
    final ready = state is LaunchReady;
    if (ready && !_wasReady) unawaited(onReady());
    // خروج/إبطال: الخادم أبطل رموز الجلسة — نسيانٌ محلي بلا شبكة.
    if (state is LaunchLoggedOut) registrar.forget();
    _wasReady = ready;
  }

  /// الجلسة جاهزة: الإذن (مرة لكل تشغيل) ثم التسجيل — صامت الفشل.
  Future<void> onReady() async {
    if (!provider.configured) return;
    final granted = _permissionGranted ??= await provider.requestPermission();
    if (!granted) {
      registrar.markPermissionDenied();
      return;
    }
    await _quiet(() => registrar.registerIfPossible(platform: _platform()));
  }

  void onForeground(PushMessage m) {
    final p = PushPayload.of(m);
    _applyBadge(p);
    _banners.add(PushBanner(p));
  }

  void onOpened(PushMessage m) {
    final p = PushPayload.of(m);
    _applyBadge(p);
    if (p.isTest || !p.navigable) {
      // التجريبي/بلا وجهة: يُعرض ولا يُنقل منه.
      _banners.add(PushBanner(p));
      return;
    }
    open(p);
  }

  /// فتح وجهة الإشعار — عبر الصندوق (ينتظر الجاهزية إن لزم).
  void open(PushPayload p) {
    if (!p.navigable) return;
    inbox.deliver(() => resolveLocation(p));
  }

  /// `/r/{module}/{id}` من الحمولة، وإلا `GET notifications/{id}/target`
  /// (null ⇒ صندوق الإشعارات بدل البقاء بلا أثر).
  Future<String?> resolveLocation(PushPayload p) async {
    final direct = p.target;
    if (direct != null) return direct.routePath;
    final id = p.notificationId;
    if (id == null) return null;
    try {
      return (await notifications.target(id))?.routePath ?? '/notifications';
    } on Object {
      return '/notifications';
    }
  }

  void _applyBadge(PushPayload p) {
    final unread = p.unread;
    if (unread != null && launch.state is LaunchReady) {
      account.setUnread(unread);
    }
  }

  Future<void> _quiet(Future<Object?> Function() f) async {
    try {
      await f();
    } on Object catch (e) {
      _log.warn(PushRegistrar.failureLog(e));
    }
  }

  Future<void> dispose() async {
    detach();
    await _banners.close();
  }
}
