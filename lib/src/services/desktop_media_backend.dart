import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      ...tuningArgs(request.tuning),
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
            DownloadCompletedEvent(
              id: request.id,
              outputLocation: saved.path,
              outputDisplayName: saved.uri.pathSegments.last,
            ),
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

  @override
  Future<RenamedOutput> renameOutput(
    String location,
    String newDisplayName,
  ) async {
    final file = File(location);
    if (!await file.exists()) {
      throw Exception('The file no longer exists at this location.');
    }

    final target = File(
      '${file.parent.path}${Platform.pathSeparator}$newDisplayName',
    );
    if (await target.exists()) {
      throw Exception('A file with that name already exists.');
    }

    final renamed = await file.rename(target.path);
    return RenamedOutput(
      location: renamed.path,
      displayName: renamed.uri.pathSegments.last,
    );
  }

  @override
  Future<Uint8List?> loadOutputThumbnail(String location, {int size = 256}) {
    // Desktop has no cheap thumbnail source; the UI falls back to an icon.
    return Future.value(null);
  }

  @override
  Future<Uint8List> readOutputBytes(
    String location, {
    required int maxBytes,
  }) async {
    final file = File(location);
    if (!await file.exists()) {
      throw Exception('The file no longer exists at this location.');
    }
    if (await file.length() > maxBytes) {
      throw Exception('The file is too large to edit on this device.');
    }

    return file.readAsBytes();
  }

  @override
  Future<void> writeOutputBytes(String location, Uint8List bytes) async {
    await File(location).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<EditableOutput> prepareOutputForEditing(String location) async {
    final file = File(location);
    if (!await file.exists()) {
      throw Exception('The file no longer exists at this location.');
    }

    final probe = await _probeOutput(location);
    return EditableOutput(
      location: location,
      previewLocation: location,
      displayName: file.uri.pathSegments.last,
      duration: probe.duration,
      hasAudio: probe.hasAudio,
      hasVideo: probe.hasVideo,
    );
  }

  @override
  Future<void> releaseEditableOutput(EditableOutput output) async {}

  @override
  Future<Uint8List?> loadOutputWaveform(
    String location, {
    int width = 1200,
    int height = 220,
  }) async {
    final probe = await _probeOutput(location);
    if (!probe.hasAudio) {
      return null;
    }

    final config = await configProvider();
    final ffmpeg = await _requireFfmpeg(config);
    final workingDir = await Directory.systemTemp.createTemp('dbase-wave-');
    try {
      final output = File(
        '${workingDir.path}${Platform.pathSeparator}wave.png',
      );
      final result = await Process.run(ffmpeg, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-i',
        location,
        '-filter_complex',
        'showwavespic=s=${width}x$height:split_channels=0:colors=0x15347A',
        '-frames:v',
        '1',
        output.path,
      ]).timeout(const Duration(minutes: 2));

      if (result.exitCode != 0 || !await output.exists()) {
        return null;
      }

      return await output.readAsBytes();
    } finally {
      unawaited(
        workingDir.delete(recursive: true).catchError((_) => workingDir),
      );
    }
  }

  @override
  Future<TrimmedOutput> trimOutput(TrimOutputRequest request) async {
    if (request.start < Duration.zero || request.end <= request.start) {
      throw Exception('Choose a valid start and end time.');
    }

    final source = File(request.location);
    if (!await source.exists()) {
      throw Exception('The file no longer exists at this location.');
    }

    final probe = await _probeOutput(request.location);
    if (probe.duration > Duration.zero && request.end > probe.duration) {
      throw Exception('The selected end time is outside the file.');
    }

    final config = await configProvider();
    final ffmpeg = await _requireFfmpeg(config);
    final workingDir = await Directory.systemTemp.createTemp('dbase-trim-');
    try {
      final outputKind = probe.hasVideo ? OutputKind.mp4 : request.outputKind;
      final extension = _trimExtension(request, source, probe);
      final baseName = _safeBaseName(request.outputBaseName);
      final tempOutput = File(
        '${workingDir.path}${Platform.pathSeparator}$baseName.$extension',
      );
      final result = await Process.run(ffmpeg, [
        '-hide_banner',
        '-y',
        '-ss',
        _ffmpegTime(request.start),
        '-i',
        source.path,
        '-t',
        _ffmpegTime(request.duration),
        ..._trimCodecArgs(outputKind, probe),
        tempOutput.path,
      ]).timeout(const Duration(minutes: 15));

      if (result.exitCode != 0 || !await tempOutput.exists()) {
        throw Exception(sanitizeProcessError(result.stderr.toString()));
      }

      final saved = await _moveToOutputDirectory(tempOutput, config);
      return TrimmedOutput(
        location: saved.path,
        displayName: saved.uri.pathSegments.last,
        outputKind: outputKind,
        hasAudio: probe.hasAudio,
        hasVideo: probe.hasVideo,
      );
    } finally {
      unawaited(
        workingDir.delete(recursive: true).catchError((_) => workingDir),
      );
    }
  }

  @override
  Future<void> setAsRingtone(String location) {
    throw UnsupportedError('Ringtone setup is only available on Android.');
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

  Future<String> _requireFfmpeg(DesktopBackendConfig config) {
    return _requireFfmpegTool(config, 'ffmpeg');
  }

  Future<String> _requireFfprobe(DesktopBackendConfig config) {
    return _requireFfmpegTool(config, 'ffprobe');
  }

  Future<String> _requireFfmpegTool(
    DesktopBackendConfig config,
    String tool,
  ) async {
    final configured = config.ffmpegPath;
    final executableName = Platform.isWindows ? '$tool.exe' : tool;
    if (configured != null && configured.isNotEmpty) {
      final configuredFile = File(configured);
      if (await configuredFile.exists()) {
        if (configuredFile.uri.pathSegments.last.toLowerCase() ==
            executableName.toLowerCase()) {
          return configuredFile.path;
        }
        final sibling = File(
          '${configuredFile.parent.path}${Platform.pathSeparator}$executableName',
        );
        if (await sibling.exists()) {
          return sibling.path;
        }
      }

      final configuredDir = Directory(configured);
      if (await configuredDir.exists()) {
        final candidate = File(
          '${configuredDir.path}${Platform.pathSeparator}$executableName',
        );
        if (await candidate.exists()) {
          return candidate.path;
        }
      }
    }

    final located = await _findOnPath(tool);
    if (located != null) {
      return located;
    }

    throw Exception(
      '$tool binary not found. Set the FFmpeg path in Settings or install '
      'FFmpeg on the system PATH.',
    );
  }

  Future<OutputProbe> _probeOutput(String location) async {
    final config = await configProvider();
    final ffprobe = await _requireFfprobe(config);
    final result = await Process.run(ffprobe, [
      '-v',
      'error',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      location,
    ]).timeout(const Duration(seconds: 30));

    if (result.exitCode != 0) {
      throw Exception(sanitizeProcessError(result.stderr.toString()));
    }

    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    return outputProbeFromFfprobeJson(json);
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

class OutputProbe {
  const OutputProbe({
    required this.duration,
    required this.hasAudio,
    required this.hasVideo,
  });

  final Duration duration;
  final bool hasAudio;
  final bool hasVideo;
}

OutputProbe outputProbeFromFfprobeJson(Map<String, dynamic> json) {
  final streams = (json['streams'] as List? ?? const []).whereType<Map>();
  var hasAudio = false;
  var hasVideo = false;
  double? durationSeconds = doubleValue((json['format'] as Map?)?['duration']);

  for (final raw in streams) {
    final stream = Map<String, dynamic>.from(raw);
    final type = stringValue(stream['codec_type']);
    hasAudio = hasAudio || type == 'audio';
    hasVideo = hasVideo || type == 'video';
    final streamDuration = doubleValue(stream['duration']);
    if (streamDuration != null &&
        (durationSeconds == null || streamDuration > durationSeconds)) {
      durationSeconds = streamDuration;
    }
  }

  if (!hasAudio && !hasVideo) {
    throw Exception('This file does not contain audio or video streams.');
  }

  return OutputProbe(
    duration: durationFromSeconds(durationSeconds) ?? Duration.zero,
    hasAudio: hasAudio,
    hasVideo: hasVideo,
  );
}

List<String> _trimCodecArgs(OutputKind outputKind, OutputProbe probe) {
  if (probe.hasVideo) {
    return const [
      '-map',
      '0:v:0',
      '-map',
      '0:a:0?',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '20',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-movflags',
      '+faststart',
    ];
  }

  return switch (outputKind) {
    OutputKind.mp3 => const ['-vn', '-c:a', 'libmp3lame', '-q:a', '2'],
    OutputKind.m4a => const ['-vn', '-c:a', 'aac', '-b:a', '192k'],
    OutputKind.mp4 => const ['-vn', '-c:a', 'aac', '-b:a', '192k'],
    OutputKind.original => const ['-vn', '-c:a', 'copy'],
  };
}

String _trimExtension(
  TrimOutputRequest request,
  File source,
  OutputProbe probe,
) {
  if (probe.hasVideo || request.outputKind == OutputKind.mp4) {
    return 'mp4';
  }

  return switch (request.outputKind) {
    OutputKind.mp3 => 'mp3',
    OutputKind.m4a => 'm4a',
    OutputKind.mp4 => 'mp4',
    OutputKind.original =>
      source.uri.pathSegments.last
          .split('.')
          .last
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .takeIfValidExtension(),
  };
}

String _safeBaseName(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[. ]+$'), '')
      .split('')
      .take(180)
      .join();
  return sanitized.isEmpty ? 'dbase-clip' : sanitized;
}

String _ffmpegTime(Duration duration) {
  return (duration.inMicroseconds / Duration.microsecondsPerSecond)
      .toStringAsFixed(3);
}

extension on String {
  String takeIfValidExtension() {
    return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(this) ? this : 'media';
  }
}

/// Per-user private app data directory used for the desktop cookie store.
/// Desktop has no app-sandbox keystore, so the file relies on OS user-profile
/// permissions; this is documented in the README privacy section.
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
  if (id != null && id.isNotEmpty) {
    return switch (ieKey) {
      'youtube' => 'https://www.youtube.com/watch?v=$id',
      'dailymotion' => 'https://www.dailymotion.com/video/$id',
      'vimeo' => 'https://vimeo.com/$id',
      _ => null,
    };
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

/// yt-dlp retry/politeness arguments for the user's tuning settings; sleep
/// options are added only when enabled so defaults match older releases.
List<String> tuningArgs(DownloadTuning tuning) {
  return [
    '--retries',
    '${tuning.retries}',
    '--fragment-retries',
    '${tuning.fragmentRetries}',
    if (tuning.sleepRequestsSeconds > 0) ...[
      '--sleep-requests',
      '${tuning.sleepRequestsSeconds}',
    ],
    if (tuning.sleepIntervalSeconds > 0) ...[
      '--sleep-interval',
      '${tuning.sleepIntervalSeconds}',
      if (tuning.maxSleepIntervalSeconds > tuning.sleepIntervalSeconds) ...[
        '--max-sleep-interval',
        '${tuning.maxSleepIntervalSeconds}',
      ],
    ],
  ];
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
