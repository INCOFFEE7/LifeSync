import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'qadha_record.g.dart';

@collection
class QadhaRecord {
  Id id = Isar.autoIncrement;
  
  String syncId = const Uuid().v4();
  String syncStatus = 'pending';
  
  late int fastingDebtId;
  late DateTime date;
  late int amount; // number of days fasting
  String? notes;
  
  DateTime createdAt = DateTime.now();
  bool deleted = false;
}
