/// التفاعلات (تبديل رمزٍ على تعليقٍ أو رسالة DM) — الخادم يحسم الحالة والعدد.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// الرموز التي يقبلها الخادم (`CommentController::REACTIONS` في الخلفية) —
/// لا نقطة تسردها، والخادم يرفض سواها بـ`VALIDATION_FAILED` فلا اختلاق.
const kReactionEmojis = ['👍', '❤️', '🎉', '😂', '🤔', '🙏'];

/// نتيجة تبديل تفاعل كما يعيدها الخادم: الحالة الجديدة لرمزٍ واحد.
class ReactionToggle {
  const ReactionToggle({
    required this.targetId,
    required this.emoji,
    required this.mine,
    required this.count,
  });

  factory ReactionToggle.fromJson(Map<String, dynamic> j, String idKey) =>
      ReactionToggle(
        targetId: j[idKey]?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '',
        mine: j['mine'] == true,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  final String targetId;
  final String emoji;
  final bool mine;
  final int count;
}

/// ورقة اختيار رمز — تعيد الرمز المختار أو null.
Future<String?> pickReaction(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.reactionsPick, style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final e in kReactionEmojis)
                  InkWell(
                    key: Key('react-$e'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(ctx, e),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// شريحة تفاعل: الرمز والعدد، ومُعلَّمة إن كان تفاعلي — النقر يبدّل.
class ReactionChip extends StatelessWidget {
  const ReactionChip({
    super.key,
    required this.emoji,
    required this.count,
    required this.mine,
    this.onTap,
  });

  final String emoji;
  final int count;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text('$emoji $count'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: mine ? BorderSide(color: theme.colorScheme.primary) : null,
      onPressed: onTap,
    );
  }
}
