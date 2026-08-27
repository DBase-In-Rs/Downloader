import 'package:flutter/material.dart';

import '../models/download_models.dart';
import '../services/app_controller.dart';
import 'common.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final history = controller.filteredHistory;

    return PageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'History',
            icon: Icons.history,
            trailing: controller.history.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear history',
                    onPressed: controller.clearHistory,
                    icon: const Icon(Icons.delete_sweep),
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
                      return DownloadItemTile(
                        item: item,
                        onRetry: retryable
                            ? () => controller.retryDownload(item)
                            : null,
                        onDelete: () => controller.deleteHistoryItem(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
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
