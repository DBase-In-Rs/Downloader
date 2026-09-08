import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/download_models.dart';
import '../services/app_controller.dart';
import 'preview_player.dart';

class TrimEditorPage extends StatefulWidget {
  const TrimEditorPage({
    required this.controller,
    required this.item,
    super.key,
  });

  final AppController controller;
  final DownloadQueueItem item;

  @override
  State<TrimEditorPage> createState() => _TrimEditorPageState();
}

class _TrimEditorPageState extends State<TrimEditorPage> {
  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _startFocusNode = FocusNode();
  final _endFocusNode = FocusNode();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  TrimPreviewPlayer? _player;
  bool _hasVideo = false;

  /// Live video/audio playback is available. False when the device cannot
  /// decode this format (e.g. 4K VP9 on Android) - trimming still works.
  bool _playbackReady = false;

  /// The video decoded but is unsupported, so only the waveform + time fields
  /// are shown for trimming.
  bool _videoUnavailable = false;
  bool _cinema = false;
  Future<Uint8List?>? _waveform;
  EditableOutput? _output;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _start = Duration.zero;
  Duration _end = Duration.zero;
  var _playing = false;
  var _selectionMode = false;
  var _loopSelection = false;
  var _saving = false;
  String? _error;
  String? _startInputError;
  String? _endInputError;

  static const _skipStep = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _syncTimeControllers(force: true);
    _startFocusNode.addListener(() {
      if (!_startFocusNode.hasFocus) {
        _applyStartText();
      }
    });
    _endFocusNode.addListener(() {
      if (!_endFocusNode.hasFocus) {
        _applyEndText();
      }
    });
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      final output = await widget.controller.prepareOutputForEditing(
        widget.item,
      );
      if (!mounted) {
        await widget.controller.releaseEditableOutput(output);
        return;
      }

      final player = createTrimPreviewPlayer();
      _subscriptions
        ..add(
          player.positionStream.listen((position) {
            if (!mounted) {
              return;
            }
            _handlePosition(position);
          }),
        )
        ..add(
          player.durationStream.listen((duration) {
            if (!mounted || duration <= Duration.zero) {
              return;
            }
            setState(() {
              _duration = duration;
              if (_end <= Duration.zero || _end > duration) {
                _end = duration;
              }
            });
            _syncTimeControllers();
          }),
        )
        ..add(
          player.playingStream.listen((playing) {
            if (mounted) {
              setState(() => _playing = playing);
            }
          }),
        )
        ..add(
          player.errorStream.listen((_) {
            // A decode error (e.g. 4K VP9 the device can't handle) leaves the
            // editor usable for trimming via the waveform and time fields.
            if (mounted) {
              setState(() {
                _videoUnavailable = _hasVideo;
                _playbackReady = false;
              });
            }
          }),
        );

      final duration = output.duration;
      _nameController.text = '${_baseName(output.displayName)} clip';
      setState(() {
        _output = output;
        _player = player;
        _hasVideo = output.hasVideo;
        _duration = duration;
        _end = duration;
        _waveform = widget.controller.loadOutputWaveform(output);
      });
      _syncTimeControllers(force: true);

      try {
        await player.open(output.previewLocation, play: false);
        if (mounted) {
          setState(() => _playbackReady = true);
        }
      } catch (error) {
        // Preparing/probing succeeded, so keep the editor open for trimming
        // even when this device cannot decode the media for live preview.
        if (mounted) {
          setState(() {
            _videoUnavailable = _hasVideo;
            _playbackReady = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyError(error));
      }
    }
  }

