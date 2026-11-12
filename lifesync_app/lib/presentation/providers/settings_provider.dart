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

  DefaultSoundNotifier() : super('ringtone_1.mp3') {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sound = prefs.getString(_prefKey) ?? 'ringtone_1.mp3';
    if (sound == 'notif.mp3') {
      state = 'ringtone_1.mp3';
      await prefs.setString(_prefKey, 'ringtone_1.mp3');
    } else {
      state = sound;
    }
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

class FontSizeNotifier extends StateNotifier<double> {
  static const _prefKey = 'app_font_scale';

  FontSizeNotifier() : super(1.0) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_prefKey) ?? 1.0;
  }

  Future<void> setScale(double scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, scale);
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontSizeNotifier, double>((ref) {
  return FontSizeNotifier();
});
