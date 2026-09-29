import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'fasting_debt.g.dart';

@collection
class FastingDebt {
  Id id = Isar.autoIncrement;
  
  String syncId = const Uuid().v4();
  String syncStatus = 'pending'; // 'pending' or 'synced'
  
  late int ramadanYear; // e.g. 1445
  late int initialDebt;
  late int currentDebt;
  String? reason;
  String? notes;
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  
  bool deleted = false;
}
