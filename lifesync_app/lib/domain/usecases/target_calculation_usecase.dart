import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';

class TargetCalculationUseCase {
  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calculate remaining days needed based on total target days and completed checklist count / progress
  static int calculateRemainingDays({
    required IncomeTarget target,
    required List<DailyIncomeRecord> collectedIncome,
    required DateTime currentDate,
  }) {
    DateTime normToday = _midnight(currentDate);
    DateTime normStart = _midnight(target.startDate);
    DateTime normEnd = _midnight(target.endDate);

    if (normToday.isBefore(normStart)) {
      return normEnd.difference(normStart).inDays + 1;
    }

    if (normToday.isAfter(normEnd)) {
      return 0;
    }

    double totalCollected = collectedIncome.fold(0.0, (sum, r) => sum + r.incomeAmount);
    if (totalCollected >= target.targetAmount) {
      return 0; // Target completed!
    }

    int totalDays = normEnd.difference(normStart).inDays + 1;
    int completedDaysCount = collectedIncome.length;

    // Sisa hari yang belum selesai = totalDays - completedDaysCount
    int remainingNeeded = (totalDays - completedDaysCount).clamp(0, totalDays);
    return remainingNeeded;
  }

  /// Compute exact integer daily distribution for fixed mode
  /// Guarantees SUM(dailyAmounts) == targetAmount exactly!
  static List<int> calculateFixedDailyDistribution(double targetAmount, DateTime startDate, DateTime endDate) {
    int totalTargetInt = targetAmount.round();
    int totalDays = _midnight(endDate).difference(_midnight(startDate)).inDays + 1;
    if (totalDays <= 0) totalDays = 1;

    int baseDailyInt = totalTargetInt ~/ totalDays;
    int remainder = totalTargetInt % totalDays;

    List<int> distribution = [];
    for (int i = 0; i < totalDays; i++) {
      int daily = baseDailyInt + (i < remainder ? 1 : 0);
      distribution.add(daily);
    }
    return distribution;
  }

  /// Calculates the initial daily target when a goal is created
  static double calculateInitialDailyTarget(double targetAmount, DateTime startDate, DateTime endDate) {
    int totalDays = _midnight(endDate).difference(_midnight(startDate)).inDays + 1;
    if (totalDays <= 0) totalDays = 1;
    return (targetAmount / totalDays).roundToDouble();
  }

  /// Recalculates the daily target based on current progress
  static double calculateAdaptiveDailyTarget({
    required double totalTargetAmount,
    required List<DailyIncomeRecord> collectedIncome,
    required DateTime endDate,
    required DateTime currentDate,
    required DateTime startDate,
    String mode = 'flexible',
    double fixedDailyAmount = 0.0,
  }) {
    DateTime normToday = _midnight(currentDate);
    DateTime normStart = _midnight(startDate);
    DateTime normEnd = _midnight(endDate);

    if (normToday.isBefore(normStart)) return 0.0;

    double totalCollected = 0.0;
    for (var record in collectedIncome) {
      totalCollected += record.incomeAmount;
    }

    double remainingTarget = totalTargetAmount - totalCollected;
    if (remainingTarget <= 0) return 0.0; // Target reached

    if (mode == 'fixed' && fixedDailyAmount > 0) {
      return remainingTarget < fixedDailyAmount ? remainingTarget : fixedDailyAmount;
    }

    DateTime activeCurrent = normToday.isBefore(normStart) ? normStart : normToday;
    int remainingDays = normEnd.difference(activeCurrent).inDays + 1;
    if (remainingDays <= 0) remainingDays = 1;

    return (remainingTarget / remainingDays).roundToDouble();
  }

  /// Determines the status of the target based on progress
  static TargetStatus determineTargetStatus({
    required IncomeTarget target,
    required List<DailyIncomeRecord> collectedIncome,
    required DateTime currentDate,
  }) {
    DateTime normToday = _midnight(currentDate);
    DateTime normStart = _midnight(target.startDate);
    DateTime normEnd = _midnight(target.endDate);

    if (normToday.isBefore(normStart)) {
      return TargetStatus.notStarted;
    }

    double totalCollected = 0.0;
    for (var record in collectedIncome) {
      totalCollected += record.incomeAmount;
    }

    if (totalCollected >= target.targetAmount) {
      return TargetStatus.completed;
    }

    if (normToday.isAfter(normEnd) && totalCollected < target.targetAmount) {
      return TargetStatus.failed;
    }

    double savedToday = 0.0;
    for (var r in collectedIncome) {
      if (r.date.year == normToday.year && r.date.month == normToday.month && r.date.day == normToday.day) {
        savedToday += r.incomeAmount;
      }
    }

    double dailyReq = calculateAdaptiveDailyTarget(
      totalTargetAmount: target.targetAmount,
      collectedIncome: collectedIncome,
      endDate: target.endDate,
      currentDate: normToday,
      startDate: target.startDate,
      mode: target.mode,
      fixedDailyAmount: target.fixedDailyAmount,
    );

    if (savedToday >= dailyReq || (dailyReq == 0 && totalCollected >= target.targetAmount)) {
      return TargetStatus.aheadOfSchedule;
    } else {
      return TargetStatus.behindSchedule;
    }
  }
}
