import 'package:dbase_downloader/src/services/binary_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses yt-dlp version output', () {
    expect(ytDlpVersionFromOutput('2026.08.11\n'), '2026.08.11');
    expect(ytDlpVersionFromOutput('\n  2026.08.11  \n'), '2026.08.11');
    expect(ytDlpVersionFromOutput(''), isNull);
  });

  test('parses ffmpeg version banner', () {
    expect(
      ffmpegVersionFromOutput(
        'ffmpeg version 7.1.1-essentials_build-www.gyan.dev '
        'Copyright (c) 2000-2025',
      ),
      '7.1.1-essentials_build-www.gyan.dev',
    );
    expect(
      ffmpegVersionFromOutput('ffmpeg version n6.1.1 Copyright'),
      'n6.1.1',
    );
    expect(ffmpegVersionFromOutput('command not found'), isNull);
  });

  test('picks the Linux install command from os-release', () {
    expect(
      linuxInstallCommand('ID=ubuntu\nID_LIKE=debian\n'),
      'sudo apt install yt-dlp ffmpeg',
    );
    expect(
      linuxInstallCommand('ID=debian\n'),
      'sudo apt install yt-dlp ffmpeg',
    );
    expect(
      linuxInstallCommand('ID=arch\n'),
      'sudo pacman -S yt-dlp ffmpeg',
    );
    expect(
      linuxInstallCommand('ID=manjaro\nID_LIKE=arch\n'),
      'sudo pacman -S yt-dlp ffmpeg',
    );
    expect(
      linuxInstallCommand('ID=fedora\n'),
      'sudo dnf install yt-dlp ffmpeg',
    );
    expect(
      linuxInstallCommand('ID=centos\nID_LIKE="rhel fedora"\n'),
      'sudo dnf install yt-dlp ffmpeg',
    );
    expect(
      linuxInstallCommand('ID=opensuse-tumbleweed\nID_LIKE="opensuse suse"\n'),
      'sudo zypper install yt-dlp ffmpeg',
    );
    // Unknown distros fall back to apt.
    expect(linuxInstallCommand(''), 'sudo apt install yt-dlp ffmpeg');
  });
}
