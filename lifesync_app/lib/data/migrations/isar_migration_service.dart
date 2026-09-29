import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';

class IsarMigrationService {
  final Isar db;
  
  IsarMigrationService(this.db);
  
  Future<void> runMigration() async {
    final prefs = await SharedPreferences.getInstance();
    String deviceId = prefs.getString('device_id') ?? '';
    
    if (deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    
    await _migrateAppSettings(deviceId);
    await _migrateDailyIncomeRecords(deviceId);
    await _migrateIncomeTargets(deviceId);
    await _migrateReminders(deviceId);
  }
  
  Future<void> _migrateAppSettings(String deviceId) async {
    final settings = await db.appSettings.filter().syncIdEqualTo('').findAll();
    if (settings.isEmpty) return;
    
    await db.writeTxn(() async {
      for (var item in settings) {
        item.syncId = const Uuid().v4();
        item.deviceId = deviceId;
        item.createdAt = DateTime.now();
        item.updatedAt = DateTime.now();
        item.version = 1;
        item.syncStatus = 'pending';
        item.deleted = false;
        await db.appSettings.put(item);
      }
    });
  }

  Future<void> _migrateDailyIncomeRecords(String deviceId) async {
    final records = await db.dailyIncomeRecords.filter().syncIdEqualTo('').findAll();
    if (records.isEmpty) return;
    
    await db.writeTxn(() async {
      for (var item in records) {
        item.syncId = const Uuid().v4();
        item.deviceId = deviceId;
        item.createdAt = DateTime.now();
        item.updatedAt = DateTime.now();
        item.version = 1;
        item.syncStatus = 'pending';
        item.deleted = false;
        await db.dailyIncomeRecords.put(item);
      }
    });
  }
  
  Future<void> _migrateIncomeTargets(String deviceId) async {
    final targets = await db.incomeTargets.filter().syncIdEqualTo('').findAll();
    if (targets.isEmpty) return;
    
    await db.writeTxn(() async {
      for (var item in targets) {
        item.syncId = const Uuid().v4();
        item.deviceId = deviceId;
        item.createdAt = DateTime.now();
        item.updatedAt = DateTime.now();
        item.version = 1;
        item.syncStatus = 'pending';
        item.deleted = false;
        await db.incomeTargets.put(item);
      }
    });
  }
  
  Future<void> _migrateReminders(String deviceId) async {
    final reminders = await db.reminders.filter().syncIdEqualTo('').findAll();
    if (reminders.isEmpty) return;
    
    await db.writeTxn(() async {
      for (var item in reminders) {
        item.syncId = const Uuid().v4();
        item.deviceId = deviceId;
        // createdAt already exists in Reminder, so we don't override it here, but we set updatedAt
        item.updatedAt = DateTime.now();
        item.version = 1;
        item.syncStatus = 'pending';
        item.deleted = false;
        await db.reminders.put(item);
      }
    });
  }
}
