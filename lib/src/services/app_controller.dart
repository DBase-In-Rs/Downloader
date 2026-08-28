import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../build_flags.dart';
import '../models/download_models.dart';
import '../models/media_providers.dart';
import 'app_update_service.dart';
import 'media_backend.dart';
import 'queue_store.dart';
import 'shared_url_service.dart';

enum EngineUpdateState { idle, checking, updated, upToDate, failed }

class AppController extends ChangeNotifier {
  AppController({
    required this.backend,
    required this.sharedUrlService,
    QueueStore? queueStore,
    bool? updateEngineOnStartup,
  }) : queueStore = queueStore ?? MemoryQueueStore(),
       updateEngineOnStartup = updateEngineOnStartup ?? !kFdroidBuild {
    _backendSubscription = backend.events.listen(_handleBackendEvent);
    _sharedUrlSubscription = sharedUrlService.sharedTextStream.listen(
      receiveSharedText,
    );
  }

  final MediaBackend backend;
  final SharedUrlService sharedUrlService;
  final QueueStore queueStore;

  /// Whether initialize() refreshes yt-dlp; false in F-Droid builds, where
  /// unattended binary downloads are not allowed. The UI must not wait for
  /// an engine check that never starts.
  final bool updateEngineOnStartup;

  late final StreamSubscription<BackendEvent> _backendSubscription;
  late final StreamSubscription<String> _sharedUrlSubscription;

  AppSection _section = AppSection.home;
  String _urlText = '';
  String? _errorMessage;
  MediaInfo? _mediaInfo;
  PlaylistInfo? _playlistInfo;
  final Set<String> _selectedPlaylistUrls = {};
  ExtractionState _extractionState = ExtractionState.idle;
  MediaKindFilter _formatFilter = MediaKindFilter.all;
  OutputKind _outputKind = OutputKind.mp3;
  CookieStatus _cookieStatus = const CookieStatus.empty();
  EngineUpdateState _engineUpdateState = EngineUpdateState.idle;
  String? _engineVersion;
  String? _engineUpdateMessage;
  bool _queuePaused = false;
  int _idSequence = 0;
  String _historyQuery = '';
  String? _historyProviderFilter;
  final List<DownloadQueueItem> _queue = [];
  final List<DownloadQueueItem> _history = [];

  static const _historyLimit = 200;

  AppSection get section => _section;

  String get urlText => _urlText;

  String? get errorMessage => _errorMessage;

  MediaInfo? get mediaInfo => _mediaInfo;

  PlaylistInfo? get playlistInfo => _playlistInfo;

  Set<String> get selectedPlaylistUrls =>
      Set.unmodifiable(_selectedPlaylistUrls);

  ExtractionState get extractionState => _extractionState;

  MediaKindFilter get formatFilter => _formatFilter;

  OutputKind get outputKind => _outputKind;

  CookieStatus get cookieStatus => _cookieStatus;

  AppUpdateInfo? _availableUpdate;

  /// A newer app release on GitHub, when one exists for this platform.
  AppUpdateInfo? get availableUpdate => _availableUpdate;

  EngineUpdateState get engineUpdateState => _engineUpdateState;

  String? get engineVersion => _engineVersion;

  String? get engineUpdateMessage => _engineUpdateMessage;

  bool get queuePaused => _queuePaused;

  List<DownloadQueueItem> get queue => List.unmodifiable(_queue);

  List<DownloadQueueItem> get history => List.unmodifiable(_history);

  String get historyQuery => _historyQuery;

  String? get historyProviderFilter => _historyProviderFilter;

  MediaProviderInfo get currentProvider {
    final info = _mediaInfo;
    if (info != null) {
      return storedMediaProvider(
        providerId: info.providerId,
        providerName: info.providerName,
        url: info.url,
      );
    }

    final playlist = _playlistInfo;
    if (playlist != null) {
      return storedMediaProvider(
        providerId: playlist.providerId,
        providerName: playlist.providerName,
        url: playlist.url,
      );
    }

    return dynamicMediaProvider(url: _urlText);
  }

