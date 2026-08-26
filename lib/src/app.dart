import 'package:flutter/material.dart';

import 'models/download_models.dart';
import 'services/app_controller.dart';
import 'services/media_backend.dart';
import 'services/shared_url_service.dart';
import 'ui/history_page.dart';
import 'ui/home_page.dart';
import 'ui/queue_page.dart';
import 'ui/settings_page.dart';

class DBaseDownloaderApp extends StatelessWidget {
  const DBaseDownloaderApp({
    required this.backend,
    required this.sharedUrlService,
    super.key,
  });

  final MediaBackend backend;
  final SharedUrlService sharedUrlService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DBase Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        visualDensity: VisualDensity.standard,
      ),
      home: DBaseDownloaderHome(
        backend: backend,
        sharedUrlService: sharedUrlService,
      ),
    );
  }
}

class DBaseDownloaderHome extends StatefulWidget {
  const DBaseDownloaderHome({
    required this.backend,
    required this.sharedUrlService,
    super.key,
  });

  final MediaBackend backend;
  final SharedUrlService sharedUrlService;

  @override
  State<DBaseDownloaderHome> createState() => _DBaseDownloaderHomeState();
}

class _DBaseDownloaderHomeState extends State<DBaseDownloaderHome> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      backend: widget.backend,
      sharedUrlService: widget.sharedUrlService,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final body = _SectionBody(controller: _controller);

            return Scaffold(
              appBar: AppBar(
                title: const Text('DBase Downloader'),
                actions: [
                  _CookieStatusButton(status: _controller.cookieStatus),
                ],
              ),
              body: wide
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _controller.section.index,
                          onDestinationSelected: (index) =>
                              _controller.setSection(AppSection.values[index]),
                          labelType: NavigationRailLabelType.all,
                          destinations: _navigationRailDestinations,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    )
                  : body,
              bottomNavigationBar: wide
                  ? null
                  : NavigationBar(
                      selectedIndex: _controller.section.index,
                      onDestinationSelected: (index) =>
                          _controller.setSection(AppSection.values[index]),
                      destinations: _navigationBarDestinations,
                    ),
            );
          },
        );
      },
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.section) {
      AppSection.home => HomePage(controller: controller),
      AppSection.queue => QueuePage(controller: controller),
      AppSection.history => HistoryPage(controller: controller),
      AppSection.settings => SettingsPage(controller: controller),
    };
  }
}

class _CookieStatusButton extends StatelessWidget {
  const _CookieStatusButton({required this.status});

  final CookieStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = status.configured ? Icons.key : Icons.key_off;
    final label = status.configured ? 'Cookies ready' : 'No cookies';

    return Tooltip(
      message: label,
      child: IconButton(onPressed: null, icon: Icon(icon)),
    );
  }
}

const _navigationBarDestinations = [
  NavigationDestination(
    icon: Icon(Icons.link),
    selectedIcon: Icon(Icons.link),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.downloading),
    selectedIcon: Icon(Icons.downloading),
    label: 'Queue',
  ),
  NavigationDestination(
    icon: Icon(Icons.history),
    selectedIcon: Icon(Icons.history),
    label: 'History',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings),
    selectedIcon: Icon(Icons.settings),
    label: 'Settings',
  ),
];

const _navigationRailDestinations = [
  NavigationRailDestination(
    icon: Icon(Icons.link),
    selectedIcon: Icon(Icons.link),
    label: Text('Home'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.downloading),
    selectedIcon: Icon(Icons.downloading),
    label: Text('Queue'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.history),
    selectedIcon: Icon(Icons.history),
    label: Text('History'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.settings),
    selectedIcon: Icon(Icons.settings),
    label: Text('Settings'),
  ),
];
