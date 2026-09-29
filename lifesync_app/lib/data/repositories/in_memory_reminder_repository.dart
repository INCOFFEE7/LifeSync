import 'dart:async';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/repositories/reminder_repository.dart';

class InMemoryReminderRepository implements ReminderRepository {
  final List<Reminder> _reminders = [];
  final _controller = StreamController<List<Reminder>>.broadcast();
  int _nextId = 1;

  InMemoryReminderRepository() {
    _emit();
  }

  void _emit() {
    _controller.add(List.from(_reminders));
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    return List.from(_reminders);
  }

  @override
  Future<Reminder?> getReminderById(int id) async {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> saveReminder(Reminder reminder) async {
    if (reminder.id == null || reminder.id == -1 || reminder.id == 0) { // Handling autoIncrement equivalent
      reminder.id = _nextId++;
      _reminders.add(reminder);
    } else {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
      } else {
        _reminders.add(reminder);
      }
    }
    _emit();
    return reminder.id!;
  }

  @override
  Future<void> deleteReminder(int id) async {
    _reminders.removeWhere((r) => r.id == id);
    _emit();
  }

  @override
  Stream<List<Reminder>> watchReminders() async* {
    yield List.from(_reminders);
    yield* _controller.stream;
  }
}
