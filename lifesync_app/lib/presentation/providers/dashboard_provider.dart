import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/domain/usecases/target_calculation_usecase.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:intl/intl.dart';

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

final dashboardDataProvider =
    StreamProvider.autoDispose<DashboardData>((ref) async* {
  final targetRepo = ref.watch(targetRepositoryProvider);
  final reminderRepo = ref.watch(reminderRepositoryProvider);

  // Watch streams so ANY change in targets or records in Isar DB updates Dashboard in real time!
  final targetsAsync = ref.watch(targetsStreamProvider);
  final remindersAsync = ref.watch(remindersStreamProvider);

  final targets = targetsAsync.value ?? await targetRepo.getAllTargets();
  final reminders =
      remindersAsync.value ?? await reminderRepo.getAllReminders();

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
      .where((t) =>
          t.status != TargetStatus.completed && t.status != TargetStatus.failed)
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
      if (r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day) {
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
      if (statusA == 'Sedang Berjalan' && statusB != 'Sedang Berjalan')
        return -1;
      if (statusA != 'Sedang Berjalan' && statusB == 'Sedang Berjalan')
        return 1;
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
  final pinnedBillIds = await HomeWidgetService.getPinnedBillIds();
  final pinnedShoppingIds = await HomeWidgetService.getPinnedShoppingIds();

  final pinnedTargetInfos = pinnedTargetIds
      .map((id) =>
          topTargetsInfo.where((info) => info.target.id == id).firstOrNull)
      .whereType<TargetDashboardInfo>()
      .toList();

  final pinnedRemindersList = reminders
      .where((r) => pinnedReminderIds.contains(r.id))
      .toList()
    ..sort((a, b) {
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return a.targetDateTime.compareTo(b.targetDateTime);
    });

  final billRepo = ref.watch(billRepositoryProvider);
  final allBills = await billRepo.getAllBills();
  final pinnedBillsList =
      allBills.where((b) => pinnedBillIds.contains(b.id)).toList();

  final shoppingAsync = ref.watch(shoppingItemsProvider);
  final allShopping = shoppingAsync.valueOrNull ?? [];
  final pinnedShoppingList =
      allShopping.where((s) => pinnedShoppingIds.contains(s.id)).toList();

  final List<dynamic> unifiedPinnedList = [
    ...pinnedRemindersList,
    ...pinnedBillsList,
    ...pinnedShoppingList,
  ];

  final displayPinnedItems =
      unifiedPinnedList.isNotEmpty ? unifiedPinnedList : upcomingReminders;

  HomeWidgetService.updateMultiTargetWidgetData(pinnedTargetInfos);
  HomeWidgetService.updateMultiReminderWidgetData(displayPinnedItems);

  // ── Sync Bento Hub Widget ──────────────────────────────────────────────────
  final notesAsync = ref.watch(financialNotesNotifierProvider);
  double todayExpense = 0.0;
  double todayIncome = 0.0;
  final notesList = notesAsync.valueOrNull ?? [];
  for (final n in notesList) {
    if (n.note.date.year == now.year &&
        n.note.date.month == now.month &&
        n.note.date.day == now.day) {
      todayExpense += n.totalExpense;
      todayIncome += n.totalIncome;
    }
  }

  final topTargetInfo = pinnedTargetInfos.isNotEmpty
      ? pinnedTargetInfos.first
      : (topTargetsInfo.isNotEmpty ? topTargetsInfo.first : null);
  final target = topTargetInfo?.target;
  final targetSavings = topTargetInfo?.savings ?? 0.0;
  double progress = (target != null && target.targetAmount > 0)
      ? (targetSavings / target.targetAmount)
      : 0.0;
  final daysLeft =
      target != null ? target.endDate.difference(now).inDays.clamp(0, 9999) : 0;

  final nextPinnedItem = unifiedPinnedList.isNotEmpty
      ? unifiedPinnedList.first
      : (upcomingReminders.isNotEmpty ? upcomingReminders.first : null);
  final dateFmt = DateFormat('dd MMM, HH:mm', 'id_ID');

  String? bentoReminderTitle;
  String? bentoReminderTime;
  String? bentoReminderDate;

  if (nextPinnedItem is Reminder) {
    bentoReminderTitle = nextPinnedItem.title;
    bentoReminderTime =
        DateFormat('HH:mm', 'id_ID').format(nextPinnedItem.targetDateTime);
    bentoReminderDate = dateFmt.format(nextPinnedItem.targetDateTime);
  } else if (nextPinnedItem is Bill) {
    bentoReminderTitle = '[Tagihan] ${nextPinnedItem.name}';
    bentoReminderTime = nextPinnedItem.isPaid ? 'Lunas' : 'Belum Lunas';
    bentoReminderDate =
        DateFormat('dd MMM yyyy', 'id_ID').format(nextPinnedItem.dueDate);
  } else if (nextPinnedItem is ShoppingItem) {
    bentoReminderTitle = '[Belanja] ${nextPinnedItem.name}';
    bentoReminderTime =
        nextPinnedItem.isChecked ? 'Sudah Dibeli' : 'Perlu Dibeli';
    bentoReminderDate = nextPinnedItem.category ?? 'Belanja';
  }

  HomeWidgetService.updateBentoWidgetData(
    todayExpense: todayExpense,
    todayIncome: todayIncome,
    targetTitle: target?.name,
    targetPct: '${(progress * 100).round()}%',
    targetProgress: (progress * 100).round(),
    targetDays: target != null ? '$daysLeft hari lagi' : null,
    reminderTitle: bentoReminderTitle,
    reminderTime: bentoReminderTime,
    reminderDate: bentoReminderDate,
  );

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
