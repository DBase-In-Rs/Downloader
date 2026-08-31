import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/android_storage_service.dart';
import '../services/app_controller.dart';
import '../services/binary_probe.dart';
import '../services/desktop_media_backend.dart';
import '../services/desktop_settings.dart';
import '../services/supporter_links.dart';
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
          // Order per maintainer: engine update, download folder, cookies,
          // support, websites, engine check, licenses, version.
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
                    tooltip: 'How to get cookies.txt',
                    onPressed: () => _showCookieHelp(context),
                    icon: const Icon(Icons.help_outline),
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
          const SizedBox(height: 10),
          _AutomationCard(controller: controller),
          const SizedBox(height: 10),
          _TuningCard(controller: controller),
          const SizedBox(height: 10),
          const _SupportCard(),
          const SizedBox(height: 10),
          if (_isDesktopPlatform) ...[
            const _EngineBinariesCard(),
            const SizedBox(height: 10),
          ],
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Open Source Licenses'),
              subtitle: const Text(
                'GPL-3.0-only app; bundled third-party components',
              ),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'DBase Downloader',
                applicationLegalese:
                    'GPL-3.0-only. Source: github.com/DBase-In-Rs/Downloader',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AboutCard(controller: controller),
        ],
      ),
    );
  }

  void _showCookieHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _CookieHelpDialog(),
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

class _CookieHelpDialog extends StatelessWidget {
  const _CookieHelpDialog();

  static const _chromeUrl =
      'https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc';
  static const _firefoxUrl =
      'https://addons.mozilla.org/en-US/firefox/addon/get-cookies-txt-locally/';

  static const _steps = [
    'Install the "Get cookies.txt LOCALLY" extension in Chrome or Firefox '
        'on your computer:',
    'Open a private/incognito window and sign in to the site (YouTube, '
        'Instagram, Facebook...). Check that the media you want actually '
        'plays there.',
    'Use the extension to export cookies for that site as cookies.txt.',
    'Close the private window WITHOUT signing out - this keeps the exported '
        'session valid much longer.',
    'Move the file to this device and import it here.',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.cookie_outlined, color: colors.primary),
      title: const Text('How to get cookies.txt'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Some media needs a signed-in account. Sites block logins '
                'from embedded app browsers, so cookies are exported from '
                'your own browser instead.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_steps[i])),
                  ],
                ),
                if (i == 0) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ExtensionLink(
                          label: 'Chrome Web Store',
                          color: const Color(0xFF4285F4),
                          url: _chromeUrl,
                        ),
                        _ExtensionLink(
                          label: 'Firefox Add-ons',
                          color: const Color(0xFFFF7139),
                          url: _firefoxUrl,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Use the cookies only in this app - using them '
                        'elsewhere invalidates them. Re-export when Settings '
                        'shows them as expired.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _ExtensionLink extends StatelessWidget {
  const _ExtensionLink({
    required this.label,
    required this.color,
    required this.url,
    this.icon = Icons.extension,
  });

  final String label;
  final Color color;
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final update = controller.availableUpdate;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('DBase Video & Music Downloader'),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(
                  info == null
                      ? 'Version unavailable'
                      : 'Version ${info.version} (build ${info.buildNumber})',
                );
              },
            ),
          ),
          if (update != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.new_releases_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New version available: ${update.version}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(update.assetUrl ?? update.releaseUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// The red half of the logo "D" (sampled from assets/branding/logo.png).
const _heartColor = Color(0xFFD01010);

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.favorite, color: _heartColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support the Developer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DBase Downloader is free and open source. If it saves '
                    'you time, supporting keeps development going.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _heartColor,
                        ),
                        onPressed: () => launchUrl(
                          Uri.parse(SupporterLinks.checkout),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Become a supporter'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => launchUrl(
                          Uri.parse(SupporterLinks.checkoutPro),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.workspace_premium, size: 18),
                        label: const Text('Supporter Pro'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _EngineBinariesCard extends StatefulWidget {
  const _EngineBinariesCard();

  @override
  State<_EngineBinariesCard> createState() => _EngineBinariesCardState();
}

class _EngineBinariesCardState extends State<_EngineBinariesCard> {
  final _probe = DesktopBinaryProbe();
  EngineProbe? _result;
  var _checking = true;
  String _installCommand = windowsInstallCommand;

  bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await _probe.probe();
    final command = _isLinux
        ? linuxInstallCommand(await readOsRelease())
        : windowsInstallCommand;
    if (mounted) {
      setState(() {
        _result = result;
        _installCommand = command;
        _checking = false;
      });
    }
  }

  Future<void> _copyCommand() async {
    await Clipboard.setData(ClipboardData(text: _installCommand));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Command copied to clipboard')),
      );
    }
  }

  Future<void> _openStore() async {
    final opened = await openLinuxSoftwareCenter();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No software center found - use the terminal command'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Engine Check',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Check again',
                  onPressed: _checking ? null : _check,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_checking || result == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else ...[
              _BinaryStatusRow(
                name: 'yt-dlp',
                purpose: 'downloads and site extraction',
                status: result.ytDlp,
              ),
              _BinaryStatusRow(
                name: 'FFmpeg',
                purpose: 'MP3/M4A conversion and MP4 merge',
                status: result.ffmpeg,
              ),
              if (!result.allFound) ...[
                const SizedBox(height: 10),
                Text(
                  _isLinux
                      ? 'Install the missing tools from the terminal:'
                      : 'Install the missing tools with winget '
                            '(built into Windows):',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _installCommand,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy command',
                        onPressed: _copyCommand,
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_isLinux)
                      OutlinedButton.icon(
                        onPressed: _openStore,
                        icon: const Icon(Icons.store, size: 18),
                        label: const Text('Open Software Center'),
                      ),
                    _ExtensionLink(
                      label: 'yt-dlp downloads',
                      color: Theme.of(context).colorScheme.primary,
                      url: 'https://github.com/yt-dlp/yt-dlp/releases/latest',
                      icon: Icons.download,
                    ),
                    if (!_isLinux)
                      _ExtensionLink(
                        label: 'FFmpeg builds',
                        color: Theme.of(context).colorScheme.primary,
                        url: 'https://www.gyan.dev/ffmpeg/builds/',
                        icon: Icons.download,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isLinux
                      ? 'Distro yt-dlp packages are often outdated; the '
                            'GitHub binary above is recommended for YouTube.'
                      : 'After installing, restart the terminal session and '
                            'press the refresh button above.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BinaryStatusRow extends StatelessWidget {
  const _BinaryStatusRow({
    required this.name,
    required this.purpose,
    required this.status,
  });

  final String name;
  final String purpose;
  final BinaryProbeResult status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status.found ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: status.found ? Colors.green.shade700 : colors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: '  -  $purpose',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12.5,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            status.found
                ? (status.version == null ? 'Found' : 'v${status.version}')
                : 'Not found',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: status.found ? Colors.green.shade700 : colors.error,
            ),
          ),
        ],
      ),
    );
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

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_outlined),
                const SizedBox(width: 12),
                Text(
                  'Automation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Detect links in clipboard'),
              subtitle: const Text(
                'When the app opens, offer to download a link found in the '
                'clipboard. The clipboard is read only while the app is on '
                'screen.',
              ),
              value: controller.clipboardWatch,
              onChanged: controller.setClipboardWatch,
            ),
          ],
        ),
      ),
    );
  }
}

