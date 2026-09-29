import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/core/sync/sync_engine.dart';
import 'package:lifesync_app/data/providers/google_auth_provider.dart';

const syncTaskName = "com.lifesync.app.backgroundSync";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("Native called background task: \$task");
      if (task == syncTaskName) {
        // We cannot use standard ref in background isolate directly easily without ProviderContainer
        final container = ProviderContainer();
        
        // Initialize DB
        final dbService = container.read(databaseServiceProvider);
        await dbService.init();

        final authService = container.read(googleAuthServiceProvider);
        final syncEngine = SyncEngine(dbService.db, authService);

        // Perform sync if connected
        final user = await authService.signInSilently();
        if (user != null) {
          await syncEngine.performSync();
        }
        
        container.dispose();
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Background sync failed: \$e");
      return Future.value(false); // return false to retry
    }
  });
}

class BackgroundSyncService {
  static Future<void> init() async {
    if (kIsWeb) return;
    
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static void registerAutoSync() {
    if (kIsWeb) return;
    
    Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(hours: 12), // Sync every 12 hours
      constraints: Constraints(
        networkType: NetworkType.connected, // Only when online
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static void cancelAutoSync() {
    if (kIsWeb) return;
    Workmanager().cancelAll();
  }
}
