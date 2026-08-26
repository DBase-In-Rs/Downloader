import 'package:flutter/material.dart';

import '../models/download_models.dart';

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
    super.key,
  });

  final DownloadQueueItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = item.progress;
    final percent = progress?.percent?.clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(item.status), color: colors.primary),
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
                        '${outputKindLabel(item.outputKind)} - ${item.format.qualityLabel} - ${item.format.extension}'
                        '${item.finishedAt != null ? ' - ${formatTimestamp(item.finishedAt!)}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
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
              Text(
                item.outputLocation!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _cancelable(DownloadStatus status) {
    return status == DownloadStatus.pending ||
        status == DownloadStatus.paused ||
        status == DownloadStatus.running;
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
