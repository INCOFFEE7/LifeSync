import 'package:lifesync_app/core/services/csv_export_service.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            _group('Cloud & Cadangan', [
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
              _SettingsRow(
                icon: Icons.file_download_outlined,
                color: LsColors.income,
                title: AppTranslations.get(lang, 'ekspor_csv'),
                subtitle: AppTranslations.get(lang, 'ekspor_csv_sub'),
                trailing: const _Chevron(),
                onTap: () => CsvExportService.showExportDialog(context, ref),
              ),
            ]),
          _group(AppTranslations.get(lang, 'tampilan'), [
            _SettingsRow(
              icon: Icons.brightness_6_rounded,
              color: LsColors.brand,
              title: AppTranslations.get(lang, 'tema_aplikasi'),
              subtitle: switch (ref.watch(themeModeProvider)) {
                ThemeMode.dark => AppTranslations.get(lang, 'mode_gelap'),
                ThemeMode.system => AppTranslations.get(lang, 'mode_sistem'),
                ThemeMode.light => AppTranslations.get(lang, 'mode_terang'),
              },
              trailing: const _Chevron(),
              onTap: () async {
                final currentMode = ref.read(themeModeProvider);
                final selected = await showDialog<ThemeMode>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(AppTranslations.get(lang, 'pilih_tema')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.light_mode_rounded,
                              color: Colors.amber),
                          title: Text(AppTranslations.get(lang, 'mode_terang')),
                          trailing: currentMode == ThemeMode.light
                              ? const Icon(Icons.check_rounded,
                                  color: LsColors.brand)
                              : null,
                          onTap: () => Navigator.pop(c, ThemeMode.light),
                        ),
                        ListTile(
                          leading: const Icon(Icons.dark_mode_rounded,
                              color: Colors.indigo),
                          title: Text(AppTranslations.get(lang, 'mode_gelap')),
                          trailing: currentMode == ThemeMode.dark
                              ? const Icon(Icons.check_rounded,
                                  color: LsColors.brand)
                              : null,
                          onTap: () => Navigator.pop(c, ThemeMode.dark),
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_suggest_rounded,
                              color: Colors.blueGrey),
                          title: Text(AppTranslations.get(lang, 'mode_sistem')),
                          trailing: currentMode == ThemeMode.system
                              ? const Icon(Icons.check_rounded,
                                  color: LsColors.brand)
                              : null,
                          onTap: () => Navigator.pop(c, ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                );
                if (selected != null) {
                  await ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(selected);
                }
              },
            ),
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
          _group(
              AppTranslations.get(lang, 'zona_berbahaya'),
              eyebrowColor: LsColors.expense,
              [
                _SettingsRow(
                  icon: Icons.delete_forever,
                  color: LsColors.expense,
                  danger: true,
                  title: AppTranslations.get(lang, 'hapus_semua_data'),
                  subtitle: AppTranslations.get(lang, 'hapus_semua_data_sub'),
                  trailing: const _Chevron(color: LsColors.expense),
                  onTap: () async {
                    final firstConfirm = await showLsConfirmDialog(
                      context: context,
                      title: 'Hapus Seluruh Data?',
                      message:
                          'Semua Catatan Keuangan, Belanja, Tagihan, Target Nabung, dan Agenda akan dihapus.',
                      confirmLabel: 'Lanjutkan',
                      cancelLabel: 'Batal',
                      isDanger: true,
                    );
                    if (firstConfirm != true) return;

                    if (!context.mounted) return;
                    bool understood = false;
                    final secondConfirm = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (modalCtx) {
                        return StatefulBuilder(
                          builder: (ctx, setModalState) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: LsColors.expense
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: LsColors.expense,
                                        size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Konfirmasi Terakhir',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tindakan ini permanen. Semua data lokal di aplikasi akan dihapus bersih tanpa bisa dikembalikan.',
                                    style: TextStyle(fontSize: 13, height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: LsColors.expense
                                          .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: LsColors.expense
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: CheckboxListTile(
                                      value: understood,
                                      activeColor: LsColors.expense,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      title: const Text(
                                        'Saya memahami bahwa seluruh data akan dihapus permanen dan tidak dapat dipulihkan.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: LsColors.expense),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                      onChanged: (val) {
                                        setModalState(
                                            () => understood = val ?? false);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              actionsPadding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              actions: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(modalCtx, false),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                        ),
                                        child: const Text('Batal'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: understood
                                            ? () =>
                                                Navigator.pop(modalCtx, true)
                                            : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: LsColors.expense,
                                          disabledBackgroundColor: LsColors
                                              .expense
                                              .withValues(alpha: 0.3),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                        ),
                                        child: const Text('Hapus Sekarang',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );

                    if (secondConfirm == true && context.mounted) {
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
                          await dbService.db.shoppingItems.clear();
                          await dbService.db.fastingDebts.clear();
                          await dbService.db.qadhaRecords.clear();
                          await dbService.db.menstruationRecords.clear();
                          await dbService.db.appSettings.clear();
                        });

                        await NotificationService().cancelAll();
                        try {
                          await HomeWidget.saveWidgetData(
                              'pinned_target_ids', '');
                          await HomeWidget.saveWidgetData(
                              'pinned_reminder_ids', '');
                          await HomeWidget.updateWidget(
                              androidName: 'TargetWidgetProvider');
                          await HomeWidget.updateWidget(
                              androidName: 'ReminderWidgetProvider');
                        } catch (_) {}

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_deleted_all', true);
                        await prefs.setBool(
                            'is_first_installation_complete', true);

                        // Invalidate Riverpod states
                        ref.invalidate(dashboardDataProvider);
                        ref.invalidate(financialNotesNotifierProvider);
                        ref.invalidate(shoppingItemsProvider);
                        ref.invalidate(targetsStreamProvider);
                        ref.invalidate(remindersStreamProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seluruh data berhasil dihapus.'),
                              backgroundColor: LsColors.expense,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menghapus data: $e'),
                              backgroundColor: LsColors.expense,
                            ),
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
