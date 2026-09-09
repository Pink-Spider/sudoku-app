# Google Mobile Ads and the UMP SDK reflect over their own classes.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }

# Flutter's embedding is referenced from generated code and the manifest.
-keep class io.flutter.embedding.** { *; }

# Flutter's embedding also references Play Core's deferred-component API,
# which is not on the classpath because this app does not use deferred
# components. Without this R8 fails the build on the missing classes.
-dontwarn com.google.android.play.core.**
