// Manual smoke test for the desktop backend against real local binaries.
//
//   dart run tool/desktop_smoke.dart <media-url> [output-dir]
//
// Uses yt-dlp/ffmpeg from PATH, downloads the URL as MP3, and prints events.
import 'dart:async';
import 'dart:io';

import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/services/desktop_media_backend.dart';
import 'package:dbase_downloader/src/services/media_backend.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/desktop_smoke.dart <url> [out-dir]');
    exit(2);
  }

  final url = args[0];
  final outputDir = args.length > 1 ? args[1] : null;
  final backend = DesktopMediaBackend(
    configProvider: () async =>
        DesktopBackendConfig(outputDirectory: outputDir),
  );

  stdout.writeln('== getInfo ==');
  final info = await backend.getInfo(MediaInfoRequest(url: url));
  stdout.writeln('title: ${info.title}');
  stdout.writeln('uploader: ${info.uploader}');
  stdout.writeln('duration: ${info.duration}');
  stdout.writeln('formats: ${info.formats.length}');

  stdout.writeln('== startDownload (mp3) ==');
  final done = Completer<void>();
  final subscription = backend.events.listen((event) {
    switch (event) {
      case DownloadProgressEvent(:final progress):
        stdout.writeln(
          'progress: ${progress.stage} '
          '${progress.percent != null ? (progress.percent! * 100).toStringAsFixed(1) : '--'}% '
          'speed=${progress.speedBytesPerSecond ?? '--'} '
          'eta=${progress.eta ?? '--'}',
        );
      case DownloadCompletedEvent(:final outputLocation):
        stdout.writeln('COMPLETED: $outputLocation');
        done.complete();
      case DownloadFailedEvent(:final message):
        stdout.writeln('FAILED: $message');
        done.completeError(message);
      case DownloadCanceledEvent():
        stdout.writeln('CANCELED');
        done.complete();
      default:
        break;
    }
  });

  await backend.startDownload(
    DownloadRequest(
      id: 'smoke-1',
      url: url,
      formatId: 'bestaudio/best',
      outputKind: OutputKind.mp3,
      title: info.title,
    ),
  );

  try {
    await done.future.timeout(const Duration(minutes: 5));
    stdout.writeln('SMOKE TEST PASSED');
  } catch (error) {
    stdout.writeln('SMOKE TEST FAILED: $error');
    exitCode = 1;
  } finally {
    await subscription.cancel();
    backend.dispose();
  }
}
