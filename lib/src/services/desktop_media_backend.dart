import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/download_models.dart';
import 'media_backend.dart';

/// Paths used by the desktop process-runner backend. yt-dlp is required;
/// FFmpeg is needed for MP3/M4A/MP4 conversion. When [outputDirectory] is
/// null, the platform Downloads folder is used.
class DesktopBackendConfig {
  const DesktopBackendConfig({
    this.ytDlpPath,
    this.ffmpegPath,
    this.outputDirectory,
  });

  final String? ytDlpPath;
  final String? ffmpegPath;
  final String? outputDirectory;
}

/// Runs yt-dlp and FFmpeg as local processes on desktop platforms. Contains
/// no Flutter dependencies so it can be exercised from plain Dart.
class DesktopMediaBackend implements MediaBackend {
  DesktopMediaBackend({required this.configProvider, String? configDir})
    : _configDir = configDir ?? desktopConfigDir();

  final Future<DesktopBackendConfig> Function() configProvider;
  final String _configDir;

  final _events = StreamController<BackendEvent>.broadcast();
  final _processes = <String, Process>{};
  final _canceled = <String>{};

  @override
  Stream<BackendEvent> get events => _events.stream;

  @override
  Future<MediaInfo> getInfo(MediaInfoRequest request) async {
    final config = await configProvider();
    final ytDlp = await _requireYtDlp(config);
    final cookieArgs = request.useCookies ? _cookieArgs() : const <String>[];
    final result = await Process.run(ytDlp, [
      '--no-playlist',
      '--no-warnings',
      '--dump-json',
      ...cookieArgs,
      request.url,
    ]).timeout(const Duration(seconds: 60));

    if (result.exitCode != 0) {
      final message = sanitizeProcessError(result.stderr.toString());
      if (cookieArgs.isNotEmpty) {
        markCookiesExpiredIfAuthError(result.stderr.toString());
      }
      throw Exception(message);
    }

    return mediaInfoFromYtDlpJson(
      jsonDecode(result.stdout.toString()) as Map<String, dynamic>,
      request.url,
    );
  }

  @override
  Future<PlaylistInfo> getPlaylistInfo(MediaInfoRequest request) async {
    final config = await configProvider();
    final ytDlp = await _requireYtDlp(config);
    final cookieArgs = request.useCookies ? _cookieArgs() : const <String>[];
    final result = await Process.run(ytDlp, [
      '--flat-playlist',
      '--no-warnings',
      '--dump-single-json',
      ...cookieArgs,
      request.url,
    ]).timeout(const Duration(seconds: 120));

    if (result.exitCode != 0) {
      final message = sanitizeProcessError(result.stderr.toString());
      if (cookieArgs.isNotEmpty) {
        markCookiesExpiredIfAuthError(result.stderr.toString());
      }
      throw Exception(message);
    }

    return playlistInfoFromYtDlpJson(
      jsonDecode(result.stdout.toString()) as Map<String, dynamic>,
      request.url,
    );
  }

