import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [StateNotifier] that holds the current app [Locale].
/// It persists the selected language using [SharedPreferences] so the choice is
/// retained across app restarts.
class LocaleNotifier extends StateNotifier<Locale> {
  static const _prefKey = 'selected_locale';

  LocaleNotifier() : super(const Locale('id')) {
    _loadFromPrefs();
  }

  // Load saved locale from SharedPreferences.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString(_prefKey) ?? 'id';
    state = Locale(localeString);
  }

  /// Change app locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}

/// Riverpod provider exposing the [LocaleNotifier].
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
