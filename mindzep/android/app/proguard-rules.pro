# ─────────────────────────────────────────────────────────────────────────────
# MindZep — R8 / ProGuard keep rules for release builds (minifyEnabled = true).
#
# Debug builds do NOT minify, so anything missing here only shows up as a
# runtime crash in the release AAB shipped to the Play Store (the app "works
# in dev but crashes after download"). Keep every plugin that touches
# reflection, serialization (Gson), or native bridges.
# ─────────────────────────────────────────────────────────────────────────────

# ── Flutter engine / embedding ───────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ── GeneratedPluginRegistrant references (R8 missing-class check) ─────────────
# registerWith() runs during FlutterEngine init; R8 (full mode) errors out on
# these plugin references unless suppressed. Keep the third-party plugin
# namespaces so they survive at runtime; -dontwarn clears the static-analysis
# error for plugins resolved from their own AARs.
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.baseflow.permissionhandler.PermissionHandlerPlugin
-dontwarn com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin
-dontwarn com.tekartik.sqflite.SqflitePlugin
-dontwarn io.flutter.plugins.googlesignin.GoogleSignInPlugin
-dontwarn io.flutter.plugins.imagepicker.ImagePickerPlugin
-dontwarn io.flutter.plugins.pathprovider.PathProviderPlugin
-dontwarn io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
-dontwarn io.flutter.plugins.urllauncher.UrlLauncherPlugin

# ── Cashfree Payment Gateway SDK ─────────────────────────────────────────────
-keep class com.cashfree.** { *; }
-dontwarn com.cashfree.**

# ── Agora RTC engine ─────────────────────────────────────────────────────────
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# ── flutter_secure_storage → AndroidX Security Crypto → Google Tink ───────────
# Reads the saved auth token at startup; Tink uses reflection + protobuf and is
# stripped by R8 without these rules (crash on launch in release builds).
-keep class com.google.crypto.tink.** { *; }
-keep class androidx.security.crypto.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**

# ── flutter_local_notifications → Gson (de)serialization ─────────────────────
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
# Keep generic signatures so Gson can resolve parameterized types under R8.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ── Firebase / Cloud Messaging ───────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── Google Sign-In / Play services ───────────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Play Core (Flutter deferred components / split install) ───────────────────
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ── Metadata required by reflective SDKs ─────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault

# ── Never strip classes that back native methods ─────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── Keep enum values() / valueOf() (used reflectively) ───────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
