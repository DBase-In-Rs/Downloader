# Contributing

Thanks for helping with DBase Video & Music Downloader.

## Ground Rules

- Keep the project GPL-3.0-only compatible.
- Do not add closed-source binary dependencies without a license review.
- Do not commit signing keys, account cookies, auth tokens, private URLs, or
  copyrighted media samples.
- Do not add DRM bypass, paywall bypass, or hidden cookie extraction.
- Keep user cookies local, encrypted where possible, explicit, and removable.

## Development Setup

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android integration work requires an Android device or emulator. iOS/macOS work
requires macOS with Xcode. Windows desktop work should be verified on Windows.

## Pull Requests

Before opening a PR:

- run `flutter analyze`;
- run `flutter test`;
- test platform-specific changes on the target OS when possible;
- update `PLAN.md` when a task is completed or changed;
- update `THIRD_PARTY_NOTICES.md` when dependencies change;
- update `PRIVACY.md` when data handling changes.

## Commit Style

Use short, imperative commit messages:

```text
Add share URL intent handling
Implement MediaStore audio save
Document FFmpeg license state
```

## License

By contributing, you agree that your contribution is provided under the project
license, GPL-3.0-only.
