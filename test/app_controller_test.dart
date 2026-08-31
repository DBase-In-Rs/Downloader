import 'dart:async';
import 'dart:typed_data';

import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/models/media_providers.dart';
import 'package:dbase_downloader/src/services/app_controller.dart';
import 'package:dbase_downloader/src/services/app_settings_store.dart';
import 'package:dbase_downloader/src/services/fake_media_backend.dart';
import 'package:dbase_downloader/src/services/media_backend.dart';
import 'package:dbase_downloader/src/services/queue_store.dart';
import 'package:dbase_downloader/src/services/shared_url_service.dart';
import 'package:flutter_test/flutter_test.dart';

class ManualMediaBackend implements MediaBackend {
  final _events = StreamController<BackendEvent>.broadcast();
  final started = <DownloadRequest>[];
  final canceled = <String>[];
  String? mediaUrlOverride;
  String? extractorOverride;

  @override
  Stream<BackendEvent> get events => _events.stream;

  @override
  Future<MediaInfo> getInfo(MediaInfoRequest request) async {
    infoCalls++;
    if (transientInfoFailures > 0) {
      transientInfoFailures--;
      throw Exception(transientExtractorMessage);
    }
    final error = infoError;
    if (error != null) {
      throw error;
    }
    return MediaInfo(
      url: mediaUrlOverride ?? request.url,
      title: 'Manual media',
      extractor: extractorOverride,
      formats: const [
        MediaFormat(
          id: 'best_mp4',
          extension: 'mp4',
          kind: MediaKind.muxed,
          qualityLabel: '1080p',
        ),
      ],
    );
  }

  PlaylistInfo? playlistResponse;
  Object? infoError;
  int infoCalls = 0;
  int transientInfoFailures = 0;

  @override
  Future<PlaylistInfo> getPlaylistInfo(MediaInfoRequest request) async {
    return playlistResponse ??
        PlaylistInfo(url: request.url, title: 'Manual playlist', entries: []);
  }

  @override
  Future<void> startDownload(DownloadRequest request) async {
    started.add(request);
  }

  @override
  Future<void> cancelDownload(String id) async {
    canceled.add(id);
    emitCanceled(id);
  }

  void emitCompleted(String id, {String? displayName}) {
    _events.add(
      DownloadCompletedEvent(
        id: id,
        outputLocation: 'out/$id',
        outputDisplayName: displayName,
      ),
    );
  }

  void emitFailed(String id, String message) {
    _events.add(DownloadFailedEvent(id: id, message: message));
  }

  void emitCanceled(String id) {
    _events.add(DownloadCanceledEvent(id));
  }

  var engineUpdateCalls = 0;
  Object? engineUpdateError;

  @override
  Future<EngineUpdateResult> updateEngine() async {
    engineUpdateCalls++;
    final error = engineUpdateError;
    if (error != null) {
      throw error;
    }
    return const EngineUpdateResult(updated: true, version: '2026.08.20');
  }

  @override
  Future<CookieStatus> getCookieStatus() async => const CookieStatus.empty();

  @override
  Future<void> importCookies(String path) async {}

  @override
  Future<void> clearCookies() async {}

  final renames = <(String, String)>[];

  @override
  Future<RenamedOutput> renameOutput(
    String location,
    String newDisplayName,
  ) async {
    renames.add((location, newDisplayName));
    return RenamedOutput(
      location: 'renamed/$newDisplayName',
      displayName: newDisplayName,
    );
  }

  @override
  Future<Uint8List?> loadOutputThumbnail(String location, {int size = 256}) {
    return Future.value(null);
  }

  Uint8List outputBytes = Uint8List(0);
  Uint8List? writtenBytes;

  @override
  Future<Uint8List> readOutputBytes(
    String location, {
    required int maxBytes,
  }) async {
    return outputBytes;
  }

  @override
  Future<void> writeOutputBytes(String location, Uint8List bytes) async {
    writtenBytes = bytes;
  }

  @override
  void dispose() {
    _events.close();
  }
}

const transientExtractorMessage =
    'ERROR: [TikTok] 7564339453137833236: Unable to extract universal data '
    'for rehydration; please report this issue on <url>, filling out the '
    'appropriate issue template. Confirm you are on the latest version '
    'using yt-dlp -U';

