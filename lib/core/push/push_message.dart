/// رسالة الدفع كما تصل من المزوّد، وقراءتها على عقد الخادم (§73–§75).
///
/// الحمولة الآمنة بالبناء (`PushService::payloadFor` في الخلفية): عنوانٌ وجسمٌ
/// عامّان + `data` نصّية: `notification_id`, `category`, `unread`, و`module`,
/// `id`, `action` حين للإشعار وجهةٌ قانونية. والإشعار التجريبي من مركز المنصة
/// `category: 'test'` بلا وجهة.
library;

import '../api/api_envelope.dart';

/// رسالة مجرّدة عن أي SDK — يبنيها المحوِّل من رسالة المزوّد.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// بيانات FCM نصّيةٌ دائماً (مفتاح ⇒ نص).
  final Map<String, String> data;
}

/// قراءة الحمولة على عقد الخادم — لا ثقة بها في التخويل: الوجهة تُفتح عبر
/// الموجّه والشاشة تطلب السجل من الخادم الذي يعيد فحص النطاق والصلاحية.
class PushPayload {
  PushPayload._({
    required this.title,
    required this.body,
    required this.category,
    required this.notificationId,
    required this.unread,
    required this.target,
  });

  factory PushPayload.of(PushMessage m) {
    String? str(String key) {
      final v = m.data[key]?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final module = str('module');
    final id = str('id');
    return PushPayload._(
      title: m.title,
      body: m.body,
      category: str('category'),
      notificationId: str('notification_id'),
      unread: int.tryParse(str('unread') ?? ''),
      target: (module != null && id != null)
          ? DeepTarget(module: module, id: id, action: str('action') ?? 'show')
          : null,
    );
  }

  final String? title;
  final String? body;
  final String? category;
  final String? notificationId;

  /// عدّاد غير المقروء الخادمي لحظة الإرسال (null حين غاب أو لم يُقرأ).
  final int? unread;

  /// الوجهة القانونية `{module,id,action}` أو null.
  final DeepTarget? target;

  /// الإشعار التجريبي من مركز المنصة — يُعرض ولا يُنقل منه.
  bool get isTest => category == 'test';

  /// هل لفتحه وجهةٌ يمكن حلّها (مباشرة أو عبر `notifications/{id}/target`)؟
  bool get navigable => !isTest && (target != null || notificationId != null);
}
