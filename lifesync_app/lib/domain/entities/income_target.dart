import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'income_target.g.dart';

@collection
class IncomeTarget {
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

  late String name;
  
  String? description;
  
  late double targetAmount;
  
  late DateTime startDate;
  
  late DateTime endDate;
  
  @enumerated
  late TargetCategory category;
  
  @enumerated
  late TargetStatus status;
  
  String? customCategory;

  // Tambahan field untuk Mode Nabung:
  // 'flexible' = Nominal Bebas, 'fixed' = Nominal Tetap
  String mode = 'flexible'; 
  
  // Jika mode == 'fixed', simpan nominal wajib hariannya
  double fixedDailyAmount = 0.0; 
}

enum TargetCategory {
  savings,
  gadget,
  travel,
  education,
  investment,
  other
}

enum TargetStatus {
  notStarted,
  active,
  aheadOfSchedule,
  onTrack,
  behindSchedule,
  completed,
  failed
}
// trigger build
