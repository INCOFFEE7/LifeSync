import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/pages/beebee/add_fasting_debt_page.dart';
import 'package:lifesync_app/presentation/pages/beebee/add_qadha_page.dart';
import 'package:lifesync_app/presentation/pages/beebee/add_menstruation_page.dart';
import 'package:lifesync_app/presentation/screens/cloud_backup_settings_screen.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class BeebeeDashboardPage extends ConsumerWidget {
  const BeebeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtSummaryAsync = ref.watch(totalFastingDebtSummaryProvider);
    final statsAsync = ref.watch(menstrualStatsProvider);
    final activeHaid = ref.watch(activeHaidProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          AppEnvironment.config.logoFullPath,
          width: 140,
          cacheWidth: 420,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (c, e, s) => const Text('LifeSync for Beebee', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: Color(0xFFE91E8C)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloudBackupSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppTranslations.get(lang, 'aksi_cepat'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E8C)),
            ),
            const SizedBox(height: 8),
            _buildQuickActions(context, ref, lang, activeHaid),
            const SizedBox(height: 16),
            _buildFastingCard(context, lang, debtSummaryAsync),
            const SizedBox(height: 12),
            _buildMenstrualCard(context, lang, statsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildFastingCard(BuildContext context, String lang, AsyncValue<Map<String, int>> summaryAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: Color(0xFFC77DFF), size: 26),
                const SizedBox(width: 10),
                Text(AppTranslations.get(lang, 'puasa_tracker'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) {
                final currentDebt = summary['currentDebt'] ?? 0;
                final totalDebt = summary['totalInitialDebt'] ?? 0;
                final totalQadha = summary['totalQadha'] ?? 0;

                double progress = 0;
                if (totalDebt > 0) {
                  progress = (totalQadha / totalDebt).clamp(0.0, 1.0);
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(AppTranslations.get(lang, 'utang'), '$totalDebt', AppTranslations.get(lang, 'hari')),
                        _buildStatBox(AppTranslations.get(lang, 'lunas'), '$totalQadha', AppTranslations.get(lang, 'hari')),
                        _buildStatBox(AppTranslations.get(lang, 'sisa'), '$currentDebt', AppTranslations.get(lang, 'hari'), isHighlight: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFFDE8E9),
                      color: const Color(0xFFE91E8C),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}${AppTranslations.get(lang, 'persen_selesai')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenstrualCard(BuildContext context, String lang, AsyncValue<MenstrualStats> statsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Color(0xFFE91E8C), size: 26),
                const SizedBox(width: 10),
                Text(AppTranslations.get(lang, 'menstrual_tracker'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) {
                String predictionText = '-';
                if (stats.nextPrediction != null) {
                  predictionText = DateFormat('dd MMM yyyy').format(stats.nextPrediction!);
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(AppTranslations.get(lang, 'siklus'), '${stats.avgCycle.toStringAsFixed(0)}', AppTranslations.get(lang, 'hari')),
                        _buildStatBox(AppTranslations.get(lang, 'durasi'), '${stats.avgDuration.toStringAsFixed(0)}', AppTranslations.get(lang, 'hari')),
                        _buildStatBox('H-?', '${stats.countdownDays}', AppTranslations.get(lang, 'hari'), isHighlight: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month, color: Color(0xFFE91E8C), size: 18),
                              const SizedBox(width: 8),
                              Text('${AppTranslations.get(lang, 'prediksi_haid')}: $predictionText', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E8C), fontSize: 13)),
                            ],
                          ),
                          if (stats.lastPeriodDate != null) ...[
                            const SizedBox(height: 6),
                            Text('${AppTranslations.get(lang, 'haid_terakhir')}: ${DateFormat('dd MMM yyyy').format(stats.lastPeriodDate!)}', style: const TextStyle(fontSize: 12, color: Color(0xFFE91E8C))),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, String unit, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFFE91E8C) : const Color(0xFF1F2937),
            )),
            const SizedBox(width: 3),
            Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, String lang, DateTime? activeHaid) {
    final now = DateTime.now();
    final int daysActive = activeHaid != null
        ? DateTime(now.year, now.month, now.day).difference(activeHaid).inDays + 1
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildActionButton(
            title: AppTranslations.get(lang, 'catat_qadha'),
            icon: Icons.add_task,
            bgColor: const Color(0xFFE8F5E9),
            fgColor: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddQadhaPage())),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            title: AppTranslations.get(lang, 'utang_baru'),
            icon: Icons.add_circle_outline,
            bgColor: const Color(0xFFFFF3E0),
            fgColor: const Color(0xFFFF9800),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFastingDebtPage())),
          ),
        ),
        const SizedBox(width: 8),
        // Dynamic Start/Stop Haid button
        Expanded(
          child: activeHaid == null
              ? _buildActionButton(
                  title: AppTranslations.get(lang, 'mulai_haid'),
                  icon: Icons.play_circle_fill,
                  bgColor: const Color(0xFFFDE8E9),
                  fgColor: const Color(0xFFE91E8C),
                  onTap: () async {
                    await ref.read(activeHaidProvider.notifier).startHaid();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppTranslations.get(lang, 'haid_sedang_berjalan'))),
                      );
                    }
                  },
                )
              : _buildHaidActiveButton(context, ref, lang, activeHaid, daysActive),
        ),
      ],
    );
  }

  Widget _buildHaidActiveButton(BuildContext context, WidgetRef ref, String lang, DateTime startDate, int daysActive) {
    return GestureDetector(
      onTap: () async {
        // Show confirm + navigate to add record
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppTranslations.get(lang, 'selesai_haid'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E8C))),
            content: Text('${AppTranslations.get(lang, 'mulai_sejak')}: ${DateFormat('dd MMM yyyy').format(startDate)}\n$daysActive ${AppTranslations.get(lang, 'hari_berjalan')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE91E8C)),
                onPressed: () => Navigator.pop(c, true),
                child: Text(AppTranslations.get(lang, 'selesai_haid')),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await ref.read(activeHaidProvider.notifier).clear();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMenstruationPage(prefillStartDate: startDate),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE91E8C).withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stop_circle, size: 24, color: Color(0xFFE91E8C)),
            const SizedBox(height: 4),
            Text(AppTranslations.get(lang, 'selesai_haid'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE91E8C))),
            Text('$daysActive ${AppTranslations.get(lang, 'hari')}', style: const TextStyle(fontSize: 10, color: Color(0xFFE91E8C))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: fgColor,
        backgroundColor: bgColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
