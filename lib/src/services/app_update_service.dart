import 'dart:convert';
import 'dart:io';

/// A newer application release discovered on GitHub.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.assetUrl,
    this.assetName,
  });

  /// Normalized version, e.g. `1.0.0-rc.2`.
  final String version;

  /// Release page URL (fallback when no platform asset matches).
  final String releaseUrl;

  /// Direct download URL of the asset for the current platform.
  final String? assetUrl;
  final String? assetName;
}

/// Checks GitHub Releases for a newer version of the app.
class AppUpdateService {
  AppUpdateService({this.repository = 'DBase-In-Rs/Downloader'});

  final String repository;

  /// Returns update info when a release newer than [currentVersion] exists.
  /// Stable installs are only offered stable releases; pre-release installs
  /// (e.g. `1.0.0-rc.1`) are also offered newer pre-releases.
  Future<AppUpdateInfo?> checkForUpdate(
    String currentVersion, {
    required String platformAssetMarker,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repository/releases?per_page=10'),
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'dbase-downloader');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final releases = jsonDecode(body);
      if (releases is! List) {
        return null;
      }

      return updateFromReleases(
        releases.whereType<Map<String, dynamic>>().toList(),
        currentVersion,
        platformAssetMarker: platformAssetMarker,
      );
    } catch (_) {
      // Update checks are best-effort; network failures stay silent.
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Pure selection logic, separated for testing.
AppUpdateInfo? updateFromReleases(
  List<Map<String, dynamic>> releases,
  String currentVersion, {
  required String platformAssetMarker,
}) {
  final currentIsPrerelease = currentVersion.contains('-');

  for (final release in releases) {
    if (release['draft'] == true) {
      continue;
    }
    final isPrerelease = release['prerelease'] == true;
    if (isPrerelease && !currentIsPrerelease) {
      continue;
    }

    final tag = (release['tag_name'] as String? ?? '');
    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    if (version.isEmpty || compareVersions(version, currentVersion) <= 0) {
      continue;
    }

    String? assetUrl;
    String? assetName;
    for (final asset in (release['assets'] as List? ?? const [])) {
      if (asset is! Map) {
        continue;
      }
      final name = asset['name'] as String? ?? '';
      if (name.contains(platformAssetMarker)) {
        assetUrl = asset['browser_download_url'] as String?;
        assetName = name;
        break;
      }
    }

    return AppUpdateInfo(
      version: version,
      releaseUrl: release['html_url'] as String? ?? '',
      assetUrl: assetUrl,
      assetName: assetName,
    );
  }

  return null;
}

/// Semver-style comparison: positive when [a] is newer than [b]. Pre-release
/// versions rank below their stable release (`1.0.0-rc.2 < 1.0.0`), and
/// numeric pre-release parts compare numerically (`rc.2 < rc.10`).
int compareVersions(String a, String b) {
  List<int> core(String v) => v
      .split('-')
      .first
      .split('+')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final coreA = core(a);
  final coreB = core(b);
  for (var i = 0; i < 3; i++) {
    final x = i < coreA.length ? coreA[i] : 0;
    final y = i < coreB.length ? coreB[i] : 0;
    if (x != y) {
      return x.compareTo(y);
    }
  }

  String? pre(String v) {
    final withoutBuild = v.split('+').first;
    final dash = withoutBuild.indexOf('-');
    return dash == -1 ? null : withoutBuild.substring(dash + 1);
  }

  final preA = pre(a);
  final preB = pre(b);
  if (preA == null && preB == null) {
    return 0;
  }
  if (preA == null) {
    return 1; // stable > pre-release
  }
  if (preB == null) {
    return -1;
  }

  final partsA = preA.split('.');
  final partsB = preB.split('.');
  for (var i = 0; i < partsA.length && i < partsB.length; i++) {
    final numA = int.tryParse(partsA[i]);
    final numB = int.tryParse(partsB[i]);
    final cmp = (numA != null && numB != null)
        ? numA.compareTo(numB)
        : partsA[i].compareTo(partsB[i]);
    if (cmp != 0) {
      return cmp;
    }
  }

  return partsA.length.compareTo(partsB.length);
}
