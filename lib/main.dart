import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

import 'src/app.dart';
import 'src/services/backend_factory.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // media_kit powers the trim preview only on Windows/Linux. Initializing it
  // on Android would touch libmpv, which the F-Droid build intentionally does
  // not bundle, so keep it desktop-only.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    MediaKit.ensureInitialized();
  }

  runApp(
    DBaseDownloaderApp(
      backend: createMediaBackend(),
      sharedUrlService: createSharedUrlService(),
      queueStore: createQueueStore(),
      settingsStore: createAppSettingsStore(),
    ),
  );
}
