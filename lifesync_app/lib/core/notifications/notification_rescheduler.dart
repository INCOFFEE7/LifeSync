import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/bill.dart';

/// Service untuk menjadwalkan ulang dan merekonsiliasi semua notifikasi aktif
/// Dipanggil saat aplikasi dibuka atau setelah APK update / HP restart
class NotificationRescheduler {
  final DatabaseService _dbService;
  final NotificationService _notifService;

  NotificationRescheduler(this._dbService, this._notifService);

  /// Rekonsiliasi lengkap setelah APK update atau app startup
  Future<void> reconcileNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString('last_app_version') ?? '';
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';

      debugPrint('[NotificationRescheduler] Starting notification reconciliation (version: $currentVersion, last: $lastVersion)');

      // 1. Re-schedule active valid future reminders & cancel expired/deleted ones
      await rescheduleAll();

      // 2. Reconcile bills
      await reconcileBills();

      if (lastVersion != currentVersion) {
        await prefs.setString('last_app_version', currentVersion);
        debugPrint('[NotificationRescheduler] Version updated, reconciliation completed.');
      }
    } catch (e, stack) {
      debugPrint('[NotificationRescheduler] Reconciliation error: $e\n$stack');
    }
  }

  /// Re-schedule semua pengingat yang masih aktif dan belum lewat waktunya
  Future<void> rescheduleAll({String defaultSound = 'notif'}) async {
    try {
      final now = DateTime.now();
      final List<Reminder> allReminders =
          await _dbService.db.reminders.where().findAll();

      int scheduled = 0;
      int cancelled = 0;

      for (final reminder in allReminders) {
        // Clamp ke int32 — Android notification ID harus int32
        final notifId = reminder.id & 0x7FFFFFFF;

        // Jika sudah dihapus, selesai, atau waktu target/end sudah lewat -> PASTIKAN dibatalkan
        if (reminder.deleted || reminder.realtimeStatus == 'Selesai' || reminder.effectiveEndTime.isBefore(now)) {
          await _notifService.cancelNotification(notifId);
          cancelled++;
          continue;
        }

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

        // Jika waktu notifikasi offset sudah lewat:
        if (scheduledTime.isBefore(now)) {
          if (reminder.targetDateTime.isAfter(now)) {
            // Fallback: jadwalkan tepat pada waktu mulai agenda
            scheduledTime = reminder.targetDateTime;
          } else {
            await _notifService.cancelNotification(notifId);
            cancelled++;
            continue;
          }
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

        final body = (reminder.description != null && reminder.description!.trim().isNotEmpty)
            ? reminder.description!.trim()
            : _buildBody(reminder);

        final success = await _notifService.scheduleNotification(
          id: notifId,
          title: reminder.title,
          body: body,
          scheduledTime: scheduledTime,
          sound: sound,
          payload: payload,
          featureName: 'Pengingat Agenda',
        );

        if (success) scheduled++;
      }

      debugPrint(
          '[Rescheduler] Reminders: $scheduled dijadwalkan, $cancelled dibatalkan (expired/deleted/selesai)');
    } catch (e, stack) {
      debugPrint('[Rescheduler] Error rescheduling reminders: $e\n$stack');
    }
  }

  Future<void> reconcileBills() async {
    try {
      final now = DateTime.now();
      final List<Bill> allBills = await _dbService.db.bills.where().findAll();

      for (final bill in allBills) {
        final notifId = bill.id + 800000;
        if (bill.deleted || bill.isPaid || bill.dueDate.isBefore(now)) {
          await _notifService.cancelNotification(notifId);
        }
      }
    } catch (e) {
      debugPrint('[Rescheduler] Bill reconciliation error: $e');
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
