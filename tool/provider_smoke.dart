// Runs provider smoke tests from a private JSON matrix.
//
//   dart run tool/provider_smoke.dart [secrets/provider_smoke.json]
//
// Matrix entries:
//   {"provider":"vimeo","url":"https://vimeo.com/...","tests":["metadata","mp4","mp3"]}
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/services/desktop_media_backend.dart';
import 'package:dbase_downloader/src/services/media_backend.dart';

Future<void> main(List<String> args) async {
  final matrixPath = args.isEmpty ? 'secrets/provider_smoke.json' : args.first;
  final matrixFile = File(matrixPath);
  if (!matrixFile.existsSync()) {
    stderr.writeln('Provider smoke matrix not found: $matrixPath');
    stderr.writeln('See docs/PROVIDER_QA.md for the private matrix format.');
    exit(2);
  }

  final decoded = jsonDecode(await matrixFile.readAsString());
  if (decoded is! List) {
    stderr.writeln('Provider smoke matrix must be a JSON list.');
    exit(2);
  }

  var failures = 0;
  for (var index = 0; index < decoded.length; index++) {
    final raw = decoded[index];
    if (raw is! Map) {
      stderr.writeln('Skipping entry $index: expected an object.');
      failures++;
      continue;
    }

    final entry = Map<String, Object?>.from(raw);
    final provider = entry['provider']?.toString() ?? 'unknown';
    final url = entry['url']?.toString();
    final outputDirectory = entry['outputDirectory']?.toString();
    final tests =
        (entry['tests'] as List?)?.map((test) => test.toString()).toSet() ??
        {'metadata'};

    if (url == null || url.isEmpty) {
      stderr.writeln('Skipping $provider: missing url.');
      failures++;
      continue;
    }

    stdout.writeln('== $provider ==');
    final backend = DesktopMediaBackend(
      configProvider: () async =>
          DesktopBackendConfig(outputDirectory: outputDirectory),
    );

    try {
      final info = await backend.getInfo(MediaInfoRequest(url: url));
      stdout.writeln('metadata: OK - ${info.title} (${info.formats.length})');

      for (final test in tests.where((test) => test != 'metadata')) {
        await _runDownloadSmoke(backend, provider, url, info.title, test);
      }
    } catch (error) {
      failures++;
      stderr.writeln('$provider: FAILED - $error');
    } finally {
      backend.dispose();
    }
  }

  if (failures > 0) {
    stderr.writeln('Provider smoke finished with $failures failure(s).');
    exit(1);
  }

  stdout.writeln('Provider smoke passed.');
}

Future<void> _runDownloadSmoke(
  MediaBackend backend,
  String provider,
  String url,
  String title,
  String test,
) async {
  final outputKind = _outputKindForTest(test);
  final formatId = switch (outputKind) {
    OutputKind.mp3 || OutputKind.m4a => 'bestaudio/best',
    OutputKind.mp4 => 'bestvideo*+bestaudio/best',
    OutputKind.original => 'best',
  };
  final id = '$provider-$test-${DateTime.now().microsecondsSinceEpoch}'
      .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]+'), '-');
  final done = Completer<void>();

  final subscription = backend.events.listen((event) {
    switch (event) {
      case DownloadProgressEvent(:final progress) when progress.id == id:
        final percent = progress.percent == null
            ? '--'
            : '${(progress.percent! * 100).toStringAsFixed(1)}%';
        stdout.writeln('$provider/$test: ${progress.stage} $percent');
      case DownloadCompletedEvent(
            id: final eventId,
            outputLocation: final outputLocation,
          )
          when eventId == id:
        stdout.writeln('$provider/$test: OK - $outputLocation');
        if (!done.isCompleted) {
          done.complete();
        }
      case DownloadFailedEvent(id: final eventId, message: final message)
          when eventId == id:
        if (!done.isCompleted) {
          done.completeError(message);
        }
      case DownloadCanceledEvent(id: final eventId) when eventId == id:
        if (!done.isCompleted) {
          done.completeError('Canceled');
        }
      default:
        break;
    }
  });

  try {
    await backend.startDownload(
      DownloadRequest(
        id: id,
        url: url,
        formatId: formatId,
        outputKind: outputKind,
        title: title,
      ),
    );
    await done.future.timeout(const Duration(minutes: 10));
  } finally {
    await subscription.cancel();
  }
}

OutputKind _outputKindForTest(String test) {
  return switch (test.toLowerCase()) {
    'mp3' => OutputKind.mp3,
    'm4a' => OutputKind.m4a,
    'mp4' => OutputKind.mp4,
    'original' => OutputKind.original,
    _ => throw ArgumentError('Unknown download smoke test: $test'),
  };
}
