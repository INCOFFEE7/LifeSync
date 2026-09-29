import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be overridden in ProviderScope');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden in ProviderScope');
});
