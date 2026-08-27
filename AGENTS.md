# AGENTS.md

## Project Identity

Project name: DBase Video & Music Downloader

Canonical app/package id: `rs.in.dbase.downloader`

Primary implementation language: Dart/Flutter UI with native platform
backends.

Shipping targets: Android, Windows, and Linux. macOS and iPhone/iOS are out
of scope until a macOS development machine is available (see PLAN.md).

License: `GPL-3.0-only`

## What The App Does

DBase Video & Music Downloader accepts media URLs, reads available formats,
downloads video or audio through yt-dlp, optionally converts audio to MP3
with FFmpeg, shows live progress, and saves finished files through the
platform's normal storage mechanisms.

Core user flows: paste/type/share a URL; provider detection and tracking-
parameter cleanup; metadata and format inspection; MP3/M4A/MP4/original
output; single items and playlists; sequential queue with pause/retry;
progress with speed/ETA/stage; persistent history with open/share actions;
optional encrypted cookies for login-required media; self-updating yt-dlp
engine; in-app update notifications.

## Platform Strategy

Keep one shared Flutter UI and isolate platform behavior behind the shared
Dart `MediaBackend` contract (`lib/src/services/media_backend.dart`).

- Android: Kotlin Platform Channels; youtubedl-android with self-updated
  yt-dlp; GPL FFmpeg artifact; foreground service; share intent; MediaStore
  or a user-selected SAF folder; Keystore-encrypted cookies. 16 KB page-size
  devices need the bundled realigned libwebp libraries (see
  THIRD_PARTY_NOTICES.md).
- Windows and Linux: `DesktopMediaBackend` runs user-provided yt-dlp/FFmpeg
  binaries (PATH or Settings paths); output to Downloads or a chosen folder;
  cookies in the per-user app-data directory.

## Android Channel Schema

MethodChannel `rs.in.dbase.downloader/downloader`. Payloads are
JSON-serializable maps; add fields, never repurpose existing ones. Update
this section whenever a method, event, or payload field changes.

- `getInfo {url, useCookies}` -> media map: `url, title, uploader,
  thumbnailUrl, durationSeconds, extractor, formats[]` where each format is
  `{id, extension, kind: muxed|video|audio|unknown, qualityLabel, width,
  height, audioBitrateKbps, videoBitrateKbps, filesizeBytes, codec, note}`.
  Runs yt-dlp `--dump-json` with a 60 s timeout; attaches cookies only when
  `useCookies` is true. Errors: `invalid_url`, `metadata_failed`.
- `getPlaylistInfo {url, useCookies}` -> `{url, title, entries[]}` with
  entries `{url, title, durationSeconds, uploader}`. Flat playlist, 120 s
  timeout; entries without a resolvable URL are dropped; flat YouTube ids
  become watch URLs.
- `startDownload {id, url, formatId, outputKind, title}` -> null. yt-dlp in
  a per-download cache dir; `-x --audio-format mp3|m4a` for audio,
  `--merge-output-format mp4` for MP4; cookies attached whenever configured
  (the plain cookie copy lives OUTSIDE the working dir so it can never be
  picked up as output); saves into the selected SAF tree, else MediaStore
  (Android 10+), else app external files; temp files always cleaned.
- `cancelDownload {id}` -> null; destroys the yt-dlp process by id.
- `updateEngine` -> `{updated, version}`. Updates yt-dlp to latest stable on
  the same single-thread executor as downloads (never overlaps). Errors:
  `engine_update_failed`.
- `getCookieStatus` -> `{configured, expired, message}`.
- `importCookies {content}` -> null. Content is validated in Dart (Netscape
  format) and stored AES/GCM-encrypted (Keystore) in the no-backup dir;
  auth-failure markers in later yt-dlp errors set the expired flag. Errors:
  `invalid_cookie_file`, `cookie_import_failed`.
- `clearCookies` -> null; deletes the encrypted store.
- `openOutput {location}` / `shareOutput {location}` -> null. ACTION_VIEW /
  ACTION_SEND for `content://` URIs only. Errors: `invalid_location`,
  `open_failed`, `share_failed`.
- `pickOutputFolder` -> folder label or null (ACTION_OPEN_DOCUMENT_TREE with
  persisted write permission); `getOutputFolder` -> label or null (revoked
  permissions are cleared); `clearOutputFolder` -> null.

EventChannel `rs.in.dbase.downloader/events`, all events carry `type` + `id`:

- `progress`: `stage, percent (0..1), downloadedBytes, totalBytes,
  speedBytesPerSecond, etaSeconds, message (redacted)`.
- `completed`: `outputLocation` (SAF/MediaStore URI, or a file path on older
  Android).
- `failed`: `message` (only yt-dlp ERROR lines, redacted).
- `canceled`.

Share intake: MethodChannel `rs.in.dbase.downloader/share` with
`getInitialSharedText` (consumed once) and EventChannel
`rs.in.dbase.downloader/share_events` for ACTION_SEND text while running.

Never pass direct media URLs, HTTP headers, cookies, or raw extractor output
through the UI channel; redact cookies/tokens/URLs in every log and error.

## Provider Rules

Provider support is yt-dlp-first: `lib/src/models/media_providers.dart`
holds the curated catalog (names, tiers, audio defaults, cookie hints), and
every uncataloged site gets a dynamic identity from its extractor or host.
Only audio/video sites belong in the catalog. Do not advertise a provider as
verified until smoke tests pass; results and procedure live in PLAN.md
(provider QA section). The upstream extractor list is at
https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md - never
mirror it into the repository.

## Platform Identity

Keep `rs.in.dbase.downloader` aligned across: Android namespace,
applicationId, and Kotlin package path (Kotlin needs `rs.`in`.dbase`
escaping); the Linux CMake APPLICATION_ID; Windows app identity when
packaging changes. The Dart package name stays `dbase_downloader`.

## Cookie Handling Rules

Cookies are sensitive credentials.

- Import only through explicit user action (`cookies.txt` via the system
  picker); the app ships a step-by-step export guide.
- Store encrypted where the platform supports it; per-user app data
  elsewhere; always deletable from Settings.
- Pass cookies only to yt-dlp requests; never log or upload them.
- In-app/WebView login capture was investigated and rejected (providers
  block embedded logins); do not reintroduce it without a policy review.
- Never read browser or other-app cookies.

## Legal And Compliance Rules

GPL-3.0-only because youtubedl-android and the FFmpeg artifact are GPL. For
every public binary release: complete corresponding source stays available
(GitHub tag archives), exact dependency versions and licenses are recorded
in THIRD_PARTY_NOTICES.md, and nothing advertises unauthorized downloading
or DRM bypass. This repository must never contain signing keys, account
cookies, tokens, private test links, proprietary media samples, or private
server infrastructure details.

## Quality Bar

Before finishing code changes run `flutter analyze` and `flutter test`.
Builds are made only when all code for the task is written (per maintainer
workflow), and releases are produced exclusively by CI from version tags.
Do not claim a platform or provider works without verification on that
platform; native-path changes need at least one real end-to-end check
before a stable release.

## Documentation Rules

Keep these updated as implementation decisions become real:

- `README.md` - user-facing overview, install instructions, features;
- `PLAN.md` - roadmap, sprint status, provider QA results;
- `AGENTS.md` (this file) - architecture rules and the channel schema;
- `CHANGELOG.md` - keep-a-changelog format, cut a section per release;
- `THIRD_PARTY_NOTICES.md` - dependency and license state;
- `SECURITY.md` - vulnerability reporting; the privacy statement lives in
  the README.
