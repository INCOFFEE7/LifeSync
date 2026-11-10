# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar Database native JNI & models
-keep class dev.isar.** { *; }
-keepclassmembers class dev.isar.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }
-keepclassmembers class es.antonborri.home_widget.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Attributes required for reflection / serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google Play Core / Deferred Components (referenced by Flutter engine)
-dontwarn com.google.android.play.core.**
