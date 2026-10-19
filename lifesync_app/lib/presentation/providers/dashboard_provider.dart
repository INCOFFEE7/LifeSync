import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/usecases/target_calculation_usecase.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';

class TargetDashboardInfo {
  final IncomeTarget target;
  final double savings;
  final double recommendedDailySaving;
  final double savedToday;

  TargetDashboardInfo({
    required this.target,
    required this.savings,
    required this.recommendedDailySaving,
    required this.savedToday,
  });
}

class DashboardData {
  final double totalSavings;
  final double totalTargetAmount;
  final int activeRemindersCount;
  final int todayRemindersCount;
  final List<TargetDashboardInfo> topTargets;
  final List<Reminder> upcomingReminders;
  final List<int> pinnedTargetIds;
  final List<int> pinnedReminderIds;

  DashboardData({
    required this.totalSavings,
    required this.totalTargetAmount,
    required this.activeRemindersCount,
    required this.todayRemindersCount,
    required this.topTargets,
    required this.upcomingReminders,
    required this.pinnedTargetIds,
    required this.pinnedReminderIds,
  });
}

final dashboardDataProvider = StreamProvider.autoDispose<DashboardData>((ref) async* {
  final targetRepo = ref.watch(targetRepositoryProvider);
  final reminderRepo = ref.watch(reminderRepositoryProvider);

  // Watch streams so ANY change in targets or records in Isar DB updates Dashboard in real time!
  final targetsAsync = ref.watch(targetsStreamProvider);
  final remindersAsync = ref.watch(remindersStreamProvider);

  final targets = targetsAsync.value ?? await targetRepo.getAllTargets();
  final reminders = remindersAsync.value ?? await reminderRepo.getAllReminders();

  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);

  // ── Total savings = sum of ALL targets' records ────────────────────────────
  double totalSavings = 0;
  double totalTargetAmount = 0;

  for (var target in targets) {
    totalTargetAmount += target.targetAmount;
    final records = await targetRepo.getRecordsForTarget(target.id);
    totalSavings += records.fold(0.0, (sum, r) => sum + r.incomeAmount);
  }

  // ── Pinned target IDs (from HomeWidget storage) ────────────────────────────
  final pinnedTargetIds = await HomeWidgetService.getPinnedTargetIds();
  final pinnedReminderIds = await HomeWidgetService.getPinnedReminderIds();

  // ── Determine which targets to show on dashboard ───────────────────────────
  // Active targets sorted by deadline
  final activeTargets = targets
      .where((t) => t.status != TargetStatus.completed && t.status != TargetStatus.failed)
      .toList()
    ..sort((a, b) => a.endDate.compareTo(b.endDate));

  List<IncomeTarget> dashboardTargets;
  if (pinnedTargetIds.isNotEmpty) {
    // Show pinned targets (preserve pin order)
    dashboardTargets = pinnedTargetIds
        .map((id) => targets.where((t) => t.id == id).firstOrNull)
        .whereType<IncomeTarget>()
        .toList();
  } else {
    // Fallback: 3 closest deadline active targets
    dashboardTargets = activeTargets.take(3).toList();
  }

  // ── Build TargetDashboardInfo for each dashboard target ───────────────────
  List<TargetDashboardInfo> topTargetsInfo = [];
  for (var t in dashboardTargets) {
    final records = await targetRepo.getRecordsForTarget(t.id);
    double savings = records.fold(0.0, (sum, r) => sum + r.incomeAmount);

    double savedToday = 0;
    for (var r in records) {
      if (r.date.year == now.year && r.date.month == now.month && r.date.day == now.day) {
        savedToday += r.incomeAmount;
      }
    }

    // Recalculate adaptive daily target in real time
    double daily = TargetCalculationUseCase.calculateAdaptiveDailyTarget(
      totalTargetAmount: t.targetAmount,
      collectedIncome: records,
      endDate: t.endDate,
      currentDate: todayMidnight,
      startDate: t.startDate,
      mode: t.mode,
      fixedDailyAmount: t.fixedDailyAmount,
    );

    topTargetsInfo.add(TargetDashboardInfo(
      target: t,
      savings: savings,
      recommendedDailySaving: daily,
      savedToday: savedToday,
    ));
  }

  // ── Reminders ─────────────────────────────────────────────────────────────
  final activeReminders = reminders
      .where((r) => !r.deleted && r.realtimeStatus != 'Selesai')
      .toList()
    ..sort((a, b) {
      final statusA = a.realtimeStatus;
      final statusB = b.realtimeStatus;
      if (statusA == 'Sedang Berjalan' && statusB != 'Sedang Berjalan') return -1;
      if (statusA != 'Sedang Berjalan' && statusB == 'Sedang Berjalan') return 1;
      return a.targetDateTime.compareTo(b.targetDateTime);
    });
  final upcomingReminders = activeReminders.take(10).toList();

  final todayRemindersCount = reminders
      .where((r) =>
          !r.deleted &&
          r.targetDateTime.year == now.year &&
          r.targetDateTime.month == now.month &&
          r.targetDateTime.day == now.day)
      .length;

  // ── Sync pinned data to home widget ───────────────────────────────────────
  final pinnedTargetInfos = pinnedTargetIds
      .map((id) => topTargetsInfo.where((info) => info.target.id == id).firstOrNull)
      .whereType<TargetDashboardInfo>()
      .toList();

  final pinnedRemindersList = reminders.where((r) => pinnedReminderIds.contains(r.id)).toList()
    ..sort((a, b) {
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return a.targetDateTime.compareTo(b.targetDateTime);
    });

  HomeWidgetService.updateMultiTargetWidgetData(pinnedTargetInfos);
  HomeWidgetService.updateMultiReminderWidgetData(pinnedRemindersList);

  yield DashboardData(
    totalSavings: totalSavings,
    totalTargetAmount: totalTargetAmount,
    activeRemindersCount: activeReminders.length,
    todayRemindersCount: todayRemindersCount,
    topTargets: topTargetsInfo,
    upcomingReminders: upcomingReminders,
    pinnedTargetIds: pinnedTargetIds,
    pinnedReminderIds: pinnedReminderIds,
  );
});
