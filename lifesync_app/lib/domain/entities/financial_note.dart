import 'package:isar/isar.dart';

part 'financial_note.g.dart';

@collection
class FinancialNote {
  Id id = Isar.autoIncrement;

  late String title;
  late DateTime date;
  String? notes;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
