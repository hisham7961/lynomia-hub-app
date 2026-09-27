/// الماسح (§70) — كاميرا ← رمز ← حل خادمي ← ملاحة للكيان المخول.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';

/// مصدر الرموز المقروءة — الكاميرا حقيقةً، وبديلٌ مزيّف في الاختبار (§103).
typedef ScanViewBuilder = Widget Function(
  BuildContext context,
  void Function(String code) onCode,
);

/// العارض الحقيقي: كاميرا `mobile_scanner` تسلّم أول قيمة خام غير فارغة.
Widget cameraScanView(BuildContext context, void Function(String) onCode) =>
    _CameraScanView(onCode: onCode);

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.scanView = cameraScanView});

  final ScanViewBuilder scanView;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _CameraScanView extends StatefulWidget {
  const _CameraScanView({required this.onCode});

  final void Function(String) onCode;

  @override
  State<_CameraScanView> createState() => _CameraScanViewState();
}

class _CameraScanViewState extends State<_CameraScanView> {
  final _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      final code = capture.barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .where((v) => v.isNotEmpty)
          .firstOrNull;
      if (code != null) widget.onCode(code);
    },
  );
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _resolving = false;
  String? _message;

  Future<void> _onCode(String code) async {
    if (_resolving || code.isEmpty) return;

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
          widget.scanView(context, _onCode),
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
