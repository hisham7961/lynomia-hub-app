/// «اسأل Hub» (`/api/mobile/v1/ask*`) — السؤال والمتابعة والمحادثات المحفوظة.
///
/// الخادم مصدر الحقيقة: هو من يقرأ بعين المستخدم ويصادق المراجع ويعيد تحقق
/// الجواب المحفوظ (`hidden`). والتطبيق يعرض فقط، ويتفرّع على رمز الإخفاق الآلي
/// (`failure`) لا على نص الرسالة العربية.
library;

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';

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
