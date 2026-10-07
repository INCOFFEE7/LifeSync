import 'package:flutter/material.dart';

enum AppVariant {
  lifesync,
  beebee
}

class AppConfig {
  final AppVariant variant;
  final String appName;
  final String logoPath;
  final String logoFullPath;
  final String logoDarkPath;
  final String logoDarkFullPath;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final List<String> enabledModules;

  const AppConfig({
    required this.variant,
    required this.appName,
    required this.logoPath,
    required this.logoFullPath,
    required this.logoDarkPath,
    required this.logoDarkFullPath,
    required this.lightTheme,
    required this.darkTheme,
    required this.enabledModules,
  });

  String getLogoPath(bool isDark) => isDark ? logoDarkPath : logoPath;
  String getLogoFullPath(bool isDark) => isDark ? logoDarkFullPath : logoFullPath;

  bool hasModule(String moduleName) {
    return enabledModules.contains(moduleName);
  }
}

class AppEnvironment {
  static late AppConfig config;

  static void setup(AppConfig config) {
    AppEnvironment.config = config;
  }
}
