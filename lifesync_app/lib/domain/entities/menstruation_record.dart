import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'menstruation_record.g.dart';

@collection
class MenstruationRecord {
  Id id = Isar.autoIncrement;
  
  String syncId = const Uuid().v4();
  String syncStatus = 'pending';
  
  late DateTime startDate;
  late DateTime endDate;
  late int duration;
  
  bool isRamadan = false;
  bool addedToDebt = false;
  String? notes;
  
  DateTime createdAt = DateTime.now();
  bool deleted = false;
}
