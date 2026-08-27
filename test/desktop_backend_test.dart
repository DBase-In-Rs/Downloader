import 'dart:io';

import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/services/desktop_media_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop cookie store round-trips with expired marker', () async {
    final dir = await Directory.systemTemp.createTemp('dbase-cookie-test');
    addTearDown(() => dir.delete(recursive: true));
    final backend = DesktopMediaBackend(
      configProvider: () async => const DesktopBackendConfig(),
      configDir: dir.path,
    );
    addTearDown(backend.dispose);

    expect((await backend.getCookieStatus()).configured, isFalse);

    await backend.importCookies('.a.com\tTRUE\t/\tTRUE\t1\tSID\tv\n');
    var status = await backend.getCookieStatus();
    expect(status.configured, isTrue);
    expect(status.expired, isFalse);

    backend.markCookiesExpiredIfAuthError(
      'ERROR: Sign in to confirm you are not a bot',
    );
    status = await backend.getCookieStatus();
    expect(status.expired, isTrue);

    // Re-import resets the expired flag.
    await backend.importCookies('.a.com\tTRUE\t/\tTRUE\t1\tSID\tv2\n');
    expect((await backend.getCookieStatus()).expired, isFalse);

    await backend.clearCookies();
    expect((await backend.getCookieStatus()).configured, isFalse);
  });

  test('maps yt-dlp media JSON into MediaInfo', () {
    final info = mediaInfoFromYtDlpJson({
      'webpage_url': 'https://example.com/watch?v=1',
      'fulltitle': 'Full title',
      'uploader': 'Uploader',
      'thumbnail': 'https://example.com/thumb.jpg',
      'duration': 196,
      'extractor_key': 'Youtube',
      'formats': [
        {
          'format_id': '251',
          'ext': 'webm',
          'vcodec': 'none',
          'acodec': 'opus',
          'abr': 128,
          'filesize': 3400000,
          'format_note': 'medium',
        },
        {
          'format_id': '137',
          'ext': 'mp4',
          'vcodec': 'avc1.640028',
          'acodec': 'none',
          'height': 1080,
          'width': 1920,
          'tbr': 4200,
          'filesize_approx': 148000000,
        },
        {'ext': 'mp4'},
      ],
    }, 'https://fallback.example');

    expect(info.title, 'Full title');
    expect(info.duration, const Duration(seconds: 196));
    expect(info.formats, hasLength(2));
    expect(info.formats[0].kind, MediaKind.audio);
    expect(info.formats[0].qualityLabel, 'medium');
    expect(info.formats[1].kind, MediaKind.video);
    expect(info.formats[1].qualityLabel, '1080p');
    expect(info.formats[1].filesizeBytes, 148000000);
  });

  test('maps flat playlist JSON and resolves YouTube ids', () {
    final playlist = playlistInfoFromYtDlpJson({
      'title': 'My playlist',
      'entries': [
        {'url': 'https://example.com/1', 'title': 'One', 'duration': 60},
        {'id': 'abc123', 'ie_key': 'Youtube', 'title': 'Two'},
        {'title': 'No URL entry'},
      ],
    }, 'https://example.com/playlist');

    expect(playlist.title, 'My playlist');
    expect(playlist.entries, hasLength(2));
    expect(playlist.entries[1].url, 'https://www.youtube.com/watch?v=abc123');
  });

  test('parses yt-dlp progress lines', () {
    final progress = parseYtDlpProgressLine(
      'id',
      '[download]  45.3% of   10.00MiB at    1.20MiB/s ETA 00:05',
    );

    expect(progress, isNotNull);
    expect(progress!.stage, 'Downloading');
    expect(progress.percent, closeTo(0.453, 0.0001));
    expect(progress.totalBytes, 10 * 1024 * 1024);
    expect(progress.speedBytesPerSecond, (1.2 * 1024 * 1024).round());
    expect(progress.eta, const Duration(seconds: 5));

    final converting = parseYtDlpProgressLine(
      'id',
      '[ExtractAudio] Destination: out.mp3',
    );
    expect(converting?.stage, 'Converting');

    expect(parseYtDlpProgressLine('id', 'random noise'), isNull);
  });

  test('sanitizes process errors and keeps only ERROR lines', () {
    final sanitized = sanitizeProcessError(
      'WARNING: something old\n'
      'ERROR: unable to download https://example.com/secret?token=abc123\n',
    );

    expect(sanitized, contains('ERROR: unable to download'));
    expect(sanitized, isNot(contains('WARNING')));
    expect(sanitized, isNot(contains('example.com')));
    expect(sanitized, isNot(contains('abc123')));
  });
}
