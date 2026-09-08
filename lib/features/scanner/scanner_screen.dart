/// الماسح (§70) — كاميرا ← رمز ← حل خادمي ← ملاحة للكيان المخول.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController();
  bool _resolving = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .firstOrNull;
    if (code == null) return;

    final l = AppLocalizations.of(context)!;
    setState(() {
      _resolving = true;
      _message = null;
    });
    try {
      // المحلل الخادمي هو الحقيقة — لا تفسير محلي للرمز (§70).
      final target = await AppScope.of(context).identity.resolve(code);
      if (!mounted) return;
      if (target == null) {
        setState(() => _message = l.scannerNotFound);
      } else {
        context.pushReplacement(target.routePath);
        return;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _message = e.code == ApiErrorCode.resourceNotFound
            ? l.scannerNotFound
            : describeError(context, e),
      );
    } on NetworkException {
      if (!mounted) return;
      setState(() => _message = l.errNetwork);
    } finally {
      if (mounted) {
        // مهلة قصيرة قبل السماح بمسح جديد — منع وابل من نداءات الحل.
        await Future<void>.delayed(const Duration(seconds: 1));
        if (mounted) setState(() => _resolving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.scannerTitle)),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _resolving ? l.stateLoading : (_message ?? l.scannerHint),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
