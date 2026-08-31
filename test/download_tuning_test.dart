import 'package:dbase_downloader/src/models/download_models.dart';
import 'package:dbase_downloader/src/services/desktop_media_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults produce the legacy retry arguments only', () {
    expect(tuningArgs(const DownloadTuning()), [
      '--retries',
      '10',
      '--fragment-retries',
      '10',
    ]);
  });

  test('sleep options appear only when enabled and consistent', () {
    expect(
      tuningArgs(
        const DownloadTuning(
          retries: 5,
          fragmentRetries: 7,
          sleepRequestsSeconds: 1.5,
          sleepIntervalSeconds: 3,
          maxSleepIntervalSeconds: 8,
        ),
      ),
      [
        '--retries',
        '5',
        '--fragment-retries',
        '7',
        '--sleep-requests',
        '1.5',
        '--sleep-interval',
        '3',
        '--max-sleep-interval',
        '8',
      ],
    );

    // A max below the min is dropped instead of producing an invalid pair.
    expect(
      tuningArgs(
        const DownloadTuning(sleepIntervalSeconds: 5, maxSleepIntervalSeconds: 2),
      ),
      containsAll(['--sleep-interval']),
    );
    expect(
      tuningArgs(
        const DownloadTuning(sleepIntervalSeconds: 5, maxSleepIntervalSeconds: 2),
      ),
      isNot(contains('--max-sleep-interval')),
    );
  });

  test('tuning serialization round-trips', () {
    const tuning = DownloadTuning(
      retries: 3,
      fragmentRetries: 4,
      sleepRequestsSeconds: 0.5,
      sleepIntervalSeconds: 2,
      maxSleepIntervalSeconds: 6,
      queueGapSeconds: 15,
    );

    final restored = DownloadTuning.fromMap(tuning.toMap());
    expect(restored.retries, 3);
    expect(restored.fragmentRetries, 4);
    expect(restored.sleepRequestsSeconds, 0.5);
    expect(restored.sleepIntervalSeconds, 2);
    expect(restored.maxSleepIntervalSeconds, 6);
    expect(restored.queueGapSeconds, 15);
  });

  test('queue item keeps display name and retry count across restore', () {
    const item = DownloadQueueItem(
      id: '42',
      url: 'https://example.com/media',
      title: 'Media title',
      format: MediaFormat(
        id: 'best_mp4',
        extension: 'mp4',
        kind: MediaKind.muxed,
        qualityLabel: '1080p',
      ),
      outputKind: OutputKind.mp4,
      status: DownloadStatus.completed,
      outputLocation: 'content://media/1',
      outputDisplayName: 'Media title.mp4',
      autoRetryCount: 2,
    );

    final restored = DownloadQueueItem.fromMap(item.toMap());
    expect(restored.outputDisplayName, 'Media title.mp4');
    expect(restored.autoRetryCount, 2);
  });
}
