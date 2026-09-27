package dev.lynomia.lynomia_hub_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * قناة Android الافتراضية `lynomia_default` (Android 8+). الخادم يرسل
 * `android.notification.channel_id = lynomia_default` (PushService::ANDROID_CHANNEL)،
 * وبغيابها يسقط النظام إلى قناة FCM الاحتياطية بلا اسمٍ معرَّب ولا أهمية عالية.
 *
 * الاسم والوصف من موارد النظام (values/ + values-ar/) — مطابقان لـ ARB
 * (notificationChannelName/Description)، وحارس ذلك test/governance_test.dart.
 * iOS لا قنوات فيه — لا مقابل هناك.
 */
object NotificationChannels {
    const val DEFAULT_ID = "lynomia_default"

    fun ensureDefault(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            DEFAULT_ID,
            context.getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.notification_channel_description)
        }
        // متكرّرٌ بلا أثر: القناة القائمة يُحدَّث اسمها ووصفها فقط (الأهمية يملكها المستخدم بعدها).
        manager.createNotificationChannel(channel)
    }
}