Future<AppController> analyzedController(
  ManualMediaBackend backend, {
  QueueStore? queueStore,
}) async {
  final controller = AppController(
    backend: backend,
    sharedUrlService: const FakeSharedUrlService(),
    queueStore: queueStore,
  );
  await controller.initialize();
  controller.setUrlText('https://example.com/media');
  await controller.analyzeUrl();
  return controller;
}

void main() {
  test('validates http and https URLs only', () {
    expect(isValidUrl('https://example.com/watch?v=1'), isTrue);
    expect(isValidUrl('http://example.com/video'), isTrue);
    expect(isValidUrl('ftp://example.com/video'), isFalse);
    expect(isValidUrl('not a url'), isFalse);
  });

  test('extracts first URL from shared text', () {
    expect(
      extractFirstUrl('Open https://youtu.be/video, thanks'),
      'https://youtu.be/video',
    );
    expect(extractFirstUrl('No link here'), isNull);
  });

  test('normalizes pasted and shared provider URLs', () {
    final controller = AppController(
      backend: FakeMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);

    controller.setUrlText(
      ' https://www.tiktok.com/@artist/video/123?is_from_webapp=1&sender_device=pc&utm_source=copy ',
    );
    expect(controller.urlText, 'https://www.tiktok.com/@artist/video/123');

    controller.receiveSharedText(
      'Watch https://www.youtube.com/watch?v=abc123&si=shared&utm_campaign=x.',
    );
    expect(controller.urlText, 'https://www.youtube.com/watch?v=abc123');
  });

  test('maps DNS restricted-mode errors to a content-filter hint', () async {
    final backend = ManualMediaBackend()
      ..infoError = Exception(
        'ERROR: [youtube] abc: Video unavailable. This video is restricted. '
        'Please check the Google Workspace administrator and/or the network '
        'administrator restrictions.',
      );
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    await controller.initialize();
    controller.setUrlText('https://www.youtube.com/watch?v=abc');
    await controller.analyzeUrl();

    expect(controller.errorMessage, contains('Restricted Mode'));
    expect(controller.errorMessage, contains('DNS filter'));
    controller.dispose();
  });

  test('controller analyzes URL with fake backend', () async {
    final controller = AppController(
      backend: FakeMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);

    controller.setUrlText('https://example.com/media');
    await controller.analyzeUrl();

    expect(controller.extractionState, ExtractionState.loaded);
    expect(controller.mediaInfo?.title, 'Sample media preview');
    expect(controller.visibleFormats, hasLength(4));
  });

  test('initialize triggers an engine update check', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await pumpEventQueue();

    expect(backend.engineUpdateCalls, 1);
    expect(controller.engineUpdateState, EngineUpdateState.updated);
    expect(controller.engineVersion, '2026.08.20');
  });

  test('failed engine update is surfaced without blocking the app', () async {
    final backend = ManualMediaBackend()
      ..engineUpdateError = Exception('No network.');
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await pumpEventQueue();

    expect(controller.engineUpdateState, EngineUpdateState.failed);
    expect(controller.engineUpdateMessage, 'No network.');
    expect(controller.errorMessage, isNull);
  });

  test('validates Netscape cookies.txt content', () {
    const valid =
        '# Netscape HTTP Cookie File\n'
        '.youtube.com\tTRUE\t/\tTRUE\t1799999999\tSID\tabc123\n';
    expect(isValidCookiesFile(valid), isTrue);
    expect(isValidCookiesFile('# only comments\n\n'), isFalse);
    expect(isValidCookiesFile('not a cookie file'), isFalse);
    expect(isValidCookiesFile(''), isFalse);
  });

  test('importCookies stores valid content and updates status', () async {
    final backend = FakeMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);

    final rejected = await controller.importCookies('garbage');
    expect(rejected, isNotNull);
    expect(controller.cookieStatus.configured, isFalse);

    final accepted = await controller.importCookies(
      '.youtube.com\tTRUE\t/\tTRUE\t1799999999\tSID\tabc123\n',
    );
    expect(accepted, isNull);
    expect(controller.cookieStatus.configured, isTrue);

    await controller.clearCookies();
    expect(controller.cookieStatus.configured, isFalse);
  });

  test('detects playlist URLs', () {
    expect(
      isLikelyPlaylistUrl('https://www.youtube.com/playlist?list=PL123'),
      isTrue,
    );
    expect(
      isLikelyPlaylistUrl('https://www.youtube.com/watch?v=a&list=PL123'),
      isTrue,
    );
    expect(isLikelyPlaylistUrl('https://soundcloud.com/a/sets/b'), isTrue);
    expect(isLikelyPlaylistUrl('https://youtu.be/abc123'), isFalse);
  });

  test('detects media providers from URL and extractor names', () {
    expect(
      mediaProviderForUrl('https://www.dailymotion.com/video/x123').id,
      'dailymotion',
    );
    expect(mediaProviderForUrl('https://vimeo.com/123456').id, 'vimeo');
    expect(
      mediaProviderForUrl('https://soundcloud.com/artist/track').id,
      'soundcloud',
    );
    expect(mediaProviderForUrl('https://vm.tiktok.com/abc').id, 'tiktok');
    expect(mediaProviderForExtractor('dailymotion:playlist').id, 'dailymotion');
    expect(mediaProviderForExtractor('Soundcloud').id, 'soundcloud');
    expect(mediaProviderForUrl('https://example.com/media').id, 'generic');
  });

  test('analyzed media and queue items carry provider metadata', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://vimeo.com/123456');
    await controller.analyzeUrl();

    expect(controller.mediaInfo?.providerId, 'vimeo');
    expect(controller.mediaInfo?.providerName, 'Vimeo');

    await controller.startDownload(controller.visibleFormats.single);

    expect(controller.queue.single.providerId, 'vimeo');
    expect(controller.queue.single.providerName, 'Vimeo');
  });

  test('YouTube Shorts provider survives canonical watch URLs', () async {
    final backend = ManualMediaBackend()
      ..mediaUrlOverride = 'https://www.youtube.com/watch?v=abc123'
      ..extractorOverride = 'Youtube';
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://www.youtube.com/shorts/abc123?si=shared');
    await controller.analyzeUrl();

    expect(controller.mediaInfo?.providerId, 'youtube_shorts');

    await controller.startDownload(controller.visibleFormats.single);
    expect(controller.queue.single.providerId, 'youtube_shorts');
  });

  test('audio-first providers reset video-only output choices', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setOutputKind(OutputKind.mp4);
    controller.setFormatFilter(MediaKindFilter.video);
    controller.setUrlText('https://soundcloud.com/artist/track');
    await controller.analyzeUrl();

    expect(controller.outputKind, OutputKind.mp3);
    expect(controller.formatFilter, MediaKindFilter.audio);
  });

  test('download failures show provider-specific cookie guidance', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://vimeo.com/123456');
    await controller.analyzeUrl();
    await controller.startDownload(controller.visibleFormats.single);
    backend.emitFailed(backend.started.single.id, 'ERROR: Login required');
    await pumpEventQueue();

    expect(controller.queue.single.status, DownloadStatus.failed);
    expect(controller.queue.single.errorMessage, contains('Vimeo'));
    expect(controller.queue.single.errorMessage, contains('cookies.txt'));
  });

  test('playlist analysis selects all entries and enqueues them', () async {
    final backend = ManualMediaBackend()
      ..playlistResponse = const PlaylistInfo(
        url: 'https://example.com/playlist?list=1',
        title: 'Test playlist',
        entries: [
          PlaylistEntry(url: 'https://example.com/1', title: 'One'),
          PlaylistEntry(url: 'https://example.com/2', title: 'Two'),
          PlaylistEntry(url: 'https://example.com/3', title: 'Three'),
        ],
      );
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://example.com/playlist?list=1');
    await controller.analyzeUrl();

    expect(controller.playlistInfo?.entries, hasLength(3));
    expect(controller.selectedPlaylistUrls, hasLength(3));

    controller.togglePlaylistEntry(controller.playlistInfo!.entries[1]);
    await controller.enqueueSelectedPlaylistEntries();

    expect(controller.queue, hasLength(2));
    expect(controller.queue[0].title, 'One');
    expect(controller.queue[1].title, 'Three');
    // Sequential execution: only the first item starts.
    expect(backend.started, hasLength(1));
    expect(backend.started.single.formatId, 'bestaudio/best');
  });

  test(
    'non-heuristic playlist URLs fall back to playlist extraction',
    () async {
      final backend = ManualMediaBackend()
        ..infoError = Exception('ERROR: no video found on this page')
        ..playlistResponse = const PlaylistInfo(
          url: 'https://artist.bandcamp.com/album/test',
          title: 'Album',
          entries: [
            PlaylistEntry(
              url: 'https://artist.bandcamp.com/track/a',
              title: 'A',
            ),
            PlaylistEntry(
              url: 'https://artist.bandcamp.com/track/b',
              title: 'B',
            ),
          ],
        );
      final controller = AppController(
        backend: backend,
        sharedUrlService: const FakeSharedUrlService(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      // No list=/playlist/sets marker, so the heuristic sees a single item.
      controller.setUrlText('https://artist.bandcamp.com/album/test');
      await controller.analyzeUrl();

      expect(controller.extractionState, ExtractionState.loaded);
      expect(controller.playlistInfo?.entries, hasLength(2));
      expect(controller.errorMessage, isNull);
    },
  );

  test('single-item error surfaces when playlist fallback is empty', () async {
    final backend = ManualMediaBackend()
      ..infoError = Exception('ERROR: not found');
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://example.com/media');
    await controller.analyzeUrl();

    expect(controller.extractionState, ExtractionState.failed);
    expect(controller.errorMessage, contains('not found'));
  });

  test('one failed playlist item does not stop the rest', () async {
    final backend = ManualMediaBackend()
      ..playlistResponse = const PlaylistInfo(
        url: 'https://example.com/playlist?list=1',
        title: 'Test playlist',
        entries: [
          PlaylistEntry(url: 'https://example.com/1', title: 'One'),
          PlaylistEntry(url: 'https://example.com/2', title: 'Two'),
        ],
      );
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://example.com/playlist?list=1');
    await controller.analyzeUrl();
    await controller.enqueueSelectedPlaylistEntries();

    backend.emitFailed(backend.started[0].id, 'boom');
    await pumpEventQueue();

    // The failed item waits in the queue for a retry; the next one runs.
    expect(backend.started, hasLength(2));
    expect(controller.queue, hasLength(2));
    expect(controller.queue[0].status, DownloadStatus.failed);
    expect(controller.queue[1].status, DownloadStatus.running);
    expect(controller.history, isEmpty);
  });

  test('history persists across restarts and supports search/delete', () async {
    final store = MemoryQueueStore();
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend, queueStore: store);

    await controller.startDownload(controller.visibleFormats.single);
    backend.emitCompleted(backend.started.single.id);
    await pumpEventQueue();
    expect(controller.history.single.finishedAt, isNotNull);
    controller.dispose();

    final restarted = AppController(
      backend: ManualMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
      queueStore: store,
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();

    expect(restarted.history, hasLength(1));
    expect(restarted.history.single.status, DownloadStatus.completed);

    restarted.setHistoryQuery('no-such-title');
    expect(restarted.filteredHistory, isEmpty);
    restarted.setHistoryQuery('manual');
    expect(restarted.filteredHistory, hasLength(1));

    restarted.deleteHistoryItem(restarted.history.single.id);
    expect(restarted.history, isEmpty);
  });

  test('history can be filtered by provider', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.setUrlText('https://www.dailymotion.com/video/x123');
    await controller.analyzeUrl();
    await controller.startDownload(controller.visibleFormats.single);
    backend.emitCompleted(backend.started.last.id);
    await pumpEventQueue();

    controller.setUrlText('https://soundcloud.com/artist/track');
    await controller.analyzeUrl();
    await controller.startDownload(controller.visibleFormats.single);
    backend.emitCompleted(backend.started.last.id);
    await pumpEventQueue();

    expect(
      controller.historyProviderOptions.map((p) => p.id),
      containsAll(['dailymotion', 'soundcloud']),
    );

    controller.setHistoryProviderFilter('dailymotion');
    expect(controller.filteredHistory, hasLength(1));
    expect(controller.filteredHistory.single.providerId, 'dailymotion');

    controller.setHistoryQuery('soundcloud');
    expect(controller.filteredHistory, isEmpty);

    controller.setHistoryProviderFilter(null);
    expect(controller.filteredHistory.single.providerId, 'soundcloud');
  });

  test('video-only formats get best audio merged in', () {
    const videoOnly = MediaFormat(
      id: '137',
      extension: 'mp4',
      kind: MediaKind.video,
      qualityLabel: '1080p',
    );
    const muxed = MediaFormat(
      id: '18',
      extension: 'mp4',
      kind: MediaKind.muxed,
      qualityLabel: '360p',
    );
    const audio = MediaFormat(
      id: '140',
      extension: 'm4a',
      kind: MediaKind.audio,
      qualityLabel: '128 kbps',
    );

    expect(
      effectiveFormatSelector(videoOnly, OutputKind.mp4),
      '137+bestaudio/137',
    );
    expect(
      effectiveFormatSelector(videoOnly, OutputKind.original),
      '137+bestaudio/137',
    );
    expect(
      effectiveFormatSelector(videoOnly, OutputKind.mp3),
      'bestaudio/best',
    );
    expect(effectiveFormatSelector(muxed, OutputKind.mp4), '18');
    expect(effectiveFormatSelector(audio, OutputKind.mp3), '140');
  });

  test('queued video-only download requests merged audio', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    controller.setOutputKind(OutputKind.mp4);
    await controller.startDownload(
      const MediaFormat(
        id: 'hd-video',
        extension: 'mp4',
        kind: MediaKind.video,
        qualityLabel: '720p',
      ),
    );

    expect(backend.started.single.formatId, 'hd-video+bestaudio/hd-video');
  });

  test('clearAnalysis resets the home screen state', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    expect(controller.hasAnalysisContent, isTrue);
    controller.clearAnalysis();

    expect(controller.urlText, isEmpty);
    expect(controller.mediaInfo, isNull);
    expect(controller.playlistInfo, isNull);
    expect(controller.errorMessage, isNull);
    expect(controller.extractionState, ExtractionState.idle);
    expect(controller.hasAnalysisContent, isFalse);
  });

  test('queue item serialization round-trips', () {
    const item = DownloadQueueItem(
      id: '42',
      url: 'https://example.com/media',
      title: 'Media title',
      format: MediaFormat(
        id: 'best_mp4',
        extension: 'mp4',
        kind: MediaKind.muxed,
        qualityLabel: '1080p',
      ),
      outputKind: OutputKind.mp4,
      status: DownloadStatus.paused,
      errorMessage: 'boom',
    );

    final restored = DownloadQueueItem.fromMap(item.toMap());

    expect(restored.id, item.id);
    expect(restored.url, item.url);
    expect(restored.title, item.title);
    expect(restored.format.id, item.format.id);
    expect(restored.outputKind, item.outputKind);
    expect(restored.status, item.status);
    expect(restored.errorMessage, item.errorMessage);
  });

  test('queue runs downloads sequentially', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    final format = controller.visibleFormats.single;
    await controller.startDownload(format);
    controller.setOutputKind(OutputKind.mp4);
    await controller.startDownload(format);

    expect(backend.started, hasLength(1));
    expect(controller.queue, hasLength(2));
    expect(controller.queue[0].status, DownloadStatus.running);
    expect(controller.queue[1].status, DownloadStatus.pending);

    backend.emitCompleted(backend.started[0].id);
    await pumpEventQueue();

    expect(backend.started, hasLength(2));
    expect(controller.queue, hasLength(1));
    expect(controller.queue[0].status, DownloadStatus.running);
    expect(controller.history.single.status, DownloadStatus.completed);
  });

  test('paused queue does not start new downloads until resumed', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    await controller.pauseQueue();
    await controller.startDownload(controller.visibleFormats.single);

    expect(controller.queuePaused, isTrue);
    expect(backend.started, isEmpty);
    expect(controller.queue.single.status, DownloadStatus.paused);

    await controller.resumeQueue();

    expect(controller.queuePaused, isFalse);
    expect(backend.started, hasLength(1));
    expect(controller.queue.single.status, DownloadStatus.running);
  });

  test('transient extractor errors re-queue the download automatically', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);
    controller.transientRetryDelay = Duration.zero;

    await controller.startDownload(controller.visibleFormats.single);
    backend.emitFailed(backend.started.single.id, transientExtractorMessage);
    await pumpEventQueue();

    // Same item restarted instead of failing to history.
    expect(backend.started, hasLength(2));
    expect(backend.started[1].id, backend.started[0].id);
    expect(controller.queue.single.status, DownloadStatus.running);
    expect(controller.history, isEmpty);

    backend.emitCompleted(backend.started.last.id);
    await pumpEventQueue();

    expect(controller.queue, isEmpty);
    expect(controller.history.single.status, DownloadStatus.completed);
  });

  test('transient retries stop after the budget and explain the error', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);
    controller.transientRetryDelay = Duration.zero;

    await controller.startDownload(controller.visibleFormats.single);
    // Initial attempt + 3 automatic retries all fail.
    for (var i = 0; i < 4; i++) {
      backend.emitFailed(backend.started.last.id, transientExtractorMessage);
      await pumpEventQueue();
    }

    expect(backend.started, hasLength(4));
    final failed = controller.queue.single;
    expect(failed.status, DownloadStatus.failed);
    expect(failed.errorMessage, contains('incomplete page'));
    expect(failed.errorMessage, contains('retry'));
    expect(controller.history, isEmpty);
  });

  test('metadata extraction retries transient errors before failing', () async {
    final backend = ManualMediaBackend()..transientInfoFailures = 2;
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    controller.transientRetryDelay = Duration.zero;
    await controller.initialize();

    controller.setUrlText('https://www.tiktok.com/@artist/video/123');
    await controller.analyzeUrl();

    expect(backend.infoCalls, 3);
    expect(controller.extractionState, ExtractionState.loaded);
    expect(controller.mediaInfo, isNotNull);
  });

  test('metadata transient failures beyond the budget surface a hint', () async {
    final backend = ManualMediaBackend()..transientInfoFailures = 10;
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    controller.transientRetryDelay = Duration.zero;
    await controller.initialize();

    controller.setUrlText('https://www.tiktok.com/@artist/video/123');
    await controller.analyzeUrl();

    expect(backend.infoCalls, 4);
    expect(controller.extractionState, ExtractionState.failed);
    expect(controller.errorMessage, contains('TikTok'));
    expect(controller.errorMessage, contains('incomplete page'));
  });

  test('failed download waits in the queue and can be retried', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    await controller.startDownload(controller.visibleFormats.single);
    backend.emitFailed(backend.started.single.id, 'Network error.');
    await pumpEventQueue();

    final failed = controller.queue.single;
    expect(failed.status, DownloadStatus.failed);
    expect(failed.errorMessage, 'Network error.');
    expect(controller.history, isEmpty);

    await controller.retryQueueItem(failed.id);

    expect(backend.started, hasLength(2));
    expect(controller.queue.single.status, DownloadStatus.running);
    expect(controller.queue.single.errorMessage, isNull);
  });

  test('dismissing a failed queue item files it under history', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    await controller.startDownload(controller.visibleFormats.single);
    backend.emitFailed(backend.started.single.id, 'Network error.');
    await pumpEventQueue();

    await controller.cancelDownload(controller.queue.single.id);

    expect(controller.queue, isEmpty);
    final dismissed = controller.history.single;
    expect(dismissed.status, DownloadStatus.failed);
    expect(dismissed.errorMessage, 'Network error.');
  });

  test('the same URL and output cannot wait in the queue twice', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    final format = controller.visibleFormats.single;
    await controller.startDownload(format);
    await controller.startDownload(format);

    expect(controller.queue, hasLength(1));
    expect(backend.started, hasLength(1));
  });

  test('repeated failures replace the older history duplicate', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    // Fail, dismiss, retry from history, fail, and dismiss again.
    await controller.startDownload(controller.visibleFormats.single);
    backend.emitFailed(backend.started.last.id, 'boom');
    await pumpEventQueue();
    await controller.cancelDownload(controller.queue.single.id);

    await controller.retryDownload(controller.history.single);
    backend.emitFailed(backend.started.last.id, 'boom again');
    await pumpEventQueue();
    await controller.cancelDownload(controller.queue.single.id);

    expect(controller.history, hasLength(1));
    expect(controller.history.single.errorMessage, 'boom again');
  });

  test('history duplicates are dropped on restore', () async {
    final store = MemoryQueueStore();
    const format = MediaFormat(
      id: 'f',
      extension: 'mp4',
      kind: MediaKind.muxed,
      qualityLabel: 'q',
    );
    DownloadQueueItem entry(String id, {String? url}) => DownloadQueueItem(
      id: id,
      url: url ?? 'https://example.com/same',
      title: 't',
      format: format,
      outputKind: OutputKind.original,
      status: DownloadStatus.failed,
    );
    await store.save(
      QueueSnapshot(
        items: const [],
        paused: false,
        history: [
          entry('1'),
          entry('2'),
          entry('3', url: 'https://example.com/other'),
        ],
      ),
    );

    final controller = AppController(
      backend: ManualMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
      queueStore: store,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(controller.history, hasLength(2));
    expect(controller.history.first.id, '1');
  });

  test('retry all collapses duplicate history entries', () async {
    final store = MemoryQueueStore();
    const format = MediaFormat(
      id: 'f',
      extension: 'mp4',
      kind: MediaKind.muxed,
      qualityLabel: 'q',
    );
    // Two canceled entries for the same request must yield one retry.
    // (Restore dedupes failed duplicates, so use distinct statuses here.)
    await store.save(
      QueueSnapshot(
        items: const [],
        paused: false,
        history: [
          DownloadQueueItem(
            id: 'a',
            url: 'https://example.com/one',
            title: 'One',
            format: format,
            outputKind: OutputKind.original,
            status: DownloadStatus.failed,
          ),
          DownloadQueueItem(
            id: 'b',
            url: 'https://example.com/one',
            title: 'One',
            format: format,
            outputKind: OutputKind.original,
            status: DownloadStatus.canceled,
          ),
        ],
      ),
    );

    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
      queueStore: store,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.history, hasLength(2));

    await controller.retryAllHistory();

    expect(controller.queue, hasLength(1));
    expect(controller.history, isEmpty);
    expect(backend.started, hasLength(1));
  });

  test('retry all re-enqueues failed and canceled history items', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    final format = controller.visibleFormats.single;
    await controller.startDownload(format);
    controller.setOutputKind(OutputKind.mp4);
    await controller.startDownload(format);
    backend.emitFailed(backend.started.single.id, 'boom');
    await pumpEventQueue();

    // Dismiss the failed item and cancel the now-running second one.
    final failedId = controller.queue
        .firstWhere((item) => item.status == DownloadStatus.failed)
        .id;
    await controller.cancelDownload(failedId);
    await pumpEventQueue();
    final runningId = controller.queue.single.id;
    await controller.cancelDownload(runningId);
    await pumpEventQueue();

    expect(controller.history, hasLength(2));

    await controller.retryAllHistory();

    expect(controller.history, isEmpty);
    expect(controller.queue, hasLength(2));
  });

  test('completed downloads carry the saved display name', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    await controller.startDownload(controller.visibleFormats.single);
    backend.emitCompleted(
      backend.started.single.id,
      displayName: 'Manual media.mp4',
    );
    await pumpEventQueue();

    final done = controller.history.single;
    expect(done.outputDisplayName, 'Manual media.mp4');
    expect(friendlyOutputName(done), 'Manual media.mp4');
  });

  test('renaming keeps the extension and sanitizes the base name', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    await controller.startDownload(controller.visibleFormats.single);
    backend.emitCompleted(
      backend.started.single.id,
      displayName: 'Original.mp4',
    );
    await pumpEventQueue();

    final failure = await controller.renameOutput(
      controller.history.single,
      ' My: new/name ',
    );

    expect(failure, isNull);
    expect(backend.renames.single.$2, 'My_ new_name.mp4');
    expect(controller.history.single.outputDisplayName, 'My_ new_name.mp4');
    expect(
      controller.history.single.outputLocation,
      'renamed/My_ new_name.mp4',
    );
  });

  test('shared links land on Home and analyze automatically', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.receiveSharedText(
      'Check https://vm.tiktok.com/abc?utm_source=copy out',
    );
    await pumpEventQueue();

    // The link behaves like a typed one: field filled, options shown.
    expect(controller.urlText, 'https://vm.tiktok.com/abc');
    expect(controller.section, AppSection.home);
    expect(controller.extractionState, ExtractionState.loaded);
    expect(controller.mediaInfo, isNotNull);
    expect(controller.visibleFormats, isNotEmpty);
    expect(backend.infoCalls, 1);
    // Nothing downloads until the user picks a format.
    expect(controller.queue, isEmpty);
    expect(backend.started, isEmpty);
  });

  test('tuning settings reach the download request', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    await controller.setTuning(
      controller.tuning.copyWith(retries: 5, sleepRequestsSeconds: 1.5),
    );
    await controller.startDownload(controller.visibleFormats.single);

    expect(backend.started.single.tuning.retries, 5);
    expect(backend.started.single.tuning.sleepRequestsSeconds, 1.5);
  });

  test('clipboard link is offered once and can be accepted', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
      clipboardReader: () async => 'Copied https://youtu.be/clip123 today',
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await pumpEventQueue();

    expect(controller.clipboardSuggestion, 'https://youtu.be/clip123');

    controller.acceptClipboardSuggestion();
    expect(controller.clipboardSuggestion, isNull);
    expect(controller.urlText, 'https://youtu.be/clip123');
    expect(controller.section, AppSection.home);

    // The same clipboard content is not offered again.
    await controller.checkClipboardForLink();
    expect(controller.clipboardSuggestion, isNull);
  });

  test('clipboard watch can be turned off', () async {
    final backend = ManualMediaBackend();
    final controller = AppController(
      backend: backend,
      sharedUrlService: const FakeSharedUrlService(),
      settingsStore: MemoryAppSettingsStore(
        const AppSettings(clipboardWatch: false),
      ),
      clipboardReader: () async => 'https://youtu.be/clip123',
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await pumpEventQueue();

    expect(controller.clipboardSuggestion, isNull);
  });

  test('file name helpers sanitize and split correctly', () {
    expect(sanitizeFileBaseName('  a<b>:c/d  '), 'a_b_c_d');
    expect(sanitizeFileBaseName('name...'), 'name');
    expect(sanitizeFileBaseName('   '), '');

    const item = DownloadQueueItem(
      id: '1',
      url: 'https://example.com',
      title: 't',
      format: MediaFormat(
        id: 'f',
        extension: 'mp3',
        kind: MediaKind.audio,
        qualityLabel: 'q',
      ),
      outputKind: OutputKind.mp3,
      status: DownloadStatus.completed,
      outputLocation: 'content://media/123',
      outputDisplayName: 'song.mp3',
    );
    expect(outputFileExtension(item), 'mp3');
    expect(friendlyOutputName(item), 'song.mp3');

    const bare = DownloadQueueItem(
      id: '2',
      url: 'https://example.com',
      title: 't',
      format: MediaFormat(
        id: 'f',
        extension: 'mp4',
        kind: MediaKind.muxed,
        qualityLabel: 'q',
      ),
      outputKind: OutputKind.mp4,
      status: DownloadStatus.completed,
      outputLocation: 'content://media/456',
    );
    expect(friendlyOutputName(bare), 'Saved to media library');
  });

  test('canceling a waiting item does not call the backend', () async {
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend);
    addTearDown(controller.dispose);

    final format = controller.visibleFormats.single;
    await controller.startDownload(format);
    controller.setOutputKind(OutputKind.mp4);
    await controller.startDownload(format);

    final waitingId = controller.queue[1].id;
    await controller.cancelDownload(waitingId);
    await pumpEventQueue();

    expect(backend.canceled, isEmpty);
    expect(controller.queue, hasLength(1));
    expect(controller.history.single.status, DownloadStatus.canceled);
  });

  test('queue is restored from the store after a restart', () async {
    final store = MemoryQueueStore();
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend, queueStore: store);

    final format = controller.visibleFormats.single;
    await controller.startDownload(format);
    controller.setOutputKind(OutputKind.mp4);
    await controller.startDownload(format);
    expect(controller.queue, hasLength(2));
    controller.dispose();

    final restartedBackend = ManualMediaBackend();
    final restarted = AppController(
      backend: restartedBackend,
      sharedUrlService: const FakeSharedUrlService(),
      queueStore: store,
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();

    // The previously running item is re-queued and started again.
    expect(restarted.queue, hasLength(2));
    expect(restartedBackend.started, hasLength(1));
    expect(restarted.queue[0].status, DownloadStatus.running);
    expect(restarted.queue[1].status, DownloadStatus.pending);
  });

  test('paused state survives a restart', () async {
    final store = MemoryQueueStore();
    final backend = ManualMediaBackend();
    final controller = await analyzedController(backend, queueStore: store);

    await controller.pauseQueue();
    await controller.startDownload(controller.visibleFormats.single);
    controller.dispose();

    final restartedBackend = ManualMediaBackend();
    final restarted = AppController(
      backend: restartedBackend,
      sharedUrlService: const FakeSharedUrlService(),
      queueStore: store,
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();

    expect(restarted.queuePaused, isTrue);
    expect(restartedBackend.started, isEmpty);
    expect(restarted.queue.single.status, DownloadStatus.paused);
  });
}
