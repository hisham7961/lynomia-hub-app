import 'package:flutter_test/flutter_test.dart';
import 'package:lynomia_hub_app/core/config/app_env.dart';

void main() {
  group('AppEnv — بوابة أمان الإعداد (§9)', () {
    test('الإنتاج يرفض غياب المضيف', () {
      const env = AppEnv(kind: AppEnvKind.prod, apiBaseUrl: '');
      expect(env.validate, throwsA(isA<AppEnvError>()));
    });

    test('الإنتاج يرفض HTTP الصريح', () {
      const env = AppEnv(
        kind: AppEnvKind.prod,
        apiBaseUrl: 'http://hub.example.com',
      );
      expect(env.validate, throwsA(isA<AppEnvError>()));
    });

    test('الإنتاج يقبل HTTPS', () {
      const env = AppEnv(
        kind: AppEnvKind.prod,
        apiBaseUrl: 'https://hub.example.com',
      );
      expect(env.validate, returnsNormally);
    });

    test('التطوير يجيز HTTP المحلي صراحة', () {
      const env = AppEnv(
        kind: AppEnvKind.dev,
        apiBaseUrl: 'http://10.0.2.2:8000',
      );
      expect(env.validate, returnsNormally);
    });

    test('القاعدة تلحق /api/mobile/v1 (§5)', () {
      const env = AppEnv(
        kind: AppEnvKind.dev,
        apiBaseUrl: 'https://hub.example.com',
      );
      expect(
        env.mobileApiBase.toString(),
        'https://hub.example.com/api/mobile/v1',
      );
    });
  });
}
