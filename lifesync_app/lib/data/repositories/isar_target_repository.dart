import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/repositories/target_repository.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';

class IsarTargetRepository implements TargetRepository {
  final DatabaseService _dbService;

  IsarTargetRepository(this._dbService);

  @override
  Future<List<IncomeTarget>> getAllTargets() async {
    return await _dbService.db.incomeTargets.filter().deletedEqualTo(false).findAll();
  }

  @override
  Future<IncomeTarget?> getTargetById(int id) async {
    return await _dbService.db.incomeTargets.get(id);
  }

  @override
  Future<int> saveTarget(IncomeTarget target) async {
    return await _dbService.db.writeTxn(() async {
      return await _dbService.db.incomeTargets.put(target);
    });
  }

  @override
  Future<void> deleteTarget(int id) async {
    await HomeWidgetService.removePinnedTarget(id);
    await _dbService.db.writeTxn(() async {
      final target = await _dbService.db.incomeTargets.get(id);
      if (target != null) {
        target.deleted = true;
        target.deletedAt = DateTime.now();
        target.updatedAt = DateTime.now();
        target.version += 1;
        target.syncStatus = 'pending';
        await _dbService.db.incomeTargets.put(target);
      }
    });
  }

  @override
  Stream<List<IncomeTarget>> watchTargets() {
    return _dbService.db.incomeTargets.filter().deletedEqualTo(false).watch(fireImmediately: true);
  }

  @override
  Future<List<DailyIncomeRecord>> getRecordsForTarget(int targetId) async {
    return await _dbService.db.dailyIncomeRecords.filter().targetIdEqualTo(targetId).and().deletedEqualTo(false).findAll();
  }

  @override
  Future<int> saveRecord(DailyIncomeRecord record) async {
    return await _dbService.db.writeTxn(() async {
      final id = await _dbService.db.dailyIncomeRecords.put(record);
      // Touch target updatedAt agar stream watchTargets() memicu update realtime di Dashboard!
      final target = await _dbService.db.incomeTargets.get(record.targetId);
      if (target != null) {
        target.updatedAt = DateTime.now();
        await _dbService.db.incomeTargets.put(target);
      }
      return id;
    });
  }

  @override
  Future<void> deleteRecord(int id) async {
    await _dbService.db.writeTxn(() async {
      final record = await _dbService.db.dailyIncomeRecords.get(id);
      if (record != null) {
        record.deleted = true;
        record.deletedAt = DateTime.now();
        record.updatedAt = DateTime.now();
        record.version += 1;
        record.syncStatus = 'pending';
        await _dbService.db.dailyIncomeRecords.put(record);

        // Touch target updatedAt agar stream watchTargets() memicu update realtime di Dashboard!
        final target = await _dbService.db.incomeTargets.get(record.targetId);
        if (target != null) {
          target.updatedAt = DateTime.now();
          await _dbService.db.incomeTargets.put(target);
        }
      }
    });
  }

  @override
  Stream<List<DailyIncomeRecord>> watchRecordsForTarget(int targetId) {
    return _dbService.db.dailyIncomeRecords.filter().targetIdEqualTo(targetId).and().deletedEqualTo(false).watch(fireImmediately: true);
  }
}
