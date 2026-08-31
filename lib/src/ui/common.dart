import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/download_models.dart';
import '../models/media_providers.dart';
import '../services/app_controller.dart' show friendlyOutputName;

class PageSurface extends StatelessWidget {
  const PageSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;

    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.title, super.key});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.outline),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadItemTile extends StatelessWidget {
  const DownloadItemTile({
    required this.item,
    this.onCancel,
    this.onRetry,
    this.onDelete,
    this.onOpen,
    this.onReveal,
    this.onShare,
    this.onRename,
    this.onEditTags,
    this.thumbnail,
    super.key,
  });

  final DownloadQueueItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  /// Opens the finished file with the default app; also invoked by tapping
  /// the tile.
  final VoidCallback? onOpen;
  final VoidCallback? onReveal;
  final VoidCallback? onShare;
  final VoidCallback? onRename;
  final VoidCallback? onEditTags;

  /// Preview image bytes for the finished output; the status icon is shown
  /// while loading or when no preview exists.
  final Future<Uint8List?>? thumbnail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Finished items keep their last progress event in the model; showing
    // it would look like the download is still running.
    final active =
        item.status == DownloadStatus.running ||
        item.status == DownloadStatus.pending ||
        item.status == DownloadStatus.paused;
    final progress = active ? item.progress : null;
    final percent = progress?.percent?.clamp(0.0, 1.0).toDouble();
    final provider = providerDisplayName(
      providerId: item.providerId,
      providerName: item.providerName,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LeadingVisual(
                    icon: _statusIcon(item.status),
                    color: colors.primary,
                    thumbnail: thumbnail,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$provider - ${outputKindLabel(item.outputKind)}'
                          ' - ${item.format.qualityLabel}'
                          ' - ${item.format.extension}'
                          '${item.finishedAt != null ? ' - ${formatTimestamp(item.finishedAt!)}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Retry download',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                  if (onCancel != null && _cancelable(item.status)) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Cancel',
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remove from history',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                  if (onOpen != null ||
                      onReveal != null ||
                      onShare != null ||
                      onRename != null ||
                      onEditTags != null)
                    PopupMenuButton<VoidCallback>(
                      tooltip: 'File actions',
                      onSelected: (action) => action(),
                      itemBuilder: (context) => [
                        if (onOpen != null)
                          PopupMenuItem(
                            value: onOpen!,
                            child: const ListTile(
                              leading: Icon(Icons.play_circle_outline),
                              title: Text('Open'),
                            ),
                          ),
                        if (onReveal != null)
                          PopupMenuItem(
                            value: onReveal!,
                            child: const ListTile(
                              leading: Icon(Icons.folder_open),
                              title: Text('Show in folder'),
                            ),
                          ),
                        if (onShare != null)
                          PopupMenuItem(
                            value: onShare!,
                            child: const ListTile(
                              leading: Icon(Icons.share),
                              title: Text('Share'),
                            ),
                          ),
                        if (onRename != null)
                          PopupMenuItem(
                            value: onRename!,
                            child: const ListTile(
                              leading: Icon(Icons.drive_file_rename_outline),
                              title: Text('Rename'),
                            ),
                          ),
                        if (onEditTags != null)
                          PopupMenuItem(
                            value: onEditTags!,
                            child: const ListTile(
                              leading: Icon(Icons.sell_outlined),
                              title: Text('Edit tags'),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: percent),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _SmallMetric(icon: Icons.sync, text: progress.stage),
                    _SmallMetric(
                      icon: Icons.speed,
                      text: formatSpeed(progress.speedBytesPerSecond),
                    ),
                    _SmallMetric(
                      icon: Icons.storage,
                      text:
                          '${formatBytes(progress.downloadedBytes)} / ${formatBytes(progress.totalBytes)}',
                    ),
                    _SmallMetric(
                      icon: Icons.timer,
                      text: formatDuration(progress.eta),
                    ),
                  ],
                ),
              ],
              if (item.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(item.errorMessage!, style: TextStyle(color: colors.error)),
              ],
              if (item.outputLocation != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        friendlyOutputName(item),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _cancelable(DownloadStatus status) {
    // A failed item stays in the queue for retries; the close button
    // dismisses it into history.
    return status == DownloadStatus.pending ||
        status == DownloadStatus.paused ||
        status == DownloadStatus.running ||
        status == DownloadStatus.failed;
  }

  IconData _statusIcon(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.pending => Icons.pending,
      DownloadStatus.running => Icons.downloading,
      DownloadStatus.paused => Icons.pause_circle,
      DownloadStatus.completed => Icons.check_circle,
      DownloadStatus.failed => Icons.error,
      DownloadStatus.canceled => Icons.cancel,
    };
  }
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({
    required this.icon,
    required this.color,
    this.thumbnail,
  });

  final IconData icon;
  final Color color;
  final Future<Uint8List?>? thumbnail;

  @override
  Widget build(BuildContext context) {
    final thumbnail = this.thumbnail;
    if (thumbnail == null) {
      return Icon(icon, color: color);
    }

    return FutureBuilder<Uint8List?>(
      future: thumbnail,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Icon(icon, color: color);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            bytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => Icon(icon, color: color),
          ),
        );
      },
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