  void _handlePosition(Duration position) {
    if (_selectionMode && _end > _start && position >= _end) {
      if (_loopSelection) {
        unawaited(_player?.seek(_start).then((_) => _player?.play()));
      } else {
        unawaited(_player?.pause());
        unawaited(_player?.seek(_start));
        setState(() {
          _selectionMode = false;
          _loopSelection = false;
          _position = _start;
        });
      }
      return;
    }

    setState(() => _position = _clampDuration(position));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final player = _player;
    if (player != null) {
      unawaited(player.dispose());
    }
    final output = _output;
    if (output != null) {
      unawaited(widget.controller.releaseEditableOutput(output));
    }
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  bool get _canPlay => _playbackReady && !_videoUnavailable && _player != null;

  @override
  Widget build(BuildContext context) {
    final output = _output;

    if (_cinema && output != null && _canPlay && output.hasVideo) {
      return _cinemaScaffold(output);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim media'),
        actions: [
          if (widget.controller.canSetAsRingtone(widget.item))
            IconButton(
              tooltip: 'Set as ringtone',
              onPressed: _setOriginalAsRingtone,
              icon: const Icon(Icons.ring_volume),
            ),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? _EditorMessage(icon: Icons.error_outline, text: _error!)
            : output == null
            ? const _EditorMessage(
                icon: Icons.hourglass_empty,
                text: 'Preparing media...',
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  if (wide) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _preview(output, expand: true),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: SingleChildScrollView(
                              child: _controls(output),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _preview(output, expand: false),
                      const SizedBox(height: 16),
                      _controls(output),
                    ],
                  );
                },
              ),
      ),
    );
  }

  /// [expand] true lets the video fill remaining height (wide layout, a
  /// bounded Column); false gives it a fixed height (narrow scrolling layout).
  Widget _preview(EditableOutput output, {required bool expand}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (output.hasVideo) ...[
          if (expand)
            Expanded(child: _videoBox())
          else
            SizedBox(height: 240, child: _videoBox()),
          const SizedBox(height: 14),
        ],
        _WaveformTimeline(
          waveform: output.hasAudio ? _waveform : null,
          position: _position,
          start: _start,
          end: _end,
          duration: _duration,
          onChanged: _setSelection,
          onSeek: _seekToFraction,
        ),
      ],
    );
  }

  Widget _videoBox() {
    final player = _player;
    Widget child;
    if (_videoUnavailable) {
      child = const _EditorMessage(
        icon: Icons.videocam_off_outlined,
        text:
            "Live video preview isn't available for this format on this "
            'device (e.g. 4K VP9). You can still trim using the waveform and '
            'the start/end time fields below.',
        dark: true,
      );
    } else if (player == null || !_playbackReady) {
      child = const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: [
          player.videoView(),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              tooltip: 'Cinema mode',
              onPressed: () => setState(() => _cinema = true),
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(color: Colors.black, child: child),
    );
  }

  Widget _cinemaScaffold(EditableOutput output) {
    final player = _player!;
    final percent = _duration > Duration.zero
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          player.videoView(),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: 'Exit cinema mode',
                onPressed: () => setState(() => _cinema = false),
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _seek(_position - _skipStep),
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: _togglePlayAll,
                      icon: Icon(
                        _playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _seek(_position + _skipStep),
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: percent.toDouble(),
                        onChanged: (value) => _seekToFraction(value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        formatPreciseDuration(_position),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(EditableOutput output) {
    final selectionDuration = _end > _start ? _end - _start : Duration.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _canPlay ? _togglePlayAll : null,
              icon: Icon(
                _playing && !_selectionMode ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(_playing && !_selectionMode ? 'Pause' : 'Play all'),
            ),
            OutlinedButton.icon(
              onPressed: _canPlay ? _playSelection : null,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Play selection'),
            ),
            OutlinedButton.icon(
              onPressed: _canPlay ? _toggleLoopSelection : null,
              icon: Icon(_loopSelection ? Icons.repeat_on : Icons.repeat),
              label: Text(_loopSelection ? 'Looping' : 'Loop selection'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            IconButton.filledTonal(
              tooltip: 'Back 10s',
              onPressed: _canPlay ? () => _seek(_position - _skipStep) : null,
              icon: const Icon(Icons.replay_10),
            ),
            IconButton.filledTonal(
              tooltip: 'Forward 10s',
              onPressed: _canPlay ? () => _seek(_position + _skipStep) : null,
              icon: const Icon(Icons.forward_10),
            ),
            IconButton.filledTonal(
              tooltip: 'Jump to start',
              onPressed: _canPlay ? () => _seek(_start) : null,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filledTonal(
              tooltip: 'Jump to end',
              onPressed: _canPlay ? () => _seek(_end) : null,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _setStartFromPosition,
              icon: const Icon(Icons.first_page),
              label: const Text('Set start'),
            ),
            OutlinedButton.icon(
              onPressed: _setEndFromPosition,
              icon: const Icon(Icons.last_page),
              label: const Text('Set end'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TimeReadout(
          position: _position,
          duration: selectionDuration,
          startController: _startController,
          endController: _endController,
          startFocusNode: _startFocusNode,
          endFocusNode: _endFocusNode,
          startError: _startInputError,
          endError: _endInputError,
          onStartSubmitted: (_) => _applyStartText(),
          onEndSubmitted: (_) => _applyEndText(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Save as',
            prefixIcon: Icon(Icons.drive_file_rename_outline),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        if (_saving)
          _SaveProgress(progress: widget.controller.trimProgress)
        else
          FilledButton.icon(
            onPressed: _saveTrim,
            icon: const Icon(Icons.save),
            label: const Text('Save clip'),
          ),
      ],
    );
  }

  Future<void> _togglePlayAll() async {
    final player = _player;
    if (player == null) {
      return;
    }
    if (_playing && !_selectionMode) {
      await player.pause();
      return;
    }

    setState(() {
      _selectionMode = false;
      _loopSelection = false;
    });
    if (_position >= _duration && _duration > Duration.zero) {
      await player.seek(Duration.zero);
    }
    await player.play();
  }

  Future<void> _playSelection() async {
    await _startSelectionPlayback(loop: false);
  }

  Future<void> _toggleLoopSelection() async {
    if (_loopSelection) {
      setState(() {
        _selectionMode = false;
        _loopSelection = false;
      });
      await _player?.pause();
      return;
    }

    await _startSelectionPlayback(loop: true);
  }

  Future<void> _startSelectionPlayback({required bool loop}) async {
    final player = _player;
    if (player == null || _end <= _start) {
      return;
    }

    setState(() {
      _selectionMode = true;
      _loopSelection = loop;
    });
    await player.seek(_start);
    await player.play();
  }

  void _setStartFromPosition() {
    final next = _clampDuration(_position);
    setState(() {
      _start = next >= _end ? _end - _minimumSelection : next;
      _start = _clampDuration(_start);
      _startInputError = null;
    });
    _syncTimeControllers(force: true);
  }

  void _setEndFromPosition() {
    final next = _clampDuration(_position);
    setState(() {
      _end = next <= _start ? _start + _minimumSelection : next;
      _end = _clampDuration(_end);
      _endInputError = null;
    });
    _syncTimeControllers(force: true);
  }

  void _setSelection(Duration start, Duration end) {
    setState(() {
      _start = _clampDuration(start);
      _end = _clampDuration(end);
      if (_end <= _start) {
        _end = _clampDuration(_start + _minimumSelection);
      }
      _startInputError = null;
      _endInputError = null;
    });
    _syncTimeControllers();
  }

  Future<void> _seek(Duration position) async {
    final clamped = _clampDuration(position);
    setState(() => _position = clamped);
    await _player?.seek(clamped);
  }

  Future<void> _seekToFraction(double fraction) async {
    if (_duration <= Duration.zero) {
      return;
    }
    await _seek(
      Duration(
        microseconds: (_duration.inMicroseconds * fraction.clamp(0.0, 1.0))
            .round(),
      ),
    );
  }

  Future<void> _saveTrim() async {
    final output = _output;
    if (output == null || _saving) {
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final failure = await widget.controller.saveTrimmedOutput(
      source: widget.item,
      editable: output,
      start: _start,
      end: _end,
      outputBaseName: _nameController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(failure ?? 'Clip saved.')));
  }

  Future<void> _setOriginalAsRingtone() async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await widget.controller.setAsRingtone(widget.item);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(failure ?? 'Ringtone set.')));
  }

  Duration _clampDuration(Duration value) {
    if (value < Duration.zero) {
      return Duration.zero;
    }
    if (_duration > Duration.zero && value > _duration) {
      return _duration;
    }
    return value;
  }

  void _applyStartText() {
    final parsed = _parseTimeInput(_startController.text);
    if (parsed == null) {
      setState(() => _startInputError = 'Use hh:mm:ss.mmm');
      return;
    }

    setState(() {
      final clamped = _clampDuration(parsed);
      _start = clamped >= _end
          ? _clampDuration(_end - _minimumSelection)
          : clamped;
      _startInputError = null;
    });
    _syncTimeControllers(force: true);
  }

  void _applyEndText() {
    final parsed = _parseTimeInput(_endController.text);
    if (parsed == null) {
      setState(() => _endInputError = 'Use hh:mm:ss.mmm');
      return;
    }

    setState(() {
      final clamped = _clampDuration(parsed);
      _end = clamped <= _start
          ? _clampDuration(_start + _minimumSelection)
          : clamped;
      _endInputError = null;
    });
    _syncTimeControllers(force: true);
  }

  void _syncTimeControllers({bool force = false}) {
    if (force || !_startFocusNode.hasFocus) {
      _startController.text = formatPreciseDuration(_start);
    }
    if (force || !_endFocusNode.hasFocus) {
      _endController.text = formatPreciseDuration(_end);
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  static const _minimumSelection = Duration(milliseconds: 10);
}

class _WaveformTimeline extends StatelessWidget {
  const _WaveformTimeline({
    required this.position,
    required this.start,
    required this.end,
    required this.duration,
    this.waveform,
    required this.onChanged,
    required this.onSeek,
  });

  final Future<Uint8List?>? waveform;
  final Duration position;
  final Duration start;
  final Duration end;
  final Duration duration;
  final void Function(Duration start, Duration end) onChanged;
  final Future<void> Function(double fraction) onSeek;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds / 1000;
    final startSeconds = _seconds(start).clamp(0.0, maxSeconds);
    final endSeconds = _seconds(end).clamp(startSeconds, maxSeconds);

    return Column(
      children: [
        GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            final width = box?.size.width ?? 1;
            unawaited(onSeek(details.localPosition.dx / width));
          },
          child: SizedBox(
            height: 118,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<Uint8List?>(
                      future: waveform,
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;
                        if (bytes != null && bytes.isNotEmpty) {
                          return Image.memory(bytes, fit: BoxFit.fill);
                        }
                        return CustomPaint(
                          painter: _FallbackWavePainter(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                    CustomPaint(
                      painter: _SelectionPainter(
                        position: _fraction(position, duration),
                        start: _fraction(start, duration),
                        end: _fraction(end, duration),
                        colors: Theme.of(context).colorScheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        RangeSlider(
          min: 0,
          max: maxSeconds,
          values: RangeValues(startSeconds, endSeconds),
          onChanged: (values) {
            onChanged(
              Duration(milliseconds: (values.start * 1000).round()),
              Duration(milliseconds: (values.end * 1000).round()),
            );
          },
        ),
      ],
    );
  }

  static double _seconds(Duration value) => value.inMilliseconds / 1000;

  static double _fraction(Duration value, Duration duration) {
    if (duration <= Duration.zero) {
      return 0;
    }
    return (value.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
  }
}

class _TimeReadout extends StatelessWidget {
  const _TimeReadout({
    required this.position,
    required this.duration,
    required this.startController,
    required this.endController,
    required this.startFocusNode,
    required this.endFocusNode,
    required this.onStartSubmitted,
    required this.onEndSubmitted,
    this.startError,
    this.endError,
  });

  final Duration position;
  final Duration duration;
  final TextEditingController startController;
  final TextEditingController endController;
  final FocusNode startFocusNode;
  final FocusNode endFocusNode;
  final ValueChanged<String> onStartSubmitted;
  final ValueChanged<String> onEndSubmitted;
  final String? startError;
  final String? endError;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _Metric(
              label: 'Position',
              value: formatPreciseDuration(position),
              style: style,
            ),
            _Metric(
              label: 'Selected',
              value: formatPreciseDuration(duration),
              style: style,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Start',
                controller: startController,
                focusNode: startFocusNode,
                errorText: startError,
                onSubmitted: onStartSubmitted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeField(
                label: 'End',
                controller: endController,
                focusNode: endFocusNode,
                errorText: endError,
                onSubmitted: onEndSubmitted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: '00:00:00.000',
        errorText: errorText,
        isDense: true,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.style,
  });

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $value', style: style),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FallbackWavePainter extends CustomPainter {
  const _FallbackWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    final center = size.height / 2;
    const bars = 96;
    for (var i = 0; i < bars; i++) {
      final x = size.width * (i + 0.5) / bars;
      final normalized = ((i * 37) % 79) / 79;
      final height = size.height * (0.16 + normalized * 0.68);
      canvas.drawLine(
        Offset(x, center - height / 2),
        Offset(x, center + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FallbackWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.position,
    required this.start,
    required this.end,
    required this.colors,
  });

  final double position;
  final double start;
  final double end;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final selected = Rect.fromLTRB(
      size.width * start,
      0,
      size.width * end,
      size.height,
    );
    final dimPaint = Paint()..color = colors.surface.withValues(alpha: 0.58);
    canvas.drawRect(Rect.fromLTRB(0, 0, selected.left, size.height), dimPaint);
    canvas.drawRect(
      Rect.fromLTRB(selected.right, 0, size.width, size.height),
      dimPaint,
    );

    final handlePaint = Paint()
      ..color = colors.secondary
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(selected.left, 0),
      Offset(selected.left, size.height),
      handlePaint,
    );
    canvas.drawLine(
      Offset(selected.right, 0),
      Offset(selected.right, size.height),
      handlePaint,
    );

    final positionPaint = Paint()
      ..color = colors.error
      ..strokeWidth = 2;
    final x = size.width * position;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), positionPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.colors != colors;
  }
}

class _EditorMessage extends StatelessWidget {
  const _EditorMessage({
    required this.icon,
    required this.text,
    this.dark = false,
  });

  final IconData icon;
  final String text;

  /// Rendered on a black video box, so use light-on-dark colors.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark
        ? Colors.white70
        : Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: dark ? const TextStyle(color: Colors.white70) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Save-in-progress control showing the ffmpeg encode percentage (or an
/// indeterminate bar until the encoder reports a position).
class _SaveProgress extends StatelessWidget {
  const _SaveProgress({required this.progress});

  final ValueListenable<double?> progress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: progress,
      builder: (context, value, _) {
        final label = value == null
            ? 'Processing...'
            : 'Processing ${(value * 100).clamp(0, 100).toStringAsFixed(0)}%';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(label),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value, minHeight: 6),
            ),
          ],
        );
      },
    );
  }
}

String _baseName(String displayName) {
  final dot = displayName.lastIndexOf('.');
  return dot <= 0 ? displayName : displayName.substring(0, dot);
}

String formatPreciseDuration(Duration duration) {
  final value = duration.isNegative ? -duration : duration;
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  final milliseconds = value.inMilliseconds
      .remainder(1000)
      .toString()
      .padLeft(3, '0');
  final sign = duration.isNegative ? '-' : '';
  return '$sign$hours:$minutes:$seconds.$milliseconds';
}

Duration? _parseTimeInput(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }

  final parts = normalized.split(':');
  if (parts.length > 3 || parts.any((part) => part.isEmpty)) {
    return null;
  }

  final secondsParts = parts.last.split('.');
  if (secondsParts.length > 2 ||
      secondsParts.first.isEmpty ||
      secondsParts.first.contains(RegExp(r'\D'))) {
    return null;
  }

  final wholeSeconds = int.tryParse(secondsParts.first);
  if (wholeSeconds == null || wholeSeconds < 0) {
    return null;
  }
  if (parts.length > 1 && wholeSeconds > 59) {
    return null;
  }

  var milliseconds = 0;
  if (secondsParts.length == 2) {
    final fraction = secondsParts.last;
    if (fraction.isEmpty ||
        fraction.length > 3 ||
        fraction.contains(RegExp(r'\D'))) {
      return null;
    }
    milliseconds = int.parse(fraction.padRight(3, '0'));
  }

  var hours = 0;
  var minutes = 0;
  if (parts.length == 3) {
    hours = int.tryParse(parts[0]) ?? -1;
    minutes = int.tryParse(parts[1]) ?? -1;
    if (hours < 0 || minutes < 0 || minutes > 59) {
      return null;
    }
  } else if (parts.length == 2) {
    minutes = int.tryParse(parts[0]) ?? -1;
    if (minutes < 0) {
      return null;
    }
  }

  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: wholeSeconds,
    milliseconds: milliseconds,
  );
}
