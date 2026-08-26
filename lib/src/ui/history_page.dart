import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import 'common.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final history = controller.history;

    return PageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'History',
            icon: Icons.history,
            trailing: history.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear history',
                    onPressed: controller.clearHistory,
                    icon: const Icon(Icons.delete_sweep),
                  ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: history.isEmpty
                ? const EmptyState(
                    icon: Icons.history_toggle_off,
                    title: 'History is empty',
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return DownloadItemTile(item: history[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
