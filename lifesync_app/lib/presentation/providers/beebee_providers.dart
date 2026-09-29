import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/data/repositories/isar_fasting_repository.dart';
import 'package:lifesync_app/data/repositories/isar_menstruation_repository.dart';
import 'package:lifesync_app/data/repositories/memory_fasting_repository.dart';
import 'package:lifesync_app/data/repositories/memory_menstruation_repository.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/domain/repositories/fasting_repository.dart';
import 'package:lifesync_app/domain/repositories/menstruation_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Active Haid Provider (tracks ongoing period via SharedPreferences) ──
class ActiveHaidNotifier extends StateNotifier<DateTime?> {
  static const _key = 'active_haid_start_date';

  ActiveHaidNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key);
    if (ms != null) {
      state = DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }

  Future<void> startHaid() async {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, now.millisecondsSinceEpoch);
    state = now;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = null;
  }
}

final activeHaidProvider = StateNotifierProvider<ActiveHaidNotifier, DateTime?>((ref) {
  return ActiveHaidNotifier();
});

final _memoryFastingRepo = MemoryFastingRepository();
late final _memoryMenstruationRepo = MemoryMenstruationRepository(_memoryFastingRepo);

final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  if (kIsWeb) return _memoryFastingRepo;
  final dbService = ref.watch(databaseServiceProvider);
  return IsarFastingRepository(dbService);
});

final menstruationRepositoryProvider = Provider<MenstruationRepository>((ref) {
  if (kIsWeb) return _memoryMenstruationRepo;
  final dbService = ref.watch(databaseServiceProvider);
  return IsarMenstruationRepository(dbService);
});

final fastingDebtsProvider = StreamProvider<List<FastingDebt>>((ref) {
  final repo = ref.watch(fastingRepositoryProvider);
  return repo.watchDebts();
});

final qadhaRecordsProvider = StreamProvider<List<QadhaRecord>>((ref) {
  final repo = ref.watch(fastingRepositoryProvider);
  return repo.watchQadha();
});

final totalFastingDebtSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(fastingDebtsProvider);
  ref.watch(qadhaRecordsProvider);
  
  final repo = ref.watch(fastingRepositoryProvider);
  final debts = await repo.getAllDebts();
  final qadhas = await repo.getAllQadha();
  
  int totalInitialDebt = debts.fold<int>(0, (int sum, debt) => sum + debt.initialDebt);
  int totalQadha = qadhas.fold<int>(0, (int sum, qadha) => sum + qadha.amount);
  
  // calculate current debt
  int currentDebt = debts.fold<int>(0, (int sum, debt) => sum + debt.currentDebt);
  
  return {
    'totalInitialDebt': totalInitialDebt,
    'totalQadha': totalQadha,
    'currentDebt': currentDebt,
  };
});

final menstruationRecordsProvider = StreamProvider<List<MenstruationRecord>>((ref) {
  final repo = ref.watch(menstruationRepositoryProvider);
  return repo.watchRecords();
});

class MenstrualStats {
  final double avgCycle;
  final double avgDuration;
  final DateTime? nextPrediction;
  final int countdownDays;
  final DateTime? lastPeriodDate;
  
  MenstrualStats({
    required this.avgCycle,
    required this.avgDuration,
    this.nextPrediction,
    required this.countdownDays,
    this.lastPeriodDate,
  });
}

final menstrualStatsProvider = FutureProvider<MenstrualStats>((ref) async {
  ref.watch(menstruationRecordsProvider);
  
  final repo = ref.watch(menstruationRepositoryProvider);
  
  final avgCycle = await repo.getAverageCycle();
  final avgDuration = await repo.getAverageDuration();
  final nextPrediction = await repo.predictNextPeriod();
  
  int countdown = 0;
  if (nextPrediction != null) {
    countdown = nextPrediction.difference(DateTime.now()).inDays;
  }
  
  final records = await repo.getAllRecords();
  DateTime? lastPeriodDate;
  if (records.isNotEmpty) {
    lastPeriodDate = records.first.startDate;
  }
  
  return MenstrualStats(
    avgCycle: avgCycle,
    avgDuration: avgDuration,
    nextPrediction: nextPrediction,
    countdownDays: countdown,
    lastPeriodDate: lastPeriodDate,
  );
});
