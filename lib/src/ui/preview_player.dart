import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';

/// Local-file preview player for the trim editor. Two implementations keep
/// the Android build free of prebuilt libmpv blobs (an F-Droid requirement):
///
/// - Android/iOS/web/macOS use [video_player] (AndroidX Media3/ExoPlayer on
///   Android - free software from Google Maven, no bundled binaries).
/// - Windows/Linux use [media_kit] with the desktop-only libmpv libs.
///
/// The factory [createTrimPreviewPlayer] picks the implementation, so the
/// trim editor never references either backend directly.
abstract class TrimPreviewPlayer {
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get playingStream;

  /// Emits a human-readable message when the backend hits a playback error
  /// (e.g. a codec the device cannot decode, such as 4K VP9 on Android).
  Stream<String> get errorStream;

  /// Opens a local file for preview. [fileLocation] is a filesystem path.
  Future<void> open(String fileLocation, {bool play = false});

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// The video surface, letterboxed (no crop). Audio-only files return an
  /// empty box.
  Widget videoView();

  Future<void> dispose();
}

TrimPreviewPlayer createTrimPreviewPlayer() {
  // Only Windows and Linux use media_kit; macOS uses video_player too, so no
  // media_kit libs are needed there either. Android never touches media_kit.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    return _MediaKitTrimPreviewPlayer();
  }
  return _VideoPlayerTrimPreviewPlayer();
}

/// media_kit-backed player for Windows/Linux desktop.
class _MediaKitTrimPreviewPlayer implements TrimPreviewPlayer {
  final mk.Player _player = mk.Player();
  // The VideoController must exist BEFORE Player.open so mpv has a video
  // output attached when the media loads; creating it lazily (on first
  // videoView build, after open) leaves the preview black while audio plays.
  // Capping to 1080p also avoids large-frame issues on some GPUs.
  late final mkv.VideoController _videoController = mkv.VideoController(
    _player,
    configuration: const mkv.VideoControllerConfiguration(
      width: 1920,
      height: 1080,
    ),
  );

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<String> get errorStream => _player.stream.error;

  @override
  Future<void> open(String fileLocation, {bool play = false}) {
    // Force the VideoController (and its texture) into existence before the
    // media loads, so mpv renders video frames instead of a black surface.
    _videoController;
    return _player.open(
      mk.Media(Uri.file(fileLocation).toString()),
      play: play,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Widget videoView() => mkv.Video(
    controller: _videoController,
    fit: BoxFit.contain,
    fill: Colors.black,
  );

  @override
  Future<void> dispose() => _player.dispose();
}

/// video_player-backed player for Android/iOS/web/macOS. Exposes stream APIs
/// on top of video_player's ValueNotifier so the editor stays backend-neutral.
class _VideoPlayerTrimPreviewPlayer implements TrimPreviewPlayer {
  VideoPlayerController? _controller;
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _error = StreamController<String>.broadcast();
  Timer? _ticker;
  Duration _lastDuration = Duration.zero;
  bool _lastPlaying = false;
  bool _errorReported = false;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration> get durationStream => _duration.stream;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<String> get errorStream => _error.stream;

  @override
  Future<void> open(String fileLocation, {bool play = false}) async {
    await _controller?.dispose();
    final controller = VideoPlayerController.file(File(fileLocation));
    _controller = controller;
    controller.addListener(_onValue);
    await controller.initialize();
    _emitDuration(controller.value.duration);
    // video_player's own position updates are coarse; a light ticker keeps
    // the scrub head and selection-stop check responsive during playback.
    _ticker = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final c = _controller;
      if (c != null && c.value.isInitialized) {
        _position.add(c.value.position);
      }
    });
    if (play) {
      await controller.play();
    }
    _position.add(controller.value.position);
  }

  void _onValue() {
    final c = _controller;
    if (c == null) {
      return;
    }
    if (c.value.hasError && !_errorReported) {
      _errorReported = true;
      _error.add(c.value.errorDescription ?? 'Playback failed.');
      return;
    }
    if (!c.value.isInitialized) {
      return;
    }
    if (c.value.duration != _lastDuration) {
      _emitDuration(c.value.duration);
    }
    if (c.value.isPlaying != _lastPlaying) {
      _lastPlaying = c.value.isPlaying;
      _playing.add(_lastPlaying);
    }
    _position.add(c.value.position);
  }

  void _emitDuration(Duration duration) {
    _lastDuration = duration;
    if (duration > Duration.zero) {
      _duration.add(duration);
    }
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> seek(Duration position) async => _controller?.seekTo(position);

  @override
  Widget videoView() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final aspect = controller.value.aspectRatio;
    return Center(
      child: AspectRatio(
        aspectRatio: aspect > 0 ? aspect : 16 / 9,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _controller?.removeListener(_onValue);
    await _controller?.dispose();
    await _position.close();
    await _duration.close();
    await _playing.close();
    await _error.close();
  }
}