  List<MediaProviderInfo> get historyProviderOptions {
    final providers = <String, MediaProviderInfo>{};
    for (final item in _history) {
      final provider = storedMediaProvider(
        providerId: item.providerId,
        providerName: item.providerName,
        url: item.url,
      );
      providers[provider.id] = provider;
    }

    final values = providers.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return values;
  }

  List<DownloadQueueItem> get filteredHistory {
    final query = _historyQuery.trim().toLowerCase();
    final providerFilter = _historyProviderFilter;
    if (query.isEmpty && providerFilter == null) {
      return history;
    }

    return _history.where((item) {
      final providerId =
          item.providerId ?? storedMediaProvider(url: item.url).id;
      final providerName = providerDisplayName(
        providerId: item.providerId,
        providerName: item.providerName,
      ).toLowerCase();
      final providerMatches =
          providerFilter == null || providerId == providerFilter;
      final queryMatches =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.url.toLowerCase().contains(query) ||
          providerName.contains(query);

      return providerMatches && queryMatches;
    }).toList();
  }

  List<MediaFormat> get visibleFormats {
    final info = _mediaInfo;
    if (info == null) {
      return const [];
    }

    return info.formats.where((format) {
      return switch (_formatFilter) {
        MediaKindFilter.all => true,
        MediaKindFilter.audio => format.hasAudio && !format.hasVideo,
        MediaKindFilter.video => format.hasVideo,
      };
    }).toList();
  }

  Future<void> initialize() async {
    _cookieStatus = await backend.getCookieStatus();
    await _restoreQueue();
    final sharedText = await sharedUrlService.getInitialSharedText();
    if (sharedText != null && sharedText.trim().isNotEmpty) {
      receiveSharedText(sharedText);
    } else {
      notifyListeners();
    }
    // Keeping yt-dlp current is required for working extraction; providers
    // regularly break older releases. The native side serializes the update
    // with downloads, so this can run alongside queue startup.
    if (updateEngineOnStartup) {
      unawaited(updateEngine());
    }
    if (!kFdroidBuild) {
      unawaited(_checkForAppUpdate());
    }
    await _pumpQueue();
  }

  Future<void> _checkForAppUpdate() async {
    if (kIsWeb) {
      return;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final marker = switch (defaultTargetPlatform) {
        TargetPlatform.android => 'arm64-v8a',
        TargetPlatform.windows => 'windows-x64',
        TargetPlatform.linux => 'linux-x64',
        _ => '',
      };
      if (marker.isEmpty) {
        return;
      }

      _availableUpdate = await AppUpdateService().checkForUpdate(
        info.version,
        platformAssetMarker: marker,
      );
      if (_availableUpdate != null) {
        notifyListeners();
      }
    } catch (_) {
      // Best-effort check; unavailable in tests and offline runs.
    }
  }

  Future<void> updateEngine() async {
    if (_engineUpdateState == EngineUpdateState.checking) {
      return;
    }

    _engineUpdateState = EngineUpdateState.checking;
    _engineUpdateMessage = null;
    notifyListeners();

    try {
      final result = await backend.updateEngine();
      _engineVersion = result.version ?? _engineVersion;
      _engineUpdateState = result.updated
          ? EngineUpdateState.updated
          : EngineUpdateState.upToDate;
    } catch (error) {
      _engineUpdateState = EngineUpdateState.failed;
      _engineUpdateMessage = _friendlyError(error);
    }

    notifyListeners();
  }

  /// True when the Home screen holds anything a user may want to clear.
  bool get hasAnalysisContent =>
      _urlText.trim().isNotEmpty ||
      _mediaInfo != null ||
      _playlistInfo != null ||
      _errorMessage != null;

  /// Resets the Home screen to its initial state (URL, results, errors).
  void clearAnalysis() {
    if (!hasAnalysisContent && _extractionState == ExtractionState.idle) {
      return;
    }

    _urlText = '';
    _mediaInfo = null;
    _playlistInfo = null;
    _selectedPlaylistUrls.clear();
    _errorMessage = null;
    _extractionState = ExtractionState.idle;
    notifyListeners();
  }

  void setSection(AppSection section) {
    if (_section == section) {
      return;
    }

    _section = section;
    notifyListeners();
  }

