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
}
