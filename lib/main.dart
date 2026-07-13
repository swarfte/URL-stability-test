import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/stability_test/models/test_configuration.dart';
import 'shared/storage/settings_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Light Mode app-wide (per project request). Setting the application
  // style to light keeps native system bars / overlays on a light style, while
  // CupertinoApp overrides platformBrightness in lib/app/app.dart so every
  // Cupertino system colour resolves to its light variant.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: CupertinoColors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

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
