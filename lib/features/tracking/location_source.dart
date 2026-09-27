/// مصدر الموقع للتتبع الميداني (§71) — خلف واجهة كي يُستبدل بـFake في الاختبار
/// (لا منصة حقيقية في الاختبارات · CLAUDE.md).
library;

import 'package:geolocator/geolocator.dart';

/// قراءة موقع واحدة كما تسلّمها المنصة.
class LocationFix {
  const LocationFix({
    required this.lat,
    required this.lng,
    required this.at,
    this.accuracy,
  });

  final double lat;
  final double lng;
  final DateTime at;
  final double? accuracy;
}

abstract interface class LocationSource {
  /// يطلب الإذن عند الحاجة — `false` ⇒ مرفوض (لا بدء).
  Future<bool> ensurePermission();

  /// بثّ القراءات أثناء الجلسة النشطة فقط (يُلغى بإنهائها).
  Stream<LocationFix> positions();
}

/// المصدر الحقيقي عبر `geolocator` — أثناء الاستخدام فقط، بدقة عالية ومرشّح مسافة.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  @override
  Stream<LocationFix> positions() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).map(
        (p) => LocationFix(
          lat: p.latitude,
          lng: p.longitude,
          at: p.timestamp,
          accuracy: p.accuracy,
        ),
      );
}
