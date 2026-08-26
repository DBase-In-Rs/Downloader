import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import 'common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.cookieStatus;

    return PageSurface(
      child: ListView(
        children: [
          const SectionHeader(title: 'Settings', icon: Icons.settings),
          const SizedBox(height: 16),
          _EngineCard(controller: controller),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(status.configured ? Icons.key : Icons.key_off),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Cookies',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.configured ? 'Configured' : 'Not configured',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Import cookies.txt',
                    onPressed: null,
                    icon: const Icon(Icons.upload_file),
                  ),
                  IconButton(
                    tooltip: 'Clear cookies',
                    onPressed: status.configured
                        ? controller.clearCookies
                        : null,
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineCard extends StatelessWidget {
  const _EngineCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.engineUpdateState;
    final version = controller.engineVersion;
    final checking = state == EngineUpdateState.checking;
    final statusText = switch (state) {
      EngineUpdateState.idle => 'Not checked yet',
      EngineUpdateState.checking => 'Checking for updates...',
      EngineUpdateState.updated => 'Updated${version != null ? ' to $version' : ''}',
      EngineUpdateState.upToDate =>
        'Up to date${version != null ? ' ($version)' : ''}',
      EngineUpdateState.failed =>
        controller.engineUpdateMessage ?? 'Update failed',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.build_circle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloader Engine (yt-dlp)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: state == EngineUpdateState.failed
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (checking)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: 'Check for engine updates',
                onPressed: controller.updateEngine,
                icon: const Icon(Icons.system_update_alt),
              ),
          ],
        ),
      ),
    );
  }
}
