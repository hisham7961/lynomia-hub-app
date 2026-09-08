/// مستودع بوابة العميل — قراءات `/api/mobile/v1/portal/*` (§12/§18).
///
/// الخادم يفشل مغلقاً على العضوية الفعّالة: عضوية معلّقة = عالم فارغ صادق،
/// والتطبيق يعرضه كما هو — لا بيانات مختلقة عند خلاء الخادم.
library;

import '../../core/api/api_client.dart';
import 'portal_models.dart';

class PortalRepository {
  PortalRepository(this.api);

  final ApiClient api;

  Future<PortalHome> home() async =>
      PortalHome.fromJson(await api.getData('portal/home'));

  Future<List<PortalEngagement>> engagements() async =>
      _list('portal/engagements', 'engagements', PortalEngagement.fromJson);

  Future<List<PortalProject>> projects() async =>
      _list('portal/projects', 'projects', PortalProject.fromJson);

  Future<PortalProject> project(String id) async => PortalProject.fromJson(
    ((await api.getData('portal/projects/$id'))['project'] as Map? ?? const {})
        .cast<String, dynamic>(),
  );

  Future<List<PortalDocument>> documents() async =>
      _list('portal/documents', 'documents', PortalDocument.fromJson);

  Future<PortalDocument> document(String id) async => PortalDocument.fromJson(
    ((await api.getData('portal/documents/$id'))['document'] as Map? ??
            const {})
        .cast<String, dynamic>(),
  );

  Future<List<PortalInvoice>> invoices() async =>
      _list('portal/invoices', 'invoices', PortalInvoice.fromJson);

  Future<PortalInvoice> invoice(String id) async => PortalInvoice.fromJson(
    ((await api.getData('portal/invoices/$id'))['invoice'] as Map? ?? const {})
        .cast<String, dynamic>(),
  );

  Future<List<PortalConversation>> conversations() async => _list(
    'portal/conversations',
    'conversations',
    PortalConversation.fromJson,
  );

  Future<PortalConversationThread> conversation(String id) async {
    final data = await api.getData('portal/conversations/$id');
    return PortalConversationThread(
      conversation: PortalConversation.fromJson(
        (data['conversation'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      messages: (data['messages'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => PortalMessage.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<List<T>> _list<T>(
    String path,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) async => ((await api.getData(path))[key] as List? ?? const [])
      .whereType<Map>()
      .map((e) => parse(e.cast<String, dynamic>()))
      .toList();
}
