# Publishing to F-Droid

The app code stays on GitHub; F-Droid clones the public repository and
builds every release from source on its own servers. Only the packaging
metadata lives on GitLab, in the
[fdroiddata](https://gitlab.com/fdroid/fdroiddata) repository.

## What is already in place

- **GPL-3.0-only license**, no proprietary SDKs, no trackers.
- **`fastlane/metadata/android/en-US/`** — F-Droid reads the store listing
  (title, descriptions, icon, per-versionCode changelogs) from there on every
  build. New releases only need a `changelogs/<versionCode>.txt` entry.
- **`FDROID_BUILD` dart-define** (`lib/src/build_flags.dart`) — building with
  `--dart-define=FDROID_BUILD=true` compiles out the GitHub release check and
  the automatic yt-dlp update on startup, as the inclusion policy requires.
  The manual engine update in Settings stays and is declared as a
  `NonFreeNet` anti-feature (the same arrangement Seal uses).
- **`docs/fdroid/rs.in.dbase.downloader.yml`** — copy of the fdroiddata
  recipe (flutter srclib checked out to the version pinned in
  .github/workflows/flutter.yml, one per-ABI build block each, tag-based
  auto updates). Version codes follow F-Droid's ABI split scheme:
  pubspec build number * 10 + ABI code (armeabi-v7a=1, arm64-v8a=2,
  x86_64=3).

## Submitting (one-time, needs a gitlab.com account)

1. Fork <https://gitlab.com/fdroid/fdroiddata>.
2. Copy `docs/fdroid/rs.in.dbase.downloader.yml` to
   `metadata/rs.in.dbase.downloader.yml` in the fork.
3. Optionally validate locally with the
   [fdroidserver tools](https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/):
   `fdroid readmeta && fdroid checkupdates rs.in.dbase.downloader && fdroid build rs.in.dbase.downloader`.
4. Open a merge request titled `New app: DBase Downloader` and fill in the
   MR template checklist. Review typically takes a few weeks; reviewers often
   tweak the recipe (e.g. split per-ABI builds) in the MR itself.

Once merged, new `v*` tags are picked up automatically
(`AutoUpdateMode: Version` + `UpdateCheckMode: Tags`); no further action is
needed per release beyond the fastlane changelog file.

## Release checklist additions

- Add `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`
  before tagging for every split APK versionCode (pubspec build number * 10
  + ABI code).
- Do not reuse or move tags: F-Droid builds the exact commit a tag points
  to and stores its hash.

## Known review topics

- `youtubedl-android` ships prebuilt Python/FFmpeg blobs inside its AAR.
  Precedent: Seal (`com.junkfood.seal`) uses the same library and is in the
  official repo.
- Screenshots are optional but improve the listing: add PNGs under
  `fastlane/metadata/android/en-US/images/phoneScreenshots/`.
