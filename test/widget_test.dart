import 'package:dbase_downloader/src/app.dart';
import 'package:dbase_downloader/src/services/fake_media_backend.dart';
import 'package:dbase_downloader/src/services/shared_url_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows downloader app shell', (tester) async {
    await tester.pumpWidget(
      DBaseDownloaderApp(
        backend: FakeMediaBackend(),
        sharedUrlService: const FakeSharedUrlService(),
      ),
    );
    await tester.pump();

    expect(find.text('DBase Downloader'), findsOneWidget);
    expect(find.text('New Download'), findsOneWidget);
    expect(find.text('Media URL'), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets(
    'dismisses the splash when the startup engine update is skipped',
    (tester) async {
      // F-Droid builds never call updateEngine() on startup, so the engine
      // state stays idle; the splash must not wait for it (regression: the
      // app used to sit on the splash screen forever).
      await tester.pumpWidget(
        MaterialApp(
          home: DBaseDownloaderHome(
            backend: FakeMediaBackend(),
            sharedUrlService: const FakeSharedUrlService(),
            updateEngineOnStartup: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('New Download'), findsOneWidget);
      expect(find.text('Analyze'), findsOneWidget);
    },
  );

  testWidgets('analyzes a URL and queues a fake download', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      DBaseDownloaderApp(
        backend: FakeMediaBackend(),
        sharedUrlService: const FakeSharedUrlService(),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/watch?v=test',
    );
    await tester.tap(find.text('Analyze'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sample media preview'), findsOneWidget);
    expect(find.text('Available Formats'), findsOneWidget);
    expect(find.text('1080p - mp4'), findsOneWidget);

    final addButton = find.byTooltip('Add to queue').first;
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Queue'), findsWidgets);
    expect(find.text('Sample media preview'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('prefills shared URL text', (tester) async {
    await tester.pumpWidget(
      DBaseDownloaderApp(
        backend: FakeMediaBackend(),
        sharedUrlService: const FakeSharedUrlService(
          initialText: 'Watch this: https://youtu.be/test.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'https://youtu.be/test');

    // Shared links auto-analyze; let the fake backend finish its work.
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('shows support and about cards in Settings', (tester) async {
    await tester.pumpWidget(
      DBaseDownloaderApp(
        backend: FakeMediaBackend(),
        sharedUrlService: const FakeSharedUrlService(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Support the Developer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Support the Developer'), findsOneWidget);
    expect(find.text('Become a supporter'), findsOneWidget);
    expect(find.text('Supporter Pro'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open Source Licenses'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Open Source Licenses'), findsOneWidget);
  });
}
