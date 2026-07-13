import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/stability_test/models/test_configuration.dart';
import 'shared/storage/settings_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System-wide Chrome theming is intentionally minimal: the app uses
  // Cupertino widgets throughout, which resolve their own colours for both
  // light and dark mode (spec §13.2).
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final SettingsStorage storage =
      SettingsStorage(await SharedPreferences.getInstance());
  final TestConfiguration savedConfig = storage.loadConfiguration();

  runApp(UrlStabilityTestApp(
    initialConfiguration: savedConfig,
    storage: storage,
  ));
}
