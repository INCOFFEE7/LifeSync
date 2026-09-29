import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';

/// Service untuk menjadwalkan ulang semua notifikasi aktif
/// Dipanggil saat aplikasi dibuka atau setelah HP restart
class NotificationRescheduler {
  final DatabaseService _dbService;
  final NotificationService _notifService;

  NotificationRescheduler(this._dbService, this._notifService);

  /// Re-schedule semua pengingat yang masih aktif dan belum lewat waktunya
  Future<void> rescheduleAll({String defaultSound = 'notif'}) async {
    try {
      // Gunakan Isar raw query untuk kompatibilitas penuh
      final List<Reminder> allReminders =
          await _dbService.db.reminders.where().findAll();

      // Filter di Dart: hanya yang belum dihapus dan belum selesai
      final reminders = allReminders
          .where((r) => !r.deleted && r.realtimeStatus != 'Selesai')
          .toList();

      int scheduled = 0;
      int skipped = 0;

      for (final reminder in reminders) {
        // Hitung waktu notifikasi yang sesungguhnya
        DateTime scheduledTime;
        if (reminder.isAllDay) {
          scheduledTime = DateTime(
            reminder.targetDateTime.year,
            reminder.targetDateTime.month,
            reminder.targetDateTime.day,
            6,
            0,
          );
        } else {
          scheduledTime = reminder.targetDateTime.subtract(
            Duration(minutes: reminder.notificationPreferenceMinutes),
          );
        }

        // Lewati jika waktu sudah lewat
        if (scheduledTime.isBefore(DateTime.now())) {
          skipped++;
          continue;
        }

        final sound = (reminder.customSound?.isNotEmpty == true)
            ? reminder.customSound!
            : defaultSound;

        final payload = jsonEncode({
          'id': reminder.id,
          'title': reminder.title,
          'description': reminder.description ?? '',
          'startTime': reminder.targetDateTime.toIso8601String(),
          'endTime': reminder.effectiveEndTime.toIso8601String(),
          'type': 'reminder',
        });

        final success = await _notifService.scheduleNotification(
          id: reminder.id,
          title: 'LifeSync: ${reminder.title}',
          body: _buildBody(reminder),
          scheduledTime: scheduledTime,
          sound: sound,
          payload: payload,
        );

        if (success) scheduled++;
      }

      debugPrint(
          '[Rescheduler] Selesai: $scheduled dijadwalkan, $skipped dilewati (sudah lewat)');
    } catch (e, stack) {
      debugPrint('[Rescheduler] Error: $e\n$stack');
    }
  }

  String _buildBody(Reminder reminder) {
    final mins = reminder.notificationPreferenceMinutes;
    if (mins == 0) return 'Pengingat "${reminder.title}" sudah tiba!';
    if (mins < 60) return 'Pengingat dalam $mins menit lagi.';
    if (mins < 1440) {
      final hours = mins ~/ 60;
      return 'Pengingat dalam $hours jam lagi.';
    }
    final days = mins ~/ 1440;
    return 'Pengingat dalam $days hari lagi.';
  }
}
