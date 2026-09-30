import 'package:flutter/material.dart';

import '../models/download_models.dart';
import '../services/app_controller.dart';
import 'common.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final queue = controller.queue;

    final paused = controller.queuePaused;

    return PageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Queue',
            icon: Icons.downloading,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: paused ? 'Resume queue' : 'Pause queue',
                  onPressed: queue.isEmpty
                      ? null
                      : paused
                      ? controller.resumeQueue
                      : controller.pauseQueue,
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                ),
                IconButton(
                  tooltip: 'Clear queue',
                  onPressed: queue.isEmpty
                      ? null
                      : () => _confirmClearQueue(context),
                  icon: const Icon(Icons.delete_sweep),
                ),
              ],
            ),
          ),
          if (paused) ...[
            const SizedBox(height: 8),
            Text(
              'Queue is paused. The active download finishes, but waiting '
              'items will not start until you resume.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: queue.isEmpty
                ? const EmptyState(
                    icon: Icons.playlist_add_check,
                    title: 'Queue is empty',
                  )
                : ListView.separated(
                    itemCount: queue.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      return DownloadItemTile(
                        item: item,
                        onCancel: () => controller.cancelDownload(item.id),
                        onRetry: item.status == DownloadStatus.failed
                            ? () => controller.retryQueueItem(item.id)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearQueue(BuildContext context) async {
    final queue = controller.queue;
    final hasRunning = queue.any(
      (item) => item.status == DownloadStatus.running,
    );
    final count = queue.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear queue?'),
        content: Text(
          hasRunning
              ? 'This will cancel the active download and remove all $count '
                    'items from the queue. Downloaded files and History will '
                    'not be deleted.'
              : 'This will remove all $count items from the queue. Downloaded '
                    'files and History will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep queue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(hasRunning ? 'Cancel and clear' : 'Clear queue'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearQueue(cancelRunning: hasRunning);
    }
  }
}
