/// Compile-time switches injected with `--dart-define`.
library;

/// True in builds produced for the F-Droid repository
/// (`flutter build apk --dart-define=FDROID_BUILD=true`).
///
/// F-Droid's inclusion policy forbids checking a competing distribution
/// channel for app updates and frowns on unattended binary downloads, so
/// those builds skip the GitHub release check and the automatic yt-dlp
/// update on startup. The manual "Check for engine updates" action stays
/// available and is declared as a NonFreeNet anti-feature.
const bool kFdroidBuild = bool.fromEnvironment('FDROID_BUILD');
