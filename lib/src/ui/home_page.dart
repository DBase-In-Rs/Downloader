import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/download_models.dart';
import '../services/app_controller.dart';
import 'common.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.controller, super.key});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.controller.urlText);
    _urlController.addListener(_handleTextChanged);
    widget.controller.addListener(_syncFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _urlController
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageSurface(
      child: ListView(
        children: [
          const SectionHeader(title: 'New Download', icon: Icons.add_link),
          const SizedBox(height: 16),
          _UrlInput(
            controller: _urlController,
            loading:
                widget.controller.extractionState == ExtractionState.loading,
            onPaste: _pasteUrl,
            onAnalyze: widget.controller.analyzeUrl,
          ),
          if (widget.controller.errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorPanel(message: widget.controller.errorMessage!),
          ],
          if (widget.controller.extractionState == ExtractionState.loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (widget.controller.mediaInfo != null) ...[
            const SizedBox(height: 18),
            _MediaInfoPanel(
              info: widget.controller.mediaInfo!,
              outputKind: widget.controller.outputKind,
              filter: widget.controller.formatFilter,
              visibleFormats: widget.controller.visibleFormats,
              onOutputKindChanged: widget.controller.setOutputKind,
              onFilterChanged: widget.controller.setFormatFilter,
              onStartDownload: widget.controller.startDownload,
            ),
          ],
          if (widget.controller.playlistInfo != null) ...[
            const SizedBox(height: 18),
            _PlaylistPanel(controller: widget.controller),
          ],
        ],
      ),
    );
  }

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      return;
    }

    widget.controller.setUrlText(text.trim());
  }

  void _handleTextChanged() {
    widget.controller.setUrlText(_urlController.text);
  }

  void _syncFromController() {
    final value = widget.controller.urlText;
    if (_urlController.text == value) {
      return;
    }

    _urlController.text = value;
    _urlController.selection = TextSelection.collapsed(offset: value.length);
  }
}

class _UrlInput extends StatelessWidget {
  const _UrlInput({
    required this.controller,
    required this.loading,
    required this.onPaste,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onPaste;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final field = TextField(
      controller: controller,
      enabled: !loading,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => loading ? null : onAnalyze(),
      decoration: InputDecoration(
        labelText: 'Media URL',
        prefixIcon: const Icon(Icons.link),
        suffixIcon: IconButton(
          tooltip: 'Paste',
          onPressed: loading ? null : onPaste,
          icon: const Icon(Icons.content_paste),
        ),
      ),
    );

    final button = FilledButton.icon(
      onPressed: loading ? null : onAnalyze,
      icon: const Icon(Icons.search),
      label: const Text('Analyze'),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: field),
          const SizedBox(width: 12),
          SizedBox(height: 56, child: button),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [field, const SizedBox(height: 10), button],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaInfoPanel extends StatelessWidget {
  const _MediaInfoPanel({
    required this.info,
    required this.outputKind,
    required this.filter,
    required this.visibleFormats,
    required this.onOutputKindChanged,
    required this.onFilterChanged,
    required this.onStartDownload,
  });

  final MediaInfo info;
  final OutputKind outputKind;
  final MediaKindFilter filter;
  final List<MediaFormat> visibleFormats;
  final ValueChanged<OutputKind> onOutputKindChanged;
  final ValueChanged<MediaKindFilter> onFilterChanged;
  final ValueChanged<MediaFormat> onStartDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MetadataItem(
                      icon: Icons.person,
                      value: info.uploader ?? 'Unknown uploader',
                    ),
                    _MetadataItem(
                      icon: Icons.schedule,
                      value: formatDuration(info.duration),
                    ),
                    _MetadataItem(
                      icon: Icons.extension,
                      value: info.extractor ?? 'Unknown extractor',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<OutputKind>(
              segments: const [
                ButtonSegment(
                  value: OutputKind.mp3,
                  icon: Icon(Icons.audiotrack),
                  label: Text('MP3'),
                ),
                ButtonSegment(
                  value: OutputKind.m4a,
                  icon: Icon(Icons.music_note),
                  label: Text('M4A'),
                ),
                ButtonSegment(
                  value: OutputKind.mp4,
                  icon: Icon(Icons.movie),
                  label: Text('MP4'),
                ),
                ButtonSegment(
                  value: OutputKind.original,
                  icon: Icon(Icons.file_present),
                  label: Text('Original'),
                ),
              ],
              selected: {outputKind},
              onSelectionChanged: (selection) =>
                  onOutputKindChanged(selection.single),
            ),
            SegmentedButton<MediaKindFilter>(
              segments: const [
                ButtonSegment(
                  value: MediaKindFilter.all,
                  icon: Icon(Icons.filter_list),
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: MediaKindFilter.audio,
                  icon: Icon(Icons.graphic_eq),
                  label: Text('Audio'),
                ),
                ButtonSegment(
                  value: MediaKindFilter.video,
                  icon: Icon(Icons.videocam),
                  label: Text('Video'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (selection) =>
                  onFilterChanged(selection.single),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Available Formats',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (visibleFormats.isEmpty)
          const EmptyState(icon: Icons.filter_alt_off, title: 'No formats')
        else
          ...visibleFormats.map(
            (format) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FormatTile(
                format: format,
                onStartDownload: () => onStartDownload(format),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaylistPanel extends StatelessWidget {
  const _PlaylistPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final playlist = controller.playlistInfo!;
    final selected = controller.selectedPlaylistUrls;
    final allSelected = selected.length == playlist.entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('${playlist.entries.length} items'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<OutputKind>(
              segments: const [
                ButtonSegment(value: OutputKind.mp3, label: Text('MP3')),
                ButtonSegment(value: OutputKind.m4a, label: Text('M4A')),
                ButtonSegment(value: OutputKind.mp4, label: Text('MP4')),
                ButtonSegment(
                  value: OutputKind.original,
                  label: Text('Original'),
                ),
              ],
              selected: {controller.outputKind},
              onSelectionChanged: (selection) =>
                  controller.setOutputKind(selection.single),
            ),
            TextButton.icon(
              onPressed: () => controller.setAllPlaylistEntries(!allSelected),
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              label: Text(allSelected ? 'Select none' : 'Select all'),
            ),
            FilledButton.icon(
              onPressed: selected.isEmpty
                  ? null
                  : controller.enqueueSelectedPlaylistEntries,
              icon: const Icon(Icons.playlist_add),
              label: Text('Add ${selected.length} to queue'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...playlist.entries.map(
          (entry) => Card(
            child: CheckboxListTile(
              value: selected.contains(entry.url),
              onChanged: (_) => controller.togglePlaylistEntry(entry),
              title: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${formatDuration(entry.duration)}'
                '${entry.uploader != null ? ' - ${entry.uploader}' : ''}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(value)],
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({required this.format, required this.onStartDownload});

  final MediaFormat format;
  final VoidCallback onStartDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(_formatIcon(format.kind)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${format.qualityLabel} - ${format.extension}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(mediaKindLabel(format.kind)),
                      Text(format.codec ?? 'Unknown codec'),
                      Text(formatBytes(format.filesizeBytes)),
                      if (format.note != null) Text(format.note!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              tooltip: 'Add to queue',
              onPressed: onStartDownload,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  IconData _formatIcon(MediaKind kind) {
    return switch (kind) {
      MediaKind.audio => Icons.audiotrack,
      MediaKind.video => Icons.videocam,
      MediaKind.muxed => Icons.movie,
      MediaKind.unknown => Icons.insert_drive_file,
    };
  }
}
