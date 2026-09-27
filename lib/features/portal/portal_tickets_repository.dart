/// «تذاكري» في بوابة العميل (المرحلة ٤.١) — `portal/tickets*`.
///
/// الخادم يحسم الحالة والقناة والعميل؛ التوأم المفتوح يُوجَّه لا يُمنع:
/// `409 CONFLICT` بـ`details.reason=duplicate_ticket` وبطاقة التذكرة القائمة،
/// والإعادة بـ`force=true` تفتح تذكرةً مختلفة عن بيّنة.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';
import '../../core/errors/api_exception.dart';

class PortalTicket {
  const PortalTicket({
    required this.id,
    required this.subject,
    this.status,
    this.priority,
    this.cat,
    this.projectId,
    this.done = false,
    this.createdAt,
    this.body,
    this.projectName,
  });

  factory PortalTicket.fromJson(Map<String, dynamic> j) => PortalTicket(
    id: j['id']?.toString() ?? '',
    subject: j['subject']?.toString() ?? '',
    status: jsonStr(j['status']),
    priority: jsonStr(j['priority']),
    cat: jsonStr(j['cat']),
    projectId: jsonStr(j['project_id']),
    done: j['done'] == true,
    createdAt: jsonDate(j['created_at']),
    body: jsonStr(j['body']),
    projectName: jsonStr(j['project_name']),
  );

  final String id;
  final String subject;
  final String? status;
  final String? priority;
  final String? cat;
  final String? projectId;

  /// مغلقة بحكم الخادم (الحالات المنتهية) — المرجع الآلي لا نصّ الحالة.
  final bool done;
  final DateTime? createdAt;
  final String? body;
  final String? projectName;
}

class PortalTicketReply {
  const PortalTicketReply({
    required this.id,
    required this.body,
    required this.mine,
    this.userName,
    this.createdAt,
  });

  factory PortalTicketReply.fromJson(Map<String, dynamic> j) =>
      PortalTicketReply(
        id: j['id']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        mine: j['mine'] == true,
        userName: UserRef.fromJson(j['user'])?.name,
        createdAt: jsonDate(j['created_at']),
      );

  final String id;
  final String body;
  final bool mine;
  final String? userName;
  final DateTime? createdAt;
}

class PortalTicketDetail {
  const PortalTicketDetail({required this.ticket, required this.replies});

  factory PortalTicketDetail.fromJson(Map<String, dynamic> j) =>
      PortalTicketDetail(
        ticket: PortalTicket.fromJson(jsonMap(j['ticket'])),
        replies: jsonMaps(j['replies'])
            .map(PortalTicketReply.fromJson)
            .toList(),
      );

  final PortalTicket ticket;

  /// الردود العامة وحدها — الملاحظة الداخلية لا تُعرض خادمياً.
  final List<PortalTicketReply> replies;
}

class IdName {
  const IdName(this.id, this.name);
  final String id;
  final String name;
}

class PortalTicketList {
  const PortalTicketList({
    required this.tickets,
    required this.projects,
    required this.clients,
    required this.priorities,
  });

  factory PortalTicketList.fromJson(Map<String, dynamic> j) {
    List<IdName> pairs(Object? v) => jsonMaps(v)
        .map(
          (e) => IdName(e['id']?.toString() ?? '', e['name']?.toString() ?? ''),
        )
        .toList();
    return PortalTicketList(
      tickets: jsonMaps(j['tickets']).map(PortalTicket.fromJson).toList(),
      projects: pairs(j['projects']),
      clients: pairs(j['clients']),
      priorities: jsonStrings(j['priorities']),
    );
  }

  final List<PortalTicket> tickets;
  final List<IdName> projects;
  final List<IdName> clients;

  /// الأولويات المقبولة خادمياً (خيارات حقل التذكرة).
  final List<String> priorities;
}

/// التوأم المفتوح: `409` بسبب `duplicate_ticket` — يحمل بطاقة التذكرة القائمة.
class DuplicateTicketException implements Exception {
  const DuplicateTicketException(this.existing, this.message);
  final PortalTicket? existing;
  final String message;
}

class PortalTicketsRepository {
  PortalTicketsRepository(this.api);

  final ApiClient api;

  Future<PortalTicketList> tickets() async =>
      PortalTicketList.fromJson(await api.getData('portal/tickets'));

  Future<PortalTicketDetail> ticket(String id) async =>
      PortalTicketDetail.fromJson(
        await api.getData('portal/tickets/${Uri.encodeComponent(id)}'),
      );

  /// فتح بلاغ — التوأم ⇒ [DuplicateTicketException] (والإعادة بـ`force`).
  Future<PortalTicketDetail> create({
    required String subject,
    required String body,
    required String priority,
    String? projectId,
    String? clientId,
    bool force = false,
    String? idempotencyKey,
  }) async {
    try {
      return PortalTicketDetail.fromJson(
        await api.sendData(
          'POST',
          'portal/tickets',
          body: {
            'subject': subject,
            'body': body,
            'priority': priority,
            'project': ?projectId,
            'client': ?clientId,
            if (force) 'force': true,
          },
          idempotencyKey: idempotencyKey ?? const Uuid().v4(),
        ),
      );
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.conflict &&
          e.details['reason'] == 'duplicate_ticket') {
        final dup = e.details['duplicate'];
        throw DuplicateTicketException(
          dup is Map ? PortalTicket.fromJson(jsonMap(dup)) : null,
          e.message,
        );
      }
      rethrow;
    }
  }

  /// ردّي على تذكرتي (عامٌّ دائماً).
  Future<PortalTicketReply> reply(
    String ticketId,
    String body, {
    String? idempotencyKey,
  }) async => PortalTicketReply.fromJson(
    jsonMap(
      (await api.sendData(
        'POST',
        'portal/tickets/${Uri.encodeComponent(ticketId)}/reply',
        body: {'body': body},
        idempotencyKey: idempotencyKey ?? const Uuid().v4(),
      ))['reply'],
    ),
  );
}
