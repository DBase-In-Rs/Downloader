import 'package:flutter/foundation.dart';

import 'desktop_media_backend.dart';
import 'desktop_settings.dart';
import 'fake_media_backend.dart';
import 'media_backend.dart';
import 'platform_media_backend.dart';
import 'platform_shared_url_service.dart';
import 'queue_store.dart';
import 'shared_url_service.dart';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

MediaBackend createMediaBackend() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return PlatformMediaBackend();
  }

  if (_isDesktop) {
    return DesktopMediaBackend(configProvider: DesktopSettings().load);
  }

  return FakeMediaBackend();
}

SharedUrlService createSharedUrlService() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return PlatformSharedUrlService();
  }

  return const FakeSharedUrlService();
}

QueueStore createQueueStore() {
  if (kIsWeb) {
    return MemoryQueueStore();
  }

  return SharedPreferencesQueueStore();
}
