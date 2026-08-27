import 'package:dbase_downloader/src/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> release(
  String tag, {
  bool prerelease = false,
  List<String> assets = const [],
}) {
  return {
    'tag_name': tag,
    'prerelease': prerelease,
    'draft': false,
    'html_url': 'https://github.com/x/y/releases/tag/$tag',
    'assets': [
      for (final name in assets)
        {
          'name': name,
          'browser_download_url': 'https://github.com/x/y/releases/download/$tag/$name',
        },
    ],
  };
}

void main() {
  test('compares versions with pre-release ordering', () {
    expect(compareVersions('1.0.1', '1.0.0'), greaterThan(0));
    expect(compareVersions('1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0-rc.2', '1.0.0-rc.1'), greaterThan(0));
    expect(compareVersions('1.0.0', '1.0.0-rc.2'), greaterThan(0));
    expect(compareVersions('1.0.0-rc.2', '1.0.0'), lessThan(0));
    expect(compareVersions('1.0.0-rc.10', '1.0.0-rc.9'), greaterThan(0));
    expect(compareVersions('2.0.0-beta.1', '1.9.9'), greaterThan(0));
    expect(compareVersions('1.0.0+7', '1.0.0+6'), 0);
  });

  test('offers a newer release with the right platform asset', () {
    final update = updateFromReleases(
      [
        release(
          'v1.0.0-rc.2',
          prerelease: true,
          assets: [
            'app-arm64-v8a-release.apk',
            'dbase-downloader-v1.0.0-rc.2-windows-x64.zip',
            'dbase-downloader-v1.0.0-rc.2-linux-x64.tar.gz',
          ],
        ),
        release('v1.0.0-rc.1', prerelease: true),
      ],
      '1.0.0-rc.1',
      platformAssetMarker: 'windows-x64',
    );

    expect(update, isNotNull);
    expect(update!.version, '1.0.0-rc.2');
    expect(update.assetName, 'dbase-downloader-v1.0.0-rc.2-windows-x64.zip');
  });

  test('stable installs are not offered pre-releases', () {
    final update = updateFromReleases(
      [
        release('v1.1.0-rc.1', prerelease: true),
        release('v1.0.0'),
      ],
      '1.0.0',
      platformAssetMarker: 'windows-x64',
    );

    expect(update, isNull);
  });

  test('pre-release installs are offered the newer stable', () {
    final update = updateFromReleases(
      [release('v1.0.0', assets: ['app-arm64-v8a-release.apk'])],
      '1.0.0-rc.2',
      platformAssetMarker: 'arm64-v8a',
    );

    expect(update, isNotNull);
    expect(update!.version, '1.0.0');
    expect(update.assetName, 'app-arm64-v8a-release.apk');
  });

  test('returns null when already up to date', () {
    expect(
      updateFromReleases(
        [release('v1.0.0')],
        '1.0.0',
        platformAssetMarker: 'windows-x64',
      ),
      isNull,
    );
  });
}
