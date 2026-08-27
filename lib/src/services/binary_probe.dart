import 'dart:async';
import 'dart:io';

import 'desktop_media_backend.dart';
import 'desktop_settings.dart';

/// Result of checking one external binary on the device.
class BinaryProbeResult {
  const BinaryProbeResult({required this.found, this.version});

  final bool found;
  final String? version;
}

/// Availability of the desktop engine binaries (yt-dlp and FFmpeg).
class EngineProbe {
  const EngineProbe({required this.ytDlp, required this.ffmpeg});

  final BinaryProbeResult ytDlp;
  final BinaryProbeResult ffmpeg;

  bool get allFound => ytDlp.found && ffmpeg.found;
}

/// Checks whether yt-dlp and FFmpeg are runnable on this desktop, honoring
/// the paths configured in Settings and falling back to PATH lookup —
/// the same resolution the download backend uses.
class DesktopBinaryProbe {
  DesktopBinaryProbe({Future<DesktopBackendConfig> Function()? configProvider})
    : _configProvider = configProvider ?? DesktopSettings().load;

  final Future<DesktopBackendConfig> Function() _configProvider;

  Future<EngineProbe> probe() async {
    final config = await _configProvider();
    final results = await Future.wait([
      _run(
        config.ytDlpPath ?? 'yt-dlp',
        const ['--version'],
        ytDlpVersionFromOutput,
      ),
      _run(
        _ffmpegExecutable(config.ffmpegPath),
        const ['-version'],
        ffmpegVersionFromOutput,
      ),
    ]);
    return EngineProbe(ytDlp: results[0], ffmpeg: results[1]);
  }

  /// The configured FFmpeg location may be the binary itself or a directory
  /// containing it (yt-dlp's `--ffmpeg-location` accepts both).
  String _ffmpegExecutable(String? configured) {
    if (configured == null || configured.isEmpty) {
      return 'ffmpeg';
    }
    if (FileSystemEntity.isDirectorySync(configured)) {
      final name = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
      return '$configured${Platform.pathSeparator}$name';
    }
    return configured;
  }

  Future<BinaryProbeResult> _run(
    String executable,
    List<String> arguments,
    String? Function(String output) parseVersion,
  ) async {
    try {
      final result = await Process.run(
        executable,
        arguments,
      ).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) {
        return const BinaryProbeResult(found: false);
      }
      return BinaryProbeResult(
        found: true,
        version: parseVersion('${result.stdout}'),
      );
    } catch (_) {
      return const BinaryProbeResult(found: false);
    }
  }
}

/// yt-dlp prints only the version on the first line (e.g. `2026.08.11`).
String? ytDlpVersionFromOutput(String output) {
  for (final line in output.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

/// FFmpeg prints a banner like `ffmpeg version 7.1.1-essentials ...`.
String? ffmpegVersionFromOutput(String output) {
  final match = RegExp(r'ffmpeg version (\S+)').firstMatch(output);
  return match?.group(1);
}

/// Install command for Windows (winget ships with Windows 10/11).
const windowsInstallCommand = 'winget install yt-dlp.yt-dlp Gyan.FFmpeg';

/// Picks the package-manager command matching /etc/os-release content.
/// Defaults to apt, which covers Debian/Ubuntu and their derivatives.
String linuxInstallCommand(String osRelease) {
  final lower = osRelease.toLowerCase();
  bool has(String id) =>
      RegExp('^(id|id_like)=.*\\b$id\\b', multiLine: true).hasMatch(lower);

  if (has('arch') || has('manjaro')) {
    return 'sudo pacman -S yt-dlp ffmpeg';
  }
  if (has('fedora') || has('rhel') || has('centos')) {
    return 'sudo dnf install yt-dlp ffmpeg';
  }
  if (has('suse') || has('opensuse')) {
    return 'sudo zypper install yt-dlp ffmpeg';
  }
  return 'sudo apt install yt-dlp ffmpeg';
}

/// Reads /etc/os-release to tailor the Linux install command; empty when
/// unavailable (falls back to apt).
Future<String> readOsRelease() async {
  try {
    return await File('/etc/os-release').readAsString();
  } catch (_) {
    return '';
  }
}

/// Opens a graphical software center on Linux, trying GNOME Software and
/// then KDE Discover. Returns false when neither is installed.
Future<bool> openLinuxSoftwareCenter() async {
  const launchers = [
    ['gnome-software', '--search=ffmpeg'],
    ['plasma-discover', '--search', 'ffmpeg'],
  ];
  for (final command in launchers) {
    try {
      await Process.start(
        command.first,
        command.sublist(1),
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (_) {
      // Try the next desktop environment's store.
    }
  }
  return false;
}
