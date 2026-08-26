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
