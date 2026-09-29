import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/presentation/providers/settings_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/screens/cloud_backup_settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:lifesync_app/config/app_variant.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _version = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _testSound() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      return;
    }
    final currentSound = ref.read(defaultSoundProvider);
    if (currentSound.contains('/')) {
      await _audioPlayer.play(DeviceFileSource(currentSound));
    } else {
      await _audioPlayer.play(AssetSource('audios/notif.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.get(lang, 'pengaturan')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            AppTranslations.get(lang, 'pengaturan'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          if (AppEnvironment.config.variant != AppVariant.beebee)
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: Colors.blue),
              title: Text(AppTranslations.get(lang, 'cloud_backup_sync')),
              subtitle: Text(AppTranslations.get(lang, 'google_drive_integration')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CloudBackupSettingsScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppTranslations.get(lang, 'bahasa')),
            subtitle: Text(lang == 'en' ? 'English' : 'Indonesia'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(AppTranslations.get(lang, 'pilih_bahasa')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Indonesia'),
                          onTap: () => Navigator.pop(c, 'id'),
                        ),
                        ListTile(
                          title: const Text('English'),
                          onTap: () => Navigator.pop(c, 'en'),
                        ),
                      ],
                    ),
                  ),
                );
                if (selected != null) {
                  await ref.read(localeProvider.notifier).setLocale(Locale(selected));
                }
              },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(AppTranslations.get(lang, 'nada_dering_default')),
            subtitle: Text(ref.watch(defaultSoundProvider).contains('/') ? AppTranslations.get(lang, 'custom_sound') : AppTranslations.get(lang, 'default_sound')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle_fill, color: Colors.blue),
                  onPressed: _testSound,
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(AppTranslations.get(lang, 'pilih_nada_dering')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.blue),
                        title: Text(AppTranslations.get(lang, 'default_sound')),
                        onTap: () => Navigator.pop(c, 'notif.mp3'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder_open, color: Colors.blue),
                        title: Text(AppTranslations.get(lang, 'pilih_dari_file')),
                        onTap: () async {
                          Navigator.pop(c);
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.audio,
                          );
                          if (result != null && result.files.single.path != null) {
                            await ref.read(defaultSoundProvider.notifier).setSound(result.files.single.path!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
              if (selected != null) {
                await ref.read(defaultSoundProvider.notifier).setSound(selected);
              }
            },
          ),
          const Divider(),
          Text(
            'Troubleshooting',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.widgets, color: Colors.orange),
            title: const Text('Perbaiki Widget (Samsung)'),
            subtitle: const Text('Gunakan jika widget tidak muncul di layar utama'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                await HomeWidgetService.requestPinTargetWidget();
                await Future.delayed(const Duration(milliseconds: 500));
                await HomeWidgetService.requestPinReminderWidget();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permintaan widget telah dikirim ke layar utama')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              }
            },
          ),
          const Divider(),
          Text(
            AppTranslations.get(lang, 'tentang_aplikasi'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppTranslations.get(lang, 'versi_aplikasi')),
            trailing: Text(_version, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
