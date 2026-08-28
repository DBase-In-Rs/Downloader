# R8 is enabled only to drop Flutter's unused Play Store deferred-components
# support: its com.google.android.play.core references trip the F-Droid
# binary scanner. Every other class is kept verbatim (youtubedl-android and
# Jackson rely on reflection), and neither obfuscation nor optimization runs,
# so the release bytecode matches a non-minified build minus those classes.
-dontobfuscate
-dontoptimize
-keepattributes *

# Keep everything except the deferred-components plumbing and the Play Core
# stubs it references (negated filters must precede the ** catch-all).
-keep class !io.flutter.embedding.engine.deferredcomponents.**,!io.flutter.embedding.android.FlutterPlayStoreSplitApplication,!com.google.android.play.core.**,** { *; }

# The Play Core classes are absent from the classpath by design; the only
# code referencing them is stripped above.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Optional dependencies of Jackson (java.beans on desktop JVMs) and of
# youtubedl-android's commons-compress (org.tukaani XZ) that have never been
# on the Android runtime classpath; the referencing code paths are unused.
-dontwarn java.beans.**
-dontwarn org.tukaani.xz.**
