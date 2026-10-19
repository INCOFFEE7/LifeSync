import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthDayPickerWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool isSeeAll;
  final bool showDayStrip;

  // Uniform filter controls
  final String? dateScope; // 'this_month', 'all', 'pick_month', 'range'
  final ValueChanged<String>? onDateScopeChanged;
  final String? statusFilter; // 'upcoming', 'completed', 'all'
  final ValueChanged<String>? onStatusFilterChanged;
  final ValueChanged<DateTimeRange>? onDateRangeChanged;

  const MonthDayPickerWidget({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.isSeeAll = false,
    this.showDayStrip = true,
    this.dateScope,
    this.onDateScopeChanged,
    this.statusFilter,
    this.onStatusFilterChanged,
    this.onDateRangeChanged,
  });

  @override
  State<MonthDayPickerWidget> createState() => _MonthDayPickerWidgetState();
}

class _MonthDayPickerWidgetState extends State<MonthDayPickerWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate(animate: false));
  }

  @override
  void didUpdateWidget(covariant MonthDayPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate && widget.showDayStrip) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate(animate: true));
    }
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (!_scrollController.hasClients || !widget.showDayStrip) return;

    final dayIndex = widget.selectedDate.day - 1;
    const itemTileWidth = 44.0;
    const itemMargin = 3.0; // 3px left + 3px right
    const itemTotalWidth = itemTileWidth + (itemMargin * 2); // 50.0
    const listPadding = 16.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemCenterPos = listPadding + (dayIndex * itemTotalWidth) + itemMargin + (itemTileWidth / 2);
    final targetOffset = itemCenterPos - (screenWidth / 2);
    final safeOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animate) {
      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(safeOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Custom Bottom Sheet untuk Scope Tanggal ────────────────────────────────
  void _showCustomDateScopeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final currentScope = widget.dateScope ?? 'this_month';

        final options = [
          {'key': 'this_month', 'label': 'Bulan Ini', 'icon': Icons.calendar_today_outlined},
          {'key': 'all', 'label': 'Semua Data', 'icon': Icons.all_inclusive_outlined},
          {'key': 'pick_month', 'label': 'Pilih Bulan & Tahun', 'icon': Icons.edit_calendar_outlined},
          {'key': 'range', 'label': 'Rentang Tanggal', 'icon': Icons.date_range_outlined},
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Rentang Tanggal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: options.map((opt) {
                  final key = opt['key'] as String;
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final isSel = currentScope == key;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSel ? const Color(0xFF2563EB).withOpacity(0.1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isSel ? const Color(0xFF2563EB) : Colors.grey.shade300),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(icon, color: isSel ? const Color(0xFF2563EB) : Colors.grey),
                      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF2563EB) : (isDark ? Colors.white : Colors.black87))),
                      trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20) : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (key == 'pick_month') {
                          _showCustomMonthYearPicker(context);
                        } else if (key == 'range') {
                          _showCustomDateRangePicker(context);
                        }
                        if (widget.onDateScopeChanged != null) {
                          widget.onDateScopeChanged!(key);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Custom Modern Date Range Picker ───────────────────────────────────────
  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: widget.selectedDate.subtract(const Duration(days: 7)),
        end: widget.selectedDate,
      ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E293B) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null && widget.onDateRangeChanged != null) {
      widget.onDateRangeChanged!(pickedRange);
    }
  }

  // ── Custom Bottom Sheet untuk Filter Status ───────────────────────────────
  void _showCustomStatusFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final currentStatus = widget.statusFilter ?? 'upcoming';

        final options = [
          {'key': 'upcoming', 'label': 'Mendatang', 'icon': Icons.hourglass_top_outlined, 'color': const Color(0xFF2563EB)},
          {'key': 'completed', 'label': 'Selesai', 'icon': Icons.check_circle_outline, 'color': Colors.green},
          {'key': 'all', 'label': 'Semua Status', 'icon': Icons.list_alt_outlined, 'color': Colors.grey.shade700},
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Status Agenda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: options.map((opt) {
                  final key = opt['key'] as String;
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final color = opt['color'] as Color;
                  final isSel = currentStatus == key;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSel ? color.withOpacity(0.1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isSel ? color : Colors.grey.shade300),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(icon, color: isSel ? color : Colors.grey),
                      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? color : (isDark ? Colors.white : Colors.black87))),
                      trailing: isSel ? Icon(Icons.check_circle, color: color, size: 20) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (widget.onStatusFilterChanged != null) {
                          widget.onStatusFilterChanged!(key);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Custom Modern Month & Year Only Picker Bottom Sheet ─────────────────
  Future<void> _showCustomMonthYearPicker(BuildContext context) async {
    int selectedYear = widget.selectedDate.year;
    int selectedMonth = widget.selectedDate.month;

    final monthsList = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24, left: 24, right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Pilih Bulan & Tahun',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Year Selector Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Color(0xFF2563EB)),
                          onPressed: selectedYear > 2020
                              ? () => setModalState(() => selectedYear--)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                          ),
                          child: Text(
                            '$selectedYear',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
                          onPressed: selectedYear < 2035
                              ? () => setModalState(() => selectedYear++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Month Grid 3x4
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, idx) {
                        final monthNum = idx + 1;
                        final isSel = monthNum == selectedMonth;

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedMonth = monthNum;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? const Color(0xFF2563EB) : Colors.grey.shade300,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              monthsList[idx],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final newDate = DateTime(selectedYear, selectedMonth, 1);
                        widget.onDateChanged(newDate);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Terapkan Bulan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getScopeLabel(String? scope) {
    switch (scope) {
      case 'all': return 'Semua';
      case 'pick_month': return 'Pilih Bulan';
      case 'range': return 'Rentang';
      default: return 'Bulan Ini';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'completed': return 'Selesai';
      case 'all': return 'Semua Status';
      default: return 'Mendatang';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonthStr = DateFormat('MMM yyyy', 'id_ID').format(widget.selectedDate);

    final daysInMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0).day;
    final days = List.generate(daysInMonth, (index) {
      return DateTime(widget.selectedDate.year, widget.selectedDate.month, index + 1);
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row Header dengan Row Flex Layout:
          // Left: Custom Scope Sheet | Center: Unified Month Pill (< 📅 Okt 2026 >) | Right: Custom Status Sheet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. SEBELAH KIRI: Custom Filter Scope Button
              if (widget.onDateScopeChanged != null)
                InkWell(
                  onTap: () => _showCustomDateScopeSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getScopeLabel(widget.dateScope),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB), size: 16),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),

              // 2. TENGAH: Unified Month Selector Pill (< 📅 Okt 2026 >)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final prev = DateTime(widget.selectedDate.year, widget.selectedDate.month - 1, 1);
                        widget.onDateChanged(prev);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        child: Icon(Icons.chevron_left, size: 16, color: Color(0xFF2563EB)),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showCustomMonthYearPicker(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 13, color: Color(0xFF2563EB)),
                          const SizedBox(width: 3),
                          Text(
                            currentMonthStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final next = DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 1);
                        widget.onDateChanged(next);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. SEBELAH KANAN: Custom Status Filter Button
              if (widget.onStatusFilterChanged != null)
                InkWell(
                  onTap: () => _showCustomStatusFilterSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusLabel(widget.statusFilter),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB), size: 16),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
          if (widget.showDayStrip) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isSelected = !widget.isSeeAll &&
                      date.year == widget.selectedDate.year &&
                      date.month == widget.selectedDate.month &&
                      date.day == widget.selectedDate.day;

                  final dayNum = DateFormat('d').format(date);
                  final dayName = DateFormat('E', 'id_ID').format(date);

                  return GestureDetector(
                    onTap: () => widget.onDateChanged(date),
                    child: Container(
                      width: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white70 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1F2937)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
