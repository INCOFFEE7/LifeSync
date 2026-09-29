import 'package:isar/isar.dart';

part 'financial_item.g.dart';

@collection
class FinancialItem {
  Id id = Isar.autoIncrement;

  @Index()
  late int noteId;

  late String description;
  late double amount;

  /// 'income' or 'expense'
  late String type;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
