import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_models.dart';

class QueueSnapshot {
  const QueueSnapshot({
    required this.items,
    required this.paused,
    this.history = const [],
  });

  final List<DownloadQueueItem> items;
  final bool paused;
  final List<DownloadQueueItem> history;

  Map<String, Object?> toMap() {
    return {
      'version': 1,
      'paused': paused,
      'items': items.map((item) => item.toMap()).toList(),
      'history': history.map((item) => item.toMap()).toList(),
    };
  }

  factory QueueSnapshot.fromMap(Map<Object?, Object?> map) {
    return QueueSnapshot(
      items: listOfMaps(map['items']).map(DownloadQueueItem.fromMap).toList(),
      paused: boolValue(map['paused']),
      history: listOfMaps(map['history'])
          .map(DownloadQueueItem.fromMap)
          .toList(),
    );
  }
}

abstract class QueueStore {
  Future<QueueSnapshot?> load();

  Future<void> save(QueueSnapshot snapshot);
}

class MemoryQueueStore implements QueueStore {
  QueueSnapshot? _snapshot;

  @override
  Future<QueueSnapshot?> load() async => _snapshot;

  @override
  Future<void> save(QueueSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

class SharedPreferencesQueueStore implements QueueStore {
  static const _key = 'download_queue_v1';

  @override
  Future<QueueSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return QueueSnapshot.fromMap(Map<Object?, Object?>.from(decoded));
      }
    } on FormatException {
      // A corrupt snapshot must not block app startup; drop it instead.
      await prefs.remove(_key);
    }

    return null;
  }

  @override
  Future<void> save(QueueSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toMap()));
  }
}
