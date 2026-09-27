/// قراءة أهلية الأزرار بلا أثر قبل عرضها (خلفية v2.619: قرار الإجازة، قدرات
/// العهدة، خيارات الدفعة). الخادم يحسم بالقواعد نفسها التي يحسم بها الفعل —
/// فلا تخمين محلي من المخطط أو من نصّ حالة عربي.
///
/// الحالات الصادقة: أثناء القراءة لا شيء (لا زرّ قد يختفي)، و`FORBIDDEN` أو
/// `RESOURCE_NOT_FOUND` ⇒ لا بطاقة (لا فعل لي هنا — تفريعٌ على الرمز الآلي)،
/// وما سواهما من أعطال ⇒ سطرٌ بإعادة المحاولة لا بطاقة ميتة.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../errors/api_exception.dart';

class EligibilityLoader<T> {
  EligibilityLoader(this._host, this._fetch);

  final State _host;
  final Future<T> Function() _fetch;

  T? value;
  Object? error;
  bool loading = true;

  /// لا أهلية بتاتاً (رفض خادمي صريح) — تُخفى البطاقة.
  bool hidden = false;

  Future<void> load() async {
    _set(() {
      loading = true;
      error = null;
      hidden = false;
    });
    try {
      final v = await _fetch();
      _set(() => value = v);
    } on ApiException catch (e) {
      final denied =
          e.code == ApiErrorCode.forbidden ||
          e.code == ApiErrorCode.resourceNotFound;
      _set(() => denied ? hidden = true : error = e);
    } on Object catch (e) {
      _set(() => error = e);
    } finally {
      _set(() => loading = false);
    }
  }

  void _set(VoidCallback fn) {
    if (_host.mounted) {
      // ignore: invalid_use_of_protected_member
      _host.setState(fn);
    } else {
      fn();
    }
  }

  Widget build(BuildContext context, Widget Function(T value) builder) {
    if (loading || hidden) return const SizedBox.shrink();
    final v = value;
    if (error != null || v == null) {
      final l = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(l.eligibilityLoadFailed)),
            TextButton(
              key: const Key('eligibility-retry'),
              onPressed: load,
              child: Text(l.actionRetry),
            ),
          ],
        ),
      );
    }
    return builder(v);
  }
}

/// ملاحظة سببٍ آلي بلا أزرار (نصّ من ARB بالرمز).
class EligibilityNote extends StatelessWidget {
  const EligibilityNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
