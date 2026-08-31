import 'package:flutter/material.dart';

import '../models/download_models.dart';
import '../services/app_controller.dart';
import '../services/id3_tags.dart';
import '../services/output_actions_service.dart';
import '../services/output_thumbnails.dart';
import 'common.dart';

class HistoryPage extends StatelessWidget {
  HistoryPage({required this.controller, super.key});

  final AppController controller;
  final _outputActions = OutputActionsService();

  @override
  Widget build(BuildContext context) {
    final history = controller.filteredHistory;
    final hasRetryable = history.any(
      (item) =>
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.canceled,
    );

    return PageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'History',
            icon: Icons.history,
            trailing: controller.history.isEmpty
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasRetryable)
                        IconButton(
                          tooltip: 'Retry all failed in this view',
                          onPressed: controller.retryAllHistory,
                          icon: const Icon(Icons.restart_alt),
                        ),
                      IconButton(
                        tooltip: 'Clear history',
                        onPressed: controller.clearHistory,
                        icon: const Icon(Icons.delete_sweep),
                      ),
                    ],
                  ),
          ),
          if (controller.history.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: controller.setHistoryQuery,
              decoration: const InputDecoration(
                labelText: 'Search history',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            _ProviderFilter(controller: controller),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: history.isEmpty
                ? EmptyState(
                    icon: Icons.history_toggle_off,
                    title: controller.history.isEmpty
                        ? 'History is empty'
                        : 'No matches',
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final retryable =
                          item.status == DownloadStatus.failed ||
                          item.status == DownloadStatus.canceled;
                      final output =
                          item.status == DownloadStatus.completed &&
                              item.outputLocation != null
                          ? item.outputLocation!
                          : null;
                      return DownloadItemTile(
                        item: item,
                        thumbnail: OutputThumbnails.of(
                          controller.backend,
                          item,
                        ),
                        onRetry: retryable
                            ? () => controller.retryDownload(item)
                            : null,
                        onDelete: () => controller.deleteHistoryItem(item.id),
                        onOpen: output != null && _outputActions.canOpen
                            ? () => _runAction(
                                context,
                                () => _outputActions.open(output),
                              )
                            : null,
                        onReveal: output != null && _outputActions.canReveal
                            ? () => _runAction(
                                context,
                                () => _outputActions.reveal(output),
                              )
                            : null,
                        onShare: output != null && _outputActions.canShare
                            ? () => _runAction(
                                context,
                                () => _outputActions.share(output),
                              )
                            : null,
                        onRename: output != null
                            ? () => _renameOutput(context, item)
                            : null,
                        onEditTags: controller.canEditTags(item)
                            ? () => _editTags(context, item)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _renameOutput(
    BuildContext context,
    DownloadQueueItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentName = friendlyOutputName(item);
    final extension = outputFileExtension(item);
    final baseName =
        extension != null && currentName.toLowerCase().endsWith(
          '.${extension.toLowerCase()}',
        )
        ? currentName.substring(0, currentName.length - extension.length - 1)
        : currentName;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RenameDialog(initialName: baseName, extension: extension),
    );
    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    final previousLocation = item.outputLocation;
    final failure = await controller.renameOutput(item, newName);
    if (failure == null && previousLocation != null) {
      OutputThumbnails.evict(previousLocation);
    }
    messenger.showSnackBar(SnackBar(content: Text(failure ?? 'Renamed.')));
  }

  Future<void> _editTags(BuildContext context, DownloadQueueItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final current = await controller.readOutputTags(item);
    if (!context.mounted) {
      return;
    }
    if (current == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not read tags from this file.')),
      );
      return;
    }

    final updated = await showDialog<AudioTags>(
      context: context,
      builder: (context) => _EditTagsDialog(initial: current),
    );
    if (updated == null) {
      return;
    }

    final failure = await controller.writeOutputTags(item, updated);
    messenger.showSnackBar(
      SnackBar(content: Text(failure ?? 'Tags saved.')),
    );
  }
}

Future<void> _runAction(
  BuildContext context,
  Future<String?> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final failure = await action();
  if (failure != null) {
    messenger.showSnackBar(SnackBar(content: Text(failure)));
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName, this.extension});

  final String initialName;
  final String? extension;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename file'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'File name',
          suffixText: widget.extension == null ? null : '.${widget.extension}',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

class _EditTagsDialog extends StatefulWidget {
  const _EditTagsDialog({required this.initial});

  final AudioTags initial;

  @override
  State<_EditTagsDialog> createState() => _EditTagsDialogState();
}

class _EditTagsDialogState extends State<_EditTagsDialog> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title ?? '');
    _artist = TextEditingController(text: widget.initial.artist ?? '');
    _album = TextEditingController(text: widget.initial.album ?? '');
    _comment = TextEditingController(text: widget.initial.comment ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit tags'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _artist,
                decoration: const InputDecoration(labelText: 'Artist'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _album,
                decoration: const InputDecoration(labelText: 'Album'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _comment,
                decoration: const InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            AudioTags(
              title: _title.text.trim(),
              artist: _artist.text.trim(),
              album: _album.text.trim(),
              comment: _comment.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProviderFilter extends StatelessWidget {
  const _ProviderFilter({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final providers = controller.historyProviderOptions;
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }

    final selected = controller.historyProviderFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All providers'),
              selected: selected == null,
              onSelected: (_) => controller.setHistoryProviderFilter(null),
            ),
          ),
          ...providers.map(
            (provider) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(provider.displayName),
                selected: selected == provider.id,
                onSelected: (_) =>
                    controller.setHistoryProviderFilter(provider.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
