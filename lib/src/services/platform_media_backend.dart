import 'package:flutter/services.dart';

import '../models/download_models.dart';
import 'media_backend.dart';

class PlatformMediaBackend implements MediaBackend {
  static const _methodChannel = MethodChannel(
    'rs.in.dbase.downloader/downloader',
  );
  static const _eventChannel = EventChannel('rs.in.dbase.downloader/events');

  @override
  Stream<BackendEvent> get events {
    return _eventChannel.receiveBroadcastStream().map(_eventFromPlatform);
  }

  @override
  Future<MediaInfo> getInfo(MediaInfoRequest request) async {
    final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'getInfo',
      request.toMap(),
    );

    if (result == null) {
      throw StateError('Native backend returned no media info.');
    }

    return MediaInfo.fromMap(result);
  }

  @override
  Future<PlaylistInfo> getPlaylistInfo(MediaInfoRequest request) async {
    final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'getPlaylistInfo',
      request.toMap(),
    );

    if (result == null) {
      throw StateError('Native backend returned no playlist info.');
    }

    return PlaylistInfo.fromMap(result);
  }

  @override
  Future<void> startDownload(DownloadRequest request) {
    return _methodChannel.invokeMethod<void>('startDownload', request.toMap());
  }

  @override
  Future<void> cancelDownload(String id) {
    return _methodChannel.invokeMethod<void>('cancelDownload', {'id': id});
  }

  @override
  Future<EngineUpdateResult> updateEngine() async {
    final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'updateEngine',
    );

    return result == null
        ? const EngineUpdateResult(updated: false)
        : EngineUpdateResult.fromMap(result);
  }

  @override
  Future<CookieStatus> getCookieStatus() async {
    final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'getCookieStatus',
    );

    return result == null
        ? const CookieStatus.empty()
        : CookieStatus.fromMap(result);
  }

  @override
  Future<void> importCookies(String content) {
    return _methodChannel.invokeMethod<void>('importCookies', {
      'content': content,
    });
  }

  @override
  Future<void> clearCookies() {
    return _methodChannel.invokeMethod<void>('clearCookies');
  }

  @override
  Future<RenamedOutput> renameOutput(
    String location,
    String newDisplayName,
  ) async {
    final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'renameOutput',
      {'location': location, 'newName': newDisplayName},
    );

    if (result == null) {
      throw StateError('Native backend returned no rename result.');
    }

    return RenamedOutput.fromMap(result);
  }

  @override
  Future<Uint8List?> loadOutputThumbnail(String location, {int size = 256}) {
    return _methodChannel.invokeMethod<Uint8List>('getOutputThumbnail', {
      'location': location,
      'size': size,
    });
  }

  @override
  Future<Uint8List> readOutputBytes(
    String location, {
    required int maxBytes,
  }) async {
    final bytes = await _methodChannel.invokeMethod<Uint8List>(
      'readOutputBytes',
      {'location': location, 'maxBytes': maxBytes},
    );

    if (bytes == null) {
      throw StateError('Native backend returned no file content.');
    }

    return bytes;
  }

  @override
  Future<void> writeOutputBytes(String location, Uint8List bytes) {
    return _methodChannel.invokeMethod<void>('writeOutputBytes', {
      'location': location,
      'bytes': bytes,
    });
  }

  @override
  void dispose() {}

  BackendEvent _eventFromPlatform(Object? payload) {
    if (payload is! Map) {
      return const BackendMessageEvent('Unknown native event.');
    }

    final map = Map<Object?, Object?>.from(payload);
    final type = stringValue(map['type']);

    return switch (type) {
      'progress' => DownloadProgressEvent(DownloadProgress.fromMap(map)),
      'completed' => DownloadCompletedEvent(
        id: stringValue(map['id']) ?? '',
        outputLocation: stringValue(map['outputLocation']) ?? '',
        outputDisplayName: stringValue(map['outputDisplayName']),
      ),
      'failed' => DownloadFailedEvent(
        id: stringValue(map['id']) ?? '',
        message: stringValue(map['message']) ?? 'Download failed.',
      ),
      'canceled' => DownloadCanceledEvent(stringValue(map['id']) ?? ''),
      'message' => BackendMessageEvent(stringValue(map['message']) ?? ''),
      _ => BackendMessageEvent('Unhandled native event: ${type ?? 'unknown'}'),
    };
  }
}
