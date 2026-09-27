/// `GET bootstrap` (§44) — لقطة الإقلاع الواحدة: هوية، سياق، أعلام، تنقّل IA،
/// عدّ غير المقروء، نسخ العقد. ETag/304 يعاد استعمال اللقطة عند الثبات.
library;

import '../../core/api/api_client.dart';
import '../../core/auth/auth_repository.dart';
import '../workspaces/ia_models.dart';

class ContextDimension {
  const ContextDimension({
    required this.restricted,
    this.active,
    required this.count,
    required this.hasMore,
    required this.items,
  });

  factory ContextDimension.fromJson(Map<String, dynamic> j) => ContextDimension(
    restricted: j['restricted'] == true,
    active: j['active']?.toString(),
    count: (j['count'] as num?)?.toInt() ?? 0,
    hasMore: j['has_more'] == true,
    items: (j['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => (
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
          ),
        )
        .toList(),
  );

  final bool restricted;
  final String? active;
  final int count;
  final bool hasMore;
  final List<({String id, String name})> items;
}

/// عضوية حساب العميل الفعّالة كما يبثها الخادم (`bootstrap.memberships`).
class ClientMembershipInfo {
  const ClientMembershipInfo({
    required this.clientId,
    required this.clientName,
    required this.role,
  });

  factory ClientMembershipInfo.fromJson(Map<String, dynamic> j) =>
      ClientMembershipInfo(
        clientId: j['client_id']?.toString() ?? '',
        clientName: j['client_name']?.toString() ?? '',
        role: j['role']?.toString() ?? '',
      );

  final String clientId;
  final String clientName;
  final String role;
}

class Bootstrap {
  const Bootstrap({
    required this.user,
    required this.companies,
    required this.clients,
    required this.featureFlags,
    required this.unreadNotifications,
    required this.ia,
    required this.schemaVersion,
    this.memberships = const [],
    this.timezone,
    this.appVersionOnServer,
  });

  factory Bootstrap.fromJson(Map<String, dynamic> j) => Bootstrap(
    user: AuthUser.fromJson(
      (j['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    companies: ContextDimension.fromJson(
      (((j['context'] as Map?) ?? const {})['companies'] as Map?)
              ?.cast<String, dynamic>() ??
          const {},
    ),
    clients: ContextDimension.fromJson(
      (((j['context'] as Map?) ?? const {})['clients'] as Map?)
              ?.cast<String, dynamic>() ??
          const {},
    ),
    featureFlags:
        (j['feature_flags'] as Map?)?.cast<String, dynamic>() ?? const {},
    unreadNotifications: (j['unread_notifications'] as num?)?.toInt() ?? 0,
    ia: j['ia'] is Map
        ? IaTree.fromJson((j['ia'] as Map).cast<String, dynamic>())
        : IaTree.empty,
    memberships: (j['memberships'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ClientMembershipInfo.fromJson(e.cast<String, dynamic>()))
        .toList(),
    schemaVersion: j['schema_version']?.toString() ?? '',
    timezone: j['timezone']?.toString(),
    appVersionOnServer: ((j['versions'] as Map?) ?? const {})['app']
        ?.toString(),
  );

  final AuthUser user;
  final ContextDimension companies;
  final ContextDimension clients;

  /// أعلام قدرة **للعرض فقط** (`can_approve` …) — الخادم يعيد الفحص في كل نقطة.
  final Map<String, dynamic> featureFlags;

  /// عضويات حساب العميل الفعّالة (فارغة للحساب الداخلي).
  final List<ClientMembershipInfo> memberships;
  final int unreadNotifications;
  final IaTree ia;
  final String schemaVersion;
  final String? timezone;
  final String? appVersionOnServer;

  bool flag(String name) => featureFlags[name] == true;

  /// علمُ قدرةٍ اختياريّ: `false` صريحٌ ⇒ مطفأة؛ غائبٌ (خادمٌ أقدم) ⇒ null
  /// فيُجرَّب النداء ويُعتمد ٤٠٤ بديلاً.
  bool? optionalFlag(String name) => switch (featureFlags[name]) {
    final bool b => b,
    _ => null,
  };
}

class BootstrapRepository {
  BootstrapRepository(this.api);

  final ApiClient api;

  String? _etag;
  Bootstrap? _cached;

  /// جلب مع ETag: 304 ⇒ اللقطة المحفوظة (لا حمولة ثانية) (§44).
  Future<Bootstrap> fetch({bool force = false}) async {
    final resp = await api.send(
      ApiRequest('GET', 'bootstrap', ifNoneMatch: force ? null : _etag),
    );
    if (resp.notModified && _cached != null) return _cached!;
    _etag = resp.etag;
    return _cached = Bootstrap.fromJson(resp.dataMap);
  }

  /// `GET navigation` — لتحديث الشجرة عند تغير الصلاحيات (§92).
  Future<IaTree> navigation() async {
    final data = await api.getData('navigation');
    return data['ia'] is Map
        ? IaTree.fromJson((data['ia'] as Map).cast<String, dynamic>())
        : IaTree.empty;
  }

  void invalidate() {
    _etag = null;
    _cached = null;
  }
}
