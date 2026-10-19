import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'shopping_item.g.dart';

@collection
class ShoppingItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String syncId = const Uuid().v4();

  late String name;
  bool isChecked = false;
  DateTime? purchaseDate;
  double price = 0.0;

  String? purchasedBy;
  String? location;

  List<String> itemsList = [];

  String? notes;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  bool deleted = false;
}
