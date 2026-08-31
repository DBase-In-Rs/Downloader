import 'media_providers.dart';

enum AppSection { home, queue, history, settings }

enum ExtractionState { idle, loading, loaded, failed }

enum MediaKind { audio, video, muxed, unknown }

enum MediaKindFilter { all, audio, video }

enum OutputKind { mp3, m4a, mp4, original }

enum DownloadStatus { pending, running, paused, completed, failed, canceled }

class MediaInfoRequest {
  const MediaInfoRequest({required this.url, this.useCookies = false});

  final String url;
  final bool useCookies;

  Map<String, Object?> toMap() {
    return {'url': url, 'useCookies': useCookies};
  }
}

class MediaInfo {
  const MediaInfo({
    required this.url,
    required this.title,
    required this.formats,
    this.uploader,
    this.thumbnailUrl,
    this.duration,
    this.extractor,
    this.providerId,
    this.providerName,
  });

  final String url;
  final String title;
  final String? uploader;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? extractor;
  final String? providerId;
  final String? providerName;
  final List<MediaFormat> formats;

  factory MediaInfo.fromMap(Map<Object?, Object?> map) {
    final url = stringValue(map['url']) ?? '';
    final extractor = stringValue(map['extractor']);
    final provider = resolveMediaProvider(url: url, extractor: extractor);
    return MediaInfo(
      url: url,
      title: stringValue(map['title']) ?? 'Untitled media',
      uploader: stringValue(map['uploader']),
      thumbnailUrl: stringValue(map['thumbnailUrl']),
      duration: durationFromSeconds(map['durationSeconds']),
      extractor: extractor,
      providerId: stringValue(map['providerId']) ?? provider.id,
      providerName: stringValue(map['providerName']) ?? provider.displayName,
      formats: listOfMaps(map['formats']).map(MediaFormat.fromMap).toList(),
    );
  }

  MediaInfo copyWith({String? providerId, String? providerName}) {
    return MediaInfo(
      url: url,
      title: title,
      formats: formats,
      uploader: uploader,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      extractor: extractor,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'url': url,
      'title': title,
      'uploader': uploader,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': duration?.inSeconds,
      'extractor': extractor,
      'providerId': providerId,
      'providerName': providerName,
      'formats': formats.map((format) => format.toMap()).toList(),
    };
  }
}

class MediaFormat {
  const MediaFormat({
    required this.id,
    required this.extension,
    required this.kind,
    required this.qualityLabel,
    this.width,
    this.height,
    this.audioBitrateKbps,
    this.videoBitrateKbps,
    this.filesizeBytes,
    this.codec,
    this.note,
  });

  final String id;
  final String extension;
  final MediaKind kind;
  final String qualityLabel;
  final int? width;
  final int? height;
  final int? audioBitrateKbps;
  final int? videoBitrateKbps;
  final int? filesizeBytes;
  final String? codec;
  final String? note;

  bool get hasAudio => kind == MediaKind.audio || kind == MediaKind.muxed;

  bool get hasVideo => kind == MediaKind.video || kind == MediaKind.muxed;

  factory MediaFormat.fromMap(Map<Object?, Object?> map) {
    return MediaFormat(
      id: stringValue(map['id']) ?? '',
      extension: stringValue(map['extension']) ?? 'unknown',
      kind: mediaKindFromString(stringValue(map['kind'])),
      qualityLabel: stringValue(map['qualityLabel']) ?? 'Unknown quality',
      width: intValue(map['width']),
      height: intValue(map['height']),
      audioBitrateKbps: intValue(map['audioBitrateKbps']),
      videoBitrateKbps: intValue(map['videoBitrateKbps']),
      filesizeBytes: intValue(map['filesizeBytes']),
      codec: stringValue(map['codec']),
      note: stringValue(map['note']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'extension': extension,
      'kind': kind.name,
      'qualityLabel': qualityLabel,
      'width': width,
      'height': height,
      'audioBitrateKbps': audioBitrateKbps,
      'videoBitrateKbps': videoBitrateKbps,
      'filesizeBytes': filesizeBytes,
      'codec': codec,
      'note': note,
    };
  }
}

class PlaylistEntry {
  const PlaylistEntry({
    required this.url,
    required this.title,
    this.duration,
    this.uploader,
  });

  final String url;
  final String title;
  final Duration? duration;
  final String? uploader;

  factory PlaylistEntry.fromMap(Map<Object?, Object?> map) {
    return PlaylistEntry(
      url: stringValue(map['url']) ?? '',
      title: stringValue(map['title']) ?? 'Untitled media',
      duration: durationFromSeconds(map['durationSeconds']),
      uploader: stringValue(map['uploader']),
    );
  }
}

class PlaylistInfo {
  const PlaylistInfo({
    required this.url,
    required this.title,
    required this.entries,
    this.providerId,
    this.providerName,
  });

