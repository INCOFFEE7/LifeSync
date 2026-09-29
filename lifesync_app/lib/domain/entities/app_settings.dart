import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String syncId = '';
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;
  bool deleted = false;
  int version = 1;
  String syncStatus = 'pending';
  String deviceId = '';

  bool isDarkMode = false;
  
  // Default minutes before reminder deadline to notify (e.g., 60 for 1 hour)
  int defaultNotificationMinutes = 60;
  
  String languageCode = 'id';
  
  List<String> customCategories = [];
}
// trigger build
