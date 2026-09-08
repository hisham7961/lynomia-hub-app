/// نماذج بوابة العميل (§12/§18) — الأشكال العميلية كما يبثها الخادم من
/// `/api/mobile/v1/portal/*`. لا حقل داخلياً هنا أصلاً: الخادم لا يحمّل
/// التكلفة/الميزانية/البنية للعميل — ما لا يُحمَّل لا يُسرَّب.
library;

class PortalClient {
  const PortalClient({required this.id, required this.name});

  factory PortalClient.fromJson(Map<String, dynamic> j) => PortalClient(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
  );

  final String id;
  final String name;
}

class PortalEngagement {
  const PortalEngagement({
    required this.id,
    required this.name,
    this.type,
    this.status,
    this.renewal,
    this.clientNote,
  });

  factory PortalEngagement.fromJson(Map<String, dynamic> j) => PortalEngagement(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    type: j['type']?.toString(),
    status: j['status']?.toString(),
    renewal: j['renewal']?.toString(),
    clientNote: j['client_note']?.toString(),
  );

  final String id;
  final String name;
  final String? type;
  final String? status;
  final String? renewal;
  final String? clientNote;
}

class PortalProject {
  const PortalProject({
    required this.id,
    required this.name,
    this.status,
    this.priority,
    this.progress,
    this.startDate,
    this.launchExpected,
    this.launchActual,
    this.description,
    this.clientName,
    this.engagementName,
  });

  factory PortalProject.fromJson(Map<String, dynamic> j) => PortalProject(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    status: j['status']?.toString(),
    priority: j['priority']?.toString(),
    progress: (j['progress'] as num?)?.toInt(),
    startDate: j['start_date']?.toString(),
    launchExpected: j['launch_exp']?.toString(),
    launchActual: j['launch_act']?.toString(),
    description: j['description']?.toString(),
    clientName: ((j['client'] as Map?) ?? const {})['name']?.toString(),
    engagementName: ((j['engagement'] as Map?) ?? const {})['name']?.toString(),
  );

  final String id;
  final String name;
  final String? status;
  final String? priority;
  final int? progress;
  final String? startDate;
  final String? launchExpected;
  final String? launchActual;
  final String? description;
  final String? clientName;
  final String? engagementName;
}

class PortalDocument {
  const PortalDocument({
    required this.id,
    required this.name,
    this.cat,
    this.docNo,
    this.issueDate,
    this.expiry,
    this.description,
  });

  factory PortalDocument.fromJson(Map<String, dynamic> j) => PortalDocument(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    cat: j['cat']?.toString(),
    docNo: j['doc_no']?.toString(),
    issueDate: j['issue_date']?.toString(),
    expiry: j['expiry']?.toString(),
    description: j['description']?.toString(),
  );

  final String id;
  final String name;
  final String? cat;
  final String? docNo;
  final String? issueDate;
  final String? expiry;
  final String? description;
}

/// فاتورة العميل — المبالغ **نصوص عشرية** كما بثها الخادم (تُعرض عبر
/// `Decimal` لا `double` — الخادم مصدر الحسابات).
class PortalInvoice {
  const PortalInvoice({
    required this.id,
    this.docNo,
    this.kind,
    this.date,
    this.due,
    this.total,
    this.paid,
    this.currency,
    this.state,
    this.projectId,
  });

  factory PortalInvoice.fromJson(Map<String, dynamic> j) => PortalInvoice(
    id: j['id']?.toString() ?? '',
    docNo: j['doc_no']?.toString(),
    kind: j['kind']?.toString(),
    date: j['date']?.toString(),
    due: j['due']?.toString(),
    total: j['total']?.toString(),
    paid: j['paid']?.toString(),
    currency: j['currency']?.toString(),
    state: j['state']?.toString(),
    projectId: j['project_id']?.toString(),
  );

  final String id;
  final String? docNo;
  final String? kind;
  final String? date;
  final String? due;
  final String? total;
  final String? paid;
  final String? currency;
  final String? state;
  final String? projectId;
}

class PortalConversation {
  const PortalConversation({
    required this.id,
    required this.kind,
    this.title,
    this.updatedAt,
  });

  factory PortalConversation.fromJson(Map<String, dynamic> j) =>
      PortalConversation(
        id: j['id']?.toString() ?? '',
        kind: j['kind']?.toString() ?? '',
        title: j['title']?.toString(),
        updatedAt: j['updated_at']?.toString(),
      );

  final String id;
  final String kind;
  final String? title;
  final String? updatedAt;
}

class PortalMessage {
  const PortalMessage({
    required this.id,
    required this.body,
    required this.userName,
    required this.mine,
    this.createdAt,
  });

  factory PortalMessage.fromJson(Map<String, dynamic> j) => PortalMessage(
    id: j['id']?.toString() ?? '',
    body: j['body']?.toString() ?? '',
    userName: ((j['user'] as Map?) ?? const {})['name']?.toString() ?? '',
    mine: j['mine'] == true,
    createdAt: j['created_at']?.toString(),
  );

  final String id;
  final String body;
  final String userName;
  final bool mine;
  final String? createdAt;
}

class PortalConversationThread {
  const PortalConversationThread({
    required this.conversation,
    required this.messages,
  });

  final PortalConversation conversation;
  final List<PortalMessage> messages;
}

/// لقطة بيت العميل — معاينات الوجهات + عدّ غير المقروء.
class PortalHome {
  const PortalHome({
    required this.clients,
    required this.engagements,
    required this.projects,
    required this.documents,
    required this.invoices,
    required this.conversations,
    required this.unreadNotifications,
  });

  factory PortalHome.fromJson(Map<String, dynamic> j) => PortalHome(
    clients: _list(j, 'clients', PortalClient.fromJson),
    engagements: _list(j, 'engagements', PortalEngagement.fromJson),
    projects: _list(j, 'projects', PortalProject.fromJson),
    documents: _list(j, 'documents', PortalDocument.fromJson),
    invoices: _list(j, 'invoices', PortalInvoice.fromJson),
    conversations: _list(j, 'conversations', PortalConversation.fromJson),
    unreadNotifications:
        (((j['notifications'] as Map?) ?? const {})['unread'] as num?)
            ?.toInt() ??
        0,
  );

  static List<T> _list<T>(
    Map<String, dynamic> j,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) => (j[key] as List? ?? const [])
      .whereType<Map>()
      .map((e) => parse(e.cast<String, dynamic>()))
      .toList();

  final List<PortalClient> clients;
  final List<PortalEngagement> engagements;
  final List<PortalProject> projects;
  final List<PortalDocument> documents;
  final List<PortalInvoice> invoices;
  final List<PortalConversation> conversations;
  final int unreadNotifications;

  bool get isEmpty =>
      clients.isEmpty &&
      engagements.isEmpty &&
      projects.isEmpty &&
      documents.isEmpty &&
      invoices.isEmpty &&
      conversations.isEmpty;
}
