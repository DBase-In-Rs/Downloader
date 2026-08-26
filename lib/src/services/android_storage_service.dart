import 'package:flutter/services.dart';

/// Android-only access to the user-selected download folder (Storage Access
/// Framework document tree). Values are folder display labels; the persisted
/// tree URI stays on the native side.
class AndroidStorageService {
  static const _channel = MethodChannel('rs.in.dbase.downloader/downloader');

  /// Returns the current folder label, or null when the default MediaStore
  /// collections are used.
  Future<String?> getOutputFolder() async {
    try {
      return await _channel.invokeMethod<String>('getOutputFolder');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens the system folder picker. Returns the new folder label, or null
  /// when the user cancels.
  Future<String?> pickOutputFolder() {
    return _channel.invokeMethod<String>('pickOutputFolder');
  }

  Future<void> clearOutputFolder() {
    return _channel.invokeMethod<void>('clearOutputFolder');
  }
}