  void setUrlText(String value) {
    final normalized = normalizeMediaUrl(value);
    if (_urlText == normalized) {
      return;
    }

    _urlText = normalized;
    if (_errorMessage != null && value.trim().isNotEmpty) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setFormatFilter(MediaKindFilter filter) {
    if (_formatFilter == filter) {
      return;
    }

    _formatFilter = filter;
    notifyListeners();
  }

  void setOutputKind(OutputKind outputKind) {
    if (_outputKind == outputKind) {
      return;
    }

    _outputKind = outputKind;
    notifyListeners();
  }

  void receiveSharedText(String text) {
    final url = extractFirstUrl(text);
    if (url == null) {
      _errorMessage = 'Shared text does not contain a URL.';
      _section = AppSection.home;
      notifyListeners();
      return;
    }

    _urlText = normalizeMediaUrl(url);
    _section = AppSection.home;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> analyzeUrl() async {
    final url = normalizeMediaUrl(_urlText);
    if (!isValidUrl(url)) {
      _errorMessage = 'Enter a valid URL.';
      _extractionState = ExtractionState.failed;
      notifyListeners();
      return;
    }

    _urlText = url;
    _extractionState = ExtractionState.loading;
    _errorMessage = null;
    _mediaInfo = null;
    _playlistInfo = null;
    _selectedPlaylistUrls.clear();
    notifyListeners();

    final request = MediaInfoRequest(
      url: url,
      useCookies: _cookieStatus.configured,
    );

    try {
      if (isLikelyPlaylistUrl(url)) {
        final playlist = await backend.getPlaylistInfo(request);
        if (playlist.entries.isEmpty) {
          // Not a real playlist; fall back to single-item analysis.
          _mediaInfo = _withResolvedProvider(await backend.getInfo(request));
          _applyProviderDefaults(currentProvider);
        } else {
          _playlistInfo = _withResolvedPlaylistProvider(playlist);
          _applyProviderDefaults(currentProvider);
          _selectedPlaylistUrls.addAll(
            playlist.entries.map((entry) => entry.url),
          );
        }
      } else {
        try {
          _mediaInfo = _withResolvedProvider(await backend.getInfo(request));
          _applyProviderDefaults(currentProvider);
        } catch (error) {
          // Pure playlist URLs (albums, channels, profiles) are not covered
          // by the URL heuristic and fail single-item extraction on any
          // provider; retry as a playlist before reporting the error.
          final playlist = await _playlistFallback(request);
          if (playlist == null || playlist.entries.isEmpty) {
            rethrow;
          }
          _playlistInfo = _withResolvedPlaylistProvider(playlist);
          _applyProviderDefaults(currentProvider);
          _selectedPlaylistUrls.addAll(
            playlist.entries.map((entry) => entry.url),
          );
        }
      }
      _extractionState = ExtractionState.loaded;
    } catch (error) {
      _extractionState = ExtractionState.failed;
      _errorMessage = _friendlyError(error, provider: currentProvider);
      unawaited(_refreshCookieStatus());
    }

    notifyListeners();
  }

  Future<PlaylistInfo?> _playlistFallback(MediaInfoRequest request) async {
    try {
      return await backend.getPlaylistInfo(request);
    } catch (_) {
      // The single-item error is the more useful one to surface.
      return null;
    }
  }

  Future<void> _refreshCookieStatus() async {
    try {
      _cookieStatus = await backend.getCookieStatus();
      notifyListeners();
    } catch (_) {
      // Keep the last known status when the backend cannot report one.
    }
  }

  void togglePlaylistEntry(PlaylistEntry entry) {
    if (!_selectedPlaylistUrls.remove(entry.url)) {
      _selectedPlaylistUrls.add(entry.url);
    }
    notifyListeners();
  }

  void setAllPlaylistEntries(bool selected) {
    _selectedPlaylistUrls.clear();
    if (selected) {
      _selectedPlaylistUrls.addAll(
        _playlistInfo?.entries.map((entry) => entry.url) ?? const [],
      );
    }
    notifyListeners();
  }

  Future<void> enqueueSelectedPlaylistEntries() async {
    final playlist = _playlistInfo;
    if (playlist == null) {
      return;
    }

    final format = presetFormatFor(_outputKind);
    for (final entry in playlist.entries) {
      if (!_selectedPlaylistUrls.contains(entry.url)) {
        continue;
      }

      await _enqueue(
        url: entry.url,
        title: entry.title,
        format: format,
        outputKind: _outputKind,
        provider: storedMediaProvider(
          providerId: playlist.providerId,
          providerName: playlist.providerName,
          url: playlist.url,
        ),
      );
    }
  }

  Future<void> startDownload(MediaFormat format) async {
    final info = _mediaInfo;
    if (info == null) {
      return;
    }

    await _enqueue(
      url: info.url,
      title: info.title,
      format: format,
      outputKind: _outputKind,
      provider: resolveMediaProvider(url: _urlText, extractor: info.extractor),
    );
  }

  Future<void> retryDownload(DownloadQueueItem source) async {
    await _enqueue(
      url: source.url,
      title: source.title,
      format: source.format,
      outputKind: source.outputKind,
      provider: storedMediaProvider(
        providerId: source.providerId,
        providerName: source.providerName,
        url: source.url,
      ),
    );
  }

  Future<void> pauseQueue() async {
    if (_queuePaused) {
      return;
    }

    _queuePaused = true;
    _setWaitingStatuses(DownloadStatus.pending, DownloadStatus.paused);
    notifyListeners();
    await _persistQueue();
  }

  Future<void> resumeQueue() async {
    if (!_queuePaused) {
      return;
    }

    _queuePaused = false;
    _setWaitingStatuses(DownloadStatus.paused, DownloadStatus.pending);
    notifyListeners();
    await _persistQueue();
    await _pumpQueue();
  }

  Future<void> cancelDownload(String id) async {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    if (_queue[index].status == DownloadStatus.running) {
      // The backend confirms with a canceled event that finishes the item.
      await backend.cancelDownload(id);
      return;
    }

    _finishQueueItem(
      id,
      (current) => current.copyWith(status: DownloadStatus.canceled),
    );
  }

  /// Imports raw `cookies.txt` content. Returns null on success or a
  /// user-facing error message on failure.
  Future<String?> importCookies(String content) async {
    if (!isValidCookiesFile(content)) {
      return 'Not a valid cookies.txt file (Netscape format expected).';
    }

    try {
      await backend.importCookies(content);
    } catch (error) {
      return _friendlyError(error);
    }

    _cookieStatus = await backend.getCookieStatus();
    notifyListeners();
    return null;
  }

  Future<void> clearCookies() async {
    await backend.clearCookies();
    _cookieStatus = await backend.getCookieStatus();
    notifyListeners();
  }

  void setHistoryQuery(String query) {
    if (_historyQuery == query) {
      return;
    }

    _historyQuery = query;
    notifyListeners();
  }

  void setHistoryProviderFilter(String? providerId) {
    if (_historyProviderFilter == providerId) {
      return;
    }

    _historyProviderFilter = providerId;
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(_persistQueue());
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    unawaited(_persistQueue());
  }

  @override
  void dispose() {
    _backendSubscription.cancel();
    _sharedUrlSubscription.cancel();
    backend.dispose();
    sharedUrlService.dispose();
    super.dispose();
  }

  Future<void> _enqueue({
    required String url,
    required String title,
    required MediaFormat format,
    required OutputKind outputKind,
    MediaProviderInfo? provider,
  }) async {
    // A timestamp alone can collide when two items are enqueued within the
    // same clock tick, so a session-local sequence keeps ids unique.
    final resolvedProvider = provider ?? dynamicMediaProvider(url: url);
    final item = DownloadQueueItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_idSequence++}',
      url: url,
      title: title,
      format: format,
      outputKind: outputKind,
      status: _queuePaused ? DownloadStatus.paused : DownloadStatus.pending,
      providerId: resolvedProvider.id,
      providerName: resolvedProvider.displayName,
    );

    _queue.add(item);
    _section = AppSection.queue;
    notifyListeners();
    await _persistQueue();
    await _pumpQueue();
  }

