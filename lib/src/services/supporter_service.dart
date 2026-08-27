import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of a supporter license key check.
enum SupporterValidation { valid, invalid, unreachable }

/// Persists the supporter license key across restarts.
abstract class SupporterStore {
  Future<String?> readKey();

  Future<void> writeKey(String? key);
}

class MemorySupporterStore implements SupporterStore {
  String? _key;

  @override
  Future<String?> readKey() async => _key;

  @override
  Future<void> writeKey(String? key) async => _key = key;
}

class SharedPreferencesSupporterStore implements SupporterStore {
  static const _prefsKey = 'supporterLicenseKey';

  @override
  Future<String?> readKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  @override
  Future<void> writeKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, key);
    }
  }
}

/// Activates supporter license keys against Polar (the merchant of record).
///
/// The validation endpoint is public and scoped by the organization id, so
/// no secret ships with the app. A key is validated once, when the user
/// enters it; afterwards the stored key is trusted so supporters are never
/// blocked offline and the app never phones home on startup.
class SupporterService {
  SupporterService({
    SupporterStore? store,
    this.organizationId = polarOrganizationId,
    this.validator,
  }) : store = store ?? MemorySupporterStore();

  /// Polar organization the license keys belong to.
  static const polarOrganizationId = 'eaa3d2c8-122d-4d8b-97e9-0aee2b476c95';

  /// Checkout page for the supporter license (Polar is the merchant of
  /// record and handles payment, receipts, and taxes).
  static const checkoutUrl =
      'https://buy.polar.sh/checkout?products=6987901a-a106-497f-901b-eaf55740b7f3';

  final SupporterStore store;
  final String organizationId;

  /// Overrides the remote Polar call, for tests.
  final Future<SupporterValidation> Function(String key)? validator;

  Future<bool> hasStoredKey() async =>
      ((await store.readKey()) ?? '').isNotEmpty;

  /// Validates [key] with Polar and stores it when granted.
  Future<SupporterValidation> activate(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return SupporterValidation.invalid;
    }

    final result = await (validator ?? _validateRemote)(trimmed);
    if (result == SupporterValidation.valid) {
      await store.writeKey(trimmed);
    }
    return result;
  }

  Future<void> clear() => store.writeKey(null);

  Future<SupporterValidation> _validateRemote(String key) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse(
          'https://api.polar.sh/v1/customer-portal/license-keys/validate',
        ),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'key': key, 'organization_id': organizationId}));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await response.transform(utf8.decoder).join();
      Object? decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }
      return validationFromResponse(response.statusCode, decoded);
    } catch (_) {
      return SupporterValidation.unreachable;
    } finally {
      client.close(force: true);
    }
  }
}

/// Pure mapping from the Polar validate response, separated for testing.
///
/// A 2xx response counts as valid only when the key status is `granted`
/// (revoked and disabled keys are rejected). Any 4xx means the key itself is
/// bad; everything else is a transient failure so network problems are never
/// reported as an invalid key.
SupporterValidation validationFromResponse(int statusCode, Object? body) {
  if (statusCode >= 200 && statusCode < 300) {
    final status = body is Map ? body['status'] : null;
    return status == 'granted'
        ? SupporterValidation.valid
        : SupporterValidation.invalid;
  }
  if (statusCode >= 400 && statusCode < 500) {
    return SupporterValidation.invalid;
  }
  return SupporterValidation.unreachable;
}
