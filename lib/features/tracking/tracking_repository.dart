/// التتبع الميداني (§71 §72) — صريح، ظاهر، بموافقة، وينتهي بإنهائه.
///
/// لا جمع موقع خارج جلسة نشطة بدأها المستخدم؛ دفعات النقاط idempotent.
library;

import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';

class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.at,
    this.accuracy,
    this.seq,
  });

  final double lat;
  final double lng;
  final DateTime at;
  final double? accuracy;
  final int? seq;

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'at': at.toUtc().toIso8601String(),
    if (accuracy != null) 'accuracy': accuracy,
    if (seq != null) 'seq': seq,
  };
}

class TrackingRepository {
  TrackingRepository(this.api);

  final ApiClient api;

  /// البدء يفرض الموافقة الصريحة خادمياً (`consent=true`).
  Future<String> start({Map<String, dynamic> extra = const {}}) async {
    final data = await api.sendData(
      'POST',
      'tracking/start',
      body: {'consent': true, ...extra},
    );
    return (data['session'] ?? data['id'])?.toString() ?? '';
  }

  /// دفعة نقاط — مفتاح idempotency ثابت للدفعة الواحدة عبر إعادة المحاولة.
  Future<void> sendPoints(
    String sessionId,
    List<TrackPoint> points, {
    String? idempotencyKey,
  }) => api.sendData(
    'POST',
    'tracking/$sessionId/points',
    body: {'points': points.map((p) => p.toJson()).toList()},
    idempotencyKey: idempotencyKey ?? const Uuid().v4(),
  );

  Future<void> end(String sessionId) =>
      api.sendData('POST', 'tracking/$sessionId/end');
}
