/// ضخّ شاشةٍ مفردة في اختبار واجهة (§103) — بحاوية الاختبار والموجّه الحقيقي:
/// صفحة جذر فيها زر «OPEN» يدفع الشاشة (فيصحّ `pop` منها)، وأي ملاحة لمسارٍ
/// غير مسجّل تظهر نصّاً `NAV:<uri>` يُؤكَّد عليه بدل شاشةٍ حقيقية.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lynomia_hub_app/app/di/app_scope.dart';
import 'package:lynomia_hub_app/l10n/app_localizations.dart';

import 'fakes.dart';

Future<GoRouter> pumpScreen(
  WidgetTester tester,
  TestHarness h,
  Widget screen, {
  List<RouteBase> extraRoutes = const [],
  Locale locale = const Locale('ar'),
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/screen'),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/screen', builder: (context, state) => screen),
      ...extraRoutes,
    ],
    errorBuilder: (context, state) => Scaffold(body: Text('NAV:${state.uri}')),
  );
  await tester.pumpWidget(
    AppScope(
      container: h.container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
  return router;
}

/// إتاحة إدخال/إخراج حقيقي (ملفات الخبيئة المشفّرة) داخل منطقة الوقت المزيّف
/// لاختبار الواجهة: جولات قصيرة من الوقت الحقيقي يليها ضخّ إطار.
Future<void> settleIo(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
