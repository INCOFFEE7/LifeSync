import 'package:lifesync_app/domain/entities/financial_record.dart';

abstract class FinancialRecordRepository {
  Future<List<FinancialRecord>> getAllRecords();
  Future<FinancialRecord?> getRecordById(int id);
  Future<void> saveRecord(FinancialRecord record);
  Future<void> deleteRecord(int id);
  Stream<List<FinancialRecord>> watchAllRecords();
}
