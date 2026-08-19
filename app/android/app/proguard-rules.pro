# Keep all ML Kit text recognition classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }
# Keep the generic signatures on the plugin's scheduled-notification model classes
# so Gson can reconstruct them via TypeToken in release/R8 builds.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Gson (used by flutter_local_notifications to serialize/deserialize notification data)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
# Keep TypeToken and its subclasses WITHOUT allowing shrinking of their generic
# signature — proguard-android-optimize.txt otherwise strips it, breaking release.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

