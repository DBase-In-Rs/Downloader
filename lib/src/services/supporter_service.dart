import 'package:shared_preferences/shared_preferences.dart';

/// Persists the supporter flag across restarts.
abstract class SupporterStore {
  Future<bool> readSupporter();

  Future<void> writeSupporter(bool value);
}

class MemorySupporterStore implements SupporterStore {
  bool _supporter = false;

  @override
  Future<bool> readSupporter() async => _supporter;

  @override
  Future<void> writeSupporter(bool value) async => _supporter = value;
}

class SharedPreferencesSupporterStore implements SupporterStore {
  static const _prefsKey = 'supporter';

  @override
  Future<bool> readSupporter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  @override
  Future<void> writeSupporter(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_prefsKey, true);
    } else {
      await prefs.remove(_prefsKey);
    }
  }
}

/// Supporter status for the heart in the app bar.
///
/// Support is honor-based: the purchase happens on Polar in the browser
/// (Polar is the merchant of record and handles payment, receipts, and
/// taxes), and the user turns the heart on afterwards. No license keys, no
/// validation, and no network calls from the app.
class SupporterService {
  SupporterService({SupporterStore? store})
    : store = store ?? MemorySupporterStore();

  /// Checkout pages for the two support tiers.
  static const checkoutUrl =
      'https://buy.polar.sh/polar_cl_zPF9CaYg2iyuHxQ3hA3mdXVvomRJb8gEzC5d93f8xfV';
  static const checkoutProUrl =
      'https://buy.polar.sh/polar_cl_G3W6En67QTEVoBC1oVln4HQqcpqK8w7vujkJD4WjGOj';

  final SupporterStore store;

  Future<bool> isSupporter() => store.readSupporter();

  Future<void> setSupporter(bool value) => store.writeSupporter(value);
}
