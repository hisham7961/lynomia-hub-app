/// لا سر يبلغ السجل (§85) — حتى في التطوير.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/security/redacting_logger.dart';

void main() {
  test('رموز الجلسة وBearer تطمس من النص الحر', () {
    final lines = <String>[];
    final log = RedactingLogger(sink: lines.add);
    log.info('token=lyma_abc123 refresh=lymr_xyz Bearer secret-value');
    expect(lines.single.contains('lyma_abc123'), isFalse);
    expect(lines.single.contains('lymr_xyz'), isFalse);
    expect(lines.single.contains('secret-value'), isFalse);
  });

  test('المفاتيح الحساسة تطمس من الخرائط', () {
    final out = RedactingLogger.redactMap({
      'password': 'p@ss',
      'access_token': 'lyma_x',
      'refresh_token': 'lymr_x',
      'code': '123456',
      'Authorization': 'Bearer x',
      'safe': 'يبقى',
    });
    expect(out['password'], '‹محجوب›');
    expect(out['access_token'], '‹محجوب›');
    expect(out['refresh_token'], '‹محجوب›');
    expect(out['code'], '‹محجوب›');
    expect(out['Authorization'], '‹محجوب›');
    expect(out['safe'], 'يبقى');
  });
}
