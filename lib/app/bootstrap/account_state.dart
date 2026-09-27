/// حالة الحساب الجارية — المستخدم + لقطة bootstrap + تبديل السياق (§42 §43 §92).
library;

import 'package:flutter/foundation.dart';

import '../../core/api/view_context.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/storage/encrypted_cache.dart';
import '../../features/launch/bootstrap_repository.dart';
import '../../features/workspaces/ia_models.dart';

class AccountState extends ChangeNotifier {
  AccountState({
    required this.bootstrapRepo,
    required this.viewContext,
    required this.cache,
  });

  final BootstrapRepository bootstrapRepo;
  final ViewContext viewContext;
  final EncryptedJsonCache cache;

  AuthUser? user;
  Bootstrap? bootstrap;

  IaTree get ia => bootstrap?.ia ?? IaTree.empty;

  /// عدّاد غير المقروء الحي (`notifications/unread-count` أو رد القراءة) —
  /// يتقدّم على لقطة bootstrap حتى إعادة جلبها.
  int? _liveUnread;
  int get unreadNotifications =>
      _liveUnread ?? bootstrap?.unreadNotifications ?? 0;

  /// تحديث الشارة من رقمٍ خادمي حيّ (لا حساب محلي).
  void setUnread(int value) {
    if (value < 0 || value == _liveUnread) return;
    _liveUnread = value;
    notifyListeners();
  }

  bool flag(String name) => bootstrap?.flag(name) ?? false;

  /// قدرةٌ لا يُحجب بابها إلا بـ`false` صريح من الخادم (غيابُ العلم ⇒ يُجرَّب
  /// والخادم يحسم بـ٤٠٤) — `collab_typing`/`collab_presence`.
  bool capabilityAllowed(String name) => bootstrap?.optionalFlag(name) ?? true;

  /// نمط الحساب — يختار القشرة (بوابة العميل أو اللوحة الداخلية). عرضٌ من
  /// المصنِّف الخادمي؛ الحرس الحقيقي `MobilePortalGuard` على الخادم (§10).
  bool get isClient => user?.isClient ?? false;
  List<ClientMembershipInfo> get memberships =>
      bootstrap?.memberships ?? const [];

  Future<void> loadBootstrap({bool force = false}) async {
    bootstrap = await bootstrapRepo.fetch(force: force);
    user = bootstrap!.user;
    _liveUnread = null;
    notifyListeners();
  }

  /// تبديل سياق العرض (§43): تحديث الحالة والترويسات (يقرؤها العميل مباشرة)،
  /// وإبطال ما لا يتوافق (خبيئة المزامنة معزولة بالمفتاح بنيوياً — تبقى لسياقها)،
  /// ثم إعادة جلب اللقطة. المزامنات المعلقة لا تُرسل بسياق آخر: الترويسات تُبنى
  /// وقت الإرسال من [ViewContext] الواحد.
  Future<void> switchCompany(String? id, {String? name}) async {
    viewContext.setCompany(id, name: name);
    bootstrapRepo.invalidate();
    await loadBootstrap(force: true);
  }

  Future<void> switchClient(String? id, {String? name}) async {
    viewContext.setClient(id, name: name);
    bootstrapRepo.invalidate();
    await loadBootstrap(force: true);
  }

  /// تحديث الصلاحيات/الشجرة عند التقدمة أو حدث تغيير (§91 §92).
  Future<void> refreshEntitlements() async {
    bootstrapRepo.invalidate();
    await loadBootstrap(force: true);
  }

  /// تنظيف عند الخروج (§39): مسح الهوية واللقطة والسياق والخبيئة الحساسة.
  Future<void> clearOnLogout() async {
    final uid = user?.id;
    user = null;
    bootstrap = null;
    _liveUnread = null;
    bootstrapRepo.invalidate();
    viewContext.clear();
    if (uid != null) await cache.deleteByPrefix('sync_u_${uid}_');
    notifyListeners();
  }
}
