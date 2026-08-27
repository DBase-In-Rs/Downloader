import 'package:dbase_downloader/src/services/app_controller.dart';
import 'package:dbase_downloader/src/services/fake_media_backend.dart';
import 'package:dbase_downloader/src/services/shared_url_service.dart';
import 'package:dbase_downloader/src/services/supporter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps Polar validate responses to supporter validation', () {
    expect(
      validationFromResponse(200, {'status': 'granted'}),
      SupporterValidation.valid,
    );
    expect(
      validationFromResponse(200, {'status': 'revoked'}),
      SupporterValidation.invalid,
    );
    expect(
      validationFromResponse(200, {'status': 'disabled'}),
      SupporterValidation.invalid,
    );
    expect(validationFromResponse(200, null), SupporterValidation.invalid);
    expect(
      validationFromResponse(404, {'detail': 'not found'}),
      SupporterValidation.invalid,
    );
    expect(
      validationFromResponse(422, {'detail': 'bad request'}),
      SupporterValidation.invalid,
    );
    expect(validationFromResponse(500, null), SupporterValidation.unreachable);
    expect(validationFromResponse(503, null), SupporterValidation.unreachable);
  });

  test('activate stores the key only when validation succeeds', () async {
    final store = MemorySupporterStore();
    var remoteCalls = 0;
    var verdict = SupporterValidation.invalid;
    final service = SupporterService(
      store: store,
      validator: (key) async {
        remoteCalls++;
        return verdict;
      },
    );

    expect(await service.activate('   '), SupporterValidation.invalid);
    expect(remoteCalls, 0, reason: 'blank keys never hit the network');

    expect(await service.activate('BAD-KEY'), SupporterValidation.invalid);
    expect(await service.hasStoredKey(), isFalse);

    verdict = SupporterValidation.unreachable;
    expect(await service.activate('ANY-KEY'), SupporterValidation.unreachable);
    expect(await service.hasStoredKey(), isFalse);

    verdict = SupporterValidation.valid;
    expect(await service.activate('  GOOD-KEY  '), SupporterValidation.valid);
    expect(await service.hasStoredKey(), isTrue);
    expect(await store.readKey(), 'GOOD-KEY');

    await service.clear();
    expect(await service.hasStoredKey(), isFalse);
  });

  test('controller flips supporter flag on successful activation', () async {
    final controller = AppController(
      backend: FakeMediaBackend(),
      sharedUrlService: const FakeSharedUrlService(),
      supporterService: SupporterService(
        validator: (key) async => key == 'GOOD-KEY'
            ? SupporterValidation.valid
            : SupporterValidation.invalid,
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.isSupporter, isFalse);
    expect(
      await controller.activateSupporterKey('BAD-KEY'),
      SupporterValidation.invalid,
    );
    expect(controller.isSupporter, isFalse);
    expect(
      await controller.activateSupporterKey('GOOD-KEY'),
      SupporterValidation.valid,
    );
    expect(controller.isSupporter, isTrue);
  });
}
