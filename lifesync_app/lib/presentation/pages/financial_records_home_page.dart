import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_financial_note_page.dart';
import 'package:lifesync_app/presentation/pages/financial_note_detail_page.dart';
import 'package:lifesync_app/presentation/widgets/month_day_picker_widget.dart';
import 'package:lifesync_app/config/app_variant.dart';

class FinancialRecordsHomePage extends ConsumerStatefulWidget {
  const FinancialRecordsHomePage({super.key});

  @override
  ConsumerState<FinancialRecordsHomePage> createState() => _FinancialRecordsHomePageState();
}

class _FinancialRecordsHomePageState extends ConsumerState<FinancialRecordsHomePage> {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');
  DateTime _selectedDate = DateTime.now();
  bool _showAllFinancial = false;

  String _formatAmount(double amount) => 'Rp ${_fmt.format(amount.toInt())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notesAsync = ref.watch(financialNotesNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(25),
        surfaceTintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        scrolledUnderElevation: 4,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Image.asset(
          AppEnvironment.config.getLogoFullPath(isDark),
          width: 140,
          cacheWidth: 420,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Text(
            AppEnvironment.config.appName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: -0.5),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'financial_note_fab',
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditFinancialNotePage()),
          );
        },
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Catatan Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allNotes) {
          final displayNotes = _showAllFinancial
              ? allNotes
              : allNotes.where((n) => isSameDay(n.note.date, _selectedDate)).toList();

          double totalIncome = 0.0;
          double totalExpense = 0.0;
          for (var note in displayNotes) {
            totalIncome += note.totalIncome;
            totalExpense += note.totalExpense;
          }
          final balance = totalIncome - totalExpense;

          return Column(
            children: [
              // Reusable Month & Day Strip Picker Widget
              MonthDayPickerWidget(
                selectedDate: _selectedDate,
                isSeeAll: _showAllFinancial,
                onDateChanged: (date) => setState(() {
                  _selectedDate = date;
                  _showAllFinancial = false;
                }),
              ),

              // "Lihat Semua" / Filter Header Toggle
              _buildSeeAllHeader(_showAllFinancial, isDark),

              // Period Summary (Total Pemasukan, Total Pengeluaran, Saldo)
              _buildSummaryHeader(totalIncome, totalExpense, balance, isDark),

              // Notes List
              Expanded(
                child: displayNotes.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: displayNotes.length,
                        itemBuilder: (context, i) {
                          final noteItem = displayNotes[i];
                          return _buildNoteCard(noteItem, isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeeAllHeader(bool isSeeAll, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isSeeAll ? 'Menampilkan Semua Catatan Keuangan' : 'Sesuai Filter Tanggal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _showAllFinancial = !_showAllFinancial;
                if (!_showAllFinancial) {
                  _selectedDate = DateTime.now(); // Reset back to Today
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSeeAll ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSeeAll ? const Color(0xFF2563EB) : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(isSeeAll ? Icons.filter_list_off : Icons.list_alt, size: 14, color: isSeeAll ? const Color(0xFF2563EB) : Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(
                    isSeeAll ? 'Filter Tanggal' : 'Lihat Semua',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSeeAll ? const Color(0xFF2563EB) : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double income, double expense, double balance, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pemasukan', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_formatAmount(income), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_formatAmount(expense), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selisih', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_formatAmount(balance), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: balance >= 0 ? const Color(0xFF2563EB) : Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan keuangan.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik "+ Catatan Baru" untuk mulai mencatat pemasukan atau pengeluaran.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteWithItems noteItem, bool isDark) {
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(noteItem.note.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinancialNoteDetailPage(noteId: noteItem.note.id),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet, color: Color(0xFF2563EB), size: 20),
        ),
        title: Text(
          noteItem.note.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 3),
            Row(
              children: [
                if (noteItem.totalIncome > 0)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('+${_formatAmount(noteItem.totalIncome)} ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ),
                if (noteItem.totalExpense > 0)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('-${_formatAmount(noteItem.totalExpense)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ),
    );
  }
}
