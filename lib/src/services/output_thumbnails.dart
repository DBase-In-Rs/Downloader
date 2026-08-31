import 'dart:typed_data';

import '../models/download_models.dart';
import 'media_backend.dart';

/// Session-wide cache of output thumbnails so list rebuilds do not hit the
/// platform again; failures are cached as null (icon fallback).
class OutputThumbnails {
  static final _cache = <String, Future<Uint8List?>>{};

  static Future<Uint8List?>? of(MediaBackend backend, DownloadQueueItem item) {
    final location = item.outputLocation;
    if (location == null || item.status != DownloadStatus.completed) {
      return null;
    }

    return _cache.putIfAbsent(
      location,
      () => backend
          .loadOutputThumbnail(location)
          .catchError((Object _) => null),
    );
  }

  /// Drops a cached entry, e.g. after the underlying file was renamed.
  static void evict(String location) {
    _cache.remove(location);
  }
}
