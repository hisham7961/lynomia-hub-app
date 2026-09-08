/// سياق العرض النشط (شركة/عميل) — **تضييق لا تخويل** (§42 §43).
///
/// يُبث في `X-Lynomia-Company`/`X-Lynomia-Client` مع كل طلب؛ الخادم يقاطعه مع
/// المسموح ويتجاهل ما يوسّع. تغييره يبطل الخبيئات غير المتوافقة بنيوياً (مفاتيح
/// الخبيئة تتضمن السياق) ويعيد جلب الشاشات المتأثرة (المستمعون).
library;

import 'package:flutter/foundation.dart';

class ContextOption {
  const ContextOption({required this.id, required this.name});
  final String id;
  final String name;
}

class ViewContext extends ChangeNotifier {
  String? _companyId;
  String? _clientId;
  String? companyName;
  String? clientName;

  String? get companyId => _companyId;
  String? get clientId => _clientId;

  /// بصمة تدخل في مفاتيح الخبيئة والمزامنة — عزل سياقي بنيوي (§64).
  String get cacheKey => 'c_${_companyId ?? '-'}_k_${_clientId ?? '-'}';

  void setCompany(String? id, {String? name}) {
    if (_companyId == id) return;
    _companyId = id;
    companyName = name;
    notifyListeners();
  }

  void setClient(String? id, {String? name}) {
    if (_clientId == id) return;
    _clientId = id;
    clientName = name;
    notifyListeners();
  }

  void clear() {
    _companyId = null;
    _clientId = null;
    companyName = null;
    clientName = null;
    notifyListeners();
  }
}
