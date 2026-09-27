/// أدوات الاختبار المشتركة (§103) — لا اختبار يلمس خدمة حقيقية:
/// ناقل HTTP مبرمج يسجل كل طلب، ومخزن آمن في الذاكرة، وبناء حاوية اختبار.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lynomia_hub_app/app/di/app_scope.dart';
import 'package:lynomia_hub_app/core/config/app_env.dart';
import 'package:lynomia_hub_app/core/push/push_registrar.dart';
import 'package:lynomia_hub_app/core/security/biometric_gate.dart';
import 'package:lynomia_hub_app/core/storage/secure_store.dart';
import 'package:lynomia_hub_app/core/telemetry/app_info.dart';
import 'package:lynomia_hub_app/features/tracking/location_source.dart';

/// مخزن آمن في الذاكرة — بديل Keychain/Keystore للاختبار.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll(Iterable<String> keys) async =>
      keys.forEach(values.remove);
}

typedef ScriptHandler = http.Response Function(RecordedRequest req);

class RecordedRequest {
  RecordedRequest(this.method, this.url, this.headers, this.bodyBytes);

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final List<int> bodyBytes;

  String get body => utf8.decode(bodyBytes);
  Map<String, dynamic> get jsonBody =>
      (jsonDecode(body) as Map).cast<String, dynamic>();

  /// المسار بعد `/api/mobile/v1/`.
  String get apiPath {
    const prefix = '/api/mobile/v1/';
    final p = url.path;
    return p.startsWith(prefix) ? p.substring(prefix.length) : p;
  }

  String get key => '$method $apiPath';
}

/// ناقل مبرمج: قواعد `'METHOD path'` (المسار بعد /api/mobile/v1/)، مع مسجل
/// طلبات كامل للتوكيد على الترويسات والأجسام.
class ScriptedHttpClient extends http.BaseClient {
  final Map<String, ScriptHandler> routes = {};
  final List<RecordedRequest> requests = [];
  ScriptHandler? fallback;

  /// أعطال شبكة مبرمجة: المفتاح يستهلك مرة ثم يمر الطلب.
  final Set<String> failOnce = {};

  void on(String key, ScriptHandler handler) => routes[key] = handler;

  /// اختصار: رد نجاح ثابت بغلاف {data, request_id}.
  void onData(String key, Map<String, dynamic> data) =>
      on(key, (_) => okData(data));

  List<RecordedRequest> sent(String key) =>
      requests.where((r) => r.key == key).toList();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final rec = RecordedRequest(
      request.method,
      request.url,
      Map.of(request.headers),
      bytes,
    );
    requests.add(rec);
    if (failOnce.remove(rec.key)) {
      throw http.ClientException('فشل شبكة مبرمج', request.url);
    }
    final handler = routes[rec.key] ?? fallback;
    if (handler == null) {
      throw StateError('لا معالج مبرمجاً للطلب: ${rec.key}');
    }
    final resp = handler(rec);
    return http.StreamedResponse(
      Stream.value(resp.bodyBytes),
      resp.statusCode,
      headers: resp.headers,
    );
  }
}

