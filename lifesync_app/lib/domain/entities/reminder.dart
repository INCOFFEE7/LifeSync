import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'reminder.g.dart';

@collection
class Reminder {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String syncId = const Uuid().v4();
  
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;
  bool deleted = false;
  int version = 1;
  String syncStatus = 'pending';
  String deviceId = '';

  late String title;
  
  String? description;

  
  late DateTime targetDateTime; // Berfungsi sebagai Start Time
  DateTime? endTime;            // End Time

  @ignore
  DateTime get effectiveEndTime {
    return endTime ?? targetDateTime.add(const Duration(hours: 1));
  }

  @ignore
  bool get isRange {
    final start = DateTime(targetDateTime.year, targetDateTime.month, targetDateTime.day);
    final end = DateTime(effectiveEndTime.year, effectiveEndTime.month, effectiveEndTime.day);
    return end.isAfter(start);
  }

  // Getter untuk menghitung status secara real-time berdasarkan waktu lokal perangkat
  @ignore
  String get realtimeStatus {
    final now = DateTime.now();
    final end = effectiveEndTime;
    if (status == ReminderStatus.completed) {
      return 'Selesai';
    }
    if (isRange) {
      // Agenda dengan rentang waktu: aktif sampai user menekan tombol Agenda Selesai
      if (now.isBefore(targetDateTime)) {
        return 'Akan Datang';
      }
      return 'Sedang Berjalan';
    }
    // Agenda satu hari: otomatis selesai jika harinya/waktunya sudah berlalu
    if (now.isBefore(targetDateTime)) {
      return 'Akan Datang';
    } else if (now.isBefore(end)) {
      return 'Sedang Berjalan';
    } else {
      return 'Selesai';
    }
  }

  @enumerated
  late ReminderCategory category;
  
  @enumerated
  late PriorityLevel priority;
  
  @enumerated
  late ReminderStatus status;
  
  late DateTime createdAt; // Already exists in reminder.dart
  
  late int notificationPreferenceMinutes; // Minutes before targetDateTime
  
  bool isAllDay = false;
  String? customSound; // name of audio file in assets/audios
  
  String? customCategory;
}

enum ReminderCategory {
  work,
  personal,
  health,
  finance,
  other
}

enum PriorityLevel {
  low,
  medium,
  high
}

enum ReminderStatus {
  pending,
  completed,
  cancelled
}
// trigger build