  @override
  Future<void> startDownload(DownloadRequest request) async {
    final config = await configProvider();
    final ytDlp = await _requireYtDlp(config);
    final workingDir = await Directory.systemTemp.createTemp('dbase-dl-');
    _canceled.remove(request.id);

    final args = [
      '--no-playlist',
      '--newline',
      '--restrict-filenames',
      '--trim-filenames',
      '180',
      '--retries',
      '10',
      '--fragment-retries',
      '10',
      '-f',
      request.formatId,
      '-o',
      '${workingDir.path}${Platform.pathSeparator}%(title)s.%(ext)s',
      ...switch (request.outputKind) {
        OutputKind.mp3 => [
          '-x',
          '--audio-format',
          'mp3',
          '--audio-quality',
          '0',
        ],
        OutputKind.m4a => ['-x', '--audio-format', 'm4a'],
        OutputKind.mp4 => ['--merge-output-format', 'mp4'],
        OutputKind.original => const <String>[],
      },
      if (config.ffmpegPath != null && config.ffmpegPath!.isNotEmpty) ...[
        '--ffmpeg-location',
        config.ffmpegPath!,
      ],
      ..._cookieArgs(),
      request.url,
    ];
    final usedCookies = args.contains('--cookies');

    final process = await Process.start(ytDlp, args);
    _processes[request.id] = process;
    _emit(
      DownloadProgressEvent(
        DownloadProgress(id: request.id, stage: 'Starting', percent: 0),
      ),
    );

    final stderrBuffer = StringBuffer();
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrBuffer.writeln);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final progress = parseYtDlpProgressLine(request.id, line);
          if (progress != null) {
            _emit(DownloadProgressEvent(progress));
          }
        });

    unawaited(
      process.exitCode.then((exitCode) async {
        _processes.remove(request.id);
        try {
          if (_canceled.remove(request.id)) {
            _emit(DownloadCanceledEvent(request.id));
            return;
          }

          if (exitCode != 0) {
            if (usedCookies) {
              markCookiesExpiredIfAuthError(stderrBuffer.toString());
            }
            _emit(
              DownloadFailedEvent(
                id: request.id,
                message: sanitizeProcessError(stderrBuffer.toString()),
              ),
            );
            return;
          }

          final output = await _newestFile(workingDir);
          if (output == null) {
            _emit(
              DownloadFailedEvent(
                id: request.id,
                message: 'Download finished without an output file.',
              ),
            );
            return;
          }

          final saved = await _moveToOutputDirectory(output, config);
          _emit(
            DownloadCompletedEvent(id: request.id, outputLocation: saved.path),
          );
        } catch (error) {
          _emit(
            DownloadFailedEvent(
              id: request.id,
              message: sanitizeProcessError(error.toString()),
            ),
          );
        } finally {
          unawaited(
            workingDir.delete(recursive: true).catchError((_) => workingDir),
          );
        }
      }),
    );
  }

  @override
  Future<void> cancelDownload(String id) async {
    final process = _processes[id];
    if (process == null) {
      _emit(DownloadCanceledEvent(id));
      return;
    }

    _canceled.add(id);
    process.kill();
  }

  @override
  Future<EngineUpdateResult> updateEngine() async {
    final config = await configProvider();
    final ytDlp = await _requireYtDlp(config);
    final update = await Process.run(ytDlp, [
      '--update',
    ]).timeout(const Duration(minutes: 3));
    final version = await Process.run(ytDlp, ['--version']);

    return EngineUpdateResult(
      updated: update.stdout.toString().contains('Updated yt-dlp'),
      version: version.stdout.toString().trim(),
    );
  }

  @override
  Future<CookieStatus> getCookieStatus() async {
    final configured = _cookieFile().existsSync();
    final expired = configured && _cookieExpiredMarker().existsSync();
    return CookieStatus(
      configured: configured,
      expired: expired,
      message: expired
          ? 'Cookies look expired or invalid; re-import cookies.txt.'
          : null,
    );
  }

  @override
  Future<void> importCookies(String content) async {
    final file = _cookieFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    if (_cookieExpiredMarker().existsSync()) {
      await _cookieExpiredMarker().delete();
    }
  }

  @override
  Future<void> clearCookies() async {
    for (final file in [_cookieFile(), _cookieExpiredMarker()]) {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  List<String> _cookieArgs() {
    final file = _cookieFile();
    return file.existsSync() ? ['--cookies', file.path] : const [];
  }

  void markCookiesExpiredIfAuthError(String errorText) {
    if (!_cookieFile().existsSync()) {
      return;
    }

    final lower = errorText.toLowerCase();
    const markers = [
      'cookies are no longer valid',
      'sign in to confirm',
      'login required',
      'not a bot',
      'account cookies',
    ];
    if (markers.any(lower.contains)) {
      try {
        _cookieExpiredMarker().writeAsStringSync('1');
      } catch (_) {
        // Marker is advisory only.
      }
    }
  }

  File _cookieFile() => File('$_configDir${Platform.pathSeparator}cookies.txt');

  File _cookieExpiredMarker() =>
      File('$_configDir${Platform.pathSeparator}cookies.expired');

  @override
  void dispose() {
    for (final process in _processes.values) {
      process.kill();
    }
    _events.close();
  }

  void _emit(BackendEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  Future<String> _requireYtDlp(DesktopBackendConfig config) async {
    final configured = config.ytDlpPath;
    if (configured != null && configured.isNotEmpty) {
      if (await File(configured).exists()) {
        return configured;
      }
      throw Exception('yt-dlp was not found at: $configured');
    }

    final located = await _findOnPath('yt-dlp');
    if (located != null) {
      return located;
    }

    throw Exception(
      'yt-dlp binary not found. Set its path in Settings or install it on '
      'the system PATH.',
    );
  }

  Future<String?> _findOnPath(String binary) async {
    final command = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(command, [binary]);
    if (result.exitCode != 0) {
      return null;
    }

    final line = result.stdout
        .toString()
        .split('\n')
        .map((entry) => entry.trim())
        .firstWhere((entry) => entry.isNotEmpty, orElse: () => '');
    return line.isEmpty ? null : line;
  }

  Future<File?> _newestFile(Directory directory) async {
    File? newest;
    DateTime newestTime = DateTime.fromMillisecondsSinceEpoch(0);
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File || entity.path.endsWith('.part')) {
        continue;
      }
      final modified = (await entity.stat()).modified;
      if (modified.isAfter(newestTime)) {
        newest = entity;
        newestTime = modified;
      }
    }
    return newest;
  }

  Future<File> _moveToOutputDirectory(
    File file,
    DesktopBackendConfig config,
  ) async {
    final directory = Directory(
      config.outputDirectory?.isNotEmpty == true
          ? config.outputDirectory!
          : defaultDownloadsPath(),
    );
    await directory.create(recursive: true);

    final baseName = file.uri.pathSegments.last;
    var target = File('${directory.path}${Platform.pathSeparator}$baseName');
    var counter = 1;
    while (await target.exists()) {
      final dot = baseName.lastIndexOf('.');
      final stem = dot <= 0 ? baseName : baseName.substring(0, dot);
      final ext = dot <= 0 ? '' : baseName.substring(dot);
      target = File(
        '${directory.path}${Platform.pathSeparator}$stem ($counter)$ext',
      );
      counter++;
    }

    try {
      return await file.rename(target.path);
    } on FileSystemException {
      // rename fails across drives/volumes; fall back to copy.
      final copied = await file.copy(target.path);
      await file.delete();
      return copied;
    }
  }
}

