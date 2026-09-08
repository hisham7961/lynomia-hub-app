/// حالة الاتصال (§84) — إشارة هادئة لا نوافذ إزعاج.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor({Stream<List<ConnectivityResult>>? source}) {
    _sub = (source ?? Connectivity().onConnectivityChanged).listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _online) {
        _online = online;
        notifyListeners();
      }
    });
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  bool get online => _online;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
