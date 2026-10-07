import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  final StreamController<Map<String, dynamic>> _inAppPopupController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onInAppPopupTriggered =>
      _inAppPopupController.stream;

  void triggerInAppPopup(Map<String, dynamic> data) {
    _inAppPopupController.add(data);
  }

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    // 1. Inisialisasi timezone dengan zona lokal yang benar
    tz.initializeTimeZones();
    _setLocalTimezone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handlePayload(response.payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotifTapped,
    );

    _initialized = true;
    debugPrint('[NotifService] Initialized successfully');

    // Cek apakah aplikasi dibuka melalui ketukan notifikasi saat tertutup
    await checkLaunchNotification();
  }

  /// Memeriksa apakah aplikasi dibuka dari ketukan notifikasi/alarm
  Future<void> checkLaunchNotification() async {
    if (kIsWeb) return;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse?.payload != null) {
        final payload = details.notificationResponse!.payload!;
        debugPrint('[NotifService] App launched from notification: $payload');
        _handlePayload(payload);
      }
    } catch (e) {
      debugPrint('[NotifService] Check launch notification error: $e');
    }
  }

  void _handlePayload(String payload) {
    if (payload.isEmpty) return;
    try {
      if (payload.startsWith('{')) {
        final data = jsonDecode(payload);
        _inAppPopupController.add(Map<String, dynamic>.from(data));
      } else {
        _inAppPopupController.add({
          'id': payload,
          'title': 'Pengingat Terjadwal',
          'body': 'Waktu pengingat Anda telah tiba!',
          'type': 'reminder',
        });
      }
    } catch (e) {
      debugPrint('[NotifService] Error parsing payload: $e');
    }
  }

  /// Deteksi dan set timezone lokal secara akurat
  void _setLocalTimezone() {
    try {
      // Coba deteksi timezone dari offset UTC
      final tzLocation = tz.getLocation(
        _mapTimezoneOffset(DateTime.now().timeZoneOffset),
      );
      tz.setLocalLocation(tzLocation);
      debugPrint('[NotifService] Timezone set to: ${tzLocation.name}');
    } catch (e) {
      // Fallback ke WIB (Asia/Jakarta) jika gagal detect
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        debugPrint('[NotifService] Timezone fallback to Asia/Jakarta');
      } catch (_) {
        debugPrint('[NotifService] Could not set timezone, using UTC');
      }
    }
  }

  /// Map UTC offset ke nama timezone yang dikenal
  String _mapTimezoneOffset(Duration offset) {
    final hours = offset.inHours;
    switch (hours) {
      case 7:
        return 'Asia/Jakarta'; // WIB
      case 8:
        return 'Asia/Makassar'; // WITA
      case 9:
        return 'Asia/Jayapura'; // WIT
      case 5:
        return 'Asia/Karachi';
      case 0:
        return 'UTC';
      default:
        return 'Asia/Jakarta'; // Default WIB
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final bool? notifGranted =
          await androidImpl.requestNotificationsPermission();
      debugPrint(
          '[NotifService] Notification permission: $notifGranted');

      // Request exact alarm permission (Android 12+)
      try {
        final bool? exactAlarmGranted =
            await androidImpl.requestExactAlarmsPermission();
        debugPrint(
            '[NotifService] Exact alarm permission: $exactAlarmGranted');
      } catch (e) {
        debugPrint('[NotifService] Exact alarm permission error: $e');
      }
    }
  }

  /// Jadwalkan satu notifikasi pengingat
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? sound,
    String? payload,
  }) async {
    if (kIsWeb) return false;

    if (!_initialized) await init();

    final now = DateTime.now();

    // Jika waktu yang dijadwalkan sudah lewat, abaikan (jangan pernah jadikan notifikasi baru atau bunyikan instan)
    if (scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now)) {
      debugPrint('[NotifService] Skipped past/expired notification: $title at $scheduledTime');
      return false;
    }

    try {
      AndroidNotificationSound? notifSound;
      String channelId;
      String channelName = 'LifeSync Alarm & Pengingat';
      bool playSound = true;

      if (sound == 'silent') {
        // Pengingat tagihan tanpa nada/ringtone
        notifSound = null;
        playSound = false;
        channelId = 'lifesync_silent_bill_v2';
        channelName = 'LifeSync Pengingat Tagihan (Tanpa Suara)';
      } else {
        // Pengingat agenda biasa: gunakan nada alarm / kustom ber-priority tinggi
        playSound = true;
        String activeSound = sound ?? '';
        if (activeSound.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          activeSound = prefs.getString('default_reminder_sound') ?? 'notif.mp3';
        }

        if (activeSound.contains('/')) {
          notifSound = UriAndroidNotificationSound('file://$activeSound');
          channelId = 'lifesync_custom_${activeSound.hashCode}_v9';
        } else {
          final soundName = activeSound.split('.').first;
          final validName = soundName.isEmpty ? 'notif' : soundName;
          notifSound = RawResourceAndroidNotificationSound(validName);
          channelId = 'lifesync_${validName}_v9';
        }
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Alarm dan Pengingat Prioritas Tinggi LifeSync',
        importance: Importance.max,
        priority: Priority.max,
        sound: notifSound,
        playSound: playSound,
        audioAttributesUsage: playSound ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        category: playSound ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        channelAction: AndroidNotificationChannelAction.update,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(body),
      );

      final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

      // Menggunakan alarmClock mode agar selalu tepat waktu di HP Samsung / Android 11+ Go Edition
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? id.toString(),
      );

      debugPrint(
          '[NotifService] Scheduled (AlarmClock): "$title" at ${scheduledTz.toString()}');
      return true;
    } catch (e, stack) {
      debugPrint('[NotifService] Schedule failed: $e\n$stack');

      // Fallback: coba dengan exactAllowWhileIdle
      try {
        await _scheduleWithFallback(id, title, body, scheduledTime, sound);
        return true;
      } catch (e2) {
        debugPrint('[NotifService] Fallback also failed: $e2');
        return false;
      }
    }
  }

  /// Fallback
  Future<void> _scheduleWithFallback(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String? sound,
  ) async {
    String activeSound = sound ?? '';
    if (activeSound.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      activeSound = prefs.getString('default_reminder_sound') ?? 'notif.mp3';
    }

    AndroidNotificationSound? notifSound;
    if (activeSound.contains('/')) {
      notifSound = UriAndroidNotificationSound('file://$activeSound');
    } else {
      notifSound = RawResourceAndroidNotificationSound(activeSound.split('.').first);
    }

    final androidDetails = AndroidNotificationDetails(
      'lifesync_fallback_v8',
      'LifeSync Reminders & Alarm',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      sound: notifSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );

    final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTz,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('[NotifService] Scheduled with fallback (alarmClock mode)');
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
    debugPrint('[NotifService] Cancelled notification id: $id');
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
    debugPrint('[NotifService] All notifications cancelled');
  }

  /// Tampilkan notifikasi sistem untuk tagihan (muncul di status bar HP)
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'lifesync_bill_system_v2',
      'LifeSync Tagihan Sistem',
      channelDescription: 'Notifikasi sistem untuk tagihan jatuh tempo',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Tagihan LifeSync',
      ),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload ?? id.toString(),
    );
    debugPrint('[NotifService] Posted system notification: $title');
  }

  /// Tampilkan notifikasi langsung sekarang
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? sound,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    String activeSound = sound ?? '';
    if (activeSound.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      activeSound = prefs.getString('default_reminder_sound') ?? 'notif.mp3';
    }

    AndroidNotificationSound? notifSound;
    String channelId = 'lifesync_test_v8';
    if (activeSound.contains('/')) {
      notifSound = UriAndroidNotificationSound('file://$activeSound');
      channelId = 'lifesync_test_custom_${activeSound.hashCode}_v8';
    } else {
      notifSound = RawResourceAndroidNotificationSound(activeSound.split('.').first);
      channelId = 'lifesync_test_${activeSound.split('.').first}_v8';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'LifeSync Test',
      importance: Importance.max,
      priority: Priority.high,
      sound: notifSound,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      99999,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
    debugPrint('[NotifService] Showed immediate notification with custom sound ($activeSound)');
  }

  /// Ambil semua notifikasi yang masih dijadwalkan
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _plugin.pendingNotificationRequests();
  }
}

/// Handler notifikasi di background (harus top-level function)
@pragma('vm:entry-point')
void _onBackgroundNotifTapped(NotificationResponse response) {
  debugPrint('[NotifService] Background tapped: ${response.payload}');
}
