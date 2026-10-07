import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/config/app_variant.dart';

class FastingHistoryPage extends ConsumerWidget {
  const FastingHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qadhaAsync = ref.watch(qadhaRecordsProvider);
    final debtsAsync = ref.watch(fastingDebtsProvider);
    final summaryAsync = ref.watch(totalFastingDebtSummaryProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 2,
        shadowColor: Colors.pink.withOpacity(0.08),
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppEnvironment.config.getLogoFullPath(isDark),
              width: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (c, e, s) => const Text('BeeNest', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E8C))),
            ),
            const Text(
              "Beebee's little private space.",
              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Top Summary Header Banner ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE8E9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: summaryAsync.when(
                data: (summary) {
                  final totalInitial = summary['totalInitialDebt'] ?? 0;
                  final totalQadha = summary['totalQadha'] ?? 0;
                  final currentDebt = summary['currentDebt'] ?? 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryBox(AppTranslations.get(lang, 'utang'), '$totalInitial Hari', Colors.grey.shade700, isDark),
                      Container(width: 1, height: 32, color: Colors.grey.shade200),
                      _buildSummaryBox(AppTranslations.get(lang, 'lunas'), '$totalQadha Hari', const Color(0xFF10B981), isDark),
                      Container(width: 1, height: 32, color: Colors.grey.shade200),
                      _buildSummaryBox(AppTranslations.get(lang, 'sisa'), '$currentDebt Hari', const Color(0xFFE91E8C), isDark, isHighlight: true),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
          ),

          // ── Section 1: Riwayat Pelunasan Qadha ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.history_edu, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.get(lang, 'riwayat_pelunasan_qadha'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF333333)),
                  ),
                ],
              ),
            ),
          ),
          qadhaAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(AppTranslations.get(lang, 'belum_ada_riwayat_qadha'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = records[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.green.shade100, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.green.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppTranslations.get(lang, 'pelunasan')} ${record.amount} ${AppTranslations.get(lang, 'hari')}',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF333333)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(DateFormat('dd MMM yyyy').format(record.date), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 22),
                                  onPressed: () => _showEditQadhaDialog(context, ref, lang, record),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text(AppTranslations.get(lang, 'hapus_catatan'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        content: Text(AppTranslations.get(lang, 'hapus_qadha_confirm')),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey))),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => Navigator.pop(c, true),
                                            child: Text(AppTranslations.get(lang, 'hapus')),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await ref.read(fastingRepositoryProvider).deleteQadha(record.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: records.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),

          // ── Section 2: Daftar Utang Puasa Ramadan ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFE91E8C), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.get(lang, 'daftar_utang_puasa'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF333333)),
                  ),
                ],
              ),
            ),
          ),
          debtsAsync.when(
            data: (debts) {
              if (debts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        AppTranslations.get(lang, 'alhamdulillah_tidak_ada_utang'),
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = debts[index];
                    final completed = (debt.initialDebt - debt.currentDebt).clamp(0, debt.initialDebt);
                    final isLunas = debt.currentDebt == 0;
                    double progress = debt.initialDebt > 0 ? (completed / debt.initialDebt).clamp(0.0, 1.0) : 0.0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isLunas ? Colors.green.shade100 : Colors.red.shade100, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${AppTranslations.get(lang, 'ramadan')} ${debt.ramadanYear}',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF333333)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLunas ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$completed / ${debt.initialDebt} Hari',
                                    style: TextStyle(
                                      color: isLunas ? Colors.green : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.pink.shade50,
                              color: isLunas ? const Color(0xFF10B981) : const Color(0xFFE91E8C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (debt.reason?.isNotEmpty ?? false) ? debt.reason! : 'Sisa Utang: ${debt.currentDebt} Hari',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 22),
                                      onPressed: () => _showEditDebtDialog(context, ref, lang, debt),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: Text(AppTranslations.get(lang, 'hapus_utang'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text(AppTranslations.get(lang, 'hapus_utang_confirm')),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey))),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                onPressed: () => Navigator.pop(c, true),
                                                child: Text(AppTranslations.get(lang, 'hapus')),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await ref.read(fastingRepositoryProvider).deleteDebt(debt.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: debts.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color, bool isDark, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFFE91E8C) : (isDark ? Colors.white : color),
          ),
        ),
      ],
    );
  }

  void _showEditQadhaDialog(BuildContext context, WidgetRef ref, String lang, QadhaRecord record) {
    int amount = record.amount;
    DateTime date = record.date;
    String notes = record.notes ?? '';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppTranslations.get(lang, 'edit_catatan_qadha'), style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: '$amount',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppTranslations.get(lang, 'jumlah_hari_qadha'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => amount = int.tryParse(val) ?? amount,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppTranslations.get(lang, 'tanggal_qadha'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.green),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => date = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: notes,
                    decoration: InputDecoration(
                      labelText: AppTranslations.get(lang, 'catatan_opsional'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => notes = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  record.amount = amount;
                  record.date = date;
                  record.notes = notes;
                  await ref.read(fastingRepositoryProvider).updateQadha(record);
                  if (context.mounted) Navigator.pop(c);
                },
                child: Text(AppTranslations.get(lang, 'simpan')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDebtDialog(BuildContext context, WidgetRef ref, String lang, FastingDebt debt) {
    int currentDebt = debt.currentDebt;
    String reason = debt.reason ?? '';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppTranslations.get(lang, 'edit_utang'), style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: '$currentDebt',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppTranslations.get(lang, 'sisa_hari'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => currentDebt = int.tryParse(val) ?? currentDebt,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: reason,
                    decoration: InputDecoration(
                      labelText: AppTranslations.get(lang, 'alasan_opsional'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => reason = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  debt.currentDebt = currentDebt;
                  debt.reason = reason;
                  await ref.read(fastingRepositoryProvider).updateDebt(debt);
                  if (context.mounted) Navigator.pop(c);
                },
                child: Text(AppTranslations.get(lang, 'simpan')),
              ),
            ],
          );
        },
      ),
    );
  }
}
