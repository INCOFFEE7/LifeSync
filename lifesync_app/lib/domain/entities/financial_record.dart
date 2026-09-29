import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'financial_record.g.dart';

@collection
class FinancialRecord {
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

  /// 'income' or 'expense'
  late String type;

  /// Category unique identifier
  late String categoryId;

  /// Optional display name or description
  String? description;

  /// Transaction value
  late double amount;

  /// Date of transaction
  late DateTime transactionDate;
}
