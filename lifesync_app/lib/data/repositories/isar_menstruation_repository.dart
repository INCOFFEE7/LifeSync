import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/repositories/menstruation_repository.dart';
import 'package:lifesync_app/core/database/database_service.dart';

class IsarMenstruationRepository implements MenstruationRepository {
  final DatabaseService _dbService;

  IsarMenstruationRepository(this._dbService);

  @override
  Future<List<MenstruationRecord>> getAllRecords() async {
    return await _dbService.db.menstruationRecords
        .filter()
        .deletedEqualTo(false)
        .sortByStartDateDesc()
        .findAll();
  }

  @override
  Stream<List<MenstruationRecord>> watchRecords() {
    return _dbService.db.menstruationRecords
        .filter()
        .deletedEqualTo(false)
        .sortByStartDateDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<MenstruationRecord?> getRecordById(int id) async {
    return await _dbService.db.menstruationRecords.get(id);
  }

  @override
  Future<int> saveRecord(MenstruationRecord record) async {
    return await _dbService.db.writeTxn(() async {
      // Calculate duration if not set
      if (record.duration == 0) {
        final utcEnd = DateTime.utc(record.endDate.year, record.endDate.month, record.endDate.day);
        final utcStart = DateTime.utc(record.startDate.year, record.startDate.month, record.startDate.day);
        record.duration = utcEnd.difference(utcStart).inDays + 1;
      }
      
      final id = await _dbService.db.menstruationRecords.put(record);
      
      // If it's ramadan and hasn't been added to debt yet
      if (record.isRamadan && !record.addedToDebt) {
        final currentYear = DateTime.now().year; // Simplified ramadan year
        
        final startStr = '${record.startDate.day}/${record.startDate.month}';
        final endStr = '${record.endDate.day}/${record.endDate.month}';
        
        final debt = FastingDebt()
          ..ramadanYear = currentYear
          ..initialDebt = record.duration
          ..currentDebt = record.duration
          ..reason = 'Haid ($startStr - $endStr)'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _dbService.db.fastingDebts.put(debt);
        
        record.addedToDebt = true;
        await _dbService.db.menstruationRecords.put(record);
      }
      
      return id;
    });
  }

  @override
  Future<void> deleteRecord(int id) async {
    await _dbService.db.writeTxn(() async {
      final record = await _dbService.db.menstruationRecords.get(id);
      if (record != null) {
        record.deleted = true;
        await _dbService.db.menstruationRecords.put(record);
      }
    });
  }

  @override
  Future<void> updateRecord(MenstruationRecord record) async {
    await _dbService.db.writeTxn(() async {
      // Recalculate duration
      final utcEnd = DateTime.utc(record.endDate.year, record.endDate.month, record.endDate.day);
      final utcStart = DateTime.utc(record.startDate.year, record.startDate.month, record.startDate.day);
      record.duration = utcEnd.difference(utcStart).inDays + 1;
      record.syncStatus = 'pending';
      await _dbService.db.menstruationRecords.put(record);
    });
  }

  @override
  Future<double> getAverageCycle() async {
    final records = await getAllRecords();
    if (records.length < 2) return 28.0; // Default cycle length
    
    // Records are sorted descending
    int totalDays = 0;
    int count = 0;
    
    for (int i = 0; i < records.length - 1; i++) {
      final current = records[i];
      final previous = records[i+1];
      
      final diff = current.startDate.difference(previous.startDate).inDays;
      if (diff > 0 && diff < 100) { // filter out anomalous data
        totalDays += diff;
        count++;
      }
    }
    
    return count > 0 ? (totalDays / count) : 28.0;
  }

  @override
  Future<double> getAverageDuration() async {
    final records = await getAllRecords();
    if (records.isEmpty) return 7.0; // Default duration
    
    int totalDuration = 0;
    for (var r in records) {
      totalDuration += r.duration;
    }
    
    return totalDuration / records.length;
  }

  @override
  Future<DateTime?> predictNextPeriod() async {
    final records = await getAllRecords();
    if (records.isEmpty) return null;
    
    final latestRecord = records.first; // Already sorted descending
    final avgCycle = await getAverageCycle();
    
    return latestRecord.startDate.add(Duration(days: avgCycle.round()));
  }
}
