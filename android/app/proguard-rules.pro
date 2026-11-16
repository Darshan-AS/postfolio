# Preserve file names and line numbers for readable Firebase Crashlytics stack traces.
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Flutter wrapper rules (supplementing Flutter Gradle plugin defaults).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# The Flutter engine references Play Core (deferred components / split install), which this
# app does not use or ship. Without this, R8 stops the release build on the missing classes.
-dontwarn com.google.android.play.core.**
