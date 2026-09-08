/// الماسح (§70) — الحل خادمي حصراً: `GET identity/resolve/{q}` يعيد كياناً
/// مخولاً مكتوباً `{module,id}` أو 404؛ لا تفسير باركود محلي.
library;

import '../../core/api/api_client.dart';
import '../../core/api/api_envelope.dart';

class IdentityRepository {
  IdentityRepository(this.api);

  final ApiClient api;

  Future<DeepTarget?> resolve(String code) async {
    final data = await api.getData(
      'identity/resolve/${Uri.encodeComponent(code)}',
    );
    return DeepTarget.fromJson(data) ?? DeepTarget.fromJson(data['target']);
  }
}
