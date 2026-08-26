import 'package:flutter/material.dart';

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
            trailing: IconButton(
              tooltip: paused ? 'Resume queue' : 'Pause queue',
              onPressed: paused
                  ? controller.resumeQueue
                  : controller.pauseQueue,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
