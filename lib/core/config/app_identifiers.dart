/// معرفات التطبيق — المركز الوحيد للمعرفات الخارجية.
///
/// كل ما هنا معرف **تطوير** يكفي للترجمة والتشغيل، وليس جاهزاً للمتاجر:
/// REPLACE_BEFORE_STORE_RELEASE — تُستبدل قبل أي نشر متجر، ويُضبط نظيرها
/// الخادمي (`setting('mobile.dl_*')` وروابط المتجر) كما في
/// `docs/mobile-readiness/08-versioning-deep-links.md` بالخلفية.
library;

abstract final class AppIdentifiers {
  /// REPLACE_BEFORE_STORE_RELEASE — معرف حزمة Android التطويري.
  static const androidApplicationId = 'dev.lynomia.lynomia_hub_app';

  /// REPLACE_BEFORE_STORE_RELEASE — معرف حزمة iOS التطويري.
  static const iosBundleId = 'dev.lynomia.lynomiaHubApp';

  /// REPLACE_BEFORE_STORE_RELEASE — لا Apple Team ID بعد (لا يُختلق).
  static const appleTeamId = 'NOT_CONFIGURED';

  /// أنماط الروابط العميقة التي يلتقطها التطبيق (عقد الخلفية §08).
  static const deepLinkPathPrefixes = ['/m/', '/app/'];

  /// اسم العرض.
  static const displayName = 'Lynomia Hub';
}
