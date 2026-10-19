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
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

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
    setState(() {
      _version = 'v2026.10.15.02.01';
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

  Widget _group(String eyebrow, List<Widget> rows, {Color? eyebrowColor}) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0)
        children
            .add(Divider(height: 1, indent: 66, color: LsColors.line(context)));
      children.add(rows[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: LsEyebrow(eyebrow, color: eyebrowColor),
          ),
          LsCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(children: children))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        title: Text(AppTranslations.get(lang, 'pengaturan')),
        centerTitle: true,
        backgroundColor: LsColors.paper(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const _ProfileHeader(name: 'LifeSync'),
          const SizedBox(height: 22),
          if (AppEnvironment.config.variant != AppVariant.beebee)
            _group('Cloud', [
              _SettingsRow(
                icon: Icons.cloud_sync,
                color: LsColors.brand,
                title: AppTranslations.get(lang, 'cloud_backup_sync'),
                subtitle: AppTranslations.get(lang, 'google_drive_integration'),
                trailing: const _Chevron(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CloudBackupSettingsScreen()),
                  );
                },
              ),
            ]),
          _group('Tampilan', [
            _SettingsRow(
              icon: Icons.language,
              color: LsColors.violet,
              title: AppTranslations.get(lang, 'bahasa'),
              subtitle: lang == 'en' ? 'English' : 'Indonesia',
              trailing: const _Chevron(),
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
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(selected));
                }
              },
            ),
          ]),
          _group(AppTranslations.get(lang, 'nada_dering_default'), [
            _SettingsRow(
              icon: Icons.music_note,
              color: LsColors.amber,
              title: AppTranslations.get(lang, 'nada_dering_default'),
              subtitle: ref.watch(defaultSoundProvider).contains('/')
                  ? AppTranslations.get(lang, 'custom_sound')
                  : AppTranslations.get(lang, 'default_sound'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                        _isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                        color: LsColors.brand),
                    onPressed: _testSound,
                  ),
                  const _Chevron(),
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
                          leading:
                              const Icon(Icons.music_note, color: Colors.blue),
                          title:
                              Text(AppTranslations.get(lang, 'default_sound')),
                          onTap: () => Navigator.pop(c, 'notif.mp3'),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.folder_open, color: Colors.blue),
                          title: Text(
                              AppTranslations.get(lang, 'pilih_dari_file')),
                          onTap: () async {
                            Navigator.pop(c);
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.audio,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              await ref
                                  .read(defaultSoundProvider.notifier)
                                  .setSound(result.files.single.path!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
                if (selected != null) {
                  await ref
                      .read(defaultSoundProvider.notifier)
                      .setSound(selected);
                }
              },
            ),
          ]),
          _group('Troubleshooting', [
            _SettingsRow(
              icon: Icons.widgets,
              color: LsColors.amber,
              title: 'Perbaiki Widget (Samsung)',
              subtitle: 'Gunakan jika widget tidak muncul di layar utama',
              trailing: const _Chevron(),
              onTap: () async {
                try {
                  await HomeWidgetService.requestPinTargetWidget();
                  await Future.delayed(const Duration(milliseconds: 500));
                  await HomeWidgetService.requestPinReminderWidget();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Permintaan widget telah dikirim ke layar utama')),
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
          ]),
          _group('Zona Berbahaya', eyebrowColor: LsColors.expense, [
            _SettingsRow(
              icon: Icons.delete_forever,
              color: LsColors.expense,
              danger: true,
              title: 'Hapus Seluruh Data',
              subtitle: 'Hapus semua Reminder, Finance, dan Savings',
              trailing: const _Chevron(color: LsColors.expense),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Hapus Seluruh Data?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                    content: const Text(
                        'Semua Reminder, Finance, dan Savings akan dihapus. Tindakan ini tidak dapat dibatalkan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final dbService = ref.read(databaseServiceProvider);
                    await dbService.db.writeTxn(() async {
                      await dbService.db.reminders.clear();
                      await dbService.db.incomeTargets.clear();
                      await dbService.db.dailyIncomeRecords.clear();
                      await dbService.db.financialRecords.clear();
                      await dbService.db.financialNotes.clear();
                      await dbService.db.financialItems.clear();
                      await dbService.db.bills.clear();
                      await dbService.db.fastingDebts.clear();
                      await dbService.db.qadhaRecords.clear();
                      await dbService.db.menstruationRecords.clear();
                      await dbService.db.appSettings.clear();
                    });

                    await NotificationService().cancelAll();
                    try {
                      await HomeWidget.saveWidgetData('pinned_target_ids', '');
                      await HomeWidget.saveWidgetData(
                          'pinned_reminder_ids', '');
                      await HomeWidget.updateWidget(
                          androidName:
                              'com.example.lifesync_app.TargetWidgetProvider');
                      await HomeWidget.updateWidget(
                          androidName:
                              'com.example.lifesync_app.ReminderWidgetProvider');
                    } catch (_) {}

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_deleted_all', true);
                    await prefs.setBool('is_first_installation_complete', true);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seluruh data berhasil dihapus.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Gagal menghapus data: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ]),
          _group(AppTranslations.get(lang, 'tentang_aplikasi'), [
            _SettingsRow(
              icon: Icons.info_outline,
              color: LsColors.brand,
              title: AppTranslations.get(lang, 'versi_aplikasi'),
              trailing: LsChip(_version, color: LsColors.brand),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  const _ProfileHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return LsCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [LsColors.heroTop, LsColors.heroBottom]),
            ),
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: LsColors.ink(context),
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text('Pengaturan aplikasi',
                    style:
                        TextStyle(fontSize: 12, color: LsColors.mute(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final Color? color;
  const _Chevron({this.color});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right_rounded, color: color ?? LsColors.mute(context));
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: danger
                              ? LsColors.expense
                              : LsColors.ink(context))),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11.5, color: LsColors.mute(context))),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
