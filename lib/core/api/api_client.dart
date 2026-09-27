/// عميل `/api/mobile/v1` الواحد (§100) — كل HTTP يمر من هنا، لا نداء في widget.
///
/// يضمن بنيوياً:
///  • ترويسات العقد (§30): Authorization، منصة/إصدار/بناء/تنصيب، سياق
///    الشركة/العميل، X-Request-Id، Idempotency-Key، If-Match.
///  • غلاف `{data|error, code, details, request_id}` وأخطاء مكتوبة تفرّع على
///    `code` (§31) — الرسالة العربية للعرض فقط.
///  • 401 انتهاء وصول ⇒ تدوير واحد متسلسل عبر [SessionManager] ثم إعادة
///    المحاولة مرة؛ `SESSION_REVOKED` ينهي الجلسة فوراً (§38).
///  • إعادة محاولة محدودة بجذر أُسي وارتعاش للعابر الآمن فقط (§59): GET أو
///    طلب يحمل Idempotency-Key؛ ولا إعادة أبداً لفشل تحقق/منع/تعارض.
///  • ETag/If-None-Match مع 304 (§44).
///  • لا رمز في رابط، ولا سر في سجل (عبر RedactingLogger).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../auth/installation_id.dart';
import '../auth/session_manager.dart';
import '../config/app_env.dart';
import '../errors/api_exception.dart';
import '../security/redacting_logger.dart';
import '../telemetry/app_info.dart';
import 'api_envelope.dart';
import 'view_context.dart';

enum AuthMode {
  /// نقطة عامة (login/refresh/app-config/health) — لا Authorization.
  none,

  /// نقطة مصادقة — Bearer إلزامي مع تدوير عند الانتهاء.
  required,
}

class ApiRequest {
  ApiRequest(
    this.method,
    this.path, {
    this.query = const {},
    this.jsonBody,
    this.bodyBytes,
    this.contentType,
    this.auth = AuthMode.required,
    this.idempotencyKey,
    this.ifMatchVersion,
    this.ifNoneMatch,
    this.headers = const {},
    this.timeout = const Duration(seconds: 30),
    bool? retriable,
  }) : retriable = retriable ?? (method == 'GET' || idempotencyKey != null);

  final String method;

  /// نسبي على `/api/mobile/v1` (بلا شرطة أولى).
  final String path;
  final Map<String, String> query;
  final Map<String, dynamic>? jsonBody;

  /// جسم خام (رفع قطعة ملف).
  final List<int>? bodyBytes;
  final String? contentType;
  final AuthMode auth;

  /// المفتاح **ثابت للعملية المنطقية الواحدة** عبر كل إعادة محاولة (§58) —
  /// ينشئه المستدعي لكل فعل مستخدم جديد.
  final String? idempotencyKey;

  /// نسخة القفل التفاؤلي — تُبث `If-Match: "<n>"` (§57).
  final int? ifMatchVersion;
  final String? ifNoneMatch;
  final Map<String, String> headers;
  final Duration timeout;
  final bool retriable;
}

class ApiRawResponse {
  const ApiRawResponse({
    required this.status,
    required this.headers,
    this.json,
    this.bodyBytes,
  });

  final int status;
  final Map<String, String> headers;
  final Object? json;
  final List<int>? bodyBytes;

  bool get notModified => status == 304;
  String? get etag => headers['etag'];
  String? get requestId => headers['x-request-id'];

  Map<String, dynamic> get dataMap {
    final j = json;
    if (j is Map && j['data'] is Map) {
      return (j['data'] as Map).cast<String, dynamic>();
    }
    return const {};
  }

  List<dynamic> get dataList {
    final j = json;
    if (j is Map && j['data'] is List) return j['data'] as List;
    return const [];
  }

  Map<String, dynamic> get envelope =>
      json is Map ? (json as Map).cast<String, dynamic>() : const {};
}

class ApiClient {
  ApiClient({
    required this.env,
    required http.Client httpClient,
    required this.session,
    required this.viewContext,
    required this.installation,
    AppInfo? clientInfo,
    RedactingLogger? log,
    Random? random,
    this.sleep = _defaultSleep,
  }) : _transport = httpClient,
       _appInfo = clientInfo,
       _log = log ?? RedactingLogger(),
       _random = random ?? Random();