  Future<void> _pumpQueue() async {
    if (_queuePaused) {
      return;
    }

    if (_queue.any((item) => item.status == DownloadStatus.running)) {
      return;
    }

    final index = _queue.indexWhere(
      (item) => item.status == DownloadStatus.pending,
    );
    if (index == -1) {
      return;
    }

    final item = _queue[index].copyWith(status: DownloadStatus.running);
    _queue[index] = item;
    notifyListeners();
    await _persistQueue();

    try {
      await backend.startDownload(
        DownloadRequest(
          id: item.id,
          url: item.url,
          formatId: effectiveFormatSelector(item.format, item.outputKind),
          outputKind: item.outputKind,
          title: item.title,
        ),
      );
    } catch (error) {
      final provider = storedMediaProvider(
        providerId: item.providerId,
        providerName: item.providerName,
        url: item.url,
      );
      _finishQueueItem(
        item.id,
        (current) => current.copyWith(
          status: DownloadStatus.failed,
          errorMessage: _friendlyError(error, provider: provider),
        ),
      );
    }
  }

  Future<void> _restoreQueue() async {
    final snapshot = await queueStore.load();
    if (snapshot == null) {
      return;
    }

    _queuePaused = snapshot.paused;
    _queue
      ..clear()
      ..addAll(snapshot.items.where(_isWaitingOrRunning).map(_restoredItem));
    _history
      ..clear()
      ..addAll(snapshot.history.take(_historyLimit));
  }