http.Response okData(
  Map<String, dynamic> data, {
  int status = 200,
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode({'data': data, 'request_id': 'rid-test'}),
  status,
  headers: {
    'content-type': 'application/json',
    'x-request-id': 'rid-test',
    ...headers,
  },
);

http.Response okList(
  List<Map<String, dynamic>> items, {
  int total = -1,
  int page = 1,
  int lastPage = 1,
  bool hasMore = false,
}) => http.Response(
  jsonEncode({
    'data': items,
    'total': total < 0 ? items.length : total,
    'page': page,
    'last_page': lastPage,
    'meta': {
      'page': page,
      'per': items.length,
      'total': total < 0 ? items.length : total,
      'last_page': lastPage,
      'has_more': hasMore,
    },
    'request_id': 'rid-test',
  }),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response apiError(
  String code,
  int status, {
  String message = 'خطأ اختباري',
  Map<String, dynamic> details = const {},
}) => http.Response(
  jsonEncode({
    'error': message,
    'code': code,
    'message': message,
    'details': details,
    'request_id': 'rid-err',
  }),
  status,
  headers: {
    'content-type': 'application/json',
    'x-error-code': code,
    'x-request-id': 'rid-err',
  },
);

/// حمولة جلسة قياسية كما يعيدها login/refresh.
Map<String, dynamic> sessionPayload({
  String access = 'lyma_access_1',
  String refresh = 'lymr_refresh_1',
  String sessionId = 'sess-1',
  Duration accessTtl = const Duration(minutes: 15),
}) => {
  'access_token': access,
  'refresh_token': refresh,
  'token_type': 'Bearer',
  'session_id': sessionId,
  'installation_id': 'inst-1',
  'access_expires_at': DateTime.now().toUtc().add(accessTtl).toIso8601String(),
  'refresh_expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(days: 30))
      .toIso8601String(),
  'user': {
    'id': 'u-1',
    'name': 'مستخدم الاختبار',
    'email': 'test@example.com',
    'role': 'موظف',
    'is_owner': false,
  },
};

class TestHarness {
  TestHarness._(this.container, this.transport, this.secureStore, this.tempDir);

  final AppContainer container;
  final ScriptedHttpClient transport;
  final InMemorySecureStore secureStore;
  final Directory tempDir;

  static TestHarness create({
    String env = 'dev',
    BiometricGate? biometricGate,
    PushTokenProvider? pushProvider,
    LocationSource? location,
  }) {
    final transport = ScriptedHttpClient();
    final secureStore = InMemorySecureStore();
    final tempDir = Directory.systemTemp.createTempSync('lynomia_test_');
    final container = AppContainer.custom(
      env: AppEnv(
        kind: env == 'prod' ? AppEnvKind.prod : AppEnvKind.dev,
        apiBaseUrl: 'https://hub.test.local',
      ),
      transport: transport,
      secureStore: secureStore,
      rootDir: tempDir,
      appInfo: const AppInfo(platform: 'android', version: '0.1.0', build: '1'),
      biometricGate: biometricGate,
      pushProvider: pushProvider,
      location: location,
    );
    return TestHarness._(container, transport, secureStore, tempDir);
  }

  /// جلسة مسبقة (إقلاع مصادق) دون المرور بشاشة الدخول.
  Future<void> seedSession() async {
    final tokens = sessionPayload();
    secureStore.values['lynomia.session'] = jsonEncode({
      'access_token': tokens['access_token'],
      'refresh_token': tokens['refresh_token'],
      'session_id': tokens['session_id'],
      'installation_id': tokens['installation_id'],
      'access_expires_at': tokens['access_expires_at'],
      'refresh_expires_at': tokens['refresh_expires_at'],
    });
    await container.session.restore();
  }

  void dispose() {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // نظافة اختبار فقط
    }
  }
}

/// لقطة bootstrap قياسية.
Map<String, dynamic> bootstrapPayload({int unread = 2}) => {
  'user': {
    'id': 'u-1',
    'name': 'مستخدم الاختبار',
    'email': 'test@example.com',
    'role': 'موظف',
    'is_owner': false,
  },
  'context': {
    'companies': {
      'restricted': true,
      'active': null,
      'count': 2,
      'has_more': false,
      'items': [
        {'id': 'c-1', 'name': 'شركة الاختبار'},
        {'id': 'c-2', 'name': 'شركة ثانية'},
      ],
    },
    'clients': {
      'restricted': false,
      'active': null,
      'count': 0,
      'has_more': false,
      'items': <Map<String, dynamic>>[],
    },
  },
  'feature_flags': {'can_approve': true, 'mfa_enrolled': false},
  'timezone': 'Asia/Kuwait',
  'versions': {'app': '2.446.0', 'mobile_api': '1', 'schema': 'abc123'},
  'unread_notifications': unread,
  'nav': {'g': <dynamic>[], 'items': <dynamic>[]},
  'ia': {
    'surfaces': <Map<String, dynamic>>[],
    'domains': [
      {
        'key': 'entities',
        'label': 'الكيانات والعلاقات',
        'icon': '🏢',
        'plane': 'work',
        'sections': [
          {
            'key': 'companies',
            'label': 'الشركات والمشاريع',
            'destinations': [
              {
                'label': 'المهام',
                'type': 'module',
                'importance': 'primary',
                'mobile': 'suitable',
                'module': 'tasks',
                'route': 'm.index',
                'args': ['tasks'],
              },
            ],
          },
        ],
      },
    ],
  },
  'schema_version': 'abc123',
};

/// مخطط وحدة مهام قياسي بكل أنواع الحقول (تغطية §20).
Map<String, dynamic> schemaPayload() => {
  'schema_version': 'abc123',
  'mobile_api_version': '1',
  'modules': [
    {
      'key': 'tasks',
      'label': 'المهام',
      'sync_class': 'CACHEABLE_INCREMENTAL',
      'can': {'v': true, 'a': true, 'e': true, 'd': true},
      'fields': [
        {'key': 'title', 'label': 'العنوان', 'type': 'text', 'required': true},
        {'key': 'details', 'label': 'التفاصيل', 'type': 'ta'},
        {'key': 'estimate', 'label': 'التقدير', 'type': 'num'},
        {'key': 'due', 'label': 'الاستحقاق', 'type': 'date'},
        {'key': 'started_at', 'label': 'البدء', 'type': 'dt'},
        {'key': 'billable', 'label': 'مفوتر', 'type': 'bool'},
        {
          'key': 'status',
          'label': 'الحالة',
          'type': 'sel',
          'options': ['جديدة', 'جارية', 'منجزة'],
        },
        {
          'key': 'project_id',
          'label': 'المشروع',
          'type': 'ref',
          'ref': 'projects',
        },
        {'key': 'tags', 'label': 'الوسوم', 'type': 'tags', 'multi': true},
        {'key': 'link', 'label': 'الرابط', 'type': 'url'},
        {'key': 'spec', 'label': 'الملف', 'type': 'file'},
        {'key': 'photo', 'label': 'الصورة', 'type': 'img'},
        {'key': 'api_key', 'label': 'المفتاح', 'type': 'sec', 'readonly': true},
      ],
    },
    {
      'key': 'projects',
      'label': 'المشاريع',
      'sync_class': 'CACHEABLE_INCREMENTAL',
      'can': {'v': true, 'a': false, 'e': false, 'd': false},
      'fields': [
        {'key': 'name', 'label': 'الاسم', 'type': 'text', 'required': true},
      ],
    },
  ],
};
