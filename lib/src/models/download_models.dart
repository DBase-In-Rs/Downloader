enum AppSection { home, queue, history, settings }

enum ExtractionState { idle, loading, loaded, failed }

enum MediaKind { audio, video, muxed, unknown }

enum MediaKindFilter { all, audio, video }

enum OutputKind { mp3, m4a, mp4, original }

enum DownloadStatus { pending, running, completed, failed, canceled }

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
  });

  final String url;
  final String title;
  final String? uploader;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? extractor;
  final List<MediaFormat> formats;

  factory MediaInfo.fromMap(Map<Object?, Object?> map) {
    return MediaInfo(
      url: stringValue(map['url']) ?? '',
      title: stringValue(map['title']) ?? 'Untitled media',
      uploader: stringValue(map['uploader']),
      thumbnailUrl: stringValue(map['thumbnailUrl']),
      duration: durationFromSeconds(map['durationSeconds']),
      extractor: stringValue(map['extractor']),
      formats: listOfMaps(map['formats']).map(MediaFormat.fromMap).toList(),
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

class DownloadRequest {
  const DownloadRequest({
    required this.id,
    required this.url,
    required this.formatId,
    required this.outputKind,
    this.title,
  });

  final String id;
  final String url;
  final String formatId;
  final OutputKind outputKind;
  final String? title;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'url': url,
      'formatId': formatId,
      'outputKind': outputKind.name,
      'title': title,
    };
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
    this.progress,
    this.outputLocation,
    this.errorMessage,
  });

  final String id;
  final String url;
  final String title;
  final MediaFormat format;
  final OutputKind outputKind;
  final DownloadStatus status;
  final DownloadProgress? progress;
  final String? outputLocation;
  final String? errorMessage;

  DownloadQueueItem copyWith({
    DownloadStatus? status,
    DownloadProgress? progress,
    String? outputLocation,
    String? errorMessage,
  }) {
    return DownloadQueueItem(
      id: id,
      url: url,
      title: title,
      format: format,
      outputKind: outputKind,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputLocation: outputLocation ?? this.outputLocation,
      errorMessage: errorMessage ?? this.errorMessage,
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

OutputKind outputKindFromString(String? value) {
  return switch (value) {
    'mp3' => OutputKind.mp3,
    'm4a' => OutputKind.m4a,
    'mp4' => OutputKind.mp4,
    _ => OutputKind.original,
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

List<Map<Object?, Object?>> listOfMaps(Object? value) {
  if (value is Iterable) {
    return value
        .whereType<Map>()
        .map((entry) => Map<Object?, Object?>.from(entry))
        .toList();
  }

  return const [];
}
