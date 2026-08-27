// Provider smoke matrix against real public URLs through the desktop
// backend, mirroring the app's analyze flow (single item with playlist
// fallback). Uses yt-dlp/ffmpeg from PATH.
//
//   dart run tool/provider_smoke.dart            # metadata matrix
//   dart run tool/provider_smoke.dart --download # + sample downloads
import 'dart:io';

import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/services/desktop_media_backend.dart';
import 'package:dbase_downloader/src/services/media_backend.dart';

class SmokeCase {
  const SmokeCase(this.provider, this.url, {this.viaPlaylist = false});

  final String provider;
  final String url;

  /// Listing URLs (profiles/channels) resolve the first playlist entry and
  /// then analyze that entry, mirroring the app's playlist flow.
  final bool viaPlaylist;
}

const cases = [
  SmokeCase('youtube', 'https://youtu.be/lvtFXtQ19BU'),
  SmokeCase(
    'tiktok',
    'https://www.tiktok.com/@tiktok/video/7106594312292453675',
  ),
  SmokeCase(
    'dailymotion',
    'https://www.dailymotion.com/france24',
    viaPlaylist: true,
  ),
  // Vimeo currently requires account cookies even for public videos; this
  // records the cookie-needed behavior rather than a green pass.
  SmokeCase('vimeo', 'https://vimeo.com/76979871'),
  SmokeCase('soundcloud', 'https://soundcloud.com/forss/flickermood'),
  SmokeCase('bandcamp', 'https://c418.bandcamp.com/track/sweden'),
  SmokeCase(
    'ted',
    'https://www.ted.com/talks/ken_robinson_do_schools_kill_creativity',
  ),
  SmokeCase('internet_archive', 'https://archive.org/details/BigBuckBunny_124'),
  SmokeCase('bilibili', 'https://www.bilibili.com/video/BV1GJ411x7h7'),
  SmokeCase(
    'twitch',
    'https://www.twitch.tv/twitch/videos?filter=archives',
    viaPlaylist: true,
  ),
];

Future<void> main(List<String> args) async {
  final withDownload = args.contains('--download');
  final backend = DesktopMediaBackend(
    configProvider: () async => const DesktopBackendConfig(),
    configDir: Directory.systemTemp.createTempSync('smoke-config').path,
  );

  final results = <String, String>{};
  for (final smokeCase in cases) {
    stdout.writeln('== ${smokeCase.provider}: ${smokeCase.url}');
    try {
      var target = smokeCase.url;
      if (smokeCase.viaPlaylist) {
        final playlist = await backend.getPlaylistInfo(
          MediaInfoRequest(url: target),
        );
        if (playlist.entries.isEmpty) {
          throw Exception('playlist returned no entries');
        }
        stdout.writeln(
          '   playlist "${playlist.title}" -> ${playlist.entries.length} '
          'entries, first: ${playlist.entries.first.url}',
        );
        target = playlist.entries.first.url;
      }

      MediaInfo info;
      try {
        info = await backend.getInfo(MediaInfoRequest(url: target));
      } catch (error) {
        // Mirror the app's playlist fallback for album/profile URLs.
        final playlist = await backend.getPlaylistInfo(
          MediaInfoRequest(url: target),
        );
        if (playlist.entries.isEmpty) {
          rethrow;
        }
        target = playlist.entries.first.url;
        info = await backend.getInfo(MediaInfoRequest(url: target));
      }

      results[smokeCase.provider] =
          'PASS - "${info.title}" (${info.formats.length} formats, '
          'extractor: ${info.extractor})';
      stdout.writeln('   ${results[smokeCase.provider]}');
    } catch (error) {
      final message = error
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      results[smokeCase.provider] =
          'FAIL - ${message.substring(0, message.length > 220 ? 220 : message.length)}';
      stdout.writeln('   ${results[smokeCase.provider]}');
    }
  }

  stdout.writeln('\n== SUMMARY ==');
  results.forEach((provider, result) => stdout.writeln('$provider: $result'));

  if (!withDownload) {
    backend.dispose();
    return;
  }

  stdout.writeln('\n== SAMPLE DOWNLOADS ==');
  final outDir = Directory.systemTemp.createTempSync('smoke-out');
  Future<void> download(String id, String url, OutputKind kind) async {
    stdout.writeln('-- $id ($kind) $url');
    final downloadBackend = DesktopMediaBackend(
      configProvider: () async =>
          DesktopBackendConfig(outputDirectory: outDir.path),
      configDir: outDir.path,
    );
    try {
      final innerDone = downloadBackend.events
          .firstWhere(
            (event) =>
                event is DownloadCompletedEvent || event is DownloadFailedEvent,
          )
          .timeout(const Duration(minutes: 4));
      await downloadBackend.startDownload(
        DownloadRequest(
          id: id,
          url: url,
          formatId: kind == OutputKind.mp3
              ? 'bestaudio/best'
              : 'bestvideo*+bestaudio/best',
          outputKind: kind,
          title: id,
        ),
      );
      final event = await innerDone;
      if (event is DownloadCompletedEvent) {
        stdout.writeln('   COMPLETED: ${event.outputLocation}');
      } else if (event is DownloadFailedEvent) {
        stdout.writeln('   FAILED: ${event.message}');
      }
    } finally {
      downloadBackend.dispose();
    }
  }

  await download(
    'tiktok-sample',
    'https://www.tiktok.com/@tiktok/video/7106594312292453675',
    OutputKind.mp4,
  );
  await download(
    'soundcloud-sample',
    'https://soundcloud.com/forss/flickermood',
    OutputKind.mp3,
  );
  await download(
    'bandcamp-sample',
    'https://c418.bandcamp.com/track/sweden',
    OutputKind.mp3,
  );

  backend.dispose();
}
