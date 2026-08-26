import '../models/download_models.dart';

abstract class MediaBackend {
  Stream<BackendEvent> get events;

  Future<MediaInfo> getInfo(MediaInfoRequest request);

  Future<void> startDownload(DownloadRequest request);

  Future<void> cancelDownload(String id);

  /// Updates the bundled media engine (yt-dlp) to the latest stable release.
  Future<EngineUpdateResult> updateEngine();

  Future<CookieStatus> getCookieStatus();

  Future<void> importCookies(String path);

  Future<void> clearCookies();

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
  });

  final String id;
  final String outputLocation;
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
