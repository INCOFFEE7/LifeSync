import 'package:isar/isar.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/domain/repositories/financial_record_repository.dart';

class IsarFinancialRecordRepository implements FinancialRecordRepository {
  final DatabaseService _dbService;

  IsarFinancialRecordRepository(this._dbService);

  @override
  Future<List<FinancialRecord>> getAllRecords() async {
    return await _dbService.db.financialRecords
        .filter()
        .deletedEqualTo(false)
        .sortByTransactionDateDesc()
        .findAll();
  }

  @override
  Future<FinancialRecord?> getRecordById(int id) async {
    return await _dbService.db.financialRecords.get(id);
  }

  @override
  Future<void> saveRecord(FinancialRecord record) async {
    record.updatedAt = DateTime.now();
    await _dbService.db.writeTxn(() async {
      await _dbService.db.financialRecords.put(record);
    });
  }

  @override
  Future<void> deleteRecord(int id) async {
    await _dbService.db.writeTxn(() async {
      final record = await _dbService.db.financialRecords.get(id);
      if (record != null) {
        record.deleted = true;
        record.deletedAt = DateTime.now();
        record.updatedAt = DateTime.now();
        await _dbService.db.financialRecords.put(record);
      }
    });
  }

  @override
  Stream<List<FinancialRecord>> watchAllRecords() {
    return _dbService.db.financialRecords
        .filter()
        .deletedEqualTo(false)
        .sortByTransactionDateDesc()
        .build()
        .watch(fireImmediately: true);
  }
}