  final String url;
  final String title;
  final List<PlaylistEntry> entries;
  final String? providerId;
  final String? providerName;

  factory PlaylistInfo.fromMap(Map<Object?, Object?> map) {
    final url = stringValue(map['url']) ?? '';
    final provider = mediaProviderForUrl(url);
    return PlaylistInfo(
      url: url,
      title: stringValue(map['title']) ?? 'Playlist',
      entries: listOfMaps(map['entries'])
          .map(PlaylistEntry.fromMap)
          .where((e) => e.url.isNotEmpty)
          .toList(),
      providerId: stringValue(map['providerId']) ?? provider.id,
      providerName: stringValue(map['providerName']) ?? provider.displayName,
    );
  }

  PlaylistInfo copyWith({String? providerId, String? providerName}) {
    return PlaylistInfo(
      url: url,
      title: title,
      entries: entries,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
    );
  }
}

class DownloadRequest {
  const DownloadRequest({
    required this.id,
    required this.url,
    required this.formatId,
    required this.outputKind,
    this.title,
    this.tuning = const DownloadTuning(),
  });

  final String id;
  final String url;
  final String formatId;
  final OutputKind outputKind;
  final String? title;
  final DownloadTuning tuning;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'url': url,
      'formatId': formatId,
      'outputKind': outputKind.name,
      'title': title,
      ...tuning.toMap(),
    };
  }
}

/// User-tunable politeness and retry knobs passed to yt-dlp. Defaults match
/// the previously hardcoded behavior, so an untouched config changes nothing.
class DownloadTuning {
  const DownloadTuning({
    this.retries = 10,
    this.fragmentRetries = 10,
    this.sleepRequestsSeconds = 0,
    this.sleepIntervalSeconds = 0,
    this.maxSleepIntervalSeconds = 0,
    this.queueGapSeconds = 0,
  });

  /// yt-dlp --retries.
  final int retries;

  /// yt-dlp --fragment-retries.
  final int fragmentRetries;

  /// yt-dlp --sleep-requests: pause between metadata requests (0 = off).
  final double sleepRequestsSeconds;

  /// yt-dlp --sleep-interval: minimum pause before each download (0 = off).
  final int sleepIntervalSeconds;

  /// yt-dlp --max-sleep-interval; only used when [sleepIntervalSeconds] > 0
  /// and this value is larger, which makes the pause a random range.
  final int maxSleepIntervalSeconds;

  /// Pause between finished queue items before the next one starts; helps
  /// avoid provider rate-limiting on long queues (0 = off).
  final int queueGapSeconds;

  DownloadTuning copyWith({
    int? retries,
    int? fragmentRetries,
    double? sleepRequestsSeconds,
    int? sleepIntervalSeconds,
    int? maxSleepIntervalSeconds,
    int? queueGapSeconds,
  }) {
    return DownloadTuning(
      retries: retries ?? this.retries,
      fragmentRetries: fragmentRetries ?? this.fragmentRetries,
      sleepRequestsSeconds: sleepRequestsSeconds ?? this.sleepRequestsSeconds,
      sleepIntervalSeconds: sleepIntervalSeconds ?? this.sleepIntervalSeconds,
      maxSleepIntervalSeconds:
          maxSleepIntervalSeconds ?? this.maxSleepIntervalSeconds,
      queueGapSeconds: queueGapSeconds ?? this.queueGapSeconds,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'retries': retries,
      'fragmentRetries': fragmentRetries,
      'sleepRequestsSeconds': sleepRequestsSeconds,
      'sleepIntervalSeconds': sleepIntervalSeconds,
      'maxSleepIntervalSeconds': maxSleepIntervalSeconds,
      'queueGapSeconds': queueGapSeconds,
    };
  }

  factory DownloadTuning.fromMap(Map<Object?, Object?> map) {
    const defaults = DownloadTuning();
    return DownloadTuning(
      retries: intValue(map['retries']) ?? defaults.retries,
      fragmentRetries:
          intValue(map['fragmentRetries']) ?? defaults.fragmentRetries,
      sleepRequestsSeconds:
          doubleValue(map['sleepRequestsSeconds']) ??
          defaults.sleepRequestsSeconds,
      sleepIntervalSeconds:
          intValue(map['sleepIntervalSeconds']) ??
          defaults.sleepIntervalSeconds,
      maxSleepIntervalSeconds:
          intValue(map['maxSleepIntervalSeconds']) ??
          defaults.maxSleepIntervalSeconds,
      queueGapSeconds:
          intValue(map['queueGapSeconds']) ?? defaults.queueGapSeconds,
    );
  }
}

