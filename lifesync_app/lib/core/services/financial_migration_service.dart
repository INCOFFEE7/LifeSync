import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinancialMigrationService {
  final Isar isar;

  FinancialMigrationService(this.isar);

  Future<void> migrateLegacyRecordsIfNeeded() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasMigrated = prefs.getBool('has_migrated_v1') ?? false;
      
      // Jika migrasi sudah pernah diproses/ditandai, jangan pernah jalankan lagi
      if (hasMigrated) return; 

      // Tandai langsung bahwa migrasi sudah diproses agar catatan yang dihapus user tidak muncul lagi!
      await prefs.setBool('has_migrated_v1', true);

      final legacyRecords = await isar.financialRecords.where().findAll();
      if (legacyRecords.isEmpty) return;

      final existingNotesCount = await isar.financialNotes.count();
      if (existingNotesCount > 0) return; // Catatan sudah ada, batalkan re-import

      debugPrint('[FinancialMigrationService] Starting legacy FinancialRecord migration (${legacyRecords.length} records)');

      // Group legacy records by Date (yyyy-MM-dd)
      final Map<String, List<FinancialRecord>> grouped = {};
      final dateFmt = DateFormat('yyyy-MM-dd');

      for (final rec in legacyRecords) {
        final key = dateFmt.format(rec.transactionDate);
        grouped.putIfAbsent(key, () => []).add(rec);
      }

      await isar.writeTxn(() async {
        for (final entry in grouped.entries) {
          final recordsInDate = entry.value;
          if (recordsInDate.isEmpty) continue;

          final firstRecDate = recordsInDate.first.transactionDate;
          final title = 'Catatan ${DateFormat('d MMMM yyyy', 'id_ID').format(firstRecDate)}';

          final note = FinancialNote()
            ..title = title
            ..date = firstRecDate
            ..notes = 'Migrasi otomatis dari transaksi lama'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          final noteId = await isar.financialNotes.put(note);

          for (final rec in recordsInDate) {
            final item = FinancialItem()
              ..noteId = noteId
              ..description = rec.description ?? rec.categoryId
              ..amount = rec.amount
              ..type = rec.type
              ..createdAt = rec.createdAt
              ..updatedAt = rec.updatedAt;

            await isar.financialItems.put(item);
          }
        }
      });
      debugPrint('[FinancialMigrationService] Migration completed successfully');
    } catch (e, stack) {
      debugPrint('[FinancialMigrationService] Migration failed: $e\n$stack');
    }
  }
}
