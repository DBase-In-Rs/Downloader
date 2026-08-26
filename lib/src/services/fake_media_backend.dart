import 'dart:async';

import '../models/download_models.dart';
import 'media_backend.dart';

class FakeMediaBackend implements MediaBackend {
  final _events = StreamController<BackendEvent>.broadcast();
  final _timers = <String, Timer>{};
  CookieStatus _cookieStatus = const CookieStatus.empty();

  @override
  Stream<BackendEvent> get events => _events.stream;

  @override
  Future<MediaInfo> getInfo(MediaInfoRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final uri = Uri.tryParse(request.url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Enter a valid URL.');
    }

    return MediaInfo(
      url: request.url,
      title: 'Sample media preview',
      uploader: uri.host,
      duration: const Duration(minutes: 4, seconds: 18),
      extractor: 'fake',
      formats: const [
        MediaFormat(
          id: 'best_mp4',
          extension: 'mp4',
          kind: MediaKind.muxed,
          qualityLabel: '1080p',
          width: 1920,
          height: 1080,
          audioBitrateKbps: 160,
          videoBitrateKbps: 4500,
          filesizeBytes: 148000000,
          codec: 'h264 + aac',
        ),
        MediaFormat(
          id: 'mp4_720',
          extension: 'mp4',
          kind: MediaKind.muxed,
          qualityLabel: '720p',
          width: 1280,
          height: 720,
          audioBitrateKbps: 128,
          videoBitrateKbps: 2800,
          filesizeBytes: 92000000,
          codec: 'h264 + aac',
        ),
        MediaFormat(
          id: 'm4a_160',
          extension: 'm4a',
          kind: MediaKind.audio,
          qualityLabel: '160 kbps',
          audioBitrateKbps: 160,
          filesizeBytes: 5200000,
          codec: 'aac',
        ),
        MediaFormat(
          id: 'webm_audio',
          extension: 'webm',
          kind: MediaKind.audio,
          qualityLabel: '128 kbps',
          audioBitrateKbps: 128,
          filesizeBytes: 4400000,
          codec: 'opus',
          note: 'Good source for MP3 conversion',
        ),
      ],
    );
  }

  @override
  Future<void> startDownload(DownloadRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    _timers[request.id]?.cancel();

    const totalBytes = 52000000;
    var tick = 0;
    _events.add(
      DownloadProgressEvent(
        DownloadProgress(
          id: request.id,
          stage: 'Starting',
          percent: 0,
          downloadedBytes: 0,
          totalBytes: totalBytes,
          speedBytesPerSecond: 0,
          eta: const Duration(seconds: 18),
        ),
      ),
    );

    _timers[request.id] = Timer.periodic(const Duration(milliseconds: 220), (
      timer,
    ) {
      tick++;
      final percent = tick / 20;
      final downloaded = (totalBytes * percent).round();
      final stage = tick < 16 ? 'Downloading' : 'Finalizing';

      _events.add(
        DownloadProgressEvent(
          DownloadProgress(
            id: request.id,
            stage: stage,
            percent: percent.clamp(0.0, 1.0),
            downloadedBytes: downloaded.clamp(0, totalBytes).toInt(),
            totalBytes: totalBytes,
            speedBytesPerSecond: 3100000,
            eta: Duration(seconds: (20 - tick).clamp(0, 20).toInt()),
          ),
        ),
      );

      if (tick >= 20) {
        timer.cancel();
        _timers.remove(request.id);
        _events.add(
          DownloadCompletedEvent(
            id: request.id,
            outputLocation:
                'Fake output/${request.title ?? request.id}.${request.outputKind.name}',
          ),
        );
      }
    });
  }

  @override
  Future<void> cancelDownload(String id) async {
    _timers.remove(id)?.cancel();
    _events.add(DownloadCanceledEvent(id));
  }

  @override
  Future<EngineUpdateResult> updateEngine() async {
    return const EngineUpdateResult(updated: false, version: 'fake-engine');
  }

  @override
  Future<CookieStatus> getCookieStatus() async {
    return _cookieStatus;
  }

  @override
  Future<void> importCookies(String content) async {
    _cookieStatus = const CookieStatus(configured: true);
  }

  @override
  Future<void> clearCookies() async {
    _cookieStatus = const CookieStatus.empty();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _events.close();
  }
}
