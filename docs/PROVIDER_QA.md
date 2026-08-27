# Provider QA

Provider support is yt-dlp-first, but DBase only advertises a provider after it
passes Android and Windows checks.

Keep real smoke-test URLs in `secrets/provider_smoke.json`. The `secrets/`
folder is ignored so private, account-gated, or temporary URLs are not
committed.

Suggested private matrix:

```json
[
  {
    "provider": "dailymotion",
    "url": "https://www.dailymotion.com/video/...",
    "tests": ["metadata", "mp4", "mp3"]
  },
  {
    "provider": "vimeo",
    "url": "https://vimeo.com/...",
    "tests": ["metadata", "mp4", "mp3"]
  },
  {
    "provider": "soundcloud",
    "url": "https://soundcloud.com/artist/track",
    "tests": ["metadata", "m4a", "mp3"]
  }
]
```

Run the Windows/desktop matrix with:

```bash
dart run tool/provider_smoke.dart
```

Pass a custom matrix path when needed:

```bash
dart run tool/provider_smoke.dart path/to/provider_smoke.json
```

## Android Checks

- Paste URL directly.
- Share URL from the provider app or browser.
- Analyze metadata.
- Download MP4 or original where video is available.
- Download MP3 for audio extraction.
- Cancel an active download.
- Background and foreground the app during a download.
- Confirm output appears in the selected SAF folder or default MediaStore
  collection.
- Confirm errors do not leak cookies, tokens, or full signed URLs.

## Windows Checks

- Test with `yt-dlp` and FFmpeg from PATH.
- Test with configured binary paths in Settings.
- Analyze metadata.
- Download MP4 or original where video is available.
- Download MP3/M4A for audio output.
- Cancel an active download.
- Confirm output folder collision handling.
- Confirm errors do not leak cookies, tokens, or full signed URLs.

## Supported Status Rules

- `Verified`: metadata plus at least one download path passed on Android and
  Windows with current yt-dlp.
- `Partial`: one platform works or only metadata works.
- `Experimental`: yt-dlp has an extractor, but DBase has no current smoke
  evidence.
- `Research`: not confirmed in the yt-dlp supported-sites list, or only the
  generic extractor might work.
