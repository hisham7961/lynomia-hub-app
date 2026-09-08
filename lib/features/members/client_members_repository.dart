/// إدارة أعضاء العميل (§15) — لوحة المدير الداخلي على
/// `/api/mobile/v1/clients/{client}/members*`.
///
/// العقد: الدعوة على سكّة B.1 (لا كلمة سر تُنشأ أو تُرسل — رسالة تفعيل)،
/// منح Owner وسحب الوصول خلف تصعيد الجوال المربوط بالغرض
/// (`action:clients:member_owner` / `action:clients:member_revoke`) —
/// الرد 428 `STEP_UP_REQUIRED` يعالجه `runWithStepUp` بغرضه المسمّى.
library;

import '../../core/api/api_client.dart';

class ClientMember {
  const ClientMember({
    required this.id,
    required this.role,
    required this.status,
    required this.userName,
    required this.userEmail,
    required this.activated,
    this.invitedAt,
    this.activatedAt,
  });

  factory ClientMember.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map? ?? const {}).cast<String, dynamic>();
    return ClientMember(
      id: j['id']?.toString() ?? '',
      role: j['role']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      userEmail: user['email']?.toString() ?? '',
      activated: user['activated'] == true,
      invitedAt: j['invited_at']?.toString(),
      activatedAt: j['activated_at']?.toString(),
    );
  }

  final String id;
  final String role;
  final String status;
  final String userName;
  final String userEmail;

  /// وضع كلمة سر بنفسه (حضور التفعيل فقط — لا أثر كلمة سر في العقد).
  final bool activated;
  final String? invitedAt;
  final String? activatedAt;
}

/// أدوار العضوية كما يعرّفها الخادم (`ClientMembership::ROLES`).
const clientMemberRoles = ['owner', 'lead', 'technical', 'finance', 'viewer'];

class ClientMembersRepository {
  ClientMembersRepository(this.api);

  final ApiClient api;

  Future<List<ClientMember>> list(String clientId) async =>
      ((await api.getData('clients/$clientId/members'))['members'] as List? ??
              const [])
          .whereType<Map>()
          .map((e) => ClientMember.fromJson(e.cast<String, dynamic>()))
          .toList();

  Future<ClientMember> invite({
    required String clientId,
    required String email,
    String? name,
    required String role,
    String? idempotencyKey,
  }) async => _member(
    await api.sendData(
      'POST',
      'clients/$clientId/members',
      idempotencyKey: idempotencyKey,
      body: {'email': email, 'name': ?name, 'role': role},
    ),
  );

  Future<ClientMember> setRole({
    required String clientId,
    required String membershipId,
    required String role,
  }) async => _member(
    await api.sendData(
      'PUT',
      'clients/$clientId/members/$membershipId',
      body: {'role': role},
    ),
  );

  Future<ClientMember> revoke({
    required String clientId,
    required String membershipId,
  }) async => _member(
    await api.sendData('DELETE', 'clients/$clientId/members/$membershipId'),
  );

  ClientMember _member(Map<String, dynamic> data) => ClientMember.fromJson(
    (data['member'] as Map? ?? const {}).cast<String, dynamic>(),
  );
}
