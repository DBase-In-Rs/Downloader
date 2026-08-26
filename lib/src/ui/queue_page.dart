import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import 'common.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final queue = controller.queue;

    return PageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Queue', icon: Icons.downloading),
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
