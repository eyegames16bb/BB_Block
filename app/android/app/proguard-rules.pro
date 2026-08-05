# Flutter's own embedding/plugin loader uses reflection to find and
# instantiate registered plugins — safe to keep unconditionally, this is
# the standard rule recommended across Flutter's own release documentation
# for any project that enables R8/ProGuard.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter's engine has an OPTIONAL dependency on Play Core's deferred-
# component/split-install APIs (`PlayStoreDeferredComponentManager`) for
# apps that use Play Feature Delivery — this app doesn't, so those classes
# are genuinely absent from the classpath. Without this `-dontwarn`, R8
# fails the build entirely on "missing classes" rather than just warning
# (a well-documented Flutter+AGP8 interaction, not specific to this app).
-dontwarn com.google.android.play.core.**

# Most modern plugin AARs (google_mobile_ads, audioplayers, shared_preferences,
# etc.) already ship their own `consumer-rules.pro`, which AGP merges in
# automatically — no per-plugin rules needed here. Google Mobile Ads SDK is
# the one exception worth a defensive keep, since ad-serving code paths are
# loaded reflectively and a missed keep rule fails silently (an ad simply
# never loads) rather than with a build error.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
