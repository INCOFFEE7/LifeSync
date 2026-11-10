import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

Future<DateTime?> showLsDateTimePickerSheet({
  required BuildContext context,
  DateTime? initialDateTime,
  DateTime? minimumDate,
  DateTime? maximumDate,
  DateTime? firstDate,
  DateTime? lastDate,
  bool enableTime = true,
  String title = 'Pilih Tanggal & Waktu',
  String confirmLabel = 'Terapkan',
}) {
  final min = minimumDate ?? firstDate;
  final max = maximumDate ?? lastDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LsColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => LsDateTimePickerSheet(
      initialDateTime: initialDateTime ?? DateTime.now(),
      minimumDate: min,
      maximumDate: max,
      enableTime: enableTime,
      title: title,
      confirmLabel: confirmLabel,
    ),
  );
}

class LsDateTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final bool enableTime;
  final String title;
  final String confirmLabel;

  const LsDateTimePickerSheet({
    super.key,
    required this.initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.enableTime = true,
    this.title = 'Pilih Tanggal & Waktu',
    this.confirmLabel = 'Terapkan',
  });

  @override
  State<LsDateTimePickerSheet> createState() => _LsDateTimePickerSheetState();
}

class _LsDateTimePickerSheetState extends State<LsDateTimePickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late DateTime _viewMonth;

  static const _quickTimes = <TimeOfDay>[
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
    _viewMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta, 1);
    });
  }

  void _selectPreset(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _viewMonth = DateTime(date.year, date.month, 1);
    });
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minimumDate != null) {
      final min = DateTime(widget.minimumDate!.year, widget.minimumDate!.month,
          widget.minimumDate!.day);
      if (date.isBefore(min)) return true;
    }
    if (widget.maximumDate != null) {
      final max = DateTime(widget.maximumDate!.year, widget.maximumDate!.month,
          widget.maximumDate!.day);
      if (date.isAfter(max)) return true;
    }
    return false;
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    // Weekend calculation (Saturday)
    final daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
    final weekend = today
        .add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));

    final combinedResult = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      widget.enableTime ? _selectedTime.hour : 0,
      widget.enableTime ? _selectedTime.minute : 0,
    );

    final lang = Localizations.localeOf(context).languageCode;
    final dateLocale = lang == 'en' ? 'en_US' : 'id_ID';
    final dayHeaders = lang == 'en'
        ? const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : const ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Sheet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LsColors.ink(context),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.enableTime
                            ? DateFormat('EEEE, d MMM yyyy • HH:mm', dateLocale)
                                .format(combinedResult)
                            : DateFormat('EEEE, d MMMM yyyy', dateLocale)
                                .format(combinedResult),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: LsColors.brand,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: LsColors.mute(context)),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Preset Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _presetChip('Hari Ini', today),
                    const SizedBox(width: 6),
                    _presetChip('Besok', tomorrow),
                    const SizedBox(width: 6),
                    _presetChip('Akhir Pekan', weekend),
                    const SizedBox(width: 6),
                    _presetChip('+1 Minggu', nextWeek),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Calendar Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LsColors.paper(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LsColors.line(context)),
                ),
                child: Column(
                  children: [
                    // Month Navigation Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _shiftMonth(-1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: LsColors.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LsColors.line(context)),
                            ),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 18, color: LsColors.ink(context)),
                          ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', dateLocale).format(_viewMonth),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context),
                          ),
                        ),
                        InkWell(
                          onTap: () => _shiftMonth(1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: LsColors.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LsColors.line(context)),
                            ),
                            child: Icon(Icons.chevron_right_rounded,
                                size: 18, color: LsColors.ink(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Day Headers (Min .. Sab or Sun .. Sat)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: dayHeaders
                          .map(
                            (d) => SizedBox(
                              width: 36,
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),

                    // Calendar Grid
                    _buildMonthGrid(),
                  ],
                ),
              ),

              // Time Section (if enabled)
              if (widget.enableTime) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Jam',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: LsColors.ink(context),
                      ),
                    ),
                    InkWell(
                      onTap: _pickCustomTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: LsColors.brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: LsColors.brand.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimeOfDay(_selectedTime),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: LsColors.brand,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: LsColors.brand),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ..._quickTimes.map((t) {
                      final isSelected = _selectedTime.hour == t.hour &&
                          _selectedTime.minute == t.minute;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: InkWell(
                            onTap: () => setState(() => _selectedTime = t),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? LsColors.brand
                                    : LsColors.paper(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? LsColors.brand
                                      : LsColors.line(context),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _formatTimeOfDay(t),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : LsColors.ink(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _pickCustomTime,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: LsColors.paper(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: LsColors.line(context)),
                        ),
                        child: Text(
                          'Kustom...',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: LsColors.mute(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: LsColors.line(context)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: LsColors.ink(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: LsColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, combinedResult),
                      child: Text(
                        widget.confirmLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return InkWell(
      onTap: () => _selectPreset(date),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? LsColors.brand : LsColors.paper(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LsColors.brand : LsColors.line(context),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : LsColors.ink(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalCells = ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (ctx, idx) {
        final dayNumber = idx - startWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
        final isSelected = _selectedDate.year == cellDate.year &&
            _selectedDate.month == cellDate.month &&
            _selectedDate.day == cellDate.day;
        final isToday = today.year == cellDate.year &&
            today.month == cellDate.month &&
            today.day == cellDate.day;
        final isDisabled = _isDateDisabled(cellDate);

        Color textColor;
        if (isDisabled) {
          textColor = LsColors.mute(context).withValues(alpha: 0.4);
        } else if (isSelected) {
          textColor = Colors.white;
        } else if (isToday) {
          textColor = LsColors.brand;
        } else {
          textColor = LsColors.ink(context);
        }

        return Center(
          child: InkWell(
            onTap: isDisabled
                ? null
                : () => setState(() => _selectedDate = cellDate),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? LsColors.brand : Colors.transparent,
                border: !isSelected && isToday
                    ? Border.all(
                        color: LsColors.brand.withValues(alpha: 0.6),
                        width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modal bottom sheet for choosing a date range with modern UX.
Future<DateTimeRange?> showLsDateRangePickerSheet({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Pilih Rentang Tanggal',
  String confirmLabel = 'Terapkan Rentang',
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LsColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => LsDateRangePickerSheet(
      initialDateRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      confirmLabel: confirmLabel,
    ),
  );
}

class LsDateRangePickerSheet extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;
  final String confirmLabel;

  const LsDateRangePickerSheet({
    super.key,
    this.initialDateRange,
    this.firstDate,
    this.lastDate,
    this.title = 'Pilih Rentang Tanggal',
    this.confirmLabel = 'Terapkan Rentang',
  });

  @override
  State<LsDateRangePickerSheet> createState() => _LsDateRangePickerSheetState();
}

class _LsDateRangePickerSheetState extends State<LsDateRangePickerSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateRange != null) {
      _startDate = DateTime(
        widget.initialDateRange!.start.year,
        widget.initialDateRange!.start.month,
        widget.initialDateRange!.start.day,
      );
      _endDate = DateTime(
        widget.initialDateRange!.end.year,
        widget.initialDateRange!.end.month,
        widget.initialDateRange!.end.day,
      );
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    }
    _viewMonth = DateTime(_startDate!.year, _startDate!.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta, 1);
    });
  }

  void _selectPresetRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
      _viewMonth = DateTime(_startDate!.year, _startDate!.month, 1);
    });
  }

  void _onDateTap(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Mulai rentang baru
        _startDate = date;
        _endDate = null;
      } else {
        // Memilih akhir rentang
        if (date.isBefore(_startDate!)) {
          _startDate = date;
          _endDate = null;
        } else {
          _endDate = date;
        }
      }
    });
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.firstDate != null) {
      final min = DateTime(widget.firstDate!.year, widget.firstDate!.month,
          widget.firstDate!.day);
      if (date.isBefore(min)) return true;
    }
    if (widget.lastDate != null) {
      final max = DateTime(
          widget.lastDate!.year, widget.lastDate!.month, widget.lastDate!.day);
      if (date.isAfter(max)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final last7DaysStart = today.subtract(const Duration(days: 6));
    final last30DaysStart = today.subtract(const Duration(days: 29));
    final thisMonthStart = DateTime(today.year, today.month, 1);
    final thisMonthEnd = DateTime(today.year, today.month + 1, 0);
    final lastMonthStart = DateTime(today.year, today.month - 1, 1);
    final lastMonthEnd = DateTime(today.year, today.month, 0);
    final thisYearStart = DateTime(today.year, 1, 1);
    final thisYearEnd = DateTime(today.year, 12, 31);

    final totalDays = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays + 1
        : (_startDate != null ? 1 : 0);

    final lang = Localizations.localeOf(context).languageCode;
    final dateLocale = lang == 'en' ? 'en_US' : 'id_ID';
    final dayHeaders = lang == 'en'
        ? const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : const ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Sheet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('d MMM yyyy', dateLocale).format(_startDate!)} — ${DateFormat('d MMM yyyy', dateLocale).format(_endDate!)}'
                                  : (_startDate != null
                                      ? '${DateFormat('d MMM yyyy', dateLocale).format(_startDate!)} ➔ ${AppTranslations.get(lang, 'pilih_tanggal_selesai')}'
                                      : AppTranslations.get(lang, 'pilih_tanggal_mulai_selesai')),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: LsColors.brand,
                              ),
                            ),
                            if (totalDays > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LsColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$totalDays Hari',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: LsColors.brand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: LsColors.mute(context)),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Preset Range Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _presetRangeChip('7 Hari Terakhir', last7DaysStart, today),
                    const SizedBox(width: 6),
                    _presetRangeChip(
                        '30 Hari Terakhir', last30DaysStart, today),
                    const SizedBox(width: 6),
                    _presetRangeChip('Bulan Ini', thisMonthStart, thisMonthEnd),
                    const SizedBox(width: 6),
                    _presetRangeChip(
                        'Bulan Lalu', lastMonthStart, lastMonthEnd),
                    const SizedBox(width: 6),
                    _presetRangeChip('Tahun Ini', thisYearStart, thisYearEnd),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Calendar Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LsColors.paper(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LsColors.line(context)),
                ),
                child: Column(
                  children: [
                    // Month Navigation Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _shiftMonth(-1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: LsColors.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LsColors.line(context)),
                            ),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 18, color: LsColors.ink(context)),
                          ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', dateLocale).format(_viewMonth),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context),
                          ),
                        ),
                        InkWell(
                          onTap: () => _shiftMonth(1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: LsColors.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LsColors.line(context)),
                            ),
                            child: Icon(Icons.chevron_right_rounded,
                                size: 18, color: LsColors.ink(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Day Headers (Min .. Sab or Sun .. Sat)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: dayHeaders
                          .map(
                            (d) => SizedBox(
                              width: 36,
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),

                    // Range Month Grid
                    _buildRangeMonthGrid(),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: LsColors.line(context)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: LsColors.ink(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: LsColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _startDate == null
                          ? null
                          : () {
                              final start = _startDate!;
                              final end = _endDate ?? _startDate!;
                              Navigator.pop(
                                context,
                                DateTimeRange(start: start, end: end),
                              );
                            },
                      child: Text(
                        widget.confirmLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetRangeChip(String label, DateTime start, DateTime end) {
    final isSelected = _startDate != null &&
        _endDate != null &&
        _startDate!.year == start.year &&
        _startDate!.month == start.month &&
        _startDate!.day == start.day &&
        _endDate!.year == end.year &&
        _endDate!.month == end.month &&
        _endDate!.day == end.day;

    return InkWell(
      onTap: () => _selectPresetRange(start, end),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? LsColors.brand : LsColors.paper(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LsColors.brand : LsColors.line(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : LsColors.ink(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeMonthGrid() {
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalCells = ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (ctx, idx) {
        final dayNumber = idx - startWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
        final isDisabled = _isDateDisabled(cellDate);
        final isToday = today.year == cellDate.year &&
            today.month == cellDate.month &&
            today.day == cellDate.day;

        final isStart = _startDate != null &&
            _startDate!.year == cellDate.year &&
            _startDate!.month == cellDate.month &&
            _startDate!.day == cellDate.day;

        final isEnd = _endDate != null &&
            _endDate!.year == cellDate.year &&
            _endDate!.month == cellDate.month &&
            _endDate!.day == cellDate.day;

        final isInRange = _startDate != null &&
            _endDate != null &&
            cellDate.isAfter(_startDate!) &&
            cellDate.isBefore(_endDate!);

        final isRangeEndpoint = isStart || isEnd;

        Color textColor;
        if (isDisabled) {
          textColor = LsColors.mute(context).withValues(alpha: 0.4);
        } else if (isRangeEndpoint) {
          textColor = Colors.white;
        } else if (isInRange) {
          textColor = LsColors.brand;
        } else if (isToday) {
          textColor = LsColors.brand;
        } else {
          textColor = LsColors.ink(context);
        }

        return InkWell(
          onTap: isDisabled ? null : () => _onDateTap(cellDate),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Range connection strip
              if (_startDate != null && _endDate != null && isInRange)
                Positioned.fill(
                  child: Container(
                    color: LsColors.brand.withValues(alpha: 0.12),
                  ),
                ),
              if (_startDate != null && _endDate != null && isStart && !isEnd)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 25,
                  child: Container(
                    color: LsColors.brand.withValues(alpha: 0.12),
                  ),
                ),
              if (_startDate != null && _endDate != null && isEnd && !isStart)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 25,
                  child: Container(
                    color: LsColors.brand.withValues(alpha: 0.12),
                  ),
                ),

              // Date Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRangeEndpoint ? LsColors.brand : Colors.transparent,
                  border: !isRangeEndpoint && isToday
                      ? Border.all(
                          color: LsColors.brand.withValues(alpha: 0.6),
                          width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isRangeEndpoint || isInRange || isToday)
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
