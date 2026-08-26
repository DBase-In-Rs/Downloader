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
| shared_preferences | Flutter plugin for local key-value storage used for download queue persistence | BSD-3-Clause | Include in generated Flutter/Dart package notices. |
| file_selector | Flutter plugin for the system file picker used for cookies.txt import | BSD-3-Clause | Include in generated Flutter/Dart package notices. |
| libwebp 1.5.0 | 16 KB page-aligned replacement builds of the libwebp libraries bundled inside the youtubedl-android FFmpeg artifact | BSD-3-Clause | Built from https://github.com/webmproject/libwebp v1.5.0 with NDK r28.2 (`-Wl,-z,max-page-size=16384`), shipped in `android/app/src/main/jniLibs`. Include license text in release notices. |
| Desktop yt-dlp binary | Windows/macOS extraction backend | Not bundled | Resolved from PATH or a user-selected path in Settings; nothing is redistributed. |
| Desktop FFmpeg binary | Windows/macOS conversion backend | Not bundled | User-selected path in Settings passed to yt-dlp via `--ffmpeg-location`; nothing is redistributed. |

## Recorded Versions (1.0.0 release line, audited 2026-08-26)

| Component | Version | License |
| --- | --- | --- |
| Flutter SDK | 3.47.1 stable (rev 6655482ec0) | BSD-3-Clause |
| cupertino_icons | 1.0.9 | MIT |
| shared_preferences (+android 2.4.27) | 2.5.5 | BSD-3-Clause |
| file_selector (+android 0.5.2+9) | 1.1.0 | BSD-3-Clause |
| youtubedl-android (library, ffmpeg) | 0.18.1 | GPL-3.0 |
| yt-dlp | bundled by 0.18.1, self-updated at runtime to latest stable (2026.08.19 at audit time) | Unlicense |
| FFmpeg (Android artifact) | 7.1.1, `--enable-gpl --enable-version3` (runtime-verified) | GPL |
| Jackson Databind | 2.11.1 | Apache-2.0 |
| libwebp (16 KB-aligned rebuild) | 1.5.0, NDK r28.2 | BSD-3-Clause |
| Kotlin / AndroidX / AGP toolchain | per `android/` gradle files | Apache-2.0 |

The full transitive Dart dependency list with licenses is bundled in the app
and shown at Settings > Open Source Licenses (Flutter license registry).

## Update Strategy

- yt-dlp: self-updates from the official stable channel via the in-app
  engine update (automatic on startup, manual in Settings).
- youtubedl-android, Flutter, and Dart packages: pinned versions, updated by
  dependency bumps in this repository.
- Desktop yt-dlp/FFmpeg: user-managed binaries; the app never redistributes
  them and can run `yt-dlp --update` on request.

## Source Availability

- This app: complete corresponding source is this repository; every release
  tag carries GitHub's auto-generated source archives.
- youtubedl-android and its FFmpeg/yt-dlp packaging:
  https://github.com/yausername/youtubedl-android (build scripts in-repo).
- yt-dlp: https://github.com/yt-dlp/yt-dlp
- FFmpeg: https://ffmpeg.org (artifact build recipe in the youtubedl-android
  repository).
- libwebp: https://github.com/webmproject/libwebp (rebuild command below).

## Release Source Bundle Procedure

1. Tag the release commit (`vX.Y.Z[-suffix]`) and push the tag.
2. Publish binaries only on that GitHub release so the auto-generated source
   archive of the same tag accompanies them.
3. Verify `android/key.properties`, keystores, cookies, and other secrets are
   absent from the archive (they are gitignored; spot-check the tag).
4. Release notes must link `THIRD_PARTY_NOTICES.md` and state the GPL-3.0
   source offer.

## Required Before Public Binary Release

- [x] Record exact dependency versions.
- [x] Record exact youtubedl-android version.
- [x] Record exact yt-dlp version (self-updating; record audit-time version).
- [x] Record exact FFmpeg artifact and build flags (runtime-verified; full
      configure flags listed in `ffmpeg -version` output on device).
- [x] Confirm whether FFmpeg build is LGPL or GPL: GPL.
- [x] Include GPL-3.0 license text (repository LICENSE).
- [x] Include source code for this app (GitHub tag archives per release).
- [x] Include or link complete corresponding source for GPL components.
- [x] Include generated Flutter/Dart package notices (Settings > Open Source
      Licenses).
- [x] Confirm no proprietary or incompatible binary dependency is bundled.
- [x] Confirm no signing key, cookie, token, or private test URL is included
      (keystore and key.properties live outside the repository; cookies are
      never committed).

## FFmpeg Notes

FFmpeg's license depends on how it is configured and which external libraries
are enabled. If GPL components are enabled, the FFmpeg build becomes GPL. The
selected Android artifact is currently
`io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1`. Runtime inspection on
2026-08-26 (`ffmpeg -version` on device) shows it bundles FFmpeg 7.1.1 built
with `--enable-gpl --enable-version3` (a Termux-based build), so the Android
FFmpeg build is GPL — compatible with this app's GPL-3.0-only license. The
full configure flags should still be captured verbatim for release notices.
Windows and macOS FFmpeg distribution is not selected yet.

The 0.18.1 FFmpeg artifact ships five libwebp libraries (`libsharpyuv.so`,
`libwebp.so`, `libwebpdecoder.so`, `libwebpdemux.so`, `libwebpmux.so`) built
with 4 KB ELF page alignment, which the Android dynamic linker rejects on
16 KB page-size devices, breaking every FFmpeg invocation there. The app
bundles 16 KB-aligned libwebp 1.5.0 replacement builds in
`android/app/src/main/jniLibs` and overwrites the extracted copies after
`FFmpeg.init` (see `MainActivity.fixFfmpegPageSizeLibs`). Rebuild command per
ABI:

```bash
cmake -G Ninja -S libwebp-1.5.0 -B out/<abi> \
  -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=<abi> -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-z,max-page-size=16384" \
  -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF \
  -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF \
  -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_WEBPMUX=OFF -DWEBP_BUILD_EXTRAS=OFF
cmake --build out/<abi>
llvm-strip --strip-unneeded out/<abi>/*.so
```

Remove the jniLibs overrides once upstream ships 16 KB-aligned libwebp.

## Android Packaging Notes

The current Android Gradle Plugin rejects explicit
`android:extractNativeLibs="true"` in the manifest. Legacy native-library
packaging is configured in `android/app/build.gradle.kts` through
`packaging.jniLibs.useLegacyPackaging = true`. `libpython.zip.so` is excluded
from debug-symbol stripping because it is a zip payload named like a shared
object, not a normal ELF object. The same keep-debug-symbol rule is applied to
`libffmpeg.zip.so`.

Kotlin incremental compilation is disabled in `android/gradle.properties`
(`kotlin.incremental=false`) because it fails on Windows when Flutter plugin
sources in the pub cache and the project build directory are on different
drive roots.

## Store And Provider Policy Notes

Downloader apps can trigger app-store and provider-policy review issues. Before
publishing outside GitHub test releases, review the target store policies and
avoid claims that encourage unauthorized downloading, DRM bypass, or paywall
bypass.
