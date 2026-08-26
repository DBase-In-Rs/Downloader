# Third-Party Notices And License Checklist

Status: Draft. This file must be updated before every public binary release.

## Project License

DBase Video & Music Downloader is intended to be distributed under
GPL-3.0-only.

## References

- youtubedl-android: https://github.com/yausername/youtubedl-android
- FFmpeg legal notes: https://www.ffmpeg.org/legal.html
- FFmpeg license notes: https://ffmpeg.org/doxygen/8.0/md_LICENSE.html
- GPL-3.0 text: https://www.gnu.org/licenses/gpl-3.0.txt

## Planned Components

| Component | Purpose | License state | Release action |
| --- | --- | --- | --- |
| Flutter | UI framework | Flutter/Dart ecosystem licenses | Include generated notices and dependency license list. |
| Android Gradle Plugin / Kotlin | Android build and native integration | Tooling licenses vary | Document build tool versions. |
| youtubedl-android | Android wrapper for yt-dlp/youtube-dl style execution | GPL-3.0 | Keep app GPL-compatible and publish complete source. |
| yt-dlp | Media extraction backend used by youtubedl-android or desktop process runner | Verify exact bundled/upstream license/version | Document exact version and source. |
| FFmpeg | Conversion/remuxing | LGPL or GPL depending on build flags and linked libraries | Document artifact, configure flags, source offer, and license. |
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
selected Android, Windows, and macOS FFmpeg distribution must be reviewed and
documented before release.

## Store And Provider Policy Notes

Downloader apps can trigger app-store and provider-policy review issues. Before
publishing outside GitHub test releases, review the target store policies and
avoid claims that encourage unauthorized downloading, DRM bypass, or paywall
bypass.
