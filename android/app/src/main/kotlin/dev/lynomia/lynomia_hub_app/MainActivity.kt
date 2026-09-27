package dev.lynomia.lynomia_hub_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth يتطلب FragmentActivity: مع FlutterActivity يفشل قفل البصمة وقت
// التشغيل على Android (حارسه: test/governance_test.dart).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // قناة الإشعار التي يسمّيها الخادم (PushService::ANDROID_CHANNEL) — عند كل
        // إقلاع: الإنشاء متكرّر بلا أثر ويحدّث الاسم/الوصف بلغة الجهاز الحالية.
        NotificationChannels.ensureDefault(this)
    }
}
