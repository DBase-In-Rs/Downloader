# Changelog

All notable changes to DBase Video & Music Downloader will be documented in
this file.

The format is based on Keep a Changelog, and this project uses semantic
versioning once releases begin.

## [Unreleased]

### Fixed

- F-Droid builds sat on the splash screen forever: the splash waited for a
  startup engine check that those builds intentionally never start. The
  splash now only waits when the startup update actually runs.

### Changed

- Android release builds now run R8 with keep-everything rules that only
  drop Flutter's unused Play Store deferred-components support (its Play
  Core references trip the F-Droid binary scanner) and exclude Google
  Play's dependency-metadata signing block; youtubedl-android and Jackson
  reflection behavior is unaffected because nothing else is shrunk,
  optimized, or obfuscated.
- Pub dependencies upgraded within existing constraints (12 packages).

### Added

- F-Droid groundwork: fastlane store metadata under
  `fastlane/metadata/android/en-US/` (title, descriptions, icon, per-version
  changelogs), an `FDROID_BUILD` dart-define that compiles out the GitHub
  update check and the automatic yt-dlp startup update in F-Droid builds,
  and a draft fdroiddata recipe with submission guide in `docs/fdroid/`.

## [1.0.1] - 2026-08-27

### Changed

- App colors now match the logo: the theme seed and app bar use the logo's
  royal blue and the Support accents use the logo's red, replacing the old
  teal palette.
- Settings reordered: engine update, download folder, cookies, support,
  engine check, licenses, and the version card last.
- The app-bar cookie status now uses a real white cookie icon instead of the
  dark key icon that clashed with the blue app bar.
