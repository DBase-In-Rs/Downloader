# Release Checklist

Use this checklist before publishing any binary build.

## Source And Version

- [ ] Version and build number are updated.
- [ ] Release commit is tagged.
- [ ] Source code for the exact release is public.
- [ ] Generated or bundled artifacts can be reproduced from source.

## Flutter

- [ ] `flutter pub get` passes.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Platform-specific build passes for each released platform.

## Android

- [ ] `applicationId` is `rs.in.dbase.downloader`.
- [ ] App label is final.
- [ ] Foreground service notification is correct.
- [ ] MediaStore save works for audio and video.
- [ ] Share intent works.
- [ ] Cookie import, use, and delete are tested.
- [ ] Release signing uses ignored/private signing files.

## Windows

- [ ] Windows build launches.
- [ ] yt-dlp and FFmpeg paths or bundled binaries are documented.
- [ ] Output folder selection works.
- [ ] Download cancellation works.

## macOS

- [ ] macOS build launches.
- [ ] Bundle identifier is aligned.
- [ ] File access works under the chosen sandbox/signing setup.
- [ ] yt-dlp and FFmpeg paths or bundled binaries are documented.

## iPhone/iOS

- [ ] iOS scope is explicitly documented.
- [ ] Build is verified on device.
- [ ] Background behavior is tested.
- [ ] File import/export works.
- [ ] Cookie behavior is local-only and removable.
- [ ] Distribution policy risk is reviewed.

## License And Notices

- [ ] GPL-3.0-only license is included.
- [ ] youtubedl-android version and source are documented.
- [ ] yt-dlp version and source are documented.
- [ ] FFmpeg artifact, configure flags, and license state are documented.
- [ ] Flutter/Dart dependency notices are included.
- [ ] No incompatible proprietary binary dependency is bundled.

## Privacy And Security

- [ ] No cookies, tokens, signing keys, private URLs, or account data are in the
      repository.
- [ ] Logs redact cookies and sensitive URL parameters.
- [ ] Temporary files are cleaned up.
- [ ] Imported cookies can be deleted from the app.
- [ ] Privacy policy matches implemented behavior.
- [ ] Security policy matches implemented behavior.

## Release Notes

- [ ] Known limitations are listed.
- [ ] Supported platforms are listed.
- [ ] Build/install instructions are listed.
- [ ] Source availability is linked.
