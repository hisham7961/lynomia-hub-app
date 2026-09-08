/// التتبع الميداني (§71 §72) — بدء صريح بموافقة، جلسة ظاهرة بمؤشر دائم،
/// دفعات نقاط، إنهاء صريح. لا جمع موقع خارج الجلسة النشطة.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'tracking_repository.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _consented = false;
  bool _busy = false;
  String? _sessionId;
  StreamSubscription<Position>? _positions;
  final List<TrackPoint> _pending = [];
  Timer? _flushTimer;
  int _sent = 0;
  int _seq = 0;

  bool get active => _sessionId != null;

  @override
  void dispose() {
    // مغادرة الشاشة لا تبقي جمعاً خفياً — الاشتراك يلغى (الجلسة الخادمية
    // تنتهي بمهلتها إن لم تُنهَ صراحة).
    _positions?.cancel();
    _flushTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final c = AppScope.of(context);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.trackingPermissionDenied)));
        }
        return;
      }
      final sessionId = await c.tracking.start();
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _sent = 0;
        _seq = 0;
      });
      _positions = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(_onPosition);
      _flushTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _flush(),
      );
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPosition(Position p) {
    _pending.add(
      TrackPoint(
        lat: p.latitude,
        lng: p.longitude,
        at: p.timestamp,
        accuracy: p.accuracy,
        seq: _seq++,
      ),
    );
    if (_pending.length >= 20) _flush();
    if (mounted) setState(() {});
  }

  Future<void> _flush() async {
    final id = _sessionId;
    if (id == null || _pending.isEmpty) return;
    final batch = List<TrackPoint>.from(_pending);
    // مفتاح ثابت للدفعة — فشل الإرسال يعيد الدفعة نفسها بلا مضاعفة (§58).
    final key = const Uuid().v4();
    try {
      await AppScope.of(context).tracking
          .sendPoints(id, batch, idempotencyKey: key);
      _pending.removeRange(0, batch.length);
      _sent += batch.length;
      if (mounted) setState(() {});
    } on Object {
      // فشل قابل للاسترداد — الدفعة تبقى للمحاولة القادمة (§118).
    }
  }

  Future<void> _end() async {
    final id = _sessionId;
    if (id == null) return;
    final tracking = AppScope.of(context).tracking;
    setState(() => _busy = true);
    await _positions?.cancel();
    _flushTimer?.cancel();
    try {
      await _flush();
      await tracking.end(id);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeError(context, e))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sessionId = null;
          _busy = false;
          _pending.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.trackingTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!active) ...[
              // موافقة صريحة قبل أي بدء (§71).
              CheckboxListTile(
                value: _consented,
                onChanged: (v) => setState(() => _consented = v ?? false),
                title: Text(l.trackingConsent),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _consented && !_busy ? _start : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(l.trackingStart),
              ),
            ] else ...[
              // الجلسة ظاهرة دائماً أثناء نشاطها (§71 §72).
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        l.trackingActive,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(l.trackingPointsSent(_sent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _end,
                icon: const Icon(Icons.stop),
                label: Text(l.trackingEnd),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
