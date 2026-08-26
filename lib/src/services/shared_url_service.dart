abstract class SharedUrlService {
  Future<String?> getInitialSharedText();

  Stream<String> get sharedTextStream;

  void dispose() {}
}

class FakeSharedUrlService implements SharedUrlService {
  const FakeSharedUrlService({this.initialText});

  final String? initialText;

  @override
  Future<String?> getInitialSharedText() async {
    return initialText;
  }

  @override
  Stream<String> get sharedTextStream => const Stream.empty();

  @override
  void dispose() {}
}