  final AppEnv env;
  final http.Client _transport;
  final SessionManager session;
  final ViewContext viewContext;
  final InstallationId installation;
  AppInfo? _appInfo;
  final RedactingLogger _log;
  final Random _random;

  /// قابل للحقن في الاختبار (لا انتظار حقيقياً).
  final Future<void> Function(Duration) sleep;

  static Future<void> _defaultSleep(Duration d) => Future.delayed(d);

  static const _maxAttempts = 3;

  set appInfo(AppInfo info) => _appInfo = info;
  AppInfo? get appInfo => _appInfo;

  Uri _uri(ApiRequest r) {
    final base = env.mobileApiBase;
    return base.replace(
      path: '${base.path}/${r.path.replaceAll(RegExp(r'^/+'), '')}',
      queryParameters: r.query.isEmpty ? null : r.query,
    );
  }

  Future<Map<String, String>> _headers(
    ApiRequest r, {
    required bool refreshed,
  }) async {
    final h = <String, String>{
      'Accept': 'application/json',
      'X-Request-Id': const Uuid().v4(),
      'X-Lynomia-Installation-Id': await installation.ensure(),
      ...r.headers,
    };
    final info = _appInfo;
    if (info != null) {
      h['X-Lynomia-App-Platform'] = info.platform;
      h['X-Lynomia-App-Version'] = info.version;
      h['X-Lynomia-App-Build'] = info.build;
    }
    final company = viewContext.companyId;
    final client = viewContext.clientId;
    if (company != null) h['X-Lynomia-Company'] = company;
    if (client != null) h['X-Lynomia-Client'] = client;
    if (r.idempotencyKey != null) h['Idempotency-Key'] = r.idempotencyKey!;
    if (r.ifMatchVersion != null) h['If-Match'] = '"${r.ifMatchVersion}"';
    if (r.ifNoneMatch != null) h['If-None-Match'] = r.ifNoneMatch!;
    if (r.jsonBody != null) h['Content-Type'] = 'application/json';
    if (r.contentType != null) h['Content-Type'] = r.contentType!;
    if (r.auth == AuthMode.required) {
      final token = refreshed
          ? session.accessToken
          : await session.freshAccessToken();
      if (token == null) {
        throw ApiException(
          code: ApiErrorCode.unauthenticated,
          httpStatus: 401,
          message: 'لا جلسة',
        );
      }
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// الإرسال الكامل: محاولات محدودة + تدوير عند 401 + أخطاء مكتوبة.
  Future<ApiRawResponse> send(ApiRequest r) async {
    var refreshedOnce = false;
    var attempt = 0;
    while (true) {
      attempt++;
      final http.Response resp;
      try {
        resp = await _execute(r, refreshed: refreshedOnce).timeout(r.timeout);
      } on TimeoutException catch (e) {
        if (r.retriable && attempt < _maxAttempts) {
          await _backoff(attempt);
          continue;
        }
        throw NetworkException('مهلة الطلب', cause: e);
      } on http.ClientException catch (e) {
        if (r.retriable && attempt < _maxAttempts) {
          await _backoff(attempt);
          continue;
        }
        throw NetworkException('تعذر الاتصال', cause: e);
      }

      if (resp.statusCode == 304) {
        return ApiRawResponse(status: 304, headers: resp.headers);
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = _decode(resp);
        // غلاف خطأ على 2xx (مثل APPROVAL_REQUIRED على 202: «صُفَّ طلبك») —
        // يُرمى مكتوباً كي يتفرع المستدعي على `code` لا على شكل الحمولة (§31).
        if (json is Map &&
            json.containsKey('error') &&
            json.containsKey('code')) {
          throw _asException(resp);
        }
        return ApiRawResponse(
          status: resp.statusCode,
          headers: resp.headers,
          json: json,
          bodyBytes: resp.bodyBytes,
        );
      }

      final error = _asException(resp);

      // انتهاء وصول على نقطة مصادقة ⇒ تدوير واحد ثم إعادة المرة الوحيدة.
      if (error.code == ApiErrorCode.unauthenticated &&
          r.auth == AuthMode.required &&
          !refreshedOnce) {
        refreshedOnce = true;
        await session.refreshNow(); // متسلسل — الكل ينتظر التدوير نفسه (§36)
        continue;
      }
      if (error.code == ApiErrorCode.sessionRevoked) {
        await session.end(SessionEndReason.revoked); // §38 — فورية
        throw error;
      }
      if (error.code == ApiErrorCode.rateLimited &&
          r.retriable &&
          attempt < _maxAttempts) {
        final retryAfter =
            int.tryParse(resp.headers['retry-after'] ?? '') ?? (attempt * 2);
        await sleep(Duration(seconds: retryAfter.clamp(1, 30)));
        continue;
      }
      if (resp.statusCode >= 500 &&
          error.code != ApiErrorCode.maintenance &&
          error.code != ApiErrorCode.lockdown &&
          r.retriable &&
          attempt < _maxAttempts) {
        await _backoff(attempt);
        continue;
      }
      throw error;
    }
  }

  Future<http.Response> _execute(
    ApiRequest r, {
    required bool refreshed,
  }) async {
    final headers = await _headers(r, refreshed: refreshed);
    final uri = _uri(r);
    _log.info('${r.method} ${uri.path}');
    final req = http.Request(r.method, uri)..headers.addAll(headers);
    if (r.jsonBody != null) req.body = jsonEncode(r.jsonBody);
    if (r.bodyBytes != null) req.bodyBytes = r.bodyBytes!;
    final streamed = await _transport.send(req);
    return http.Response.fromStream(streamed);
  }

  Object? _decode(http.Response resp) {
    final type = resp.headers['content-type'] ?? '';
    if (!type.contains('json')) return null;
    if (resp.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(resp.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  ApiException _asException(http.Response resp) {
    final body = _decode(resp);
    final map = body is Map
        ? body.cast<String, dynamic>()
        : const <String, dynamic>{};
    // بعض النقاط (مثل `work/today`) تردّ `{error: '<رمز_آلي>', message}` بلا
    // `code`: الرمزُ الآليّ حينها هو `error` نفسه (snake_case لا نص عربي) —
    // يُحفظ خاماً كي يتفرّع المستدعي عليه لا على الرسالة.
    final errorToken = map['error']?.toString();
    final rawCode =
        (map['code'] ??
                resp.headers['x-error-code'] ??
                (errorToken != null &&
                        RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(errorToken)
                    ? errorToken
                    : null))
            ?.toString();
    return ApiException(
      code: ApiErrorCode.parse(rawCode),
      rawCode: rawCode,
      httpStatus: resp.statusCode,
      message: rawCode != null && rawCode == errorToken && map['code'] == null
          ? (map['message']?.toString() ?? '')
          : (map['error']?.toString() ?? map['message']?.toString() ?? ''),
      details: map['details'] is Map
          ? (map['details'] as Map).cast<String, dynamic>()
          : const {},
      requestId: (map['request_id'] ?? resp.headers['x-request-id'])
          ?.toString(),
    );
  }

  Future<void> _backoff(int attempt) => sleep(
    Duration(milliseconds: (1 << attempt) * 250 + _random.nextInt(250)),
  ); // أُسي + ارتعاش

  // ── مختصرات مريحة ────────────────────────────────────────────────────────

  /// GET يعيد كائن `data`.
  Future<Map<String, dynamic>> getData(
    String path, {
    Map<String, String> query = const {},
    AuthMode auth = AuthMode.required,
  }) async =>
      (await send(ApiRequest('GET', path, query: query, auth: auth))).dataMap;

  /// POST/PUT يعيد كائن `data`.
  Future<Map<String, dynamic>> sendData(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int? ifMatchVersion,
    AuthMode auth = AuthMode.required,
  }) async => (await send(
    ApiRequest(
      method,
      path,
      jsonBody: body,
      idempotencyKey: idempotencyKey,
      ifMatchVersion: ifMatchVersion,
      auth: auth,
    ),
  )).dataMap;

  /// قائمة مرقمة قياسية.
  Future<ListPage<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic>) itemOf, {
    Map<String, String> query = const {},
  }) async {
    final resp = await send(ApiRequest('GET', path, query: query));
    return ListPage.fromJson(resp.envelope, itemOf);
  }
}
