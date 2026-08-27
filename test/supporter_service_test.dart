import 'package:dbase_downloader/src/services/app_controller.dart';
import 'package:dbase_downloader/src/services/fake_media_backend.dart';
import 'package:dbase_downloader/src/services/shared_url_service.dart';
import 'package:dbase_downloader/src/services/supporter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supporter flag round-trips through the store', () async {
    final service = SupporterService(store: MemorySupporterStore());

    expect(await service.isSupporter(), isFalse);
    await service.setSupporter(true);
    expect(await service.isSupporter(), isTrue);
    await service.setSupporter(false);
    expect(await service.isSupporter(), isFalse);
  });

  test('controller flips the supporter heart and persists it', () async {
    final store = MemorySupporterStore();
    final controller = AppController(
      backend: FakeMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
      supporterService: SupporterService(store: store),
    );
    addTearDown(controller.dispose);

    expect(controller.isSupporter, isFalse);
    await controller.setSupporter(true);
    expect(controller.isSupporter, isTrue);
    expect(await store.readSupporter(), isTrue);

    // A restart restores the heart from the store.
    final restarted = AppController(
      backend: FakeMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
      supporterService: SupporterService(store: store),
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();
    expect(restarted.isSupporter, isTrue);
  });
}
