import 'package:lifesync_app/domain/entities/menstruation_record.dart';

abstract class MenstruationRepository {
  Future<List<MenstruationRecord>> getAllRecords();
  Stream<List<MenstruationRecord>> watchRecords();
  Future<MenstruationRecord?> getRecordById(int id);
  Future<int> saveRecord(MenstruationRecord record);
  Future<void> updateRecord(MenstruationRecord record);
  Future<void> deleteRecord(int id);
  
  Future<double> getAverageCycle();
  Future<double> getAverageDuration();
  Future<DateTime?> predictNextPeriod();
}
