import 'package:lifesync_app/core/services/google_sheets_service.dart';
import 'package:lifesync_app/domain/repositories/target_repository.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/repositories/reminder_repository.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';

import 'package:lifesync_app/core/database/database_service.dart';

import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/domain/repositories/financial_record_repository.dart';

class SyncUseCase {
  final GoogleSheetsService sheetsService;
  final TargetRepository targetRepository;
  final ReminderRepository reminderRepository;
  final FinancialRecordRepository financialRecordRepository;
  final DatabaseService databaseService;

  SyncUseCase({
    required this.sheetsService, 
    required this.targetRepository,
    required this.reminderRepository,
    required this.financialRecordRepository,
    required this.databaseService,
  });

  Future<void> performTwoWaySync() async {
    final isConnected = await sheetsService.init();
    if (!isConnected) {
      throw Exception('Google Sheets API tidak terkonfigurasi atau kredensial salah.');
    }

    await _syncTargets();
    await _syncReminders();
    await _syncIncomeRecords();
    await _syncFinancialRecords();
    await _syncCategories();
  }

  Future<void> _syncCategories() async {
    final settings = await databaseService.db.appSettings.get(1);
    final localCategories = settings?.customCategories ?? [];
    await sheetsService.syncCategories(localCategories);
  }

  Future<void> _syncTargets() async {
    // 1. Get Local Targets
    final localTargets = await targetRepository.getAllTargets();
    final localIds = localTargets.map((t) => t.id.toString()).toSet();

    // 2. Get Cloud Targets
    final cloudData = await sheetsService.getValues('Targets!A:G');
    // Assuming format: ID, Name, Amount, StartDate, EndDate, Category, Status
    final cloudIds = <String>{};
    
    // Parse cloud data to find what's missing locally
    for (var i = 1; i < cloudData.length; i++) { // Skip header
      final row = cloudData[i];
      if (row.isEmpty) continue;
      final parsedId = _parseId(row[0].toString());
      if (parsedId == null) continue;
      
      final idStr = parsedId.toString();
      cloudIds.add(idStr);
      
      if (!localIds.contains(idStr)) {
        // Exists in cloud, missing locally -> Download to local
        try {
          final target = IncomeTarget();
          target.id = parsedId;
          
          target
            ..name = row.length > 1 ? (row[1]?.toString() ?? 'Unknown') : 'Unknown'
            ..targetAmount = row.length > 2 ? _parseDouble(row[2]) : 0.0
            ..startDate = row.length > 3 ? _parseDate(row[3]?.toString() ?? '') : DateTime.now()
            ..endDate = row.length > 4 ? _parseDate(row[4]?.toString() ?? '') : DateTime.now()
            ..category = TargetCategory.values.firstWhere((e) => e.name == (row.length > 5 ? row[5]?.toString() : 'savings'), orElse: () => TargetCategory.savings)
            ..status = TargetStatus.values.firstWhere((e) => e.name == (row.length > 6 ? row[6]?.toString() : 'notStarted'), orElse: () => TargetStatus.notStarted);
          
          await targetRepository.saveTarget(target);
        } catch (e) {
          print('Error parsing cloud target: $e');
        }
      }
    }

    // 3. Push local targets that are missing in cloud
    for (final target in localTargets) {
      if (!cloudIds.contains(target.id.toString())) {
        String catName = target.category.name;
        if (target.category == TargetCategory.other && target.customCategory != null) {
          catName = target.customCategory!;
        }
        await sheetsService.appendRow('Targets!A:G', [
          target.id.toString(),
          target.name,
          target.targetAmount.toString(),
          target.startDate.toIso8601String(),
          target.endDate.toIso8601String(),
          catName,
          target.status.name,
        ]);
      }
    }
  }

  Future<void> _syncReminders() async {
    final localReminders = await reminderRepository.getAllReminders();
    final localIds = localReminders.map((r) => r.id.toString()).toSet();

    // 2. Get Cloud Reminders
    final cloudData = await sheetsService.getValues('Reminders!A:F');
    // Format: ID, Title, Category, Priority, TargetDateTime, Status
    final cloudIds = <String>{};

    for (var i = 1; i < cloudData.length; i++) { // Skip header
      final row = cloudData[i];
      if (row.isEmpty) continue;
      final parsedId = _parseId(row[0].toString());
      if (parsedId == null) continue;

      final idStr = parsedId.toString();
      cloudIds.add(idStr);

      if (!localIds.contains(idStr)) {
        // Exists in cloud, missing locally -> Download to local
        try {
          final reminder = Reminder();
          reminder.id = parsedId;

          reminder
            ..title = row.length > 1 ? (row[1]?.toString() ?? 'Unknown') : 'Unknown'
            ..category = ReminderCategory.values.firstWhere((e) => e.name == (row.length > 2 ? row[2]?.toString() : 'other'), orElse: () => ReminderCategory.other)
            ..priority = PriorityLevel.values.firstWhere((e) => e.name == (row.length > 3 ? row[3]?.toString() : 'medium'), orElse: () => PriorityLevel.medium)
            ..targetDateTime = row.length > 4 ? _parseDate(row[4]?.toString() ?? '') : DateTime.now()
            ..status = ReminderStatus.values.firstWhere((e) => e.name == (row.length > 5 ? row[5]?.toString() : 'pending'), orElse: () => ReminderStatus.pending)
            ..createdAt = DateTime.now()
            ..notificationPreferenceMinutes = 15;

          await reminderRepository.saveReminder(reminder);
        } catch (e) {
          print('Error parsing cloud reminder: $e');
        }
      }
    }

    // 3. Push local reminders that are missing in cloud
    for (final reminder in localReminders) {
      if (!cloudIds.contains(reminder.id.toString())) {
        await sheetsService.appendRow('Reminders!A:F', [
          reminder.id.toString(),
          reminder.title,
          reminder.category.name,
          reminder.priority.name,
          reminder.targetDateTime.toIso8601String(),
          reminder.status.name,
        ]);
      }
    }
  }

