/// إثبات لا ادعاء (§111): الخبيئة مشفرة فعلاً، والحساس لا يبلغ القرص إطلاقاً.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/storage/encrypted_cache.dart';

import '../fakes/fakes.dart';

void main() {
  late Directory dir;
  late EncryptedJsonCache cache;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cache_test_');
    cache = EncryptedJsonCache(rootDir: dir, keyStore: InMemorySecureStore());
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('دورة كتابة/قراءة كاملة', () async {
    await cache.write('ns1', {
      'اسم': 'قيمة عربية',
      'n': 5,
    }, syncClass: 'CACHEABLE_INCREMENTAL');
    final back = await cache.read('ns1');
    expect(back, {'اسم': 'قيمة عربية', 'n': 5});
  });

  test('البايتات على القرص ليست نصاً صريحاً (§63)', () async {
    const marker = 'SECRET_BUSINESS_VALUE_12345';
    await cache.write('ns2', {'v': marker});
    final file = dir
        .listSync(recursive: true)
        .whereType<File>()
        .firstWhere((f) => f.path.contains('ns2'));
    final raw = file.readAsBytesSync();
    expect(
      utf8.decode(raw, allowMalformed: true).contains(marker),
      isFalse,
      reason: 'لا قاعدة مؤسسية نصية على القرص',
    );
    expect(utf8.decode(raw, allowMalformed: true).contains('اسم'), isFalse);
  });

  test('SENSITIVE_NO_PERSIST يرفض بنيوياً ولا يترك أثراً (§62 §111)', () async {
    await expectLater(
      cache.write('vault_ns', {
        'secret': 'x',
      }, syncClass: 'SENSITIVE_NO_PERSIST'),
      throwsA(isA<CachePolicyViolation>()),
    );
    expect(await cache.existsOnDisk('vault_ns'), isFalse);
  });

  test('ONLINE_ONLY يرفض أيضاً — لا تخبئة لسياسة لحظية (§61)', () async {
    await expectLater(
      cache.write('live_ns', {'x': 1}, syncClass: 'ONLINE_ONLY'),
      throwsA(isA<CachePolicyViolation>()),
    );
  });

  test('ملف تالف يقرأ null بأمان لا انهياراً', () async {
    await cache.write('ns3', {'x': 1});
    final file = dir
        .listSync(recursive: true)
        .whereType<File>()
        .firstWhere((f) => f.path.contains('ns3'));
    file.writeAsBytesSync(List.filled(64, 7));
    expect(await cache.read('ns3'), isNull);
  });

  test('deleteByPrefix يمسح نطاقات مستخدم/سياق (§39 §43)', () async {
    await cache.write('sync_u_1_c_A_tasks', {'a': 1});
    await cache.write('sync_u_1_c_B_tasks', {'b': 1});
    await cache.write('sync_u_2_c_A_tasks', {'c': 1});
    await cache.deleteByPrefix('sync_u_1_');
    expect(await cache.read('sync_u_1_c_A_tasks'), isNull);
    expect(await cache.read('sync_u_1_c_B_tasks'), isNull);
    expect(await cache.read('sync_u_2_c_A_tasks'), isNotNull);
  });
}
