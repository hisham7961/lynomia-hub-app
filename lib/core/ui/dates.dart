/// تنسيق تواريخ العرض بحسب لغة الواجهة (توقيت الجهاز المحلي).
library;

import 'package:intl/intl.dart' as intl;

/// تاريخ قصير: «٢٧ سبتمبر ٢٠٢٦» / «Sep 27, 2026».
String formatShortDate(DateTime d, String locale) =>
    intl.DateFormat.yMMMd(locale).format(d.toLocal());

/// وقت قصير: «٤:٣٠ م» / «4:30 PM».
String formatShortTime(DateTime d, String locale) =>
    intl.DateFormat.jm(locale).format(d.toLocal());
