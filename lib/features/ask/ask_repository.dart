/// «اسأل Hub» (`/api/mobile/v1/ask*`) — السؤال والمتابعة والمحادثات المحفوظة.
///
/// الخادم مصدر الحقيقة: هو من يقرأ بعين المستخدم ويصادق المراجع ويعيد تحقق
/// الجواب المحفوظ (`hidden`). والتطبيق يعرض فقط، ويتفرّع على رمز الإخفاق الآلي
/// (`failure`) لا على نص الرسالة العربية.
library;

import 'dart:async';
import 'dart:convert';

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';
import '../../core/errors/api_exception.dart';

/// فئات رموز الإخفاق — للعرض المحلي؛ الرمز الخام يبقى في [AskAnswer.failure].
enum AskFailureKind {
  unavailable,
  limit,
  denied,
  noData,
  question,
  tooBig,
  other,
}

AskFailureKind askFailureKind(String? code) => switch (code) {
  'UNAVAILABLE' ||
  'GATEWAY_FAILURE' ||
  'PROVIDER_FAILURE' ||
  'MODEL_FAILURE' ||
  'MODEL_UNAVAILABLE' ||
  'PROVIDER_CREDITS' => AskFailureKind.unavailable,
  'RATE_LIMITED' ||
  'BUDGET_EXCEEDED' ||
  'QUOTA_EXCEEDED' => AskFailureKind.limit,
  'UNAUTHORIZED' || 'POLICY_DENIED' => AskFailureKind.denied,
  'NO_ACCESSIBLE_DATA' => AskFailureKind.noData,
  'MALFORMED_QUESTION' => AskFailureKind.question,
  'CONTEXT_LIMIT' || 'OUTPUT_LIMIT' || 'TOOL_BUDGET' => AskFailureKind.tooBig,
  _ => AskFailureKind.other,
};

/// مصدرٌ قرأه الخادم بعين المستخدم — وجهةٌ تُفتح حين يكون سجلاً واحداً.
class AskSource {
  const AskSource({
    required this.n,
    required this.module,
    required this.label,
    required this.rows,
    required this.ids,
  });

  factory AskSource.fromJson(Map<String, dynamic> j) => AskSource(
    n: (j['n'] as num?)?.toInt() ?? 0,
    module: j['module']?.toString(),
    label: j['label']?.toString() ?? j['module']?.toString() ?? '',
    rows: (j['rows'] as num?)?.toInt() ?? 0,
    ids: (j['ids'] as List? ?? const []).map((e) => e.toString()).toList(),
  );

  final int n;
  final String? module;
  final String label;
  final int rows;
  final List<String> ids;

  /// سجلٌ واحدٌ في وحدةٍ معروفة ⇒ وجهةٌ؛ وإلا فلا رابط (لا اختلاق وجهة).
  DeepTarget? get target => module != null && ids.length == 1
      ? DeepTarget(module: module!, id: ids.single)
      : null;
}

class AskAnswer {
  const AskAnswer({
    required this.ok,
    required this.answer,
    required this.partial,
    required this.failure,
    required this.message,
    required this.sources,
    required this.thread,
  });

  factory AskAnswer.fromJson(Map<String, dynamic> j) => AskAnswer(
    ok: j['ok'] == true,
    answer: j['answer']?.toString(),
    partial: j['partial'] == true,
    failure: j['failure']?.toString(),
    message: j['message']?.toString() ?? '',
    sources: (j['sources'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AskSource.fromJson(e.cast<String, dynamic>()))
        .toList(),
    thread: j['thread']?.toString(),
  );

  final bool ok;
  final String? answer;
  final bool partial;
  final String? failure;

  /// نص الخادم العربي — للعرض المساعد فقط، لا يُفرَّع عليه.
  final String message;
  final List<AskSource> sources;
  final String? thread;

  AskFailureKind get failureKind => askFailureKind(failure);
}

class AskThreadSummary {
  const AskThreadSummary({
    required this.id,
    required this.title,
    required this.lastAt,
  });

