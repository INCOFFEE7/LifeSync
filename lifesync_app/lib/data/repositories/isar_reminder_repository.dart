import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/repositories/reminder_repository.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';

class IsarReminderRepository implements ReminderRepository {
  final DatabaseService _dbService;

  IsarReminderRepository(this._dbService);

  @override
  Future<List<Reminder>> getAllReminders() async {
    return await _dbService.db.reminders.filter().deletedEqualTo(false).findAll();
  }

  @override
  Future<Reminder?> getReminderById(int id) async {
    return await _dbService.db.reminders.get(id);
  }

  @override
  Future<int> saveReminder(Reminder reminder) async {
    return await _dbService.db.writeTxn(() async {
      return await _dbService.db.reminders.put(reminder);
    });
  }

  @override
  Future<void> deleteReminder(int id) async {
    await HomeWidgetService.removePinnedReminder(id);
    await _dbService.db.writeTxn(() async {
      final reminder = await _dbService.db.reminders.get(id);
      if (reminder != null) {
        reminder.deleted = true;
        reminder.deletedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.version += 1;
        reminder.syncStatus = 'pending';
        await _dbService.db.reminders.put(reminder);
      }
    });
  }

  @override
  Stream<List<Reminder>> watchReminders() {
    return _dbService.db.reminders.filter().deletedEqualTo(false).watch(fireImmediately: true);
  }
}
