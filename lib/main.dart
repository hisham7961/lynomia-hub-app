import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await AppContainer.boot();
  runApp(LynomiaApp(container: container));
}
