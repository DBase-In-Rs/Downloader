import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/download_models.dart';
import 'media_backend.dart';
import 'shared_url_service.dart';

class AppController extends ChangeNotifier {
  AppController({required this.backend, required this.sharedUrlService}) {
    _backendSubscription = backend.events.listen(_handleBackendEvent);
    _sharedUrlSubscription = sharedUrlService.sharedTextStream.listen(
      receiveSharedText,
    );
  }

  final MediaBackend backend;
  final SharedUrlService sharedUrlService;

  late final StreamSubscription<BackendEvent> _backendSubscription;
  late final StreamSubscription<String> _sharedUrlSubscription;

  AppSection _section = AppSection.home;
  String _urlText = '';
  String? _errorMessage;
  MediaInfo? _mediaInfo;
  ExtractionState _extractionState = ExtractionState.idle;
  MediaKindFilter _formatFilter = MediaKindFilter.all;
  OutputKind _outputKind = OutputKind.mp3;
  CookieStatus _cookieStatus = const CookieStatus.empty();
  final List<DownloadQueueItem> _queue = [];
  final List<DownloadQueueItem> _history = [];

  AppSection get section => _section;

  String get urlText => _urlText;

  String? get errorMessage => _errorMessage;

  MediaInfo? get mediaInfo => _mediaInfo;

  ExtractionState get extractionState => _extractionState;

  MediaKindFilter get formatFilter => _formatFilter;

  OutputKind get outputKind => _outputKind;

  CookieStatus get cookieStatus => _cookieStatus;

  List<DownloadQueueItem> get queue => List.unmodifiable(_queue);

  List<DownloadQueueItem> get history => List.unmodifiable(_history);

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
    final sharedText = await sharedUrlService.getInitialSharedText();
    if (sharedText != null && sharedText.trim().isNotEmpty) {
      receiveSharedText(sharedText);
    } else {
      notifyListeners();
    }
  }

  void setSection(AppSection section) {
    if (_section == section) {
      return;
    }

    _section = section;
    notifyListeners();
  }

  void setUrlText(String value) {
    if (_urlText == value) {
      return;
    }

    _urlText = value;
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

    _urlText = url;
    _section = AppSection.home;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> analyzeUrl() async {
    final url = _urlText.trim();
    if (!isValidUrl(url)) {
      _errorMessage = 'Enter a valid URL.';
      _extractionState = ExtractionState.failed;
      notifyListeners();
      return;
    }

    _extractionState = ExtractionState.loading;
    _errorMessage = null;
    _mediaInfo = null;
    notifyListeners();

    try {
      _mediaInfo = await backend.getInfo(
        MediaInfoRequest(url: url, useCookies: _cookieStatus.configured),
      );
      _extractionState = ExtractionState.loaded;
    } catch (error) {
      _extractionState = ExtractionState.failed;
      _errorMessage = _friendlyError(error);
    }

    notifyListeners();
  }

  Future<void> startDownload(MediaFormat format) async {
    final info = _mediaInfo;
    if (info == null) {
      return;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = DownloadQueueItem(
      id: id,
      url: info.url,
      title: info.title,
      format: format,
      outputKind: _outputKind,
      status: DownloadStatus.pending,
    );

    _queue.insert(0, item);
    _section = AppSection.queue;
    notifyListeners();

    try {
      await backend.startDownload(
        DownloadRequest(
          id: id,
          url: info.url,
          formatId: format.id,
          outputKind: _outputKind,
          title: info.title,
        ),
      );
      _replaceQueueItem(
        id,
        (current) => current.copyWith(status: DownloadStatus.running),
      );
    } catch (error) {
      _replaceQueueItem(
        id,
        (current) => current.copyWith(
          status: DownloadStatus.failed,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  Future<void> cancelDownload(String id) {
    return backend.cancelDownload(id);
  }

  Future<void> clearCookies() async {
    await backend.clearCookies();
    _cookieStatus = await backend.getCookieStatus();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _backendSubscription.cancel();
    _sharedUrlSubscription.cancel();
    backend.dispose();
    sharedUrlService.dispose();
    super.dispose();
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
        _finishQueueItem(
          id,
          (current) => current.copyWith(
            status: DownloadStatus.failed,
            errorMessage: message,
          ),
        );
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

    final finished = update(_queue.removeAt(index));
    _history.insert(0, finished);
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is FormatException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
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
