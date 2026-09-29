import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class FastingHistoryPage extends ConsumerWidget {
  const FastingHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qadhaAsync = ref.watch(qadhaRecordsProvider);
    final debtsAsync = ref.watch(fastingDebtsProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppTranslations.get(lang, 'riwayat_puasa'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(AppTranslations.get(lang, 'riwayat_pelunasan_qadha'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF333333))),
            ),
          ),
          qadhaAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.history_edu, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(AppTranslations.get(lang, 'belum_ada_riwayat_qadha'), style: const TextStyle(color: Colors.grey)),
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
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.green.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                        border: Border.all(color: Colors.green.shade50, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppTranslations.get(lang, 'pelunasan')} ${record.amount} ${AppTranslations.get(lang, 'hari')}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF333333)),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(DateFormat('dd MMM yyyy').format(record.date), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 26),
                                  onPressed: () => _showEditQadhaDialog(context, ref, lang, record),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 26),
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
                                            child: Text(AppTranslations.get(lang, 'hapus'))
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
            error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(AppTranslations.get(lang, 'daftar_utang_puasa'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF333333))),
            ),
          ),
          debtsAsync.when(
            data: (debts) {
              if (debts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.done_all, size: 48, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(AppTranslations.get(lang, 'alhamdulillah_tidak_ada_utang'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = debts[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.orange.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                        border: Border.all(color: Colors.orange.shade50, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.nights_stay, color: Colors.orange, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppTranslations.get(lang, 'ramadan')} ${debt.ramadanYear}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF333333)),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('${AppTranslations.get(lang, 'sisa')}: ${debt.currentDebt} / ${debt.initialDebt} ${AppTranslations.get(lang, 'hari')}', 
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 26),
                                  onPressed: () => _showEditDebtDialog(context, ref, lang, debt),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 26),
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
                                            child: Text(AppTranslations.get(lang, 'hapus'))
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
                      ),
                    );
                  },
                  childCount: debts.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showEditQadhaDialog(BuildContext context, WidgetRef ref, String lang, qadha) {
    int amount = qadha.amount;
    String notes = qadha.notes;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppTranslations.get(lang, 'edit_qadha'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: '$amount',
                decoration: InputDecoration(
                  labelText: AppTranslations.get(lang, 'jumlah_hari'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? AppTranslations.get(lang, 'wajib_diisi') : null,
                onSaved: (val) => amount = int.tryParse(val!) ?? amount,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: notes,
                decoration: InputDecoration(
                  labelText: AppTranslations.get(lang, 'catatan'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSaved: (val) => notes = val ?? '',
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
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                qadha.amount = amount;
                qadha.notes = notes;
                await ref.read(fastingRepositoryProvider).updateQadha(qadha);
                if (context.mounted) Navigator.pop(c);
              }
            },
            child: Text(AppTranslations.get(lang, 'simpan')),
          ),
        ],
      ),
    );
  }

  void _showEditDebtDialog(BuildContext context, WidgetRef ref, String lang, debt) {
    int currentDebt = debt.currentDebt;
    String reason = debt.reason;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppTranslations.get(lang, 'edit_utang'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: '$currentDebt',
                decoration: InputDecoration(
                  labelText: AppTranslations.get(lang, 'sisa_hari'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? AppTranslations.get(lang, 'wajib_diisi') : null,
                onSaved: (val) => currentDebt = int.tryParse(val!) ?? currentDebt,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: reason,
                decoration: InputDecoration(
                  labelText: AppTranslations.get(lang, 'alasan'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSaved: (val) => reason = val ?? '',
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
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                debt.currentDebt = currentDebt;
                debt.reason = reason;
                await ref.read(fastingRepositoryProvider).updateDebt(debt);
                if (context.mounted) Navigator.pop(c);
              }
            },
            child: Text(AppTranslations.get(lang, 'simpan')),
          ),
        ],
      ),
    );
  }
}
