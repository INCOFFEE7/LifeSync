import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_financial_note_page.dart';
import 'package:lifesync_app/presentation/pages/financial_note_detail_page.dart';
import 'package:lifesync_app/presentation/widgets/month_day_picker_widget.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

class FinancialRecordsHomePage extends ConsumerStatefulWidget {
  const FinancialRecordsHomePage({super.key});

  @override
  ConsumerState<FinancialRecordsHomePage> createState() => _FinancialRecordsHomePageState();
}

class _FinancialRecordsHomePageState extends ConsumerState<FinancialRecordsHomePage> {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');
  DateTime _selectedDate = DateTime.now();
  String _periodScope = 'month'; // 'month', 'all', 'range'
  DateTimeRange? _selectedDateRange;

  void resetToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _periodScope = 'month';
      _selectedDateRange = null;
    });
  }

  bool _matchesPeriod(DateTime date) {
    if (_periodScope == 'all') return true;
    if (_periodScope == 'range' && _selectedDateRange != null) {
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
    }
    return date.year == _selectedDate.year && date.month == _selectedDate.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _periodScope = 'month';
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(_selectedDate.year, _selectedDate.month, 1),
        end: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: LsColors.brand,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _periodScope = 'range';
      });
    }
  }

  Widget _monthNav() {
    String label;
    if (_periodScope == 'all') {
      label = 'Semua Data';
    } else if (_periodScope == 'range' && _selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      label = '${DateFormat('d MMM', 'id_ID').format(s)} – ${DateFormat('d MMM yyyy', 'id_ID').format(e)}';
    } else {
      label = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);
    }

    final isMonth = _periodScope == 'month';

    Widget arrow(IconData icon, int delta) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isMonth ? () => _shiftMonth(delta) : null,
          child: Opacity(
            opacity: isMonth ? 1.0 : 0.25,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: LsColors.paper(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LsColors.line(context)),
              ),
              child: Icon(icon, size: 18, color: LsColors.ink(context)),
            ),
          ),
        );

    return Row(
      children: [
        arrow(Icons.chevron_left_rounded, -1),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (_periodScope == 'range') {
                _pickDateRange();
              } else {
                _pickMonth();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  const LsEyebrow('Periode'),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: LsColors.ink(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        arrow(Icons.chevron_right_rounded, 1),
      ],
    );
  }

  Widget _filterHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Baris 1: navigasi bulan + capsule dropdown scope ──────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: LsColors.surface(context),
            border: Border(bottom: BorderSide(color: LsColors.line(context))),
          ),
          child: Row(
            children: [
              // Navigasi bulan (panah kiri/kanan + label bulan di tengah)
              _monthNav(),
              const SizedBox(width: 10),
              // Capsule scope dropdown
              LsCapsuleDropdown<String>(
                width: 130,
                value: _periodScope,
                isHighlighted: _periodScope != 'month',
                options: const [
                  LsDropdownOption(value: 'month', label: 'Bulan Ini', icon: Icons.calendar_today_outlined),
                  LsDropdownOption(value: 'all', label: 'Semua Data', icon: Icons.all_inclusive_outlined),
                  LsDropdownOption(value: 'range', label: 'Pilih Rentang', icon: Icons.date_range_outlined),
                ],
                onSelected: (val) {
                  if (val == 'range') {
                    _pickDateRange();
                  } else {
                    setState(() {
                      _periodScope = val;
                      if (val == 'month') _selectedDate = DateTime.now();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        // ── Baris 2: day strip (hanya tampil saat scope 'month') ──────
        if (_periodScope == 'month')
          MonthDayPickerWidget(
            selectedDate: _selectedDate,
            showDayStrip: true,
            isSeeAll: false,
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
      ],
    );
  }

  String _formatAmount(double amount) => 'Rp ${_fmt.format(amount.toInt())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notesAsync = ref.watch(financialNotesNotifierProvider);

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Image.asset(
            AppEnvironment.config.getLogoFullPath(isDark),
            width: 175,
            height: 42,
            cacheWidth: 525,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Text(
              AppEnvironment.config.appName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: -0.5),
            ),
          ),
        ),
      ),
      floatingActionButton: LsCompactFab(
        heroTag: 'financial_note_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditFinancialNotePage(initialDate: _selectedDate)),
          );
        },
        icon: Icons.add_rounded,
        label: 'Catatan Baru',
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allNotes) {
          final displayNotes = allNotes.where((n) => _matchesPeriod(n.note.date)).toList()
            ..sort((a, b) => b.note.date.compareTo(a.note.date));

          double totalIncome = 0.0;
          double totalExpense = 0.0;
          for (var note in displayNotes) {
            totalIncome += note.totalIncome;
            totalExpense += note.totalExpense;
          }
          final balance = totalIncome - totalExpense;

          return Column(
            children: [
              _filterHeader(),

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

  Widget _buildSummaryHeader(double income, double expense, double balance, bool isDark) {
    Widget sub(String label, double v, Color c, IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, size: 14, color: c),
                  const SizedBox(width: 4),
                  Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white70)),
                ]),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_formatAmount(v), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
    final total = income + expense;
    final ratio = total <= 0 ? 0.0 : income / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: LsHeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LsEyebrow('Selisih', color: Colors.white70),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${balance < 0 ? '-' : ''}${_formatAmount(balance.abs())}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(children: [
                  Expanded(flex: (ratio * 1000).round(), child: Container(color: LsColors.income)),
                  Expanded(flex: ((1 - ratio) * 1000).round(), child: Container(color: total <= 0 ? Colors.white24 : LsColors.expense)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              sub('Pemasukan', income, LsColors.income, Icons.arrow_downward_rounded),
              const SizedBox(width: 10),
              sub('Pengeluaran', expense, const Color(0xFFFCA5A5), Icons.arrow_upward_rounded),
            ]),
          ],
        ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: LsColors.brand.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 34, color: LsColors.brand),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan keuangan.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: LsColors.ink(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik "+ Catatan Baru" untuk mulai mencatat pemasukan atau pengeluaran.',
              style: TextStyle(fontSize: 12, color: LsColors.mute(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteWithItems noteItem, bool isDark) {
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(noteItem.note.date);
    final net = noteItem.totalIncome - noteItem.totalExpense;

    Widget col(String label, double v, Color c, {String prefix = ''}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: LsColors.mute(context))),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('$prefix${_formatAmount(v.abs())}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c)),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LsCard(
        padding: const EdgeInsets.all(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinancialNoteDetailPage(noteId: noteItem.note.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: LsColors.brand.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: LsColors.brand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noteItem.note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: LsColors.ink(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: LsColors.mute(context))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: LsColors.mute(context), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: LsColors.paper(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  col('Pemasukan', noteItem.totalIncome, LsColors.income, prefix: '+'),
                  col('Pengeluaran', noteItem.totalExpense, LsColors.expense, prefix: '-'),
                  col('Selisih', net, net >= 0 ? LsColors.brand : LsColors.expense, prefix: net < 0 ? '-' : ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
