# Changelog

All notable changes to DBase Video & Music Downloader will be documented in
this file.

The format is based on Keep a Changelog, and this project uses semantic
versioning once releases begin.

## [Unreleased]

### Added

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