  Future<void> _syncFinancialRecords() async {
    // 1. Get Local Records
    final localRecords = await financialRecordRepository.getAllRecords();
    final localIds = localRecords.map((r) => r.id.toString()).toSet();

    // 2. Get Cloud Financial Records
    final cloudData = await sheetsService.getValues('FinancialRecords!A:G');
    // Format: ID, Type, CategoryID, Description, Amount, Date, DeviceID
    final cloudIds = <String>{};

    for (var i = 1; i < cloudData.length; i++) { // Skip header
      final row = cloudData[i];
      if (row.isEmpty) continue;
      final parsedId = _parseId(row[0].toString());
      if (parsedId == null) continue;

      final idStr = parsedId.toString();
      cloudIds.add(idStr);

      if (!localIds.contains(idStr)) {
        try {
          final record = FinancialRecord();
          record.id = parsedId;
          record.type = row.length > 1 ? (row[1]?.toString() ?? 'expense') : 'expense';
          record.categoryId = row.length > 2 ? (row[2]?.toString() ?? 'expense_other') : 'expense_other';
          record.description = row.length > 3 ? row[3]?.toString() : null;
          record.amount = row.length > 4 ? _parseDouble(row[4]) : 0.0;
          record.transactionDate = row.length > 5 ? _parseDate(row[5]?.toString() ?? '') : DateTime.now();

          await financialRecordRepository.saveRecord(record);
        } catch (e) {
          print('Error parsing cloud financial record: $e');
        }
      }
    }

    // 3. Push local financial records that are missing in cloud
    for (final record in localRecords) {
      if (!cloudIds.contains(record.id.toString())) {
        await sheetsService.appendRow('FinancialRecords!A:G', [
          record.id.toString(),
          record.type,
          record.categoryId,
          record.description ?? '',
          record.amount.toString(),
          record.transactionDate.toIso8601String(),
          record.deviceId,
        ]);
      }
    }
  }

  Future<void> _syncIncomeRecords() async {
    // 1. Get all local records by iterating over local targets
    final localTargets = await targetRepository.getAllTargets();
    final localRecords = <DailyIncomeRecord>[];
    for (var t in localTargets) {
      localRecords.addAll(await targetRepository.getRecordsForTarget(t.id));
    }
    final localIds = localRecords.map((r) => r.id.toString()).toSet();

    // 2. Get Cloud Records
    final cloudData = await sheetsService.getValues('IncomeRecords!A:E');
    // Format: ID, TargetID, Date, Amount, Notes
    final cloudIds = <String>{};

    for (var i = 1; i < cloudData.length; i++) { // Skip header
      final row = cloudData[i];
      if (row.isEmpty) continue;
      final parsedId = _parseId(row[0].toString());
      if (parsedId == null) continue;

      final idStr = parsedId.toString();
      cloudIds.add(idStr);

      if (!localIds.contains(idStr)) {
        try {
          final record = DailyIncomeRecord();
          record.id = parsedId;
          
          record.targetId = row.length > 1 ? (int.tryParse(row[1]?.toString() ?? '') ?? 0) : 0;
          record.date = row.length > 2 ? _parseDate(row[2]?.toString() ?? '') : DateTime.now();
          record.incomeAmount = row.length > 3 ? _parseDouble(row[3]) : 0.0;
          record.notes = row.length > 4 ? row[4]?.toString() : '';

          if (record.targetId > 0) {
            await targetRepository.saveRecord(record);
          }
        } catch (e) {
          print('Error parsing cloud income record: $e');
        }
      }
    }

    // 3. Push local records that are missing in cloud
    for (final record in localRecords) {
      if (!cloudIds.contains(record.id.toString())) {
        await sheetsService.appendRow('IncomeRecords!A:E', [
          record.id.toString(),
          record.targetId.toString(),
          record.date.toIso8601String(),
          record.incomeAmount.toString(),
          record.notes ?? '',
        ]);
      }
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        var parts = dateStr.trim().split(' ');
        if (parts.length == 2) {
          var timeParts = parts[1].split(':');
          if (timeParts.isNotEmpty && timeParts[0].length == 1) {
            timeParts[0] = '0${timeParts[0]}';
          }
          return DateTime.parse('${parts[0]} ${timeParts.join(':')}');
        }
        return DateTime.now();
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  int? _parseId(String val) {
    if (val.isEmpty || val == 'null') return null;
    var exact = int.tryParse(val);
    if (exact != null) return exact;
    
    var clean = val.replaceAll(',', '');
    var d = double.tryParse(clean);
    if (d != null) return d.toInt();
    
    return null;
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      if (val == 'null' || val.isEmpty) return 0.0;
      var clean = val.replaceAll(',', '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}
