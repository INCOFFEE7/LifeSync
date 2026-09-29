import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'bill.g.dart';

@collection
class Bill {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String syncId = const Uuid().v4();

  late String name;
  late double amount;            // Nominal yang direncanakan
  double? realizationAmount;     // Nominal realisasi pembayaran saat ini
  double? prePaymentRealization;  // Realisasi sebelum pembayaran dicentang (untuk dikembalikan saat uncheck)

  @Index()
  late String month;             // Format 'YYYY-MM' (contoh: '2026-09')

  late DateTime dueDate;         // Tanggal jatuh tempo
  bool isPaid = false;           // Status pembayaran
  DateTime? paidAt;              // Tanggal pembayaran saat dicentang
  
  // Preference reminder: -1 = Tidak ada, 0 = Hari H, 1 = 1 hari sebelumnya, 3 = 3 hari, 7 = 7 hari
  int reminderDaysBefore = 0;

  String? notes;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  bool deleted = false;
}
