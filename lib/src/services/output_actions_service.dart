import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens, reveals, and shares finished download outputs.
///
/// Android works with MediaStore/SAF content URIs (open with the default
/// player, share through the system sheet). Desktop works with file paths
/// (open with the default app, reveal in the file manager).
class OutputActionsService {
  static const _channel = MethodChannel('rs.in.dbase.downloader/downloader');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get canOpen => _isAndroid || _isDesktop;

  bool get canReveal => _isDesktop;

  bool get canShare => _isAndroid;

  /// Opens the output with the platform default app. Returns a user-facing
  /// error message, or null on success.
  Future<String?> open(String location) async {
    try {
      if (_isAndroid) {
        await _channel.invokeMethod<void>('openOutput', {'location': location});
        return null;
      }

      if (_isDesktop) {
        if (!File(location).existsSync()) {
          return 'The file no longer exists at this location.';
        }
        return await _runDesktop(switch (defaultTargetPlatform) {
          TargetPlatform.windows => (
            'rundll32',
            ['url.dll,FileProtocolHandler', location],
          ),
          TargetPlatform.macOS => ('open', [location]),
          _ => ('xdg-open', [location]),
        });
      }

      return 'Opening files is not supported on this platform.';
    } on PlatformException catch (error) {
      return error.message ?? 'Could not open the file.';
    }
  }

  /// Reveals the output in the platform file manager (desktop only).
  Future<String?> reveal(String location) async {
    if (!_isDesktop) {
      return 'Show in folder is not supported on this platform.';
    }
    if (!File(location).existsSync()) {
      return 'The file no longer exists at this location.';
    }

    return _runDesktop(switch (defaultTargetPlatform) {
      TargetPlatform.windows => ('explorer.exe', ['/select,$location']),
      TargetPlatform.macOS => ('open', ['-R', location]),
      _ => ('xdg-open', [File(location).parent.path]),
    });
  }

  /// Opens the platform share sheet for the output (Android only).
  Future<String?> share(String location) async {
    if (!_isAndroid) {
      return 'Sharing is not supported on this platform.';
    }

    try {
      await _channel.invokeMethod<void>('shareOutput', {'location': location});
      return null;
    } on PlatformException catch (error) {
      return error.message ?? 'Could not share the file.';
    }
  }

  Future<String?> _runDesktop((String, List<String>) command) async {
    try {
      final result = await Process.run(command.$1, command.$2);
      // explorer.exe reports exit code 1 even on success; treat spawn
      // success as success and rely on the file-existence check above.
      return result.exitCode == 0 || command.$1 == 'explorer.exe'
          ? null
          : 'Could not open the file manager.';
    } on ProcessException {
      return 'Could not launch the file manager.';
    }
  }
}
