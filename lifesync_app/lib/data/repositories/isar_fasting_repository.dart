import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/domain/repositories/fasting_repository.dart';
import 'package:lifesync_app/core/database/database_service.dart';

class IsarFastingRepository implements FastingRepository {
  final DatabaseService _dbService;

  IsarFastingRepository(this._dbService);

  @override
  Future<List<FastingDebt>> getAllDebts() async {
    return await _dbService.db.fastingDebts.filter().deletedEqualTo(false).findAll();
  }

  @override
  Stream<List<FastingDebt>> watchDebts() {
    return _dbService.db.fastingDebts.filter().deletedEqualTo(false).watch(fireImmediately: true);
  }

  @override
  Future<FastingDebt?> getDebtById(int id) async {
    return await _dbService.db.fastingDebts.get(id);
  }

  @override
  Future<int> saveDebt(FastingDebt debt) async {
    return await _dbService.db.writeTxn(() async {
      debt.updatedAt = DateTime.now();
      return await _dbService.db.fastingDebts.put(debt);
    });
  }

  @override
  Future<int> updateDebt(FastingDebt debt) async {
    return await _dbService.db.writeTxn(() async {
      debt.updatedAt = DateTime.now();
      return await _dbService.db.fastingDebts.put(debt);
    });
  }

  @override
  Future<void> deleteDebt(int id) async {
    await _dbService.db.writeTxn(() async {
      final debt = await _dbService.db.fastingDebts.get(id);
      if (debt != null) {
        debt.deleted = true;
        debt.updatedAt = DateTime.now();
        await _dbService.db.fastingDebts.put(debt);
      }
    });
  }

  @override
  Future<List<QadhaRecord>> getAllQadha() async {
    return await _dbService.db.qadhaRecords.filter().deletedEqualTo(false).findAll();
  }

  @override
  Stream<List<QadhaRecord>> watchQadha() {
    return _dbService.db.qadhaRecords.filter().deletedEqualTo(false).watch(fireImmediately: true);
  }

  @override
  Future<List<QadhaRecord>> getQadhaByDebtId(int debtId) async {
    return await _dbService.db.qadhaRecords
        .filter()
        .fastingDebtIdEqualTo(debtId)
        .and()
        .deletedEqualTo(false)
        .findAll();
  }

  @override
  Future<int> saveQadha(QadhaRecord qadha) async {
    return await _dbService.db.writeTxn(() async {
      final id = await _dbService.db.qadhaRecords.put(qadha);
      
      // Update the debt
      final debt = await _dbService.db.fastingDebts.get(qadha.fastingDebtId);
      if (debt != null) {
        debt.currentDebt = debt.currentDebt - qadha.amount;
        debt.updatedAt = DateTime.now();
        await _dbService.db.fastingDebts.put(debt);
      }
      
      return id;
    });
  }

  @override
  Future<int> updateQadha(QadhaRecord qadha) async {
    return await _dbService.db.writeTxn(() async {
      final oldQadha = await _dbService.db.qadhaRecords.get(qadha.id);
      if (oldQadha != null) {
        final amountDiff = qadha.amount - oldQadha.amount;
        
        final id = await _dbService.db.qadhaRecords.put(qadha);
        
        if (amountDiff != 0) {
          final debt = await _dbService.db.fastingDebts.get(qadha.fastingDebtId);
          if (debt != null) {
            debt.currentDebt -= amountDiff;
            debt.updatedAt = DateTime.now();
            await _dbService.db.fastingDebts.put(debt);
          }
        }
        return id;
      }
      return -1;
    });
  }

  @override
  Future<void> deleteQadha(int id) async {
    await _dbService.db.writeTxn(() async {
      final qadha = await _dbService.db.qadhaRecords.get(id);
      if (qadha != null) {
        qadha.deleted = true;
        await _dbService.db.qadhaRecords.put(qadha);
        
        // Revert the debt
        final debt = await _dbService.db.fastingDebts.get(qadha.fastingDebtId);
        if (debt != null) {
          debt.currentDebt = debt.currentDebt + qadha.amount;
          debt.updatedAt = DateTime.now();
          await _dbService.db.fastingDebts.put(debt);
        }
      }
    });
  }

  @override
  Future<int> getTotalCurrentDebt() async {
    final debts = await getAllDebts();
    return debts.fold<int>(0, (int sum, debt) => sum + debt.currentDebt);
  }
}
