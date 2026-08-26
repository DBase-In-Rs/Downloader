import 'package:shared_preferences/shared_preferences.dart';

import 'desktop_media_backend.dart';

/// Persists desktop backend paths: yt-dlp binary, FFmpeg location, and the
/// output directory. Values are read lazily on every backend operation, so
/// changes apply without restarting.
class DesktopSettings {
  static const _ytDlpKey = 'desktop_ytdlp_path';
  static const _ffmpegKey = 'desktop_ffmpeg_path';
  static const _outputKey = 'desktop_output_dir';

  Future<DesktopBackendConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DesktopBackendConfig(
      ytDlpPath: prefs.getString(_ytDlpKey),
      ffmpegPath: prefs.getString(_ffmpegKey),
      outputDirectory: prefs.getString(_outputKey),
    );
  }

  Future<void> setYtDlpPath(String? path) => _set(_ytDlpKey, path);

  Future<void> setFfmpegPath(String? path) => _set(_ffmpegKey, path);

  Future<void> setOutputDirectory(String? path) => _set(_outputKey, path);

  Future<void> _set(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
