import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';

abstract class FastingRepository {
  Future<List<FastingDebt>> getAllDebts();
  Stream<List<FastingDebt>> watchDebts();
  Future<FastingDebt?> getDebtById(int id);
  Future<int> saveDebt(FastingDebt debt);
  Future<int> updateDebt(FastingDebt debt);
  Future<void> deleteDebt(int id);
  
  Future<List<QadhaRecord>> getAllQadha();
  Stream<List<QadhaRecord>> watchQadha();
  Future<List<QadhaRecord>> getQadhaByDebtId(int debtId);
  Future<int> saveQadha(QadhaRecord qadha);
  Future<int> updateQadha(QadhaRecord qadha);
  Future<void> deleteQadha(int id);
  
  Future<int> getTotalCurrentDebt();
}
