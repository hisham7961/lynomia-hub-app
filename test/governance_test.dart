/// حوكمة النسخة — VERSION و pubspec و README و CHANGELOG متطابقة (CLAUDE.md).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('النسخة متطابقة في مواضعها الأربعة', () {
    final version = File('VERSION').readAsStringSync().trim();
    expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('version: $version+'),
      reason: 'pubspec.yaml لا يطابق VERSION',
    );

    final readmeFirst = File('README.md').readAsLinesSync().first;
    expect(
      readmeFirst,
      '# Lynomia Hub — v$version',
      reason: 'سطر README الأول لا يطابق VERSION',
    );

    final changelog = File('CHANGELOG.md').readAsStringSync();
    expect(
      changelog,
      contains('## v$version'),
      reason: 'لا مدخل CHANGELOG للنسخة الحالية',
    );
  });

  test('لا أسرار مدفوعة: لا ملف اعتماد مزود دفع في الشجرة', () {
    expect(File('android/app/google-services.json').existsSync(), isFalse);
    expect(File('ios/Runner/GoogleService-Info.plist').existsSync(), isFalse);
  });

  test('Android: MainActivity من FlutterFragmentActivity (شرط local_auth)', () {
    final kt = File(
      'android/app/src/main/kotlin/dev/lynomia/lynomia_hub_app/MainActivity.kt',
    ).readAsStringSync();
    expect(
      kt,
      contains('class MainActivity : FlutterFragmentActivity()'),
      reason: 'مع FlutterActivity يفشل قفل البصمة وقت التشغيل على Android',
    );
    expect(
      kt,
      isNot(contains('import io.flutter.embedding.android.FlutterActivity\n')),
    );
    // وسمة الإقلاع AppCompat — شرط local_auth على Android 8 وما دونه.
    for (final path in [
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('name="LaunchTheme" parent="Theme.AppCompat'),
        reason: path,
      );
    }
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('androidx.appcompat:appcompat'),
    );
  });

  test(
    'لا نصَّ واجهةٍ عربيّاً صلباً في lib/app وlib/features (كله عبر ARB)',
    () {
      // سلسلةٌ حرفيّةٌ فيها حرفٌ عربي خارج التعليقات — النصوص التقنية (سجلات،
      // أخطاء مطوّر) تعيش في lib/core ولا تُعرض واجهةً إلا عبر describeError.
      final arabic = RegExp(r"'[^'\n]*[\u0600-\u06FF][^'\n]*'");
      final offenders = <String>[];
      for (final root in ['lib/app', 'lib/features']) {
        for (final f in Directory(root).listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          final lines = f.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final code = lines[i].trimLeft();
            if (code.startsWith('//')) continue;
            final beforeComment = code.split(' //').first;
            if (arabic.hasMatch(beforeComment)) {
              offenders.add('${f.path}:${i + 1}: ${code.trim()}');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    },
  );
}
