# Third-Party Notices And License Checklist

Status: Draft. This file must be updated before every public binary release.

## Project License

DBase Video & Music Downloader is intended to be distributed under
GPL-3.0-only.

## References

- youtubedl-android: https://github.com/yausername/youtubedl-android
- FFmpeg legal notes: https://www.ffmpeg.org/legal.html
- FFmpeg license notes: https://ffmpeg.org/doxygen/8.0/md_LICENSE.html
- Jackson Databind: https://github.com/FasterXML/jackson-databind
- GPL-3.0 text: https://www.gnu.org/licenses/gpl-3.0.txt

## Planned Components

| Component | Purpose | License state | Release action |
| --- | --- | --- | --- |
| Flutter | UI framework | Flutter/Dart ecosystem licenses | Include generated notices and dependency license list. |
| Android Gradle Plugin / Kotlin | Android build and native integration | Tooling licenses vary | Document build tool versions. |
| youtubedl-android | Android wrapper for yt-dlp/youtube-dl style execution | GPL-3.0 | Android app currently uses `io.github.junkfood02.youtubedl-android:library:0.18.1`; keep app GPL-compatible and publish complete source. |
| yt-dlp | Media extraction backend used by youtubedl-android or desktop process runner | Bundled inside selected youtubedl-android artifact; exact bundled version still needs release verification | Document exact version and source. |
| youtubedl-android FFmpeg artifact | Android conversion/remuxing | LGPL or GPL depending on bundled FFmpeg build flags and linked libraries | Android app currently uses `io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1`; document configure flags, source offer, and license before public binary release. |
| FFmpeg | Desktop conversion/remuxing if bundled separately | LGPL or GPL depending on build flags and linked libraries | Document artifact, configure flags, source offer, and license. |
| Jackson Databind | Android JSON parsing for youtubedl-android metadata output | Apache-2.0 | Android app directly depends on `com.fasterxml.jackson.core:jackson-databind:2.11.1` because the youtubedl-android object mapper is used from the app module. |
| Desktop yt-dlp binary | Windows/macOS extraction backend if bundled | To be verified before bundling | Prefer user-selected binary until release packaging is decided. |
| Desktop FFmpeg binary | Windows/macOS conversion backend if bundled | To be verified before bundling | Prefer user-selected binary until release packaging is decided. |

## Required Before Public Binary Release

- [ ] Record exact dependency versions.
- [ ] Record exact youtubedl-android version.
- [ ] Record exact yt-dlp version.
- [ ] Record exact FFmpeg artifact and build flags.
- [ ] Confirm whether FFmpeg build is LGPL or GPL.
- [ ] Include GPL-3.0 license text.
- [ ] Include source code for this app.
- [ ] Include or link complete corresponding source for GPL components.
- [ ] Include generated Flutter/Dart package notices.
- [ ] Confirm no proprietary or incompatible binary dependency is bundled.
- [ ] Confirm no signing key, cookie, token, or private test URL is included.

## FFmpeg Notes

FFmpeg's license depends on how it is configured and which external libraries
are enabled. If GPL components are enabled, the FFmpeg build becomes GPL. The
selected Android artifact is currently
`io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1`, but its exact FFmpeg
version, configure flags, and LGPL/GPL state still need release verification.
Windows and macOS FFmpeg distribution is not selected yet.

## Android Packaging Notes

The current Android Gradle Plugin rejects explicit
`android:extractNativeLibs="true"` in the manifest. Legacy native-library
packaging is configured in `android/app/build.gradle.kts` through
`packaging.jniLibs.useLegacyPackaging = true`. `libpython.zip.so` is excluded
from debug-symbol stripping because it is a zip payload named like a shared
object, not a normal ELF object. The same keep-debug-symbol rule is applied to
`libffmpeg.zip.so`.

## Store And Provider Policy Notes

Downloader apps can trigger app-store and provider-policy review issues. Before
publishing outside GitHub test releases, review the target store policies and
avoid claims that encourage unauthorized downloading, DRM bypass, or paywall
bypass.
