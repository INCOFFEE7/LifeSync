import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/financial_category.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

class DailyFinancialDetailPage extends ConsumerWidget {
  final DateTime date;
  final List<FinancialRecord> records;

  const DailyFinancialDetailPage({
    super.key,
    required this.date,
    required this.records,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = ref.watch(localeProvider).languageCode;
    final fmt = NumberFormat('#,###', 'id_ID');
    final dateLabel = DateFormat('d MMMM yyyy', 'id_ID').format(date);

    final incomes = records.where((r) => r.type == 'income').toList();
    final expenses = records.where((r) => r.type == 'expense').toList();
    final totalIncome = incomes.fold(0.0, (sum, r) => sum + r.amount);
    final totalExpense = expenses.fold(0.0, (sum, r) => sum + r.amount);
    final netBalance = totalIncome - totalExpense;

    Widget sub(String label, double v, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white70)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Rp ${fmt.format(v.toInt())}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c)),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.surface(context),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
        title: Text(
          dateLabel,
          style: TextStyle(color: LsColors.ink(context), fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: LsColors.ink(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LsHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LsEyebrow(AppTranslations.get(lang, 'saldo_bersih'), color: Colors.white70),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${netBalance >= 0 ? '+' : '-'}Rp ${fmt.format(netBalance.abs().toInt())}',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      sub(AppTranslations.get(lang, 'pemasukan'), totalIncome, const Color(0xFF6EE7B7)),
                      const SizedBox(width: 10),
                      sub(AppTranslations.get(lang, 'pengeluaran'), totalExpense, const Color(0xFFFCA5A5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (incomes.isNotEmpty) ...[
                  _sectionHeader(AppTranslations.get(lang, 'pemasukan'), LsColors.income),
                  ...incomes.map((r) => _transactionTile(context, r, isDark, fmt)),
                  const SizedBox(height: 12),
                ],
                if (expenses.isNotEmpty) ...[
                  _sectionHeader(AppTranslations.get(lang, 'pengeluaran'), LsColors.expense),
                  ...expenses.map((r) => _transactionTile(context, r, isDark, fmt)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: color)),
    );
  }

  Widget _transactionTile(BuildContext context, FinancialRecord record, bool isDark, NumberFormat fmt) {
    final cat = FinancialCategory.findById(record.categoryId);
    final isIncome = record.type == 'income';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(cat.icon, size: 18, color: cat.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LsColors.ink(context))),
                  if (record.description != null && record.description!.isNotEmpty)
                    Text(record.description!, style: TextStyle(fontSize: 12, color: LsColors.mute(context))),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}Rp ${fmt.format(record.amount.toInt())}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isIncome ? LsColors.income : LsColors.expense),
            ),
          ],
        ),
      ),
    );
  }
}
