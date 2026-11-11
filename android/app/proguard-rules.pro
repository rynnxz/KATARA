## Flutter wrapper & JNI rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Google Play Services Auth & Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

## Keep native methods and annotations
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclasseswithmembernames class * {
    native <methods>;
}
