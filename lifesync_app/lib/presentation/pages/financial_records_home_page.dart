import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/pages/financial_note_detail_page.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:lifesync_app/presentation/widgets/ls_date_time_picker_sheet.dart';

class FinancialRecordsHomePage extends ConsumerStatefulWidget {
  const FinancialRecordsHomePage({super.key});

  @override
  ConsumerState<FinancialRecordsHomePage> createState() =>
      _FinancialRecordsHomePageState();
}

class _FinancialRecordsHomePageState
    extends ConsumerState<FinancialRecordsHomePage> {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDay;
  String _periodScope = 'month'; // 'month', 'all', 'range'
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  void resetToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedDay = null;
      _periodScope = 'month';
      _selectedDateRange = null;
    });
  }

  bool _matchesPeriod(DateTime date) {
    if (_periodScope == 'all') return true;
    if (_periodScope == 'range' && _selectedDateRange != null) {
      final start = DateTime(_selectedDateRange!.start.year,
          _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59);
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end.add(const Duration(seconds: 1)));
    }
    // Scope: month
    final isSameMonth =
        date.year == _selectedDate.year && date.month == _selectedDate.month;
    if (!isSameMonth) return false;
    if (_selectedDay != null) {
      return date.day == _selectedDay!.day;
    }
    return true;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
      _selectedDay = null;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _selectedDate,
      enableTime: false,
      title: 'Pilih Periode Kalender',
      confirmLabel: 'Terapkan Periode',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedDay = null;
        _periodScope = 'month';
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showLsDateRangePickerSheet(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(_selectedDate.year, _selectedDate.month, 1),
            end: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
          ),
      title: 'Pilih Rentang Tanggal Transaksi',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _periodScope = 'range';
        _selectedDay = null;
      });
    }
  }

  Widget _buildIconFilterButton<T>({
    required T value,
    required IconData icon,
    required Color color,
    required bool isHighlighted,
    required String tooltip,
    required List<LsDropdownOption<T>> options,
    required ValueChanged<T> onSelected,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: LsColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: LsColors.line(context)),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        initialValue: value,
        onSelected: onSelected,
        offset: const Offset(0, 40),
        itemBuilder: (ctx) => options.map((opt) {
          final isSelected = opt.value == value;
          final itemColor =
              opt.color ?? (isSelected ? LsColors.brand : LsColors.ink(ctx));
          return PopupMenuItem<T>(
            value: opt.value,
            child: Row(
              children: [
                Icon(opt.icon, size: 18, color: itemColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: itemColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, size: 16, color: itemColor),
              ],
            ),
          );
        }).toList(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isHighlighted
                ? color.withValues(alpha: 0.12)
                : LsColors.paper(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted ? color : LsColors.line(context),
              width: isHighlighted ? 1.5 : 1.0,
            ),
          ),
          child: Icon(icon,
              size: 18, color: isHighlighted ? color : LsColors.ink(context)),
        ),
      ),
    );
  }

  Widget _filterHeader(List<NoteWithItems> allNotes) {
    String label;
    if (_periodScope == 'all') {
      label = 'Semua Data';
    } else if (_periodScope == 'range' && _selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      label =
          '${DateFormat('d MMM', 'id_ID').format(s)} – ${DateFormat('d MMM yyyy', 'id_ID').format(e)}';
    } else {
      label = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);
    }

    final isMonth = _periodScope == 'month';

    Widget arrow(IconData icon, int delta) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isMonth ? () => _shiftMonth(delta) : null,
          child: Opacity(
            opacity: isMonth ? 1.0 : 0.25,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: LsColors.paper(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LsColors.line(context)),
              ),
              child: Icon(icon, size: 18, color: LsColors.ink(context)),
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: LsColors.surface(context),
        border: Border(bottom: BorderSide(color: LsColors.line(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                arrow(Icons.chevron_left_rounded, -1),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (_periodScope == 'range') {
                      _pickDateRange();
                    } else {
                      _pickMonth();
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: LsColors.paper(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LsColors.line(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 18, color: LsColors.mute(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                arrow(Icons.chevron_right_rounded, 1),
                const Spacer(),
                if (_periodScope == 'month' && _selectedDay != null) ...[
                  InkWell(
                    onTap: () => setState(() => _selectedDay = null),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: LsColors.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: LsColors.brand.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tgl ${_selectedDay!.day}',
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: LsColors.brand),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close_rounded,
                              size: 14, color: LsColors.brand),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildIconFilterButton<String>(
                  value: _periodScope,
                  icon: _periodScope == 'range'
                      ? Icons.date_range_rounded
                      : (_periodScope == 'all'
                          ? Icons.all_inclusive_rounded
                          : Icons.calendar_today_rounded),
                  color: LsColors.brand,
                  isHighlighted: _periodScope != 'month',
                  tooltip: 'Filter Periode',
                  options: const [
                    LsDropdownOption(
                        value: 'month',
                        label: 'Bulan Ini',
                        icon: Icons.calendar_today_outlined),
                    LsDropdownOption(
                        value: 'all',
                        label: 'Semua Data',
                        icon: Icons.all_inclusive_outlined),
                    LsDropdownOption(
                        value: 'range',
                        label: 'Pilih Rentang',
                        icon: Icons.date_range_outlined),
                  ],
                  onSelected: (val) {
                    if (val == 'range') {
                      _pickDateRange();
                    } else {
                      setState(() {
                        _periodScope = val;
                        _selectedDay = null;
                        if (val == 'month') _selectedDate = DateTime.now();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          if (_periodScope == 'month') _buildDayStrip(allNotes),
        ],
      ),
    );
  }

  Widget _buildDayStrip(List<NoteWithItems> allNotes) {
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeDays = <int>{};
    for (final note in allNotes) {
      if (note.note.date.year == _selectedDate.year &&
          note.note.date.month == _selectedDate.month) {
        activeDays.add(note.note.date.day);
      }
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: daysInMonth,
        itemBuilder: (context, idx) {
          final day = idx + 1;
          final date = DateTime(_selectedDate.year, _selectedDate.month, day);
          final isSelected = _selectedDay != null &&
              _selectedDay!.year == date.year &&
              _selectedDay!.month == date.month &&
              _selectedDay!.day == date.day;
          final isToday = DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;
          final hasNotes = activeDays.contains(day);
          final dayName = DateFormat('E', 'id_ID').format(date);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDay = null;
                  ref.read(selectedFinancialDateProvider.notifier).state =
                      _selectedDate;
                } else {
                  _selectedDay = date;
                  ref.read(selectedFinancialDateProvider.notifier).state = date;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? LsColors.brand
                    : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? LsColors.brand
                      : (isToday
                          ? LsColors.brand.withValues(alpha: 0.5)
                          : Colors.transparent),
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : LsColors.mute(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : LsColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white
                          : (hasNotes ? LsColors.brand : Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                  letterSpacing: -0.5),
            ),
          ),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allNotes) {
          final displayNotes = allNotes.where((n) {
            if (!_matchesPeriod(n.note.date)) return false;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matchTitle = n.note.title.toLowerCase().contains(q);
              final matchItem =
                  n.items.any((it) => it.description.toLowerCase().contains(q));
              if (!matchTitle && !matchItem) return false;
            }
            return true;
          }).toList()
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
              _filterHeader(allNotes),

              // Period Summary (Total Pemasukan, Total Pengeluaran, Saldo)
              _buildSummaryHeader(totalIncome, totalExpense, balance, isDark),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: AppTranslations.get(
                        ref.watch(localeProvider).languageCode,
                        'cari_catatan_transaksi'),
                    hintStyle:
                        TextStyle(fontSize: 13, color: LsColors.mute(context)),
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: LsColors.brand),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: LsColors.surface(context),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: LsColors.line(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: LsColors.line(context)),
                    ),
                  ),
                ),
              ),

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

  Widget _buildSummaryHeader(
      double income, double expense, double balance, bool isDark) {
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
                  Text(label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white70)),
                ]),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_formatAmount(v),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
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
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Colors.white,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(children: [
                  Expanded(
                      flex: (ratio * 1000).round(),
                      child: Container(color: LsColors.income)),
                  Expanded(
                      flex: ((1 - ratio) * 1000).round(),
                      child: Container(
                          color:
                              total <= 0 ? Colors.white24 : LsColors.expense)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              sub('Pemasukan', income, LsColors.income,
                  Icons.arrow_downward_rounded),
              const SizedBox(width: 10),
              sub('Pengeluaran', expense, const Color(0xFFFCA5A5),
                  Icons.arrow_upward_rounded),
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
              decoration: BoxDecoration(
                  color: LsColors.brand.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 34, color: LsColors.brand),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan keuangan.',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LsColors.ink(context)),
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
    final dateStr =
        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(noteItem.note.date);
    final net = noteItem.totalIncome - noteItem.totalExpense;

    Widget col(String label, double v, Color c, {String prefix = ''}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: LsColors.mute(context))),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('$prefix${_formatAmount(v.abs())}',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w800, color: c)),
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
                  decoration: BoxDecoration(
                      color: LsColors.brand.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: LsColors.brand, size: 20),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: LsColors.ink(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 11, color: LsColors.mute(context))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: LsColors.mute(context), size: 20),
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
                  col('Pemasukan', noteItem.totalIncome, LsColors.income,
                      prefix: '+'),
                  col('Pengeluaran', noteItem.totalExpense, LsColors.expense,
                      prefix: '-'),
                  col('Selisih', net,
                      net >= 0 ? LsColors.brand : LsColors.expense,
                      prefix: net < 0 ? '-' : ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
