/// طيّ الروابط العالمية/العميقة (§76) إلى وجهةٍ محلية — دالةٌ صرفة مختبرة.
///
/// المنصة (intent-filter بـ`autoVerify` على Android و`applinks:` على iOS) هي
/// التي تحصر الروابط في نطاقنا الموثَّق؛ وهنا نحصرها في المسارين المعلَنين في
/// `/.well-known/*` بالخادم (`/m/*` و`/app/*`) ونطويها على نظيرتها المحلية.
library;

import '../config/app_identifiers.dart';

/// `/app/activate/{token}` ⇒ `/activate/{token}` (تفعيلٌ عامٌّ قبل الدخول)،
/// و`/app/...` ⇒ `/m/...`؛ وغير ذلك كما هو.
String foldAppPath(String path) {
  if (!path.startsWith('/app/')) return path;
  return path.startsWith('/app/activate/')
      ? path.replaceFirst('/app/', '/')
      : path.replaceFirst('/app/', '/m/');
}

/// الوجهة المحلية لرابطٍ وارد، أو `null` حين لا يخصّنا.
///
/// يُقبل `https` (وhttp للتطوير المحلي فقط لا يصل من المنصة أصلاً)، ويُرفض أي
/// مسارٍ خارج البادئتين أو فيه مقطعٌ فارغ أو `..`. سلسلة الاستعلام تُحفظ.
String? foldDeepLink(Uri uri) {
  if (uri.hasScheme && uri.scheme != 'https' && uri.scheme != 'http') {
    return null;
  }
  var path = uri.path;
  if (!AppIdentifiers.deepLinkPathPrefixes.any(path.startsWith)) return null;
  // `/m/tasks/` ⇒ `/m/tasks` (go_router لا يطابق الشرطة الختامية).
  while (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  final segments = path.split('/').skip(1).toList();
  if (segments.length < 2 ||
      segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
    return null;
  }
  final local = foldAppPath(path);
  return uri.hasQuery ? '$local?${uri.query}' : local;
}
