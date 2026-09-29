import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';

enum FilterMode { daily, weekly, monthly, yearly, custom }

class FinancialFilter {
  final FilterMode mode;
  final DateTime? customStart;
  final DateTime? customEnd;

  const FinancialFilter({
    this.mode = FilterMode.daily,
    this.customStart,
    this.customEnd,
  });

  FinancialFilter copyWith({
    FilterMode? mode,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return FinancialFilter(
      mode: mode ?? this.mode,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  DateTimeRange get effectiveDateRange {
    final now = DateTime.now();
    switch (mode) {
      case FilterMode.daily:
        // Last 30 days
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 30),
          end: now,
        );
      case FilterMode.weekly:
        // Current week (Monday to today)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(monday.year, monday.month, monday.day),
          end: now,
        );
      case FilterMode.monthly:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case FilterMode.yearly:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case FilterMode.custom:
        return DateTimeRange(
          start: customStart ?? DateTime(now.year, now.month, 1),
          end: customEnd ?? now,
        );
    }
  }
}

class DailyFinancialSummary {
  final DateTime date;
  final String dateLabel;
  final String relativeLabel;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<FinancialRecord> incomeRecords;
  final List<FinancialRecord> expenseRecords;

  const DailyFinancialSummary({
    required this.date,
    required this.dateLabel,
    required this.relativeLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.incomeRecords,
    required this.expenseRecords,
  });

  List<FinancialRecord> get allRecords => [...incomeRecords, ...expenseRecords];
}

class PeriodSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final int transactionCount;

  const PeriodSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.transactionCount,
  });
}

// ─── Providers ───────────────────────────────────────────────────────────────

final financialRecordsStreamProvider = StreamProvider<List<FinancialRecord>>((ref) {
  final repository = ref.watch(financialRecordRepositoryProvider);
  return repository.watchAllRecords();
});

final financialFilterProvider = StateProvider<FinancialFilter>(
  (ref) => const FinancialFilter(mode: FilterMode.daily),
);

final filteredFinancialRecordsProvider = Provider<List<FinancialRecord>>((ref) {
  final asyncRecords = ref.watch(financialRecordsStreamProvider);
  final filter = ref.watch(financialFilterProvider);

  return asyncRecords.maybeWhen(
    data: (records) {
      final range = filter.effectiveDateRange;
      return records.where((r) {
        final date = r.transactionDate;
        return !date.isBefore(range.start) && !date.isAfter(range.end);
      }).toList();
    },
    orElse: () => [],
  );
});

final groupedDailySummariesProvider = Provider<List<DailyFinancialSummary>>((ref) {
  final records = ref.watch(filteredFinancialRecordsProvider);
  if (records.isEmpty) return [];

  final Map<String, List<FinancialRecord>> grouped = {};

  for (var record in records) {
    final key = DateFormat('yyyy-MM-dd').format(record.transactionDate);
    grouped.putIfAbsent(key, () => []).add(record);
  }

  final now = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

  final List<DailyFinancialSummary> summaries = [];
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  for (var key in sortedKeys) {
    final dayRecords = grouped[key]!;
    final firstDate = dayRecords.first.transactionDate;

    String relativeLabel = '';
    if (key == todayStr) {
      relativeLabel = 'Today';
    } else if (key == yesterdayStr) {
      relativeLabel = 'Yesterday';
    }

    final dateLabel = DateFormat('d MMMM yyyy', 'id_ID').format(firstDate);

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final List<FinancialRecord> incomes = [];
    final List<FinancialRecord> expenses = [];

    for (var r in dayRecords) {
      if (r.type == 'income') {
        totalIncome += r.amount;
        incomes.add(r);
      } else {
        totalExpense += r.amount;
        expenses.add(r);
      }
    }

    summaries.add(DailyFinancialSummary(
      date: DateTime.parse(key),
      dateLabel: dateLabel,
      relativeLabel: relativeLabel,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      incomeRecords: incomes,
      expenseRecords: expenses,
    ));
  }

  return summaries;
});

final periodSummaryProvider = Provider<PeriodSummary>((ref) {
  final records = ref.watch(filteredFinancialRecordsProvider);
  double income = 0;
  double expense = 0;
  for (var r in records) {
    if (r.type == 'income') income += r.amount;
    else expense += r.amount;
  }
  return PeriodSummary(
    totalIncome: income,
    totalExpense: expense,
    netBalance: income - expense,
    transactionCount: records.length,
  );
});