/// Per-user private app data directory used for the desktop cookie store.
/// Desktop has no app-sandbox keystore, so the file relies on OS user-profile
/// permissions; this is documented in PRIVACY.md.
String desktopConfigDir() {
  final base = Platform.isWindows
      ? Platform.environment['APPDATA']
      : Platform.isMacOS
      ? '${Platform.environment['HOME']}/Library/Application Support'
      : '${Platform.environment['HOME']}/.config';
  return '${base ?? Directory.systemTemp.path}'
      '${Platform.pathSeparator}rs.in.dbase.downloader';
}

String defaultDownloadsPath() {
  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'];
    if (profile != null) {
      return '$profile\\Downloads';
    }
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    return '$home/Downloads';
  }
  return Directory.systemTemp.path;
}

MediaInfo mediaInfoFromYtDlpJson(Map<String, dynamic> json, String url) {
  final formats = (json['formats'] as List? ?? const [])
      .whereType<Map>()
      .map((format) => _formatFromYtDlpJson(Map<String, dynamic>.from(format)))
      .whereType<MediaFormat>()
      .toList();

  return MediaInfo(
    url: stringValue(json['webpage_url']) ?? url,
    title:
        stringValue(json['fulltitle']) ??
        stringValue(json['title']) ??
        'Untitled media',
    uploader: stringValue(json['uploader']) ?? stringValue(json['channel']),
    thumbnailUrl: stringValue(json['thumbnail']),
    duration: durationFromSeconds(json['duration']),
    extractor:
        stringValue(json['extractor_key']) ?? stringValue(json['extractor']),
    formats: formats,
  );
}

MediaFormat? _formatFromYtDlpJson(Map<String, dynamic> json) {
  final id = stringValue(json['format_id']);
  if (id == null || id.isEmpty) {
    return null;
  }

  final vcodec = stringValue(json['vcodec']);
  final acodec = stringValue(json['acodec']);
  final hasVideo = vcodec != null && vcodec.isNotEmpty && vcodec != 'none';
  final hasAudio = acodec != null && acodec.isNotEmpty && acodec != 'none';
  final height = intValue(json['height']);
  final abr = intValue(json['abr']);
  final tbr = intValue(json['tbr']);
  final note = stringValue(json['format_note']);

  final qualityLabel = note?.isNotEmpty == true
      ? note!
      : height != null && height > 0
      ? '${height}p'
      : abr != null && abr > 0
      ? '$abr kbps'
      : tbr != null && tbr > 0
      ? '$tbr kbps'
      : stringValue(json['format']) ?? id;

  return MediaFormat(
    id: id,
    extension: stringValue(json['ext']) ?? 'unknown',
    kind: hasVideo && hasAudio
        ? MediaKind.muxed
        : hasVideo
        ? MediaKind.video
        : hasAudio
        ? MediaKind.audio
        : MediaKind.unknown,
    qualityLabel: qualityLabel,
    width: intValue(json['width']),
    height: height,
    audioBitrateKbps: abr,
    videoBitrateKbps: hasVideo ? tbr : null,
    filesizeBytes:
        intValue(json['filesize']) ?? intValue(json['filesize_approx']),
    codec:
        [if (hasVideo) vcodec, if (hasAudio) acodec]
            .join(' + ')
            .replaceAll(RegExp(r'^\s*\+\s*|\s*\+\s*$'), '')
            .trim()
            .isEmpty
        ? null
        : [if (hasVideo) vcodec, if (hasAudio) acodec].join(' + '),
    note: note,
  );
}

