import 'package:flutter/cupertino.dart';

import '../features/stability_test/controllers/stability_test_controller.dart';
import '../features/stability_test/models/test_configuration.dart';
import '../shared/storage/settings_storage.dart';
import 'routes.dart';
import 'theme.dart';
import '../features/stability_test/screens/test_progress_screen.dart';
import '../features/stability_test/screens/test_result_screen.dart';
import '../features/stability_test/screens/test_setup_screen.dart';

/// Root widget. Owns the [StabilityTestController] and the [SettingsStorage]
/// and wires them into the three screens via the navigator (spec §5).
class UrlStabilityTestApp extends StatelessWidget {
  UrlStabilityTestApp({
    required this.initialConfiguration,
    required this.storage,
    StabilityTestController? controller,
    super.key,
  }) : controller = controller ?? StabilityTestController();

  /// The configuration loaded from local storage at startup (spec §16).
  final TestConfiguration initialConfiguration;
  final SettingsStorage storage;
  final StabilityTestController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'URL 穩定性測試',
      debugShowCheckedModeBanner: false,
      theme: buildCupertinoTheme(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.setup:
        return CupertinoPageRoute<void>(
          builder: (_) => TestSetupScreen(
            controller: controller,
            storage: storage,
            initialConfiguration: initialConfiguration,
          ),
          settings: settings,
        );
      case AppRoutes.progress:
        return CupertinoPageRoute<void>(
          builder: (_) => TestProgressScreen(controller: controller),
          settings: settings,
          fullscreenDialog: false,
        );
      case AppRoutes.result:
        return CupertinoPageRoute<void>(
          builder: (_) => TestResultScreen(controller: controller),
          settings: settings,
        );
    }
    return null;
  }
}
