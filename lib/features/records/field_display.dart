/// عرض قيم الحقول القراءة (§20) — كل نوع يبثه المخطط له عارض:
/// text ta num date dt bool sel ref tags url file img sec — والمجهول يُعرض
/// نصاً بأمان (لا انهيار إصدار §93). التغطية موثقة في docs/schema-field-coverage.md.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../modules/module_schema.dart';

class FieldValueView extends StatelessWidget {
  const FieldValueView({super.key, required this.field, required this.value});

  final FieldSpec field;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = value;
    if (v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty)) {
      return Text(l.fieldNoValue);
    }
    switch (field.type) {
      case 'bool':
        return Icon(
          v == true || v == 1 || v == '1' ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: v == true || v == 1 || v == '1'
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        );
      case 'num':
        // عرض عشري آمن (§81): Decimal يطبع القيمة الخادمية بدقتها الكاملة —
        // لا double ولا حساب محلي.
        final d = Decimal.tryParse(v.toString());
        return Text(
          d?.toString() ?? v.toString(),
          textDirection: TextDirection.ltr,
        );
      case 'date':
      case 'dt':
        final parsed = DateTime.tryParse(v.toString());
        if (parsed == null) return Text(v.toString());
        final local = parsed.toLocal();
        final fmt = field.type == 'date'
            ? intl.DateFormat.yMMMd(Localizations.localeOf(context).toString())
            : intl.DateFormat.yMMMd(Localizations.localeOf(context).toString())
                  .add_Hm();
        return Text(fmt.format(local));
      case 'tags':
        final tags = v is List ? v : v.toString().split(',');
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in tags)
              Chip(
                label: Text(t.toString()),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        );
      case 'url':
        final url = v.toString();
        return InkWell(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            url,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'sec':
        // سري: يُقنع، ولا نسخ تلقائياً للحافظة (§142)، ولا يُخبأ (§62).
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('••••••••', textDirection: TextDirection.ltr),
            const SizedBox(width: 8),
            Tooltip(
              message: l.fieldSecretMasked,
              child: const Icon(Icons.lock_outline, size: 16),
            ),
          ],
        );
      case 'file':
      case 'img':
        // المرفق حضور لا مسار — التنزيل عبر بوابة الملفات المصادقة (§69).
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              field.type == 'img' ? Icons.image_outlined : Icons.attach_file,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                v.toString().split('/').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'ref':
        if (v is List) return Text(v.map((e) => e.toString()).join('، '));
        return Text(v.toString());
      case 'ta':
        return Text(v.toString());
      default: // text وأي نوع مستقبلي مجهول — نص آمن (§93)
        if (v is List) return Text(v.map((e) => e.toString()).join('، '));
        return Text(v.toString());
    }
  }
}
