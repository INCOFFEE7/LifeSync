import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _prefKey = 'app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_prefKey) ?? 'light';
    switch (modeStr) {
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
        state = ThemeMode.system;
        break;
      case 'light':
      default:
        state = ThemeMode.light;
        break;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final modeStr = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_prefKey, modeStr);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class DefaultSoundNotifier extends StateNotifier<String> {
  static const _prefKey = 'default_reminder_sound';

  DefaultSoundNotifier() : super('notif.mp3') {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sound = prefs.getString(_prefKey) ?? 'notif.mp3';
    state = sound;
  }

  Future<void> setSound(String sound) async {
    state = sound;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, sound);
  }
}

final defaultSoundProvider =
    StateNotifierProvider<DefaultSoundNotifier, String>((ref) {
  return DefaultSoundNotifier();
});