  bool _isWaitingOrRunning(DownloadQueueItem item) {
    return item.status == DownloadStatus.pending ||
        item.status == DownloadStatus.paused ||
        item.status == DownloadStatus.running;
  }

  DownloadQueueItem _restoredItem(DownloadQueueItem item) {
    // Native downloads do not survive an app restart, so a persisted running
    // item is re-queued instead of restored as running.
    return item.copyWith(
      status: _queuePaused ? DownloadStatus.paused : DownloadStatus.pending,
    );
  }

  void _setWaitingStatuses(DownloadStatus from, DownloadStatus to) {
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].status == from) {
        _queue[i] = _queue[i].copyWith(status: to);
      }
    }
  }

  Future<void> _persistQueue() async {
    try {
      await queueStore.save(
        QueueSnapshot(
          items: List.of(_queue),
          paused: _queuePaused,
          history: _history.take(_historyLimit).toList(),
        ),
      );
    } catch (_) {
      // Persistence failures must not break active downloads.
    }
  }

  void _handleBackendEvent(BackendEvent event) {
    switch (event) {
      case DownloadProgressEvent(:final progress):
        _replaceQueueItem(
          progress.id,
          (current) => current.copyWith(
            status: DownloadStatus.running,
            progress: progress,
          ),
        );
      case DownloadCompletedEvent(:final id, :final outputLocation):
        _finishQueueItem(
          id,
          (current) => current.copyWith(
            status: DownloadStatus.completed,
            outputLocation: outputLocation,
          ),
        );
      case DownloadFailedEvent(:final id, :final message):
        final provider = _queueProviderFor(id);
        _finishQueueItem(
          id,
          (current) => current.copyWith(
            status: DownloadStatus.failed,
            errorMessage: _friendlyError(message, provider: provider),
          ),
        );
        unawaited(_refreshCookieStatus());
      case DownloadCanceledEvent(:final id):
        _finishQueueItem(
          id,
          (current) => current.copyWith(status: DownloadStatus.canceled),
        );
      case BackendMessageEvent(:final message):
        _errorMessage = message;
        notifyListeners();
    }
  }

  void _replaceQueueItem(
    String id,
    DownloadQueueItem Function(DownloadQueueItem current) update,
  ) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    _queue[index] = update(_queue[index]);
    notifyListeners();
  }

  void _finishQueueItem(
    String id,
    DownloadQueueItem Function(DownloadQueueItem current) update,
  ) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final finished = update(_queue.removeAt(index))
        .copyWith(finishedAt: DateTime.now());
    _history.insert(0, finished);
    if (_history.length > _historyLimit) {
      _history.removeRange(_historyLimit, _history.length);
    }
    notifyListeners();
    unawaited(_persistQueue());
    unawaited(_pumpQueue());
  }

  MediaProviderInfo? _queueProviderFor(String id) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index == -1) {
      return null;
    }

    final item = _queue[index];
    return storedMediaProvider(
      providerId: item.providerId,
      providerName: item.providerName,
      url: item.url,
    );
  }

  String _friendlyError(Object error, {MediaProviderInfo? provider}) {
    if (error is FormatException) {
      return error.message;
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = message.toLowerCase();
    final providerName = provider?.displayName ?? 'this site';

    if (lower.contains('unsupported url') ||
        lower.contains('no suitable extractor') ||
        lower.contains('no video formats found')) {
      return 'This URL is not supported by the current yt-dlp engine. Update yt-dlp in Settings, then try a public media URL from $providerName again.';
    }

    if (lower.contains('login required') ||
        lower.contains('sign in') ||
        lower.contains('cookies') ||
        lower.contains('private video') ||
        lower.contains('not a bot') ||
        lower.contains('confirm your age')) {
      final cookieHint = provider?.cookiesOftenNeeded == true
          ? '$providerName often requires account cookies for restricted media.'
          : 'This media appears to require account access.';
      return '$cookieHint Import a fresh cookies.txt file in Settings and try again.';
    }

    if (lower.contains('private') ||
        lower.contains('unavailable') ||
        lower.contains('not available')) {
      return '$providerName says this media is private, removed, or unavailable.';
    }

    if (lower.contains('geo') ||
        lower.contains('country') ||
        lower.contains('region')) {
      return '$providerName is blocking this media in the current region.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('temporarily blocked')) {
      return '$providerName is rate-limiting requests. Wait a bit, update yt-dlp if needed, then try again.';
    }

    if (lower.contains('drm') || lower.contains('protected')) {
      return '$providerName appears to use DRM or protected media. DBase does not bypass DRM.';
    }

    return message.isEmpty ? 'The media request failed.' : message;
  }

  MediaInfo _withResolvedProvider(MediaInfo info) {
    final provider = dynamicMediaProvider(
      url: _urlText,
      extractor: info.extractor,
    );
    return info.copyWith(
      providerId: info.providerId ?? provider.id,
      providerName: info.providerName ?? provider.displayName,
    );
  }

  PlaylistInfo _withResolvedPlaylistProvider(PlaylistInfo playlist) {
    final provider = dynamicMediaProvider(url: playlist.url);
    return playlist.copyWith(
      providerId: playlist.providerId ?? provider.id,
      providerName: playlist.providerName ?? provider.displayName,
    );
  }

  void _applyProviderDefaults(MediaProviderInfo provider) {
    if (!provider.audioFirst) {
      return;
    }

    if (_outputKind == OutputKind.mp4) {
      _outputKind = OutputKind.mp3;
    }
    if (_formatFilter == MediaKindFilter.video) {
      _formatFilter = MediaKindFilter.audio;
    }
  }
}

