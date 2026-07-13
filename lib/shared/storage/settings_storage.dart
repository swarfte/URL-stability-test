import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/stability_test/models/test_configuration.dart';

/// Persists the most recent test configuration using simple key-value storage
/// (spec §16). Only the user-editable subset of [TestConfiguration] is stored;
/// no response data, cookies, or auth material is ever written.
class SettingsStorage {
  SettingsStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'test_configuration';

  /// Loads the saved configuration, or a default one if none exists yet.
  TestConfiguration loadConfiguration() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return const TestConfiguration();
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return TestConfiguration.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt data → fall back to defaults.
    }
    return const TestConfiguration();
  }

  /// Saves the user-editable fields of [configuration].
  Future<void> saveConfiguration(TestConfiguration configuration) async {
    await _prefs.setString(_key, jsonEncode(configuration.toJson()));
  }
}
