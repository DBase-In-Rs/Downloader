import 'dart:typed_data';

import '../models/download_models.dart';

abstract class MediaBackend {
  Stream<BackendEvent> get events;

  Future<MediaInfo> getInfo(MediaInfoRequest request);

  /// Fetches flat playlist metadata (entry URLs and titles, no formats).
  Future<PlaylistInfo> getPlaylistInfo(MediaInfoRequest request);

  Future<void> startDownload(DownloadRequest request);

  Future<void> cancelDownload(String id);

  /// Updates the bundled media engine (yt-dlp) to the latest stable release.
  Future<EngineUpdateResult> updateEngine();

  Future<CookieStatus> getCookieStatus();

  /// Stores the raw `cookies.txt` content in platform-encrypted storage.
  Future<void> importCookies(String content);

  Future<void> clearCookies();

  /// Renames a finished output to [newDisplayName] (with extension). The
  /// location may change on some storage backends.
  Future<RenamedOutput> renameOutput(String location, String newDisplayName);

  /// Compressed preview image bytes for a finished output, or null when the
  /// platform cannot produce one.
  Future<Uint8List?> loadOutputThumbnail(String location, {int size = 256});

  /// Full content of a finished output; throws when the file exceeds
  /// [maxBytes] (tag editing rewrites files in memory).
  Future<Uint8List> readOutputBytes(String location, {required int maxBytes});

  /// Replaces the content of a finished output.
  Future<void> writeOutputBytes(String location, Uint8List bytes);

  void dispose() {}
}

sealed class BackendEvent {
  const BackendEvent();
}

class DownloadProgressEvent extends BackendEvent {
  const DownloadProgressEvent(this.progress);

  final DownloadProgress progress;
}

class DownloadCompletedEvent extends BackendEvent {
  const DownloadCompletedEvent({
    required this.id,
    required this.outputLocation,
    this.outputDisplayName,
  });

  final String id;
  final String outputLocation;

  /// User-facing file name of the saved output (raw locations are opaque
  /// content:// URIs on Android).
  final String? outputDisplayName;
}

class DownloadFailedEvent extends BackendEvent {
  const DownloadFailedEvent({required this.id, required this.message});

  final String id;
  final String message;
}

class DownloadCanceledEvent extends BackendEvent {
  const DownloadCanceledEvent(this.id);

  final String id;
}

class BackendMessageEvent extends BackendEvent {
  const BackendMessageEvent(this.message);

  final String message;
}
