/// طيّ الروابط العالمية (§76) — `foldDeepLink` دالةٌ صرفة، والمسار الكامل عبر
/// الموجّه (`/app/*` ⇒ `/m/*` ⇒ `/r/*`) مختبرٌ في اختبارات الواجهة.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/links/deep_link.dart';

void main() {
  String? fold(String s) => foldDeepLink(Uri.parse(s));

  group('foldDeepLink', () {
    test('/m/* كما هو، مع الاستعلام', () {
      expect(fold('https://hub.example.com/m/tasks'), '/m/tasks');
      expect(fold('https://hub.example.com/m/tasks/42'), '/m/tasks/42');
      expect(
        fold('https://hub.example.com/m/tasks/42/edit?from=mail'),
        '/m/tasks/42/edit?from=mail',
      );
    });

    test('/app/* ⇒ /m/*، و/app/activate/* ⇒ /activate/*', () {
      expect(fold('https://hub.example.com/app/tasks/7'), '/m/tasks/7');
      expect(
        fold('https://hub.example.com/app/activate/tok-123'),
        '/activate/tok-123',
      );
    });

    test('الشرطة الختامية تُزال', () {
      expect(fold('https://hub.example.com/m/tasks/'), '/m/tasks');
      expect(fold('https://hub.example.com/app/tasks/7//'), '/m/tasks/7');
    });

    test('خارج البادئتين أو مسارٌ ناقص/ملتبس ⇒ null', () {
      expect(fold('https://hub.example.com/'), isNull);
      expect(fold('https://hub.example.com/login'), isNull);
      expect(fold('https://hub.example.com/admin/mobile-platform'), isNull);
      expect(fold('https://hub.example.com/m/'), isNull);
      expect(fold('https://hub.example.com/app'), isNull);
      expect(fold('https://hub.example.com/mx/tasks'), isNull);
      expect(fold('https://hub.example.com/m//7'), isNull);
    });

    test('مخططٌ غير الويب ⇒ null', () {
      expect(fold('javascript:/m/tasks'), isNull);
      expect(fold('file:///m/tasks'), isNull);
      expect(fold('lynomia://hub/m/tasks'), isNull);
    });

    test('مسارٌ نسبيّ بلا مخطط (من الإشعار/الاختبار) يُطوى أيضاً', () {
      expect(fold('/app/tasks/9'), '/m/tasks/9');
    });
  });

  group('foldAppPath', () {
    test('يطابق طيّ الموجّه', () {
      expect(foldAppPath('/app/crm/1'), '/m/crm/1');
      expect(foldAppPath('/app/activate/x'), '/activate/x');
      expect(foldAppPath('/m/crm/1'), '/m/crm/1');
    });
  });
}
