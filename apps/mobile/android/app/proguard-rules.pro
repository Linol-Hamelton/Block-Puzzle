# ProGuard and R8 rules for Lumina Blocks (apps/mobile)
# Ensures required symbols, reflection targets, and Crashlytics mapping tables are retained.

# Flutter wrapper and engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve line numbers and source file names for Crashlytics stack deobfuscation
-keepattributes SourceFile,LineNumberTable

# Firebase Crashlytics
-keep public class * extends java.lang.Exception
-keepclassmembers class * {
    @com.google.firebase.crashlytics.** *;
}

# Google Play Billing
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# Audioplayers plugin
-keep class xyz.luan.audioplayers.** { *; }

# Preserve native methods and JNI bindings
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve annotations and type signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