PlaylistInfo playlistInfoFromYtDlpJson(Map<String, dynamic> json, String url) {
  final entries = (json['entries'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final entry = Map<String, dynamic>.from(raw);
        final entryUrl = _playlistEntryUrl(entry);
        if (entryUrl == null) {
          return null;
        }
        return PlaylistEntry(
          url: entryUrl,
          title: stringValue(entry['title']) ?? 'Untitled media',
          duration: durationFromSeconds(entry['duration']),
          uploader:
              stringValue(entry['uploader']) ?? stringValue(entry['channel']),
        );
      })
      .whereType<PlaylistEntry>()
      .toList();

  return PlaylistInfo(
    url: stringValue(json['webpage_url']) ?? url,
    title: stringValue(json['title']) ?? 'Playlist',
    entries: entries,
  );
}

String? _playlistEntryUrl(Map<String, dynamic> entry) {
  final webpage = stringValue(entry['webpage_url']);
  if (webpage != null && webpage.startsWith('http')) {
    return webpage;
  }

  final url = stringValue(entry['url']);
  if (url != null && url.startsWith('http')) {
    return url;
  }

  final id = stringValue(entry['id']) ?? url;
  final ieKey = stringValue(entry['ie_key'])?.toLowerCase();
  if (id != null && id.isNotEmpty && ieKey == 'youtube') {
    return 'https://www.youtube.com/watch?v=$id';
  }

  return null;
}

final _progressLineRegex = RegExp(
  r'\[download\]\s+(?<percent>[0-9.]+)%'
  r'(?:\s+of\s+~?\s*(?<totalValue>[0-9.]+)(?<totalUnit>[KMGT]?i?B))?'
  r'(?:\s+at\s+(?<speedValue>[0-9.]+)(?<speedUnit>[KMGT]?i?B)/s)?'
  r'(?:\s+ETA\s+(?<eta>[0-9:]+))?',
);

DownloadProgress? parseYtDlpProgressLine(String id, String line) {
  final stage = line.contains('[ExtractAudio]')
      ? 'Converting'
      : line.contains('[Merger]')
      ? 'Merging'
      : line.contains('[download]')
      ? 'Downloading'
      : line.contains('[ffmpeg]')
      ? 'Finalizing'
      : null;
  if (stage == null) {
    return null;
  }

  final match = _progressLineRegex.firstMatch(line);
  if (match == null) {
    return DownloadProgress(id: id, stage: stage);
  }

  final percent = double.tryParse(match.namedGroup('percent') ?? '');
  final totalBytes = _bytesFromUnit(
    match.namedGroup('totalValue'),
    match.namedGroup('totalUnit'),
  );
  final speed = _bytesFromUnit(
    match.namedGroup('speedValue'),
    match.namedGroup('speedUnit'),
  );

  return DownloadProgress(
    id: id,
    stage: stage,
    percent: percent == null ? null : percent / 100,
    downloadedBytes: totalBytes != null && percent != null
        ? (totalBytes * percent / 100).round()
        : null,
    totalBytes: totalBytes,
    speedBytesPerSecond: speed,
    eta: _etaFromText(match.namedGroup('eta')),
  );
}

int? _bytesFromUnit(String? value, String? unit) {
  final number = double.tryParse(value ?? '');
  if (number == null) {
    return null;
  }

  final multiplier = switch (unit?.toLowerCase()) {
    'b' => 1.0,
    'kb' => 1000.0,
    'kib' => 1024.0,
    'mb' => 1000.0 * 1000,
    'mib' => 1024.0 * 1024,
    'gb' => 1000.0 * 1000 * 1000,
    'gib' => 1024.0 * 1024 * 1024,
    'tb' => 1000.0 * 1000 * 1000 * 1000,
    'tib' => 1024.0 * 1024 * 1024 * 1024,
    _ => null,
  };
  if (multiplier == null) {
    return null;
  }

  return (number * multiplier).round();
}

Duration? _etaFromText(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }

  final parts = text.split(':').map(int.tryParse).toList();
  if (parts.any((part) => part == null)) {
    return null;
  }

  return switch (parts.length) {
    3 => Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!),
    2 => Duration(minutes: parts[0]!, seconds: parts[1]!),
    1 => Duration(seconds: parts[0]!),
    _ => null,
  };
}

String sanitizeProcessError(String raw) {
  final errorLines = raw
      .split('\n')
      .where((line) => line.trimLeft().startsWith('ERROR:'))
      .join('\n');
  final message = errorLines.isEmpty ? raw.trim() : errorLines;
  final bounded = message.isEmpty ? 'Process failed.' : message;

  final redacted = bounded
      .replaceAllMapped(
        RegExp(
          r'(cookie|token|auth|session)[^\s&=]*=([^\s&]+)',
          caseSensitive: false,
        ),
        (match) => '${match[1]}=<redacted>',
      )
      .replaceAll(RegExp(r'https?://\S+'), '<url>');

  return redacted.length > 800 ? redacted.substring(0, 800) : redacted;
}