  factory AskThreadSummary.fromJson(Map<String, dynamic> j) => AskThreadSummary(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    lastAt: DateTime.tryParse(j['last_at']?.toString() ?? ''),
  );

  final String id;
  final String title;
  final DateTime? lastAt;
}

class AskThreads {
  const AskThreads({
    required this.memory,
    required this.retentionDays,
    required this.threads,
  });

  final bool memory;
  final int retentionDays;
  final List<AskThreadSummary> threads;
}

class AskTurn {
  const AskTurn({
    required this.question,
    required this.answer,
    required this.ok,
    required this.hidden,
    required this.failure,
  });

  factory AskTurn.fromJson(Map<String, dynamic> j) => AskTurn(
    question: j['question']?.toString() ?? '',
    answer: j['answer']?.toString(),
    ok: j['ok'] == true,
    hidden: j['hidden'] == true,
    failure: j['failure']?.toString(),
  );

  final String question;
  final String? answer;
  final bool ok;

  /// الخادم أعاد التحقق فلم يعد الجواب متاحاً لهذا المستخدم الآن — يُعرض السؤال وحده.
  final bool hidden;
  final String? failure;
}

class AskRepository {
  AskRepository(this.api);

  final ApiClient api;

  /// سؤالٌ جديد، أو متابعةٌ في [thread]. لا إعادة تلقائية: السؤال نداءٌ محكومٌ
  /// مدفوع — والإعادة قرار المستخدم.
  /// والمهلة أطول من الافتراض: الجواب قراءاتٌ ونداءاتُ نموذجٍ متتابعة. وPOST بلا
  /// مفتاح تكرار **غير قابل للإعادة** في العميل — فلا يُدفع السؤال مرتين.
  Future<AskAnswer> ask(String q, {String? thread}) async {
    final resp = await api.send(
      ApiRequest(
        'POST',
        'ask',
        jsonBody: {'q': q, 'thread': ?thread},
        timeout: askTimeout,
      ),
    );
    return AskAnswer.fromJson(resp.dataMap);
  }

  static const askTimeout = Duration(seconds: 120);

  /// `POST ask/stream` (SSE) — أحداث `progress` ثم `done` (حمولة `POST ask`
  /// نفسها) أو `error` {code, text}؛ الرفض قبل البثّ JSON عاديّ ⇒ [ApiException].
  ///
  /// سؤالٌ بالبثّ مع تقدّمٍ نصّي، وارتدادٌ لـ`POST ask` **فقط** حين يتعذّر فتح
  /// البثّ دون أن يبدأ الخادم العمل: خادمٌ أقدم بلا المسار (٤٠٤/٤٠٥) أو فشل
  /// اتصالٍ قبل أيّ رد (لا مهلة — قد يكون السؤال بلغ الخادم فلا يُدفع مرتين).
  /// بثٌّ بدأ ثم انقطع ⇒ خطأ صادق لا إعادة إرسال (الخادم يُكمل ويحفظ الدور).
  Future<AskAnswer> askWithProgress(
    String q, {
    String? thread,
    void Function(String text)? onProgress,
  }) async {
    final ApiStreamResponse resp;
    try {
      resp = await api.openStream(
        ApiRequest(
          'POST',
          'ask/stream',
          jsonBody: {'q': q, 'thread': ?thread},
          timeout: askTimeout,
        ),
      );
    } on Object catch (e) {
      if (shouldFallback(e)) return ask(q, thread: thread);
      rethrow;
    }
    // يُستهلك البثّ حتى نهايته (لا إلغاء اشتراكٍ في منتصفه): الخادم يغلقه بعد
    // `done`/`error`، والحدث الحاسم يُحفظ ثم يُعاد.
    AskAnswer? answer;
    ApiException? failure;
    try {
      await for (final e in parseAskEvents(resp.body)) {
        switch (e) {
          case AskProgress(:final text):
            if (text.isNotEmpty && answer == null) onProgress?.call(text);
          case AskDone(answer: final a):
            answer ??= a;
          case AskStreamError(:final code, :final text, :final requestId):
            failure ??= ApiException(
              code: ApiErrorCode.parse(code),
              rawCode: code,
              httpStatus: 200,
              message: text,
              requestId: requestId ?? resp.requestId,
            );
        }
      }
    } on Object catch (e) {
      if (answer == null && failure == null) {
        throw NetworkException('stream interrupted', cause: e);
      }
    }
    if (answer != null) return answer;
    if (failure != null) throw failure;
    // انتهى البثّ بلا done ولا error — انقطاعٌ في منتصفه.
    throw NetworkException('stream ended before done');
  }

