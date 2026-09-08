/// تفضيلات الخادم (§79 §80) — كتم الإشعارات والمثبتات عبر العقد، لا محلياً.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';

class MuteableKind {
  const MuteableKind({
    required this.key,
    required this.label,
    required this.muted,
  });

  factory MuteableKind.fromJson(Map<String, dynamic> j) => MuteableKind(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    muted: j['muted'] == true,
  );

  final String key;
  final String label;
  final bool muted;
}

class PinTarget {
  const PinTarget({
    required this.token,
    required this.label,
    required this.pinned,
    this.module,
  });

  factory PinTarget.fromJson(Map<String, dynamic> j) => PinTarget(
    token: j['token']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    pinned: j['pinned'] == true,
    module: j['module']?.toString(),
  );

  final String token;
  final String label;
  final bool pinned;
  final String? module;
}

class ServerPrefs {
  const ServerPrefs({
    required this.muted,
    required this.muteable,
    required this.pinned,
    required this.pinTargets,
    required this.pinMax,
  });

  factory ServerPrefs.fromJson(Map<String, dynamic> j) {
    final notify = (j['notify'] as Map?)?.cast<String, dynamic>() ?? const {};
    final pins = (j['pins'] as Map?)?.cast<String, dynamic>() ?? const {};
    List<PinTarget> targets(Object? v) => (v as List? ?? const [])
        .whereType<Map>()
        .map((e) => PinTarget.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ServerPrefs(
      muted: (notify['mute'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      muteable: (notify['muteable'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MuteableKind.fromJson(e.cast<String, dynamic>()))
          .toList(),
      pinned: targets(pins['pinned']),
      pinTargets: targets(pins['targets']),
      pinMax: (pins['max'] as num?)?.toInt() ?? 12,
    );
  }

  final List<String> muted;
  final List<MuteableKind> muteable;
  final List<PinTarget> pinned;
  final List<PinTarget> pinTargets;
  final int pinMax;
}

class PrefsRepository {
  PrefsRepository(this.api);

  final ApiClient api;

  Future<ServerPrefs> fetch() async =>
      ServerPrefs.fromJson(await api.getData('prefs'));

  Future<List<String>> setMute(List<String> muted) async {
    final data = await api.sendData('PUT', 'prefs', body: {'mute': muted});
    return (((data['notify'] as Map?) ?? const {})['mute'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  /// تبديل تثبيت — ليس عديم الأثر ⇒ idempotency للفعل الواحد.
  Future<bool> togglePin(String token, {String? idempotencyKey}) async {
    final data = await api.sendData(
      'POST',
      'prefs/pin',
      body: {'token': token},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return data['pinned'] == true;
  }
}
