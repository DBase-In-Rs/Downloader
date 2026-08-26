import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/services/app_controller.dart';
import 'package:dbase_downloader/src/services/fake_media_backend.dart';
import 'package:dbase_downloader/src/services/shared_url_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
