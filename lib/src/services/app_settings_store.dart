import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_models.dart';

/// User preferences that are not part of the download queue: yt-dlp tuning
/// plus automation toggles.
class AppSettings {
  const AppSettings({
    this.tuning = const DownloadTuning(),
    this.clipboardWatch = true,
  });

  final DownloadTuning tuning;

  /// When true, the app offers to download a link found in the clipboard
  /// when it comes to the foreground.
  final bool clipboardWatch;

  AppSettings copyWith({DownloadTuning? tuning, bool? clipboardWatch}) {
    return AppSettings(
      tuning: tuning ?? this.tuning,
      clipboardWatch: clipboardWatch ?? this.clipboardWatch,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'version': 1,
      'tuning': tuning.toMap(),
      'clipboardWatch': clipboardWatch,
    };
  }

  factory AppSettings.fromMap(Map<Object?, Object?> map) {
    return AppSettings(
      tuning: DownloadTuning.fromMap(mapValue(map['tuning'])),
      clipboardWatch: map['clipboardWatch'] == null
          ? true
          : boolValue(map['clipboardWatch']),
    );
  }
}

abstract class AppSettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class MemoryAppSettingsStore implements AppSettingsStore {
  MemoryAppSettingsStore([this._settings = const AppSettings()]);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}

class SharedPreferencesAppSettingsStore implements AppSettingsStore {
  static const _key = 'app_settings_v1';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return const AppSettings();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppSettings.fromMap(Map<Object?, Object?>.from(decoded));
      }
    } on FormatException {
      await prefs.remove(_key);
    }

    return const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toMap()));
  }
}
