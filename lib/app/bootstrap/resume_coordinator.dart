/// منسّق الإقلاع والاستئناف (§45 §51 §60 §94) — ما يجري حين تصير الجلسة جاهزة
/// وحين يعود التطبيق للمقدّمة، بتواترٍ مقيّد لا وابل:
///
///  • `GET health` (عامة) ⇒ صيانة/إغلاق/تحديث حاجب أثناء الاستعمال.
///  • `GET notifications/unread-count` ⇒ الشارة الحية.
///  • مزامنة الخلفية للوحدات `CACHEABLE_*` وحدها (للحساب الداخلي).
///
/// كل خطوة صامتة الفشل: الانقطاع يظهر في شريط الاتصال والشاشات الحية، لا هنا.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/errors/api_exception.dart';
import '../../features/launch/app_config_repository.dart';
import '../../features/modules/sync_scheduler.dart';
import '../../features/notifications/notification_repository.dart';
import 'account_state.dart';
import 'launch_controller.dart';

class ResumeCoordinator {
  ResumeCoordinator({
    required this.launch,
    required this.account,
    required this.appConfigRepo,
    required this.notifications,
    required this.syncScheduler,
    DateTime Function()? now,
    this.healthInterval = const Duration(seconds: 60),
    this.badgeInterval = const Duration(seconds: 15),
  }) : _now = now ?? DateTime.now;

  final LaunchController launch;
  final AccountState account;
  final AppConfigRepository appConfigRepo;
  final NotificationRepository notifications;
  final SyncScheduler syncScheduler;
  final DateTime Function() _now;

  /// أدنى فاصل بين فحصَي صحة (الخادم يحدّ `health` بـ60/دقيقة).
  final Duration healthInterval;
  final Duration badgeInterval;

  DateTime? _lastHealth;
  DateTime? _lastBadge;
  AppLifecycleListener? _lifecycle;
  bool _wasReady = false;

  /// ربط دورة الحياة وحالة الإقلاع — مرة واحدة من جذر التطبيق.
  void attach() {
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(onResumed()));
    launch.addListener(_onLaunchChanged);
    _onLaunchChanged();
  }

  void detach() {
    _lifecycle?.dispose();
    _lifecycle = null;
    launch.removeListener(_onLaunchChanged);
  }

  void _onLaunchChanged() {
    final ready = launch.state is LaunchReady;
    if (ready && !_wasReady) unawaited(onReady());
    if (!ready && launch.state is LaunchLoggedOut) syncScheduler.reset();
    _wasReady = ready;
  }

  /// الجلسة صارت جاهزة (إقلاع/دخول): الشارة + مزامنة الخلفية. الصحة فُحصت
  /// للتو ضمنياً عبر `app-config` في الإقلاع — فلا تكرار.
  Future<void> onReady() async {
    _lastHealth = _now();
    await refreshBadge(force: true);
    await _backgroundSync();
  }

  /// عودة للمقدّمة: صحة (مقيّدة) ثم شارة ثم مزامنة — كلٌّ بمهلته.
  Future<void> onResumed() async {
    if (launch.state is! LaunchReady) return;
    await checkHealth();
    if (launch.state is! LaunchReady) return; // حُجب بصيانة/تحديث
    await refreshBadge();
    await _backgroundSync();
  }

  Future<void> checkHealth({bool force = false}) async {
    final last = _lastHealth;
    if (!force && last != null && _now().difference(last) < healthInterval) {
      return;
    }
    _lastHealth = _now();
    try {
      await launch.applyHealth(await appConfigRepo.health());
    } on ApiException catch (e) {
      launch.onServiceBlocked(e);
    } on Object {
      // انقطاع — شريط الاتصال يتكفّل بالعرض.
    }
  }

  Future<void> refreshBadge({bool force = false}) async {
    final last = _lastBadge;
    if (!force && last != null && _now().difference(last) < badgeInterval) {
      return;
    }
    _lastBadge = _now();
    try {
      account.setUnread(await notifications.unreadCount());
    } on Object {
      // الشارة تبقى على آخر قيمة خادمية معروفة.
    }
  }

  Future<void> _backgroundSync() async {
    // بوابة العميل عالم حي بلا تخبئة (§12) — المزامنة للداخلي وحده.
    if (account.isClient || account.user == null) return;
    await syncScheduler.syncBackground();
  }
}
