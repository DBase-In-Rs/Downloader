import 'package:flutter/foundation.dart';

import 'fake_media_backend.dart';
import 'media_backend.dart';
import 'platform_media_backend.dart';
import 'platform_shared_url_service.dart';
import 'queue_store.dart';
import 'shared_url_service.dart';

MediaBackend createMediaBackend() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return PlatformMediaBackend();
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
