import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/services/backend_factory.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DBaseDownloaderApp(
      backend: createMediaBackend(),
      sharedUrlService: createSharedUrlService(),
      queueStore: createQueueStore(),
    ),
  );
}
