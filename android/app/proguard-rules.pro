# Flutter-specific ProGuard rules
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the app's MainActivity (referenced only from AndroidManifest.xml)
-keep class com.pitrified.acerta.MainActivity { *; }

# Keep annotations
-keepattributes *Annotation*

# Suppress warnings for Play Core (deferred components, not used)
-dontwarn com.google.android.play.core.**
