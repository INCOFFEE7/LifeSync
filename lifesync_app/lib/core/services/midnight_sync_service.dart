import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

const String midnightSyncTask = 'midnight_sync_task';

// Top-level callback required by workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == midnightSyncTask) {
      try {
        // Sync is triggered — actual sync logic runs in the main app
        debugPrint('[MidnightSync] Background sync triggered at ${DateTime.now()}');
      } catch (e) {
        debugPrint('[MidnightSync] Error: $e');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

class MidnightSyncService {
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await scheduleMidnightSync();
    } catch (e) {
      debugPrint('[MidnightSync] Init error: $e');
    }
  }

  static Future<void> scheduleMidnightSync() async {
    if (kIsWeb) return;
    try {
      // Calculate initial delay until next midnight
      final now = DateTime.now();
      final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
      final initialDelay = nextMidnight.difference(now);

      // Cancel any existing sync task first
      await Workmanager().cancelByUniqueName(midnightSyncTask);

      // Schedule periodic task every 24 hours, starting at next midnight
      await Workmanager().registerPeriodicTask(
        midnightSyncTask,
        midnightSyncTask,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected, // Only run if connected to internet
          requiresBatteryNotLow: false,
        ),
      );
      debugPrint('[MidnightSync] Scheduled for ${nextMidnight.toIso8601String()} (delay: ${initialDelay.inMinutes} min)');
    } catch (e) {
      debugPrint('[MidnightSync] Schedule error: $e');
    }
  }
}
