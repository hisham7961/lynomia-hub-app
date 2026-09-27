/// «احفظ» على تعليقٍ أو رسالة DM (`POST saved`) مع تراجعٍ فوري (`DELETE saved/{id}`).
///
/// الحفظ خادمياً «حفظٌ لا تبديل»: الإعادة تعيد القائمة (`created=false`) فيُقال
/// «محفوظة سلفاً» ولا يُعرض تراجعٌ يزيل ما حفظه المستخدم من قبل.
library;

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';

Future<void> saveWithUndo(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) async {
  final l = AppLocalizations.of(context)!;
  final collab = AppScope.of(context).collab;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final res = await collab.save(targetType: targetType, targetId: targetId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(res.created ? l.savedDone : l.savedAlready),
        action: res.created && res.item.id.isNotEmpty
            ? SnackBarAction(
                label: l.savedUndo,
                onPressed: () => collab.unsave(res.item.id).catchError((_) {}),
              )
            : null,
      ),
    );
  } on Object catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(describeError(context, e))));
  }
}
