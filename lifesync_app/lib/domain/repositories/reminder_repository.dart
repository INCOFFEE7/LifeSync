import 'package:lifesync_app/domain/entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAllReminders();
  Future<Reminder?> getReminderById(int id);
  Future<int> saveReminder(Reminder reminder);
  Future<void> deleteReminder(int id);
  Stream<List<Reminder>> watchReminders();
}
