# Platform Channels

Status: Android `getInfo` and single-item `startDownload` are wired to
youtubedl-android 0.18.1. Android FFmpeg conversion/remux options, foreground
service startup, cancel, and MediaStore saves are implemented. Manual device QA
is still pending.

## Downloader Method Channel

Name: `rs.in.dbase.downloader/downloader`

### `getInfo`

Request:

```json
{
  "url": "https://example.com/media",
  "useCookies": false
}
```

Response:

```json
{
  "url": "https://example.com/media",
  "title": "Media title",
  "uploader": "example.com",
  "thumbnailUrl": null,
  "durationSeconds": 258,
  "extractor": "youtube",
  "formats": [
    {
      "id": "best_mp4",
      "extension": "mp4",
      "kind": "muxed",
      "qualityLabel": "1080p",
      "width": 1920,
      "height": 1080,
      "audioBitrateKbps": 160,
      "videoBitrateKbps": 4500,
      "filesizeBytes": 148000000,
      "codec": "h264 + aac",
      "note": null
    }
  ]
}
```

### `startDownload`

Request:

```json
{
  "id": "download-id",
  "url": "https://example.com/media",
  "formatId": "best_mp4",
  "outputKind": "mp3",
  "title": "Media title"
}
```

Response: `null` on accepted start.

Android behavior:

- uses yt-dlp with the selected `formatId`;
- writes temporary output under the app cache directory;
- uses `-x --audio-format mp3` for MP3;
- uses `-x --audio-format m4a` for M4A;
- uses `--merge-output-format mp4` for MP4;
- saves completed files through MediaStore on Android 10+;
- falls back to the app external files directory before Android 10;
- deletes temporary files after success, failure, or cancel.

### `cancelDownload`

Request:

```json
{
  "id": "download-id"
}
```

Response: `null` on accepted cancellation.

### `updateEngine`

Updates the bundled yt-dlp engine to the latest stable release. The Android
implementation runs the update on the same single-thread executor as metadata
extraction and downloads, so an update never overlaps a running yt-dlp
process. Called automatically on app startup and manually from Settings.

Response:

```json
{
  "updated": true,
  "version": "2026.08.20"
}
```

`updated` is `false` when the engine was already up to date. Errors are
reported with code `engine_update_failed`.

### `getCookieStatus`

Response:

```json
{
  "configured": false,
  "expired": false,
  "message": null
}
```

### `importCookies`

Request:

```json
{
  "content": "# Netscape HTTP Cookie File\n.youtube.com\tTRUE\t/\tTRUE\t1799999999\tSID\tvalue\n"
}
```

Response: `null` on success. Errors: `invalid_cookie_file`,
`cookie_import_failed`.

Android behavior:

- content is validated in Dart (Netscape format) before the channel call;
- content is encrypted with an Android Keystore AES/GCM key and stored in the
  app's no-backup directory;
- when cookies are configured, yt-dlp requests receive a short-lived decrypted
  copy through `--cookies`; the plain file is deleted after the process
  finishes and is kept outside the download working directory so it can never
  be picked up as a download output;
- `getInfo` attaches cookies only when the request sets `useCookies`;
  downloads attach cookies whenever they are configured;
- cookie values are never logged; error output is redacted.

### `clearCookies`

Response: `null`. Deletes the encrypted cookie store.

## Downloader Event Channel

Name: `rs.in.dbase.downloader/events`

### Progress

```json
{
  "type": "progress",
  "id": "download-id",
  "stage": "Downloading",
  "percent": 0.5,
  "downloadedBytes": 26000000,
  "totalBytes": 52000000,
  "speedBytesPerSecond": 3100000,
  "etaSeconds": 10
}
```

### Completed

```json
{
  "type": "completed",
  "id": "download-id",
  "outputLocation": "content://media/external/audio/media/123"
}
```

`outputLocation` is a MediaStore content URI on Android 10+ and a local app
external-files path on older Android versions.

### Failed

```json
{
  "type": "failed",
  "id": "download-id",
  "message": "Download failed."
}
```

### Canceled

```json
{
  "type": "canceled",
  "id": "download-id"
}
```

## Share Method Channel

Name: `rs.in.dbase.downloader/share`

### `getInitialSharedText`

Response: shared text from the launch intent, or `null`.

The Android implementation consumes the initial value after returning it once.

## Share Event Channel

Name: `rs.in.dbase.downloader/share_events`

Payload: shared text string from a later `ACTION_SEND` intent while the app is
already running.

## Compatibility Rules

- Add fields rather than changing existing field meanings.
- Keep every payload JSON-serializable.
- Redact cookies, auth headers, and sensitive URL query parameters before
  emitting logs or error messages.
- Preserve these channel names unless a migration layer is added.
