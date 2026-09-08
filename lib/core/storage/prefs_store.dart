/// تفضيلات محلية **غير حساسة** (§102) — لغة، مظهر، أعلام واجهة.
///
/// منفصلة عمداً عن المخزن الآمن (أسرار) وعن الخبيئة المشفرة (بيانات أعمال):
/// ملف JSON بسيط لا يجوز أن يحمل رمزاً أو سجل عمل.
library;

import 'dart:convert';
import 'dart:io';

class PrefsStore {
  PrefsStore(this.rootDir);

  final Directory rootDir;
  Map<String, dynamic> _cache = {};
  bool _loaded = false;

  File get _file => File('${rootDir.path}/prefs.json');

  Future<void> _ensure() async {
    if (_loaded) return;
    _loaded = true;
    if (await _file.exists()) {
      try {
        _cache = (jsonDecode(await _file.readAsString()) as Map)
            .cast<String, dynamic>();
      } on FormatException {
        _cache = {};
      }
    }
  }

  Future<Object?> get(String key) async {
    await _ensure();
    return _cache[key];
  }

  Future<void> set(String key, Object? value) async {
    await _ensure();
    if (value == null) {
      _cache.remove(key);
    } else {
      _cache[key] = value;
    }
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(_cache), flush: true);
  }
}
