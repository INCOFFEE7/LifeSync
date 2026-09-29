import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'daily_income_record.g.dart';

@collection
class DailyIncomeRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String syncId = const Uuid().v4();
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;
  bool deleted = false;
  int version = 1;
  String syncStatus = 'pending';
  String deviceId = '';

  late int targetId; // References IncomeTarget.id
  
  late DateTime date;
  
  late double incomeAmount;
  
  String? description;
  
  String? notes;
}
// trigger build
