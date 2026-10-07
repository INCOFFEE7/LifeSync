import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/config/beebee_config.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/core/notifications/notification_rescheduler.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/core/theme/app_theme.dart';
import 'package:lifesync_app/presentation/screens/beebee_splash_screen.dart';
import 'package:lifesync_app/presentation/screens/lifesync_splash_screen.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:lifesync_app/core/services/midnight_sync_service.dart';
import 'package:lifesync_app/core/sync/background_sync.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Detect flavor dynamically from Flutter runtime or fallback to lifesync config
  if (appFlavor == 'beebee') {
    AppEnvironment.setup(BeebeeConfig.config);
  } else {
    AppEnvironment.setup(AppConfig(
      variant: AppVariant.lifesync,
      appName: 'LifeHaven',
      logoPath: 'assets/images/LifeHavenApk.png',
      logoFullPath: 'assets/images/LifeHavenFull.png',
      logoDarkPath: 'assets/images/LifeHavenDarkBG.png',
      logoDarkFullPath: 'assets/images/LifeHavenDarkBG.png',
      lightTheme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      enabledModules: ['finance_tracker', 'goals_tracker', 'reminders'],
    ));
  }

  try {
    await initializeDateFormatting('id_ID', null);

    final dbService = DatabaseService();
    await dbService.init();
    
    final notificationService = NotificationService();
    await notificationService.init();

    // Jalankan runApp segera agar AnimatedSplashScreen tampil secara instan tanpa lag!
    runApp(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(dbService),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: const LifeSyncApp(),
      ),
    );

    // Jalankan inisialisasi background service secara asinkron tanpa memblokir UI main thread
    Future.microtask(() async {
      try {
        await notificationService.requestPermissions();
        final rescheduler = NotificationRescheduler(dbService, notificationService);
        await rescheduler.reconcileNotifications();
      } catch (e) {
        debugPrint('Notification rescheduler error: $e');
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
    });
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

class LifeSyncApp extends ConsumerWidget {
  const LifeSyncApp({super.key});

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
      home: AppEnvironment.config.variant == AppVariant.beebee 
          ? const BeebeeSplashScreen() 
          : const LifeHavenSplashScreen(),
    );
  }
}
