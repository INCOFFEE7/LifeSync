import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final defaultSoundProvider = StateNotifierProvider<DefaultSoundNotifier, String>((ref) {
  return DefaultSoundNotifier();
});
