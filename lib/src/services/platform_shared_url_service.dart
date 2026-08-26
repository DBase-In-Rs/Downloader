import 'package:flutter/services.dart';

import 'shared_url_service.dart';

class PlatformSharedUrlService implements SharedUrlService {
  static const _methodChannel = MethodChannel('rs.in.dbase.downloader/share');
  static const _eventChannel = EventChannel(
    'rs.in.dbase.downloader/share_events',
  );

  @override
  Future<String?> getInitialSharedText() {
    return _methodChannel.invokeMethod<String>('getInitialSharedText');
  }

  @override
  Stream<String> get sharedTextStream {
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is String)
        .cast<String>();
  }

  @override
  void dispose() {}
}
