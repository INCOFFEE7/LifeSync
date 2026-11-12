import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/domain/usecases/countdown_usecase.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.lifesync';
  static const int maxPinned = 999; // increased limit

  static final NumberFormat _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget init error: $e');
    }
  }

  // ── Pinned IDs management ──────────────────────────────────────────────────

  static Future<List<int>> getPinnedTargetIds() async {
    if (kIsWeb) return [];
    try {
      final raw = await HomeWidget.getWidgetData<String>('pinned_target_ids',
          defaultValue: '');
      if (raw == null || raw.isEmpty) return [];
      return raw
          .split(',')
          .map((e) => int.tryParse(e) ?? -1)
          .where((e) => e != -1)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<int>> getPinnedReminderIds() async {
    if (kIsWeb) return [];
    try {
      final raw = await HomeWidget.getWidgetData<String>('pinned_reminder_ids',
          defaultValue: '');
      if (raw == null || raw.isEmpty) return [];
      return raw
          .split(',')
          .map((e) => int.tryParse(e) ?? -1)
          .where((e) => e != -1)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Toggle pin for a target. Returns null if max reached (not added), else returns updated list.
  static Future<List<int>?> togglePinTarget(int id) async {
    if (kIsWeb) return null;
    final ids = await getPinnedTargetIds();
    bool added = false;
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      if (ids.length >= maxPinned) return null; // max reached
      ids.add(id);
      added = true;
    }
    await HomeWidget.saveWidgetData<String>('pinned_target_ids', ids.join(','));
    if (added) {
      await requestPinTargetWidget();
    }
    return ids;
  }

  /// Toggle pin for a reminder. Returns null if max reached (not added), else returns updated list.
  static Future<List<int>?> togglePinReminder(int id) async {
    if (kIsWeb) return null;
    final ids = await getPinnedReminderIds();
    bool added = false;
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      if (ids.length >= maxPinned) return null;
      ids.add(id);
      added = true;
    }
    await HomeWidget.saveWidgetData<String>(
        'pinned_reminder_ids', ids.join(','));
    if (added) {
      await requestPinReminderWidget();
    }
    return ids;
  }

  static Future<List<int>> getPinnedBillIds() async {
    if (kIsWeb) return [];
    final raw = await HomeWidget.getWidgetData<String>('pinned_bill_ids',
        defaultValue: '');
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }

  static Future<List<int>?> togglePinBill(int id) async {
    if (kIsWeb) return null;
    final ids = await getPinnedBillIds();
    bool added = false;
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      if (ids.length >= maxPinned) return null;
      ids.add(id);
      added = true;
    }
    await HomeWidget.saveWidgetData<String>('pinned_bill_ids', ids.join(','));
    if (added) {
      await requestPinReminderWidget();
    }
    return ids;
  }

  static Future<List<int>> getPinnedShoppingIds() async {
    if (kIsWeb) return [];
    final raw = await HomeWidget.getWidgetData<String>('pinned_shopping_ids',
        defaultValue: '');
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }

  static Future<List<int>?> togglePinShopping(int id) async {
    if (kIsWeb) return null;
    final ids = await getPinnedShoppingIds();
    bool added = false;
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      if (ids.length >= maxPinned) return null;
      ids.add(id);
      added = true;
    }
    await HomeWidget.saveWidgetData<String>(
        'pinned_shopping_ids', ids.join(','));
    if (added) {
      await requestPinReminderWidget();
    }
    return ids;
  }

  static Future<void> removePinnedTarget(int id) async {
    if (kIsWeb) return;
    final ids = await getPinnedTargetIds();
    if (ids.remove(id)) {
      await HomeWidget.saveWidgetData<String>(
          'pinned_target_ids', ids.join(','));
    }
  }

  static Future<void> removePinnedReminder(int id) async {
    if (kIsWeb) return;
    final ids = await getPinnedReminderIds();
    if (ids.remove(id)) {
      await HomeWidget.saveWidgetData<String>(
          'pinned_reminder_ids', ids.join(','));
    }
  }

  // ── Multi-slot widget data update ─────────────────────────────────────────

  static Future<void> updateMultiTargetWidgetData(List<dynamic> infos) async {
    if (kIsWeb) return;
    try {
      final now = DateTime.now();
      for (int i = 0; i < 3; i++) {
        final hasData = i < infos.length;
        if (hasData) {
          final info = infos[i];
          final target = info.target as IncomeTarget;
          final savings = info.savings as double;
          final recommendedDaily = info.recommendedDailySaving as double;
          final savedToday = info.savedToday as double;
          double progress =
              target.targetAmount > 0 ? (savings / target.targetAmount) : 0.0;
          if (progress.isNaN || progress.isInfinite) progress = 0.0;
          if (progress > 1.0) progress = 1.0;
          final pct = '${(progress * 100).round()}%';
          final int daysLeft =
              target.endDate.difference(now).inDays.clamp(0, 9999);
          final double remaining =
              (recommendedDaily - savedToday).clamp(0.0, double.infinity);
          final todayStr = remaining > 0
              ? 'Setor hari ini: ${_fmt.format(remaining)}'
              : '✓ Target hari ini tercapai!';

          await HomeWidget.saveWidgetData<String>('t${i}_title', target.name);
          await HomeWidget.saveWidgetData<String>('t${i}_pct', pct);
          await HomeWidget.saveWidgetData<String>('t${i}_progress_text',
              '${_fmt.format(savings)} / ${_fmt.format(target.targetAmount)}');
          await HomeWidget.saveWidgetData<int>(
              't${i}_progress', (progress * 100).round());
          await HomeWidget.saveWidgetData<String>(
              't${i}_days', '$daysLeft hari lagi');
          await HomeWidget.saveWidgetData<String>('t${i}_today', todayStr);
          await HomeWidget.saveWidgetData<bool>('t${i}_visible', true);
        } else {
          await HomeWidget.saveWidgetData<bool>('t${i}_visible', false);
        }
      }
      await HomeWidget.updateWidget(
        name: 'TargetWidgetProvider',
        androidName: 'TargetWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating multi-target widget: $e');
    }
  }

  static Future<void> updateMultiReminderWidgetData(
      List<dynamic> items) async {
    if (kIsWeb) return;
    try {
      final dateFmt = DateFormat('dd MMM, HH.mm', 'id_ID');
      final dayFmt = DateFormat('dd MMM yyyy', 'id_ID');
      for (int i = 0; i < 3; i++) {
        final hasData = i < items.length;
        if (hasData) {
          final item = items[i];
          String title = '';
          String dateStr = '';
          String timeStr = '';
          int targetEpoch = -1;

          if (item is Reminder) {
            title = item.title;
            dateStr = dateFmt.format(item.targetDateTime);
            timeStr = CountdownUseCase.calculateCountdown(
                DateTime.now(), item.targetDateTime);
            targetEpoch = item.targetDateTime.millisecondsSinceEpoch;
          } else if (item is Bill) {
            title = '[Tagihan] ${item.name}';
            dateStr = 'Jatuh tempo: ${dayFmt.format(item.dueDate)}';
            timeStr = item.isPaid
                ? 'Lunas'
                : 'Rp ${_fmt.format(item.amount.toInt())}';
            targetEpoch = item.dueDate.millisecondsSinceEpoch;
          } else if (item is ShoppingItem) {
            title = '[Belanja] ${item.name}';
            dateStr = item.category ?? 'Daftar Belanja';
            timeStr = item.isChecked
                ? 'Sudah Dibeli'
                : (item.price > 0
                    ? 'Rp ${_fmt.format(item.price.toInt())}'
                    : 'Perlu Dibeli');
            targetEpoch = item.purchaseDate?.millisecondsSinceEpoch ?? 0;
          } else {
            title = item.toString();
          }

          await HomeWidget.saveWidgetData<String>('r${i}_title', title);
          await HomeWidget.saveWidgetData<String>('r${i}_date', dateStr);
          await HomeWidget.saveWidgetData<String>('r${i}_time', timeStr);
          await HomeWidget.saveWidgetData<int>(
              'r${i}_target_epoch', targetEpoch);
          await HomeWidget.saveWidgetData<bool>('r${i}_visible', true);
        } else {
          await HomeWidget.saveWidgetData<bool>('r${i}_visible', false);
          await HomeWidget.saveWidgetData<int>('r${i}_target_epoch', -1);
        }
      }
      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating multi-reminder widget: $e');
    }
  }

  // ── Pin widget to home screen ─────────────────────────────────────────────

  static Future<void> requestPinTargetWidget() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.requestPinWidget(
        name: 'TargetWidgetProvider',
        androidName: 'TargetWidgetProvider',
        qualifiedAndroidName: 'com.example.lifesync_app.TargetWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error pinning target widget: $e');
    }
  }

  static Future<void> requestPinReminderWidget() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.requestPinWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
        qualifiedAndroidName: 'com.example.lifesync_app.ReminderWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error pinning reminder widget: $e');
    }
  }

  // ── Bento Hub Widget ──────────────────────────────────────────────────────

  static Future<void> updateBentoWidgetData({
    required double todayExpense,
    required double todayIncome,
    String? targetTitle,
    String? targetPct,
    int? targetProgress,
    String? targetDays,
    String? reminderTitle,
    String? reminderTime,
    String? reminderDate,
  }) async {
    if (kIsWeb) return;
    try {
      final now = DateTime.now();
      final dateFmt = DateFormat('EEEE, d MMM', 'id_ID');
      await HomeWidget.saveWidgetData<String>(
          'bento_date', dateFmt.format(now));
      await HomeWidget.saveWidgetData<String>(
          'bento_expense', _fmt.format(todayExpense));
      await HomeWidget.saveWidgetData<String>(
          'bento_income', '+ Masuk ${_fmt.format(todayIncome)}');

      await HomeWidget.saveWidgetData<bool>(
          'bento_has_target', targetTitle != null);
      if (targetTitle != null) {
        await HomeWidget.saveWidgetData<String>(
            'bento_target_title', targetTitle);
        await HomeWidget.saveWidgetData<String>(
            'bento_target_pct', targetPct ?? '0%');
        await HomeWidget.saveWidgetData<int>(
            'bento_target_progress', targetProgress ?? 0);
        await HomeWidget.saveWidgetData<String>(
            'bento_target_days', targetDays ?? '');
      }

      await HomeWidget.saveWidgetData<bool>(
          'bento_has_reminder', reminderTitle != null);
      if (reminderTitle != null) {
        await HomeWidget.saveWidgetData<String>(
            'bento_reminder_title', reminderTitle);
        await HomeWidget.saveWidgetData<String>(
            'bento_reminder_time', reminderTime ?? '');
        await HomeWidget.saveWidgetData<String>(
            'bento_reminder_date', reminderDate ?? '');
      }

      await HomeWidget.updateWidget(
        name: 'BentoWidgetProvider',
        androidName: 'BentoWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating bento widget: $e');
    }
  }

  static Future<void> requestPinBentoWidget() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.requestPinWidget(
        name: 'BentoWidgetProvider',
        androidName: 'BentoWidgetProvider',
        qualifiedAndroidName: 'com.example.lifesync_app.BentoWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error pinning bento widget: $e');
    }
  }
}