/// Result of renaming a finished output: the (possibly new) location plus
/// the display name the platform actually stored.
class RenamedOutput {
  const RenamedOutput({required this.location, required this.displayName});

  final String location;
  final String displayName;

  factory RenamedOutput.fromMap(Map<Object?, Object?> map) {
    return RenamedOutput(
      location: stringValue(map['location']) ?? '',
      displayName: stringValue(map['displayName']) ?? '',
    );
  }
}

class DownloadProgress {
  const DownloadProgress({
    required this.id,
    required this.stage,
    this.percent,
    this.downloadedBytes,
    this.totalBytes,
    this.speedBytesPerSecond,
    this.eta,
  });

  final String id;
  final String stage;
  final double? percent;
  final int? downloadedBytes;
  final int? totalBytes;
  final int? speedBytesPerSecond;
  final Duration? eta;

  factory DownloadProgress.fromMap(Map<Object?, Object?> map) {
    return DownloadProgress(
      id: stringValue(map['id']) ?? '',
      stage: stringValue(map['stage']) ?? 'working',
      percent: doubleValue(map['percent']),
      downloadedBytes: intValue(map['downloadedBytes']),
      totalBytes: intValue(map['totalBytes']),
      speedBytesPerSecond: intValue(map['speedBytesPerSecond']),
      eta: durationFromSeconds(map['etaSeconds']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'stage': stage,
      'percent': percent,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'speedBytesPerSecond': speedBytesPerSecond,
      'etaSeconds': eta?.inSeconds,
    };
  }
}

class DownloadQueueItem {
  const DownloadQueueItem({
    required this.id,
    required this.url,
    required this.title,
    required this.format,
    required this.outputKind,
    required this.status,
    this.providerId,
    this.providerName,
    this.progress,
    this.outputLocation,
    this.outputDisplayName,
    this.errorMessage,
    this.finishedAt,
    this.autoRetryCount = 0,
  });

  final String id;
  final String url;
  final String title;
  final MediaFormat format;
  final OutputKind outputKind;
  final DownloadStatus status;
  final String? providerId;
  final String? providerName;
  final DownloadProgress? progress;
  final String? outputLocation;

  /// File name shown to the user instead of the raw location (which is an
  /// opaque content:// URI on Android).
  final String? outputDisplayName;
  final String? errorMessage;
  final DateTime? finishedAt;

  /// How many times this item was re-queued automatically after a
  /// transient extractor error.
  final int autoRetryCount;

  DownloadQueueItem copyWith({
    DownloadStatus? status,
    String? providerId,
    String? providerName,
    DownloadProgress? progress,
    String? outputLocation,
    String? outputDisplayName,
    String? errorMessage,
    DateTime? finishedAt,
    int? autoRetryCount,
  }) {
    return DownloadQueueItem(
      id: id,
      url: url,
      title: title,
      format: format,
      outputKind: outputKind,
      status: status ?? this.status,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      progress: progress ?? this.progress,
      outputLocation: outputLocation ?? this.outputLocation,
      outputDisplayName: outputDisplayName ?? this.outputDisplayName,
      errorMessage: errorMessage ?? this.errorMessage,
      finishedAt: finishedAt ?? this.finishedAt,
      autoRetryCount: autoRetryCount ?? this.autoRetryCount,
    );
  }

  /// Fresh copy for a manual retry of a failed item: waiting state, no
  /// progress, error, or output from the previous attempt.
  DownloadQueueItem resetForRetry({required bool paused}) {
    return DownloadQueueItem(
      id: id,
      url: url,
      title: title,
      format: format,
      outputKind: outputKind,
      status: paused ? DownloadStatus.paused : DownloadStatus.pending,
      providerId: providerId,
      providerName: providerName,
    );
  }

  factory DownloadQueueItem.fromMap(Map<Object?, Object?> map) {
    final finishedAtMillis = intValue(map['finishedAtMillis']);
    final url = stringValue(map['url']) ?? '';
    final provider = mediaProviderForUrl(url);
    return DownloadQueueItem(
      id: stringValue(map['id']) ?? '',
      url: url,
      title: stringValue(map['title']) ?? 'Untitled media',
      format: MediaFormat.fromMap(mapValue(map['format'])),
      outputKind: outputKindFromString(stringValue(map['outputKind'])),
      status: downloadStatusFromString(stringValue(map['status'])),
      providerId: stringValue(map['providerId']) ?? provider.id,
      providerName: stringValue(map['providerName']) ?? provider.displayName,
      outputLocation: stringValue(map['outputLocation']),
      outputDisplayName: stringValue(map['outputDisplayName']),
      errorMessage: stringValue(map['errorMessage']),
      finishedAt: finishedAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(finishedAtMillis),
      autoRetryCount: intValue(map['autoRetryCount']) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'format': format.toMap(),
      'outputKind': outputKind.name,
      'status': status.name,
      'providerId': providerId,
      'providerName': providerName,
      'outputLocation': outputLocation,
      'outputDisplayName': outputDisplayName,
      'errorMessage': errorMessage,
      'finishedAtMillis': finishedAt?.millisecondsSinceEpoch,
      'autoRetryCount': autoRetryCount,
    };
  }
}

class EngineUpdateResult {
  const EngineUpdateResult({required this.updated, this.version});

