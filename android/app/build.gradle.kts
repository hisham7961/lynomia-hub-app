import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // لا إضافة com.google.gms.google-services عمداً: Firebase يُهيَّأ من Dart بخيارات
    // --dart-define (lib/core/push/firebase_env.dart) — لا google-services.json في المستودع.
}

// ─────────────────────────────────────────────────────────────────────────────
// هوية التطبيق — قابلةٌ للضبط من خارج المستودع (docs/OWNER_SETUP.md):
//   خاصية Gradle:  flutter build apk -P lynomia.applicationId=com.example.hub
//                  (أو في ~/.gradle/gradle.properties أو android/local.properties)
//   أو متغير بيئة:  LYNOMIA_ANDROID_APP_ID / LYNOMIA_APP_LINK_HOST (CI)
// نظيرها في Dart: lib/core/config/app_identifiers.dart — ونظيرها الخادمي:
// setting('mobile.dl_android_package') و setting('mobile.dl_android_fingerprints').
// ─────────────────────────────────────────────────────────────────────────────
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun identity(prop: String, env: String, default: String): String =
    (project.findProperty(prop) as String?)?.trim()?.takeIf { it.isNotEmpty() }
        ?: localProps.getProperty(prop)?.trim()?.takeIf { it.isNotEmpty() }
        ?: System.getenv(env)?.trim()?.takeIf { it.isNotEmpty() }
        ?: default

// REPLACE_BEFORE_STORE_RELEASE — معرّف الحزمة التطويري (يُمرَّر النهائي كخاصية).
val lynomiaApplicationId = identity(
    "lynomia.applicationId", "LYNOMIA_ANDROID_APP_ID", "dev.lynomia.lynomia_hub_app",
)

// REPLACE_BEFORE_STORE_RELEASE — نطاق الروابط العالمية (App Links). `.invalid` نطاقٌ
// محجوزٌ لا يُحلّ أبداً: البناء الافتراضي لا يدّعي ربطاً بنطاقٍ حقيقي.
val lynomiaAppLinkHost = identity(
    "lynomia.appLinkHost", "LYNOMIA_APP_LINK_HOST", "app-links.lynomia.invalid",
)

// ─────────────────────────────────────────────────────────────────────────────
// توقيع الإصدار — android/key.properties (مُتجاهَل في git؛ القالب key.properties.example).
// غيابه ⇒ توقيع debug **للبناء المحلي فقط** مع تحذيرٍ صريح؛ و
// -P lynomia.requireReleaseSigning=true (أو LYNOMIA_REQUIRE_RELEASE_SIGNING=true في CI)
// يحوّل الغياب إلى فشل بناء — فلا يُرفع للمتجر ملفٌّ موقَّعٌ بمفتاح debug.
// ─────────────────────────────────────────────────────────────────────────────
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties().apply {
    if (keyPropsFile.exists()) keyPropsFile.inputStream().use { load(it) }
}
val hasReleaseKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !keyProps.getProperty(it).isNullOrBlank() }
val requireReleaseSigning =
    identity("lynomia.requireReleaseSigning", "LYNOMIA_REQUIRE_RELEASE_SIGNING", "false") == "true"
val buildsRelease = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }

if (buildsRelease && !hasReleaseKey) {
    if (requireReleaseSigning) {
        throw GradleException(
            "Release signing required but android/key.properties is missing/incomplete " +
                "(توقيع الإصدار مطلوب) — see docs/OWNER_SETUP.md §5",
        )
    }
    logger.warn(
        """
        |
        |⚠️⚠️⚠️  RELEASE BUILD SIGNED WITH THE DEBUG KEY  ⚠️⚠️⚠️
        |  android/key.properties is missing/incomplete — LOCAL TESTING ONLY,
        |  Google Play will reject it. See docs/OWNER_SETUP.md §5 (keystore + key.properties).
        |  (مفتاح الإصدار غائب — للتجربة المحلية فقط، لا يُقبل في المتجر.)
        |""".trimMargin(),
    )
}

android {
    // مساحة أسماء الشيفرة (حزمة Kotlin لـMainActivity و R) — ثابتة عمداً ومستقلة عن
    // applicationId: تغيير هوية المتجر لا يتطلب نقل الشيفرة (راجع OWNER_SETUP §٢).
    namespace = "dev.lynomia.lynomia_hub_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = lynomiaApplicationId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // يُحقن في intent-filter الروابط العالمية (AndroidManifest.xml).
        manifestPlaceholders["appLinkHost"] = lynomiaAppLinkHost
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
                storeFile = rootProject.file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // للبناء المحلي فقط — التحذير أعلاه، والفشل مع requireReleaseSigning.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // سمة LaunchTheme من AppCompat — شرط local_auth على Android 8 وما دونه
    // (FlutterFragmentActivity + Theme.AppCompat).
    implementation("androidx.appcompat:appcompat:1.6.1")
}
