/// اختبارات العقد (§123) — افتراضات التطبيق ضد لقطات contracts/ الملتزمة.
/// انحراف اللقطة عن حاجة التطبيق يفشل هنا بوضوح.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/errors/api_exception.dart';

Map<String, dynamic> _loadJson(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();

void main() {
  final caps = _loadJson('contracts/mobile-capabilities.json');
  final openapi = _loadJson('contracts/mobile-openapi.json');
  final source = _loadJson('contracts/backend-source.json');

  Set<String> endpointsOf(String area) {
    final a = ((caps['areas'] as Map)[area] as Map?)?.cast<String, dynamic>();
    expect(a, isNotNull, reason: 'المجال $area غائب عن سجل القدرات');
    return (a!['endpoints'] as List)
        .whereType<Map>()
        .map((e) => '${e['method']} ${e['path']}')
        .toSet();
  }

  test('مصدر العقد موثق: مستودع/فرع/SHA/نسخة (§12)', () {
    expect(source['backend_repository'], 'hisham7961/lynomia-hub');
    expect(source['backend_commit_sha'], matches(RegExp(r'^[0-9a-f]{40}$')));
    expect(source['mobile_api_version'], '1');
    expect(source['backend_ref'], isNotEmpty);
  });

  test('نسخة العقد 1 ومساحة الاسم /api/mobile/v1 (§5)', () {
    expect(caps['mobile_api_version'], '1');
    expect(caps['namespace'], '/api/mobile/v1');
    expect(openapi['info']['version'], '1');
  });

  test('مسارات المصادقة الحرجة موجودة (§123)', () {
    final auth = endpointsOf('auth');
    expect(
      auth,
      containsAll([
        'POST /api/mobile/v1/auth/login',
        'POST /api/mobile/v1/auth/mfa/verify',
        'POST /api/mobile/v1/auth/refresh',
        'POST /api/mobile/v1/auth/logout',
        'POST /api/mobile/v1/auth/logout-all',
        'GET /api/mobile/v1/auth/sessions',
        'DELETE /api/mobile/v1/auth/sessions/{id}',
        'POST /api/mobile/v1/auth/step-up',
        'GET /api/mobile/v1/app-config',
      ]),
    );
  });

  test('السياق والإقلاع والمخطط والتنقل موجودة', () {
    expect(
      endpointsOf('context'),
      containsAll([
        'GET /api/mobile/v1/bootstrap',
        'GET /api/mobile/v1/context',
        'GET /api/mobile/v1/navigation',
      ]),
    );
    expect(
      endpointsOf('schema'),
      containsAll([
        'GET /api/mobile/v1/schema',
        'GET /api/mobile/v1/schema/modules',
      ]),
    );
  });

  test('CRUD العام والإجراءات والمزامنة موجودة (§123)', () {
    expect(endpointsOf('crud'), hasLength(6));
    expect(
      endpointsOf('actions'),
      containsAll([
        'GET /api/mobile/v1/{module}/{id}/actions',
        'POST /api/mobile/v1/{module}/{id}/actions/{action}',
      ]),
    );
    expect(endpointsOf('sync'), contains('GET /api/mobile/v1/sync/{module}'));
  });

  test('التعاون: إشعارات/تعليقات/DM/اعتمادات/بحث/بيت', () {
    expect(endpointsOf('notifications'), hasLength(5));
    expect(endpointsOf('comments'), hasLength(2));
    expect(endpointsOf('dm'), hasLength(4));
    expect(endpointsOf('approvals'), hasLength(4));
    expect(endpointsOf('search'), contains('GET /api/mobile/v1/search'));
    expect(endpointsOf('home'), contains('GET /api/mobile/v1/home'));
  });

  test('الملفات والماسح والتتبع والدفع', () {
    expect(endpointsOf('files'), hasLength(6));
    expect(
      endpointsOf('scanner'),
      contains('GET /api/mobile/v1/identity/resolve/{q}'),
    );
    expect(endpointsOf('tracking'), hasLength(3));
    expect(
      endpointsOf('push'),
      containsAll([
        'POST /api/mobile/v1/push/register',
        'POST /api/mobile/v1/push/unregister',
      ]),
    );
  });

  test('أكواد الخطأ التي يفرع عليها التطبيق كلها معلنة في العقد (§31)', () {
    final declared = {
      ...((caps['error_codes'] as Map)['reused'] as List).cast<String>(),
      ...((caps['error_codes'] as Map)['mobile_added'] as List).cast<String>(),
    };
    for (final code in ApiErrorCode.values) {
      if (code == ApiErrorCode.unknown) continue;
      expect(
        declared,
        contains(code.wire),
        reason: 'الكود ${code.wire} غير معلن في سجل القدرات — انحراف عقد',
      );
    }
  });

  test('أصناف المزامنة التي يعرفها المحرك مطابقة للعقد (§61)', () {
    final classes = ((caps['sync'] as Map)['classes'] as List)
        .cast<String>()
        .toSet();
    expect(classes, {
      'CACHEABLE_INCREMENTAL',
      'CACHEABLE_READ_ONLY',
      'ONLINE_ONLY',
      'SENSITIVE_NO_PERSIST',
      'NOT_APPLICABLE',
    });
    expect((caps['sync'] as Map)['default_class'], 'ONLINE_ONLY');
  });

  test('الوحدات الحساسة معلنة SENSITIVE_NO_PERSIST (§62)', () {
    final modules = ((caps['sync'] as Map)['modules'] as Map)
        .cast<String, dynamic>();
    for (final m in ['phones', 'carriers', 'vault']) {
      expect(modules[m], 'SENSITIVE_NO_PERSIST');
    }
    expect(modules['users'], 'NOT_APPLICABLE');
  });

  test('عقد الرابط العميق: /m/* قانوني و{module,id,action} (§76)', () {
    final dl = (caps['deep_link'] as Map).cast<String, dynamic>();
    expect(
      (dl['universal_link_encoding'] as Map)['path_template'],
      '/m/{module}/{id}',
    );
    expect(dl['no_hardcoded_screens'], true);
  });

  test('مواصفة OpenAPI تحمل المسارات المفتاحية', () {
    final paths = (openapi['paths'] as Map).keys.cast<String>().toSet();
    expect(
      paths,
      containsAll([
        '/api/mobile/v1/auth/login',
        '/api/mobile/v1/auth/refresh',
        '/api/mobile/v1/bootstrap',
        '/api/mobile/v1/schema',
        '/api/mobile/v1/sync/{module}',
        '/api/mobile/v1/{module}',
        '/api/mobile/v1/{module}/{id}',
      ]),
    );
  });
}
