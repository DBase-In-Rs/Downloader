import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/android_storage_service.dart';
import '../services/app_controller.dart';
import '../services/desktop_media_backend.dart';
import '../services/desktop_settings.dart';
import 'common.dart';

bool get _isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

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
          if (_isDesktopPlatform) ...[
            const _DesktopPathsCard(),
            const SizedBox(height: 10),
          ],
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const _AndroidFolderCard(),
            const SizedBox(height: 10),
          ],
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
                          status.expired
                              ? (status.message ??
                                    'Expired or invalid - re-import')
                              : status.configured
                              ? 'Configured'
                              : 'Not configured',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: status.expired
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cookies stay on this device, encrypted, and are '
                          'sent only to the media provider with yt-dlp '
                          'requests.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Import cookies.txt',
                    onPressed: () => _importCookies(context),
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

  Future<void> _importCookies(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'cookies.txt', extensions: ['txt']),
      ],
    );
    if (file == null) {
      return;
    }

    String? failure;
    try {
      failure = await controller.importCookies(await file.readAsString());
    } catch (_) {
      failure = 'Could not read the selected file.';
    }

    messenger.showSnackBar(
      SnackBar(content: Text(failure ?? 'Cookies imported.')),
    );
  }
}

class _AndroidFolderCard extends StatefulWidget {
  const _AndroidFolderCard();

  @override
  State<_AndroidFolderCard> createState() => _AndroidFolderCardState();
}

class _AndroidFolderCardState extends State<_AndroidFolderCard> {
  final _storage = AndroidStorageService();
  String? _folder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final folder = await _storage.getOutputFolder();
    if (mounted) {
      setState(() => _folder = folder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.folder),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Folder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _folder ?? 'Default (Music/Movies collections)',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Choose folder',
              onPressed: _pick,
              icon: const Icon(Icons.folder_open),
            ),
            IconButton(
              tooltip: 'Reset to default',
              onPressed: _folder == null ? null : _clear,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    try {
      await _storage.pickOutputFolder();
    } catch (_) {
      // Cancel or picker failure keeps the previous folder.
    }
    await _load();
  }

  Future<void> _clear() async {
    await _storage.clearOutputFolder();
    await _load();
  }
}

class _DesktopPathsCard extends StatefulWidget {
  const _DesktopPathsCard();

  @override
  State<_DesktopPathsCard> createState() => _DesktopPathsCardState();
}

class _DesktopPathsCardState extends State<_DesktopPathsCard> {
  final _settings = DesktopSettings();
  DesktopBackendConfig _config = const DesktopBackendConfig();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _settings.load();
    if (mounted) {
      setState(() => _config = config);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desktop Binaries & Output',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'yt-dlp is required (from PATH when unset); FFmpeg is needed '
              'for MP3/M4A/MP4 conversion.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _PathRow(
              label: 'yt-dlp binary',
              value: _config.ytDlpPath,
              placeholder: 'Auto-detect on PATH',
              onPick: () => _pickFile(_settings.setYtDlpPath),
              onClear: () => _update(() => _settings.setYtDlpPath(null)),
            ),
            _PathRow(
              label: 'FFmpeg location',
              value: _config.ffmpegPath,
              placeholder: 'Not set',
              onPick: () => _pickFile(_settings.setFfmpegPath),
              onClear: () => _update(() => _settings.setFfmpegPath(null)),
            ),
            _PathRow(
              label: 'Output folder',
              value: _config.outputDirectory,
              placeholder: 'Downloads folder',
              onPick: _pickOutputDirectory,
              onClear: () => _update(() => _settings.setOutputDirectory(null)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(Future<void> Function(String?) save) async {
    final file = await openFile();
    if (file == null) {
      return;
    }
    await _update(() => save(file.path));
  }

  Future<void> _pickOutputDirectory() async {
    final directory = await getDirectoryPath();
    if (directory == null) {
      return;
    }
    await _update(() => _settings.setOutputDirectory(directory));
  }

  Future<void> _update(Future<void> Function() action) async {
    await action();
    await _load();
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                value?.isNotEmpty == true ? value! : placeholder,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Browse',
          onPressed: onPick,
          icon: const Icon(Icons.folder_open),
        ),
        IconButton(
          tooltip: 'Reset to default',
          onPressed: value?.isNotEmpty == true ? onClear : null,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
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
