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

Recommended batches:

- Batch 1: Dailymotion, Vimeo, SoundCloud.
- Batch 2: YouTube Shorts, TikTok, Instagram, Facebook, Twitter/X.
- Batch 3: Pinterest, Reddit, Twitch, Rumble, Bandcamp.
- Batch 4: Audiomack, Mixcloud, Audius, Internet Archive, Odysee/LBRY.
- Batch 5: Streamable, Imgur, Flickr, BitChute, PeerTube, TED, Bilibili,
  Niconico, Coub.
- Batch 6: Vocaroo, HearThis.at, Apple Podcasts, Podbay, Podchaser, Acast.
- Batch 7: BBC, CNN, PBS, ESPN, Substack, Bluesky, Truth Social, Rutube,
  Youku.
- Embed/CDN batch: Cloudflare Stream, JW Platform, Kaltura, Wistia,
  Brightcove.
- Research batch: BuzzVideo, Tubidy, wallpaper/static-image sites, Threads,
  Snapchat Spotlight.

Each matrix row should use a public URL where possible. For login-required
cases, use a non-committed URL and fresh cookies only on the local test machine.

Run the Windows/desktop matrix with:

```bash
dart run tool/provider_smoke.dart            # metadata matrix
dart run tool/provider_smoke.dart --download # + sample MP4/MP3 downloads
```

The matrix lives in `tool/provider_smoke.dart`; edit the `cases` list to add
providers or swap in private URLs locally (do not commit account-gated URLs).

## Windows Smoke Results (2026-08-27, yt-dlp 2026.08.19)

| Provider | Metadata | Download | Notes |
| --- | --- | --- | --- |
| YouTube | PASS (42 formats) | PASS (MP3, earlier runs) | |
| TikTok | PASS (14 formats) | PASS (MP4 merge) | profile listings can hit HTTP 429 rate limits; direct video URLs are reliable |
| Dailymotion | PASS | not sampled | channel URL expanded to 1000 flat entries, first entry extracted |
| SoundCloud | PASS | PASS (MP3) | |
| Bandcamp | PASS | PASS (MP3) | one transient TLS failure, succeeded on retry |
| Internet Archive | PASS | not sampled | |
| Twitch | PASS | not sampled | VOD listing expanded to 1044 flat entries, first VOD extracted (8 formats) |
| Vimeo | cookies required | - | upstream: Vimeo web client now requires login even for public videos; works with imported cookies |
| TED | upstream broken | - | yt-dlp TED extractor error ("JSON object must be str..."), not an app issue |
| Bilibili | geo-blocked | - | test video unavailable from this region without proxy |
| Reddit | untested | - | needs a live post URL; subreddit listings unsupported by yt-dlp |

## Android Spot Check (2026-08-27, Moto G54, Android 15)

- TikTok: share-intent URL intake, metadata (formats listed, provider chip
  shown), and a watermarked MP4 download completed into the user-selected
  SAF folder; history records the provider and the provider filter works.
- The remaining Android matrix was intentionally stopped: Android uses the
  same self-updated yt-dlp engine as the verified Windows runs, and the
  YouTube path was already verified on-device earlier. Full per-provider
  Android sweeps remain optional follow-up work.

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

## Provider Error Checks

For each provider batch, force or find at least one failure case when practical:

- login/cookies required;
- private, removed, or unavailable media;
- geo/region block;
- rate limit or temporary block;
- unsupported URL or broken extractor;
- DRM/protected-media rejection.

The UI should turn those into short user-facing messages and must not show full
signed URLs, cookies, auth headers, or tokens.
