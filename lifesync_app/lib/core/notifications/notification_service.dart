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

  /// Resolusi channel dan label fitur otomatis (Tagihan, Target Nabung, Pengingat Agenda, Belanja)
  Map<String, String> _resolveFeatureDetails({
    String? featureName,
    required String title,
    required String body,
    String? sound,
  }) {
    final combined = '${featureName ?? ''} $title $body'.toLowerCase();

    if (combined.contains('nabung') ||
        combined.contains('target') ||
        combined.contains('tabungan')) {
      return {
        'channelId': 'wattodo_target_v1',
        'channelName': 'WATTODO Target Nabung',
        'channelDesc': 'Notifikasi pengingat target menabung',
        'summaryText': 'Target Nabung',
      };
    } else if (combined.contains('belanja')) {
      return {
        'channelId': 'wattodo_shopping_v1',
        'channelName': 'WATTODO Belanja',
        'channelDesc': 'Notifikasi catatan belanjaan',
        'summaryText': 'Belanja',
      };
    } else if (combined.contains('tagihan') || sound == 'silent') {
      return {
        'channelId': 'wattodo_bill_v1',
        'channelName': 'WATTODO Tagihan',
        'channelDesc': 'Notifikasi jatuh tempo tagihan',
        'summaryText': 'Tagihan',
      };
    } else {
      return {
        'channelId': 'wattodo_agenda_v1',
        'channelName': 'WATTODO Pengingat Agenda',
        'channelDesc': 'Notifikasi pengingat agenda dan kegiatan',
        'summaryText': 'Pengingat Agenda',
      };
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
    String? featureName,
  }) async {
    if (kIsWeb) return false;

    if (!_initialized) await init();

    final now = DateTime.now();

    // Jika waktu yang dijadwalkan sudah lewat, abaikan
    if (scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now)) {
      debugPrint('[NotifService] Skipped past/expired notification: $title at $scheduledTime');
      return false;
    }

    try {
      AndroidNotificationSound? notifSound;
      bool playSound = true;

      final feature = _resolveFeatureDetails(
        featureName: featureName,
        title: title,
        body: body,
        sound: sound,
      );

      String channelId = feature['channelId']!;
      String channelName = feature['channelName']!;
      String channelDesc = feature['channelDesc']!;
      String summaryText = feature['summaryText']!;

      if (sound == 'silent') {
        notifSound = null;
        playSound = false;
        channelId = 'wattodo_silent_v1';
        channelName = 'WATTODO Tagihan (Tanpa Suara)';
        summaryText = 'Tagihan';
      } else {
        playSound = true;
        String activeSound = sound ?? '';
        if (activeSound.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          activeSound = prefs.getString('default_reminder_sound') ?? 'notif.mp3';
        }

        if (activeSound.contains('/')) {
          notifSound = UriAndroidNotificationSound('file://$activeSound');
          channelId = '${channelId}_custom_${activeSound.hashCode}';
        } else {
          final soundName = activeSound.split('.').first;
          final validName = soundName.isEmpty ? 'notif' : soundName;
          notifSound = RawResourceAndroidNotificationSound(validName);
          channelId = '${channelId}_$validName';
        }
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
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
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: summaryText,
        ),
      );

      final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

      // Coba berurutan: alarmClock -> exactAllowWhileIdle -> inexact
      try {
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
        debugPrint('[NotifService] Scheduled (alarmClock): "$title" at $scheduledTz ($summaryText)');
        return true;
      } catch (e) {
        debugPrint('[NotifService] alarmClock failed: $e, mencoba exactAllowWhileIdle...');
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledTz,
            NotificationDetails(android: androidDetails),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload ?? id.toString(),
          );
          debugPrint('[NotifService] Scheduled (exactAllowWhileIdle): "$title" at $scheduledTz ($summaryText)');
          return true;
        } catch (e2) {
          debugPrint('[NotifService] exactAllowWhileIdle failed: $e2, fallback ke inexact...');
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledTz,
            NotificationDetails(android: androidDetails),
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload ?? id.toString(),
          );
          debugPrint('[NotifService] Scheduled (inexact): "$title" at $scheduledTz ($summaryText)');
          return true;
        }
      }
    } catch (e, stack) {
      debugPrint('[NotifService] Schedule completely failed: $e\n$stack');
      return false;
    }
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

  /// Tampilkan notifikasi sistem status bar HP sesuai fitur (Nabung, Tagihan, Agenda, Belanja)
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? featureName,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final feature = _resolveFeatureDetails(
      featureName: featureName,
      title: title,
      body: body,
    );

    final androidDetails = AndroidNotificationDetails(
      feature['channelId']!,
      feature['channelName']!,
      channelDescription: feature['channelDesc']!,
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: feature['summaryText']!,
      ),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload ?? id.toString(),
    );
    debugPrint('[NotifService] Posted system notification: $title (${feature['summaryText']})');
  }

  /// Tampilkan notifikasi langsung sekarang
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? sound,
    String? featureName,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final feature = _resolveFeatureDetails(
      featureName: featureName,
      title: title,
      body: body,
      sound: sound,
    );

    String activeSound = sound ?? '';
    if (activeSound.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      activeSound = prefs.getString('default_reminder_sound') ?? 'notif.mp3';
    }

    AndroidNotificationSound? notifSound;
    String channelId = feature['channelId']!;
    if (activeSound.contains('/')) {
      notifSound = UriAndroidNotificationSound('file://$activeSound');
      channelId = '${channelId}_custom_${activeSound.hashCode}';
    } else {
      final soundName = activeSound.split('.').first;
      final validName = soundName.isEmpty ? 'notif' : soundName;
      notifSound = RawResourceAndroidNotificationSound(validName);
      channelId = '${channelId}_$validName';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      feature['channelName']!,
      channelDescription: feature['channelDesc']!,
      importance: Importance.max,
      priority: Priority.high,
      sound: notifSound,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: feature['summaryText']!,
      ),
    );

    await _plugin.show(
      99999,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
    debugPrint('[NotifService] Showed immediate notification: $title (${feature['summaryText']})');
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
