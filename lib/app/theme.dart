import 'package:flutter/cupertino.dart';

/// Cupertino theme tuned for an Apple-inspired look that works across Android,
/// Windows and macOS (spec §3.1, §13). Colours resolve automatically for light
/// and dark mode (spec §13.2) because we use Cupertino system colours.
///
/// Per spec §3.2 we deliberately do NOT hardcode SF Pro: leaving
/// [textTheme] unspecified lets Cupertino fall back to each platform's default
/// sans-serif, avoiding undefined font behaviour on Android/Windows.
CupertinoThemeData buildCupertinoTheme() {
  return const CupertinoThemeData(
    primaryColor: CupertinoColors.activeBlue,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    textTheme: CupertinoTextThemeData(),
  );
}