  final bool updated;
  final String? version;

  factory EngineUpdateResult.fromMap(Map<Object?, Object?> map) {
    return EngineUpdateResult(
      updated: boolValue(map['updated']),
      version: stringValue(map['version']),
    );
  }
}

class CookieStatus {
  const CookieStatus({
    required this.configured,
    this.expired = false,
    this.message,
  });

  const CookieStatus.empty()
    : configured = false,
      expired = false,
      message = null;

  final bool configured;
  final bool expired;
  final String? message;

  factory CookieStatus.fromMap(Map<Object?, Object?> map) {
    return CookieStatus(
      configured: boolValue(map['configured']),
      expired: boolValue(map['expired']),
      message: stringValue(map['message']),
    );
  }
}

MediaKind mediaKindFromString(String? value) {
  return switch (value) {
    'audio' => MediaKind.audio,
    'video' => MediaKind.video,
    'muxed' => MediaKind.muxed,
    _ => MediaKind.unknown,
  };
}

DownloadStatus downloadStatusFromString(String? value) {
  return switch (value) {
    'running' => DownloadStatus.running,
    'paused' => DownloadStatus.paused,
    'completed' => DownloadStatus.completed,
    'failed' => DownloadStatus.failed,
    'canceled' => DownloadStatus.canceled,
    _ => DownloadStatus.pending,
  };
}

OutputKind outputKindFromString(String? value) {
  return switch (value) {
    'mp3' => OutputKind.mp3,
    'm4a' => OutputKind.m4a,
    'mp4' => OutputKind.mp4,
    _ => OutputKind.original,
  };
}

/// Format preset used for playlist items, where per-item format lists are
/// not fetched; the id is a yt-dlp format selector expression.
MediaFormat presetFormatFor(OutputKind outputKind) {
  return switch (outputKind) {
    OutputKind.mp3 || OutputKind.m4a => const MediaFormat(
      id: 'bestaudio/best',
      extension: 'auto',
      kind: MediaKind.audio,
      qualityLabel: 'Best audio',
    ),
    OutputKind.mp4 => const MediaFormat(
      id: 'bestvideo*+bestaudio/best',
      extension: 'auto',
      kind: MediaKind.muxed,
      qualityLabel: 'Best video',
    ),
    OutputKind.original => const MediaFormat(
      id: 'best',
      extension: 'auto',
      kind: MediaKind.muxed,
      qualityLabel: 'Best available',
    ),
  };
}

String outputKindLabel(OutputKind outputKind) {
  return switch (outputKind) {
    OutputKind.mp3 => 'MP3',
    OutputKind.m4a => 'M4A',
    OutputKind.mp4 => 'MP4',
    OutputKind.original => 'Original',
  };
}

String mediaKindLabel(MediaKind kind) {
  return switch (kind) {
    MediaKind.audio => 'Audio',
    MediaKind.video => 'Video',
    MediaKind.muxed => 'Video + audio',
    MediaKind.unknown => 'Unknown',
  };
}

String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) {
    return 'Unknown size';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }

  final decimals = unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

String formatDuration(Duration? duration) {
  if (duration == null) {
    return '--:--';
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }

  return '$minutes:$seconds';
}

String formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String formatSpeed(int? bytesPerSecond) {
  if (bytesPerSecond == null || bytesPerSecond <= 0) {
    return '--';
  }

  return '${formatBytes(bytesPerSecond)}/s';
}

bool boolValue(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is String) {
    return value == 'true';
  }

  return false;
}

String? stringValue(Object? value) {
  if (value == null) {
    return null;
  }

  return value.toString();
}

int? intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.round();
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

double? doubleValue(Object? value) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

Duration? durationFromSeconds(Object? value) {
  final seconds = intValue(value);
  if (seconds == null) {
    return null;
  }

  return Duration(seconds: seconds);
}

Map<Object?, Object?> mapValue(Object? value) {
  if (value is Map) {
    return Map<Object?, Object?>.from(value);
  }

  return const {};
}

List<Map<Object?, Object?>> listOfMaps(Object? value) {
  if (value is Iterable) {
    return value
        .whereType<Map>()
        .map((entry) => Map<Object?, Object?>.from(entry))
        .toList();
  }

  return const [];
}
