import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthDayPickerWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const MonthDayPickerWidget({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  Future<void> _pickMonthYearDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonthStr = DateFormat('MMMM yyyy', 'id_ID').format(selectedDate);

    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final days = List.generate(daysInMonth, (index) {
      return DateTime(selectedDate.year, selectedDate.month, index + 1);
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22),
                onPressed: () {
                  final prev = DateTime(selectedDate.year, selectedDate.month - 1, 1);
                  onDateChanged(prev);
                },
              ),
              const SizedBox(width: 4),
              // Clickable Month Title with Calendar Icon
              InkWell(
                onTap: () => _pickMonthYearDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        currentMonthStr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22),
                onPressed: () {
                  final next = DateTime(selectedDate.year, selectedDate.month + 1, 1);
                  onDateChanged(next);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 62,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

                final dayNum = DateFormat('d').format(date);
                final dayName = DateFormat('E', 'id_ID').format(date);

                return GestureDetector(
                  onTap: () => onDateChanged(date),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white70 : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 15,
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
      ),
    );
  }
}