/// Builds the yt-dlp format selector for a queue item. Sites like Facebook,
/// Instagram, and YouTube serve DASH video-only streams; requesting such a
/// format alone produces a silent video, so best audio is merged in. A
/// video-only pick with an audio output falls back to the best audio stream.
String effectiveFormatSelector(MediaFormat format, OutputKind outputKind) {
  final videoOnly = format.hasVideo && !format.hasAudio;
  if (!videoOnly) {
    return format.id;
  }

  return switch (outputKind) {
    OutputKind.mp3 || OutputKind.m4a => 'bestaudio/best',
    OutputKind.mp4 ||
    OutputKind.original => '${format.id}+bestaudio/${format.id}',
  };
}

bool isValidUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

String? extractFirstUrl(String text) {
  final match = RegExp(r'https?://[^\s]+').firstMatch(text);
  if (match == null) {
    return null;
  }

  return match.group(0)?.replaceAll(RegExp(r'[),.;]+$'), '');
}

bool isLikelyPlaylistUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }

  return uri.queryParameters.containsKey('list') ||
      uri.path.contains('/playlist') ||
      uri.path.contains('/sets/');
}

/// Accepts Netscape-format cookie files: comment/blank lines plus at least
/// one cookie line with seven tab-separated fields.
bool isValidCookiesFile(String content) {
  if (content.length > 1024 * 1024) {
    return false;
  }

  return content.split('\n').any((line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      return false;
    }

    return line.split('\t').length == 7;
  });
}
