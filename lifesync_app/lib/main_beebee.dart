import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/config/beebee_config.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/core/notifications/notification_rescheduler.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/presentation/screens/beebee_splash_screen.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:lifesync_app/core/services/midnight_sync_service.dart';
import 'package:lifesync_app/core/sync/background_sync.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Explicitly set config to beebee
  AppEnvironment.setup(BeebeeConfig.config);

  try {
    await initializeDateFormatting('id_ID', null);

    final dbService = DatabaseService();
    await dbService.init();
    
    final notificationService = NotificationService();
    try {
      await notificationService.init();
      await notificationService.requestPermissions();
      // Re-schedule semua pengingat aktif setiap kali aplikasi dibuka
      final rescheduler = NotificationRescheduler(dbService, notificationService);
      rescheduler.rescheduleAll().catchError((e) {
        debugPrint('Rescheduler error: $e');
      });
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }

    try {
      await HomeWidgetService.init();
    } catch (e) {
      debugPrint('HomeWidget init failed: $e');
    }

    try {
      await MidnightSyncService.init();
    } catch (e) {
      debugPrint('MidnightSync init failed: $e');
    }
    
    try {
      await BackgroundSyncService.init();
      BackgroundSyncService.registerAutoSync();
    } catch (e) {
      debugPrint('BackgroundSync init failed: $e');
    }

    runApp(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(dbService),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: const BeebeeApp(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Initialization Error:\n$e\n\n$stackTrace', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    ));
  }
}

class BeebeeApp extends ConsumerWidget {
  const BeebeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: AppEnvironment.config.appName,
      theme: AppEnvironment.config.lightTheme,
      darkTheme: AppEnvironment.config.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const BeebeeSplashScreen(),
    );
  }
}
