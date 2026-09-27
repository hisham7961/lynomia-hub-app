/// جذر التطبيق — عربي RTL أولاً (§23 §24): الاتجاه يقوده locale لا قسر.
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_manager.dart';
import '../core/links/deep_link.dart';
import '../l10n/app_localizations.dart';
import 'bootstrap/push_coordinator.dart';
import 'di/app_scope.dart';
import 'router/app_router.dart';

class LynomiaApp extends StatefulWidget {
  const LynomiaApp({
    super.key,
    required this.container,
    this.listenAppLinks = true,
  });

  final AppContainer container;

  /// تعطيل الاستماع في الاختبارات (لا قناة منصة).
  final bool listenAppLinks;

  @override
  State<LynomiaApp> createState() => _LynomiaAppState();
}

class _LynomiaAppState extends State<LynomiaApp> {
  late final GoRouter _router = buildRouter(widget.container);
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<PushBanner>? _bannerSub;
  StreamSubscription<Uri>? _linkSub;
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    widget.container.launch.start();
    // الإقلاع/الاستئناف: صحة مقيّدة، شارة حية، مزامنة القابل للتخبئة (§45 §51 §60).
    widget.container.resume.attach();
    _restorePrefs();
    // الملاحة الواردة (رابط/إشعار) تُسلَّم عبر الصندوق بعد الجاهزية — دفعاً
    // فوق الوجهة الحالية كي يبقى الرجوع ممكناً.
    widget.container.inbox.attachNavigator((loc) => _router.push(loc));
    _bannerSub = widget.container.pushCoordinator.banners.listen(_showBanner);
    unawaited(widget.container.pushCoordinator.attach());
    if (widget.listenAppLinks) _wireDeepLinks();
    // انتهاء/إبطال الجلسة أثناء الاستخدام ⇒ عودة للدخول (§38 §90).
    widget.container.session.endEvents.listen((reason) {
      if (reason != SessionEndReason.loggedOut) {
        widget.container.launch.onSignedOut();
      }
    });
  }

  @override
  void dispose() {
    widget.container.resume.detach();
    widget.container.pushCoordinator.detach();
    _bannerSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _restorePrefs() async {
    final prefs = widget.container.prefs;
    final locale = await prefs.get('locale');
    final theme = await prefs.get('theme');
    if (!mounted) return;
    setState(() {
      if (locale is String && locale.isNotEmpty) _locale = Locale(locale);
      _themeMode = switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  /// روابط عالمية/عميقة من حالة باردة وحية (§76 §90) — الموجه يطويها.
  Future<void> _wireDeepLinks() async {
    final links = AppLinks();
    try {
      final initial = await links.getInitialLink();
      if (initial != null) _openLink(initial);
    } on Object {
      // قناة غائبة (اختبار) — تجاهل صامت
    }
    _linkSub = links.uriLinkStream.listen(_openLink, onError: (_) {});
  }

  /// غير المطابق (`foldDeepLink` ⇒ null) يُتجاهل؛ والمطابق ينتظر الجاهزية.
  void _openLink(Uri uri) {
    final location = foldDeepLink(uri);
    if (location != null) widget.container.inbox.deliverLocation(location);
  }

  /// شريط الإشعار داخل التطبيق (رسالة في المقدّمة أو تجريبي) — نصّه من
  /// الحمولة العامة للخادم، وزر «فتح» حين للإشعار وجهة.
  void _showBanner(PushBanner banner) {
    final messenger = _messenger.currentState;
    final ctx = _messenger.currentContext;
    if (messenger == null || ctx == null) return;
    final l = AppLocalizations.of(ctx)!;
    final p = banner.payload;
    final title = p.isTest
        ? l.pushTestReceived
        : (p.title?.trim().isNotEmpty ?? false)
        ? p.title!
        : l.pushBannerDefaultTitle;
    final body = p.isTest ? null : p.body;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          body == null || body.trim().isEmpty ? title : '$title\n$body',
        ),
        behavior: SnackBarBehavior.floating,
        action: banner.openable
            ? SnackBarAction(
                label: l.pushBannerOpen,
                onPressed: () => widget.container.pushCoordinator.open(p),
              )
            : null,
      ),
    );
  }

  /// تبديل لغة/مظهر من شاشة الحساب (تفضيل محلي §79).
  void applyLocale(Locale locale) {
    setState(() => _locale = locale);
    widget.container.prefs.set('locale', locale.languageCode);
  }

  void applyThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.container.prefs.set('theme', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  @override
  Widget build(BuildContext context) => AppScope(
    container: widget.container,
    child: _AppSettings(
      state: this,
      child: MaterialApp.router(
        title: 'Lynomia Hub',
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        scaffoldMessengerKey: _messenger,
        routerConfig: _router,
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: _themeMode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
      ),
    ),
  );

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF0F5E59),
    visualDensity: VisualDensity.standard,
  );
}

/// وصول شاشات الإعدادات لتبديل اللغة/المظهر.
class _AppSettings extends InheritedWidget {
  const _AppSettings({required this.state, required super.child});

  final _LynomiaAppState state;

  @override
  bool updateShouldNotify(_AppSettings oldWidget) => false;
}

extension AppSettingsX on BuildContext {
  void setAppLocale(Locale locale) =>
      dependOnInheritedWidgetOfExactType<_AppSettings>()!.state.applyLocale(
        locale,
      );

  void setAppThemeMode(ThemeMode mode) =>
      dependOnInheritedWidgetOfExactType<_AppSettings>()!.state.applyThemeMode(
        mode,
      );
}