- README refreshed (supporter badges, emoji section headers matching the
  maintainer's other repositories, Engine Check, install commands) and a
  GitHub Sponsor button added via .github/FUNDING.yml with Polar checkouts,
  Ko-fi, and PayPal.

### Removed

- The Supported Websites card and dialog in Settings; the upstream yt-dlp
  site list stays linked from the README.

### Added

- Engine Check card in desktop Settings: detects whether yt-dlp and FFmpeg
  are runnable (configured paths or PATH) and, when missing, shows how to
  install them - the winget command on Windows, the distro's package-manager
  command (apt/dnf/pacman/zypper from /etc/os-release) or the software
  center on Linux, plus official download links. Android needs none of this
  since both tools ship with the app.
- Support the developer through Polar (merchant of record): a Support card
  in Settings opens the Supporter or Supporter Pro checkout in the browser.
  The app never tracks purchases - no license keys, no validation, and no
  network calls.

## [1.0.0] - 2026-08-27

First stable release: download video and music from any yt-dlp-supported
site on Android, Windows, and Linux.

### Added

- New app icon (bold D mark) readable in the Android launcher, with a
  matching white launch/splash screen.
- In-app update notifications: the app checks GitHub Releases on startup
  and Settings offers the right download for the platform; stable installs
  are only offered stable releases.
- About card in Settings with the app version and build number.
- In-app cookies.txt export guide with Chrome Web Store and Firefox Add-ons
  links for the "Get cookies.txt LOCALLY" extension.
- Windows installer (Inno Setup): per-user install without an admin prompt,
  Start Menu entry, optional desktop icon, uninstaller, silent flags.
- Debian package, published automatically to the apt repository at
  https://peace.dbase.in.rs (install once, update via `apt upgrade`).
- Dependabot (pub, Gradle, GitHub Actions), Dependabot alerts and security
  updates, secret scanning with push protection, private vulnerability
  reporting, and CodeQL code scanning.

### Changed

- Documentation consolidated: the channel schema lives in AGENTS.md, the
  provider QA results in PLAN.md, and the privacy statement in the README.
- Upgraded transitive and Android build dependencies (Jackson 2.22,
  Gradle 9.7.1, AGP 9.3.2, Kotlin 2.4.10, GitHub Actions majors).

### Fixed

- apt package indexes now use relative paths, so installs work from any
  client.
- CI workflow token limited to read-only contents (CodeQL finding).

## [1.0.0-rc.1] - 2026-08-27

Release candidate for 1.0.0: Android, Windows, and Linux.

### Added

- Clear button on the Home screen to reset the URL, results, and errors
  after a download is queued.
- History items are now actionable: tap to open the finished file with the
  default app, plus a menu with Open, Show in folder (desktop), and Share
  (Android).
- Automated release builds: pushing a `v*` tag builds signed Android APKs
  (all ABIs), the Windows zip, and a Linux tarball on GitHub Actions and
  attaches them to the release; a manual run from the Actions tab produces
  the same artifacts without publishing.
- Linux desktop support, verified on WSL Ubuntu 24.04: release build, GUI
  launch, and an end-to-end YouTube MP3 download through the shared desktop
  backend.
- Dynamic provider identity for every yt-dlp-supported site (~1750
  extractors): sites outside the curated catalog are now named after their
  yt-dlp extractor (or the URL host) instead of "Generic URL", and group
  correctly in the history provider filter.
- 36 more recognized providers, all verified against the live yt-dlp
  extractor list: OK.ru, Boosty, Dzen, Newgrounds, Nebula, Floatplane, Vevo,
  Daily Wire, Mave, RTV Slovenija, HRTi, RaiPlay, ARD Mediathek, Česká
  televize, RTVE, SVT Play, NRK, TVP, MédiaKlikk, Puhutv, France TV,
  ABC/CBS/Fox/NBC News, GameSpot, IGN, Libsyn, NHL, Picarto, Rooster Teeth,
  Dumpert, Steam, Vidyard, Sky News Australia, and BanBye.

### Removed

- Non-media catalog entries, per the audio/video-only scope: the
  wallpaper/static-image research entry and article/lyrics extractor
  aliases.

### Fixed

- Silent videos from Facebook, Instagram, YouTube, and other DASH sites:
  picking a video-only format now merges the best audio stream via FFmpeg;
  a video-only pick with an MP3/M4A output uses the best audio stream.

## [1.0.0-beta.4] - 2026-08-27

### Added

- Playlist fallback for every provider: when single-item analysis fails on a
  URL without playlist markers (albums, channels, profiles), the app retries
  playlist extraction before reporting an error.
- Provider smoke matrix tool (`tool/provider_smoke.dart`) and recorded
  Windows results for YouTube, TikTok, Dailymotion, SoundCloud, Bandcamp,
  Internet Archive, and Twitch in `docs/PROVIDER_QA.md`.
- 18 more recognized providers verified against the live yt-dlp extractor
  list: Kick, N1 Info, Google Drive, Dropbox, Telegram, Patreon, 9GAG, Loom,
  Zoom, Douyin, Weibo, RedGifs, Jamendo, iHeartRadio, Spreaker, MLB,
  Al Jazeera, and ARTE.

### Added

- Multi-site provider catalog for Dailymotion, Vimeo, SoundCloud, TikTok,
  Instagram, Facebook, Twitter/X, Pinterest, Reddit, Twitch, Rumble, and
  many secondary yt-dlp providers.
- Detected-provider labels in Home, Queue, and History, plus provider filtering
  in History.
- Supported Websites dialog in Settings, grouped by provider status.
- Shared/pasted provider URL cleanup for common tracking parameters.
- Provider-aware error messages for login-required, private, geo-blocked,
  rate-limited, unsupported, and DRM/protected media failures.
- Full upstream yt-dlp extractor list mirrored in
  `docs/SUPPORTED_WEBSITES.md`.
- Provider QA notes and a private-matrix desktop smoke tool
  (`tool/provider_smoke.dart`).

### Fixed

- Added spacing between the Settings license action and the cookies section.

## [1.0.0-beta.3] - 2026-08-26

### Added

- App branding: new launcher icon on Android (adaptive) and Windows, a dark
  branded native launch screen, and an in-app splash with the logo and a
  progress indicator while the yt-dlp engine updates on startup.
- Open Source Licenses screen in Settings (Flutter license registry).
- Release compliance audit: recorded dependency versions and licenses,
  update strategy, source availability, and source bundle procedure in
  THIRD_PARTY_NOTICES.md.
- Project badges in the README.

### Fixed

- Expired-cookie detection now works for URL analysis: `--no-warnings`
  suppressed the cookie-validity warnings the detector matches against.

- Safe cookie import: `cookies.txt` through the system file picker, Netscape
  format validation, Android Keystore AES/GCM encryption at rest, short-lived
  decrypted copies for yt-dlp requests, and a clear-cookies action.
- Playlist support: flat playlist extraction, item selection with select
  all/none, output presets, queue expansion, and independent per-item
  failures.
- Persistent download history with finish timestamps, search, per-item
  delete, and clear-all, restored across app restarts.
- Desktop (Windows-first) media backend running local yt-dlp and FFmpeg
  processes: metadata, playlists, downloads with progress, cancel, collision
  handling, engine self-update, and Settings for binary paths and output
  folder.
- Android download folder selection through the system folder picker (SAF),
  with fallback to the default MediaStore collections.
- Crash-safe cleanup of stale temporary download files on Android startup.
- Expired-cookie detection: auth failures from cookie-backed requests flag
  the store as expired with a re-import hint in Settings.
- Desktop cookie support: cookies.txt import, use, expiry detection, and
  delete on Windows/desktop.
- Release builds are signed with a private release keystore
  (android/key.properties, kept outside the repository).

### Changed

- macOS and iOS are declared out of scope; the app ships for Android and
  Windows (see PLAN.md).
- Assisted WebView login investigation concluded as no-ship; cookies.txt
  import remains the supported path.

## [1.0.0-beta.1] - 2026-08-26

First public pre-release: Android-only beta with single-item downloads,
MP3/M4A/MP4 output, a sequential queue, and yt-dlp engine self-update.
Release builds are signed with debug keys for this beta.

### Added

- Initial project documentation.
- Cross-platform roadmap for Android, Windows, macOS, and iPhone/iOS.
- GPL-3.0-only license baseline.
- GitHub community files and issue templates.
- Flutter app shell with Home, Queue, History, and Settings sections.
- Typed Dart media/download/cookie models and backend contracts.
- Fake media backend for UI development and tests.
- Android MethodChannel and EventChannel bridge.
- Android shared text intake from `ACTION_SEND`.
- Platform channel schema documentation.
- youtubedl-android 0.18.1 dependency for Android metadata extraction.
- Android `getInfo` bridge that maps `VideoInfo` and `VideoFormat` into the
  shared Dart schema.
- Android yt-dlp download worker with native progress, cancel support, and temp
  directory cleanup.
- Android foreground service for active downloads.
- Android FFmpeg artifact integration for MP3/M4A extraction and MP4 merge.
- Android MediaStore save path for completed audio and video files.
- Jackson Databind dependency for app-side parsing of yt-dlp JSON metadata.
- Sequential download queue with paused state, pause/resume controls, and
  retry for failed or canceled items.
- Queue persistence across app restarts through `shared_preferences`.
- yt-dlp engine self-update: automatic check on app startup and a manual
  update action in Settings, fixing YouTube HTTP 403 failures caused by a
  stale bundled yt-dlp.

### Changed

- Native error messages now surface only yt-dlp `ERROR:` lines instead of the
  full output with warnings.
- Download queue ids include a session-local sequence so rapid enqueues can
  no longer collide on the same clock tick.

### Fixed

- FFmpeg postprocessing ("ffprobe and ffmpeg not found") on 16 KB page-size
  Android devices: the FFmpeg artifact ships 4 KB-aligned libwebp libraries
  that the dynamic linker rejects, so the app now bundles 16 KB-aligned
  libwebp 1.5.0 builds and overwrites the extracted copies after FFmpeg
  initialization.
