/// مدير الجلسة — رمز الوصول في الذاكرة، والتحديث **عملية واحدة متسلسلة** (§36).
///
/// رمز التحديث الخادمي **يستهلك لمرة** ويتدور: خمسة طلبات تصادف 401 معاً يجب أن
/// تنتظر تدويراً واحداً لا أن ترسل خمسة تحديثات بالرمز نفسه (إعادة استعمال رمز
/// مدوَّر = إشارة هجوم تبطل العائلة كلها خادمياً). التسلسل هنا بنيوي:
/// [refreshNow] يشارك Future واحداً لكل المنتظرين.
///
/// بعد نجاح التدوير يُستبدل الزوج المخزن ذرياً (§37). `REFRESH_TOKEN_INVALID`
/// أو `SESSION_REVOKED` ⇒ مسح الاعتماد والعودة للمصادقة — لا يُعاد الرمز القديم.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/api_exception.dart';
import '../security/redacting_logger.dart';
import 'session_tokens.dart';
import 'token_store.dart';

enum SessionEndReason { loggedOut, expired, revoked, restricted }

/// منفذ نداء التحديث الفعلي — يحقنه التوصيل (AuthRepository عبر ApiClient بلا
/// اعتراض مصادقة) لكسر الدور بين المدير والعميل.
typedef RefreshExecutor = Future<SessionTokens> Function(String refreshToken);

class SessionManager extends ChangeNotifier {
  SessionManager({required SessionTokenStore tokenStore, RedactingLogger? log})
    : _store = tokenStore,
      _log = log ?? RedactingLogger();

  final SessionTokenStore _store;
  final RedactingLogger _log;

  RefreshExecutor? refreshExecutor;

  SessionTokens? _tokens;
  Future<void>? _inflightRefresh;
  final _ends = StreamController<SessionEndReason>.broadcast();

  /// نهايات الجلسة (انتهاء/إبطال/خروج) — يستمع لها الموجه لإعادة التوجيه.
  Stream<SessionEndReason> get endEvents => _ends.stream;

  bool get hasSession => _tokens != null;
  String? get accessToken => _tokens?.accessToken;
  String? get sessionId => _tokens?.sessionId;

  /// تبني زوجاً جديداً (دخول/MFA/تدوير): استبدال ذري في المخزن الآمن ثم الذاكرة.
  Future<void> adopt(SessionTokens t) async {
    await _store.replace(t);
    _tokens = t;
    notifyListeners();
  }

  /// استرجاع الجلسة عند الإقلاع البارد.
  Future<bool> restore() async {
    _tokens = await _store.read();
    return _tokens != null;
  }

  /// رمز وصول صالح للطلب القادم — يجدد استباقياً إن كان منتهياً.
  Future<String?> freshAccessToken() async {
    final t = _tokens;
    if (t == null) return null;
    if (!t.accessExpired()) return t.accessToken;
    await refreshNow();
    return _tokens?.accessToken;
  }

  /// التدوير المتسلسل: مشاركة عملية واحدة بين كل المتزامنين (§36).
  Future<void> refreshNow() {
    final inflight = _inflightRefresh;
    if (inflight != null) return inflight;
    final run = _doRefresh().whenComplete(() => _inflightRefresh = null);
    _inflightRefresh = run;
    return run;
  }

  Future<void> _doRefresh() async {
    final t = _tokens;
    final exec = refreshExecutor;
    if (t == null || exec == null) {
      throw StateError('لا جلسة أو لا منفذ تحديث');
    }
    try {
      final fresh = await exec(t.refreshToken);
      await adopt(fresh); // §37: استبدال ذري — القديم مات
      _log.info('تدوير جلسة ناجح');
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.refreshTokenInvalid ||
          e.code == ApiErrorCode.sessionRevoked ||
          e.code == ApiErrorCode.unauthenticated) {
        // §37/§38: لا إعادة للرمز القديم — مسح والعودة للمصادقة.
        await end(
          e.code == ApiErrorCode.sessionRevoked
              ? SessionEndReason.revoked
              : SessionEndReason.expired,
        );
      }
      rethrow;
    }
  }

  /// إنهاء الجلسة محلياً (بعد logout خادمي أو حكم إبطال) وبث السبب.
  Future<void> end(SessionEndReason reason) async {
    _tokens = null;
    await _store.clear();
    _ends.add(reason);
    notifyListeners();
  }

  @override
  void dispose() {
    _ends.close();
    super.dispose();
  }
}
