package dev.lynomia.lynomia_hub_app

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth يتطلب FragmentActivity: مع FlutterActivity يفشل قفل البصمة وقت
// التشغيل على Android (حارسه: test/governance_test.dart).
class MainActivity : FlutterFragmentActivity()