class _TuningCard extends StatelessWidget {
  const _TuningCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tuning = controller.tuning;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: Text(
          'Download Tuning',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Pauses and retry limits for yt-dlp',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pauses and retry limits passed to yt-dlp. Longer pauses look '
              'more like a person and help avoid rate-limiting when '
              'downloading many items in a row.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          _TuningSlider(
            label: 'Retries',
            value: tuning.retries.toDouble(),
            max: 30,
            display: '${tuning.retries}',
            onChanged: (value) =>
                controller.setTuning(tuning.copyWith(retries: value.round())),
          ),
          _TuningSlider(
            label: 'Fragment retries',
            value: tuning.fragmentRetries.toDouble(),
            max: 30,
            display: '${tuning.fragmentRetries}',
            onChanged: (value) => controller.setTuning(
              tuning.copyWith(fragmentRetries: value.round()),
            ),
          ),
          _TuningSlider(
            label: 'Sleep between requests',
            value: tuning.sleepRequestsSeconds,
            max: 10,
            divisions: 20,
            display: tuning.sleepRequestsSeconds == 0
                ? 'Off'
                : '${tuning.sleepRequestsSeconds} s',
            onChanged: (value) => controller.setTuning(
              tuning.copyWith(sleepRequestsSeconds: (value * 2).round() / 2),
            ),
          ),
          _TuningSlider(
            label: 'Min pause before download',
            value: tuning.sleepIntervalSeconds.toDouble(),
            max: 30,
            display: tuning.sleepIntervalSeconds == 0
                ? 'Off'
                : '${tuning.sleepIntervalSeconds} s',
            onChanged: (value) => controller.setTuning(
              tuning.copyWith(sleepIntervalSeconds: value.round()),
            ),
          ),
          _TuningSlider(
            label: 'Max pause before download',
            value: tuning.maxSleepIntervalSeconds.toDouble(),
            max: 60,
            enabled: tuning.sleepIntervalSeconds > 0,
            display: tuning.maxSleepIntervalSeconds == 0
                ? 'Off'
                : '${tuning.maxSleepIntervalSeconds} s',
            onChanged: (value) => controller.setTuning(
              tuning.copyWith(maxSleepIntervalSeconds: value.round()),
            ),
          ),
          _TuningSlider(
            label: 'Pause between queue items',
            value: tuning.queueGapSeconds.toDouble(),
            max: 120,
            display: tuning.queueGapSeconds == 0
                ? 'Off'
                : '${tuning.queueGapSeconds} s',
            onChanged: (value) => controller.setTuning(
              tuning.copyWith(queueGapSeconds: value.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TuningSlider extends StatelessWidget {
  const _TuningSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.display,
    required this.onChanged,
    this.divisions,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double max;
  final String display;
  final int? divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          flex: 6,
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            divisions: divisions ?? max.round(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
      EngineUpdateState.updated =>
        'Updated${version != null ? ' to $version' : ''}',
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
