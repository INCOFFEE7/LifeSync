import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';

abstract class TargetRepository {
  Future<List<IncomeTarget>> getAllTargets();
  Future<IncomeTarget?> getTargetById(int id);
  Future<int> saveTarget(IncomeTarget target);
  Future<void> deleteTarget(int id);
  Stream<List<IncomeTarget>> watchTargets();
  
  Future<List<DailyIncomeRecord>> getRecordsForTarget(int targetId);
  Future<int> saveRecord(DailyIncomeRecord record);
  Future<void> deleteRecord(int id);
  Stream<List<DailyIncomeRecord>> watchRecordsForTarget(int targetId);
}
