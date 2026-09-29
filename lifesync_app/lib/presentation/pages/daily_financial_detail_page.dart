import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/financial_category.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          dateLabel,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Period Net Balance Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _summaryTile('Rp ${fmt.format(totalIncome.toInt())}', AppTranslations.get(lang, 'pemasukan'), const Color(0xFF10B981), isDark),
                ),
                Container(width: 1, height: 40, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                Expanded(
                  child: _summaryTile('Rp ${fmt.format(totalExpense.toInt())}', AppTranslations.get(lang, 'pengeluaran'), const Color(0xFFEF4444), isDark),
                ),
                Container(width: 1, height: 40, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                Expanded(
                  child: _summaryTile(
                    '${netBalance >= 0 ? '+' : '-'}Rp ${fmt.format(netBalance.abs().toInt())}',
                    AppTranslations.get(lang, 'saldo_bersih'),
                    netBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    isDark,
                  ),
                ),
              ],
            ),
          ),

          // All transactions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (incomes.isNotEmpty) ...[
                  _sectionHeader(AppTranslations.get(lang, 'pemasukan'), const Color(0xFF10B981)),
                  ...incomes.map((r) => _transactionTile(r, isDark, fmt)),
                  const SizedBox(height: 12),
                ],
                if (expenses.isNotEmpty) ...[
                  _sectionHeader(AppTranslations.get(lang, 'pengeluaran'), const Color(0xFFEF4444)),
                  ...expenses.map((r) => _transactionTile(r, isDark, fmt)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String amount, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: color)),
    );
  }

  Widget _transactionTile(FinancialRecord record, bool isDark, NumberFormat fmt) {
    final cat = FinancialCategory.findById(record.categoryId);
    final isIncome = record.type == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: cat.color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(cat.icon, size: 18, color: cat.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                if (record.description != null && record.description!.isNotEmpty)
                  Text(record.description!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}Rp ${fmt.format(record.amount.toInt())}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}