  /// إخفاق **فتح** البثّ الذي يستوجب الارتداد لـ`POST ask`.
  static bool shouldFallback(Object e) {
    if (e is ApiException) {
      return e.code == ApiErrorCode.resourceNotFound ||
          e.code == ApiErrorCode.methodNotAllowed ||
          e.rawCode == 'NOT_A_STREAM';
    }
    if (e is NetworkException) return e.cause is! TimeoutException;
    return false;
  }

  Future<AskThreads> threads() async {
    final d = await api.getData('ask/threads');
    return AskThreads(
      memory: d['memory'] == true,
      retentionDays: (d['retention_days'] as num?)?.toInt() ?? 0,
      threads: (d['threads'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => AskThreadSummary.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<List<AskTurn>> turns(String threadId) async {
    final d = await api.getData('ask/threads/${Uri.encodeComponent(threadId)}');
    return (d['turns'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AskTurn.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<int> deleteThread(String threadId) async =>
      ((await api.sendData(
                'DELETE',
                'ask/threads/${Uri.encodeComponent(threadId)}',
              ))['deleted']
              as num?)
          ?.toInt() ??
      0;

  Future<int> deleteAll() async =>
      ((await api.sendData('DELETE', 'ask/threads'))['deleted'] as num?)
          ?.toInt() ??
      0;
}

/// حدث بثّ «اسأل Hub».
sealed class AskStreamEvent {
  const AskStreamEvent();
}

/// تقدّمٌ نصّي من الخادم (`progress.text`) — للعرض فقط.
class AskProgress extends AskStreamEvent {
  const AskProgress(this.stage, this.text);
  final String stage;
  final String text;
}

class AskDone extends AskStreamEvent {
  const AskDone(this.answer);
  final AskAnswer answer;
}

/// خطأٌ داخل البثّ: `code` آليّ و`text` للعرض.
class AskStreamError extends AskStreamEvent {
  const AskStreamError(this.code, this.text, this.requestId);
  final String code;
  final String text;
  final String? requestId;
}

/// محلّل SSE: أسطر `event:`/`data:` تفصلها سطرٌ فارغ؛ `data` JSON.
Stream<AskStreamEvent> parseAskEvents(Stream<List<int>> bytes) async* {
  String? event;
  final data = StringBuffer();
  AskStreamEvent? build() {
    final name = event ?? 'message';
    final raw = data.toString();
    event = null;
    data.clear();
    if (raw.isEmpty) return null;
    Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final j = json.cast<String, dynamic>();
    return switch (name) {
      'progress' => AskProgress(
        j['stage']?.toString() ?? '',
        j['text']?.toString() ?? '',
      ),
      'done' => AskDone(
        AskAnswer.fromJson(
          (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      ),
      'error' => AskStreamError(
        j['code']?.toString() ?? '',
        j['text']?.toString() ?? '',
        j['request_id']?.toString(),
      ),
      _ => null,
    };
  }

  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      final e = build();
      if (e != null) yield e;
      continue;
    }
    if (line.startsWith(':')) continue; // تعليق/نبضة
    final i = line.indexOf(':');
    final field = i < 0 ? line : line.substring(0, i);
    var value = i < 0 ? '' : line.substring(i + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'event') event = value;
    if (field == 'data') {
      if (data.isNotEmpty) data.write('\n');
      data.write(value);
    }
  }
  final tail = build();
  if (tail != null) yield tail;
}
