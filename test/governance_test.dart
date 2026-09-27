/// حوكمة النسخة — VERSION و pubspec و README و CHANGELOG متطابقة (CLAUDE.md).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/config/app_identifiers.dart';

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

  group('المرحلة ٢.٢/٢.٣/٥ — إعداد المنصتين (حرّاس ثابتة)', () {
    String read(String p) => File(p).readAsStringSync();

    test('Android: intent-filter للروابط العالمية بنطاقٍ محقون', () {
      final m = read('android/app/src/main/AndroidManifest.xml');
      expect(m, contains('<intent-filter android:autoVerify="true">'));
      expect(m, contains('android.intent.action.VIEW'));
      expect(m, contains('android.intent.category.BROWSABLE'));
      expect(m, contains('android:scheme="https"'));
      expect(m, contains(r'android:host="${appLinkHost}"'));
      for (final prefix in AppIdentifiers.deepLinkPathPrefixes) {
        expect(m, contains('android:pathPrefix="$prefix"'));
      }
      final g = read('android/app/build.gradle.kts');
      expect(g, contains('manifestPlaceholders["appLinkHost"]'));
      expect(g, contains('"${AppIdentifiers.defaultAppLinkHost}"'));
      expect(g, contains('"${AppIdentifiers.androidApplicationId}"'));
    });

    test('Android: لا نسخ احتياطي، والاسم مُعرَّب، والإذن للإشعار', () {
      final m = read('android/app/src/main/AndroidManifest.xml');
      expect(m, contains('android:allowBackup="false"'));
      expect(
        m,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(m, contains('android:fullBackupContent="@xml/backup_rules"'));
      expect(m, contains('android.permission.POST_NOTIFICATIONS'));
      expect(m, contains('android:label="@string/app_name"'));
      final rules = read(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      );
      expect(rules, contains('<cloud-backup>'));
      expect(rules, contains('<device-transfer>'));
      expect(rules, isNot(contains('<include')));
      expect(
        read('android/app/src/main/res/values/strings.xml'),
        contains('>${AppIdentifiers.displayName}<'),
      );
      expect(
        read('android/app/src/main/res/values-ar/strings.xml'),
        contains('>${AppIdentifiers.displayNameAr}<'),
      );
    });

    test('Android: قناة الإشعار lynomia_default تُنشأ عند الإقلاع باسمٍ معرَّب '
        '(المرحلة ٥ · طلب #10)', () {
      const id = AppIdentifiers.androidNotificationChannelId;
      expect(id, 'lynomia_default', reason: 'PushService::ANDROID_CHANNEL');
      const dir = 'android/app/src/main/kotlin/dev/lynomia/lynomia_hub_app';
      final activity = read('$dir/MainActivity.kt');
      expect(activity, contains('override fun onCreate('));
      expect(activity, contains('NotificationChannels.ensureDefault(this)'));
      final channels = read('$dir/NotificationChannels.kt');
      expect(channels, contains('const val DEFAULT_ID = "$id"'));
      expect(channels, contains('NotificationManager.IMPORTANCE_HIGH'));
      expect(channels, contains('Build.VERSION_CODES.O'));
      expect(channels, contains('R.string.notification_channel_name'));
      expect(channels, contains('R.string.notification_channel_description'));
      final m = read('android/app/src/main/AndroidManifest.xml');
      expect(
        m,
        contains(
          'android:name="com.google.firebase.messaging.default_notification_channel_id"',
        ),
      );
      expect(m, contains('android:value="$id"'));
      // الاسم والوصف مطابقان لـ ARB في اللغتين (مصدرٌ واحد للنص).
      Map<String, dynamic> arb(String p) =>
          (jsonDecode(read(p)) as Map).cast<String, dynamic>();
      for (final (res, arbPath) in [
        ('values', 'lib/l10n/app_en.arb'),
        ('values-ar', 'lib/l10n/app_ar.arb'),
      ]) {
        final xml = read('android/app/src/main/res/$res/strings.xml');
        final a = arb(arbPath);
        expect(
          xml,
          contains(
            '<string name="notification_channel_name">'
            '${a['notificationChannelName']}</string>',
          ),
          reason: res,
        );
        expect(
          xml,
          contains(
            '<string name="notification_channel_description">'
            '${a['notificationChannelDescription']}</string>',
          ),
          reason: res,
        );
      }
    });

    test('Android: توقيع من key.properties، ولا إضافة google-services', () {
      final g = read('android/app/build.gradle.kts');
      expect(g, contains('rootProject.file("key.properties")'));
      expect(g, contains('lynomia.requireReleaseSigning'));
      expect(g, isNot(contains('id("com.google.gms.google-services")')));
      expect(
        read('android/settings.gradle.kts'),
        isNot(contains('com.google.gms')),
      );
      expect(File('android/key.properties.example').existsSync(), isTrue);
      final ignore = read('.gitignore');
      for (final secret in [
        '/android/key.properties',
        '*.jks',
        '/firebase.defines.json',
        '/ios/Flutter/AppIdentity.local.xcconfig',
      ]) {
        expect(ignore, contains(secret), reason: secret);
      }
    });

    test('iOS: الاستحقاقات (applinks + aps) موصولة لكل إعدادات Runner', () {
      final e = read('ios/Runner/Runner.entitlements');
      expect(e, contains('applinks:\$(APP_LINK_HOST)'));
      expect(e, contains('<key>aps-environment</key>'));
      expect(e, contains('\$(APS_ENVIRONMENT)'));
      final pbx = read('ios/Runner.xcodeproj/project.pbxproj');
      expect(
        'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
            .allMatches(pbx)
            .length,
        3,
        reason: 'Debug + Release + Profile',
      );
      expect(
        'PRODUCT_BUNDLE_IDENTIFIER = "\$(APP_BUNDLE_ID)";'
            .allMatches(pbx)
            .length,
        3,
      );
      final identity = read('ios/Flutter/AppIdentity.xcconfig');
      expect(
        identity,
        contains('APP_BUNDLE_ID = ${AppIdentifiers.iosBundleId}'),
      );
      expect(
        identity,
        contains('APP_LINK_HOST = ${AppIdentifiers.defaultAppLinkHost}'),
      );
      expect(identity, contains('#include? "AppIdentity.local.xcconfig"'));
      expect(
        read('ios/Flutter/Debug.xcconfig'),
        contains('APS_ENVIRONMENT = development'),
      );
      expect(
        read('ios/Flutter/Release.xcconfig'),
        contains('APS_ENVIRONMENT = production'),
      );
    });

    test('iOS: خلفية الإشعار، واللغتان، والاسم المُعرَّب', () {
      final plist = read('ios/Runner/Info.plist');
      expect(plist, contains('<string>remote-notification</string>'));
      expect(plist, contains('<key>CFBundleLocalizations</key>'));
      expect(plist, contains('<string>\$(APP_DISPLAY_NAME)</string>'));
      expect(
        read('ios/Runner/ar.lproj/InfoPlist.strings'),
        contains('"CFBundleDisplayName" = "${AppIdentifiers.displayNameAr}";'),
      );
      expect(
        read('ios/Runner/en.lproj/InfoPlist.strings'),
        contains('"CFBundleDisplayName" = "${AppIdentifiers.displayName}";'),
      );
    });

    test('الأيقونات: كل ملفات AppIcon موجودة، والتكيّفية لـAndroid', () {
      final dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final names = RegExp(r'"filename" : "([^"]+)"')
          .allMatches(read('$dir/Contents.json'))
          .map((m) => m.group(1)!)
          .toSet();
      expect(names, isNotEmpty);
      for (final n in names) {
        expect(File('$dir/$n').existsSync(), isTrue, reason: n);
      }
      for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        for (final f in [
          'ic_launcher.png',
          'ic_launcher_round.png',
          'ic_launcher_foreground.png',
        ]) {
          final p = 'android/app/src/main/res/mipmap-$d/$f';
          expect(File(p).existsSync(), isTrue, reason: p);
        }
      }
      expect(
        read('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml'),
        contains('<adaptive-icon'),
      );
    });
  });
}
