# Changelog

All notable changes to DBase Video & Music Downloader will be documented in
this file.

The format is based on Keep a Changelog, and this project uses semantic
versioning once releases begin.

## [Unreleased]

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
