import 'dart:async';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/domain/repositories/fasting_repository.dart';
import 'package:lifesync_app/domain/repositories/menstruation_repository.dart';

class MemoryMenstruationRepository implements MenstruationRepository {
  final List<MenstruationRecord> _records = [];
  int _nextId = 1;
  final _recordsController = StreamController<List<MenstruationRecord>>.broadcast();
  final FastingRepository _fastingRepo;

  MemoryMenstruationRepository(this._fastingRepo) {
    _recordsController.add(getAllRecordsSync());
  }

  void _notify() => _recordsController.add(getAllRecordsSync());

  List<MenstruationRecord> getAllRecordsSync() {
    final list = _records.where((r) => !r.deleted).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate)); // descending
    return list;
  }

  @override
  Future<List<MenstruationRecord>> getAllRecords() async => getAllRecordsSync();

  @override
  Stream<List<MenstruationRecord>> watchRecords() async* {
    yield getAllRecordsSync();
    yield* _recordsController.stream;
  }

  @override
  Future<MenstruationRecord?> getRecordById(int id) async {
    try {
      return _records.firstWhere((r) => r.id == id && !r.deleted);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> saveRecord(MenstruationRecord record) async {
    if (record.duration == 0) {
      record.duration = record.endDate.difference(record.startDate).inDays + 1;
    }
    
    if (record.id == -1 || record.id == 0) {
      record.id = _nextId++;
      _records.add(record);
    } else {
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) _records[index] = record;
      else _records.add(record);
    }
    
    // Ramadan debt logic
    if (record.isRamadan && !record.addedToDebt) {
      final currentYear = DateTime.now().year;
      final debts = await _fastingRepo.getAllDebts();
      var debt = debts.cast<FastingDebt?>().firstWhere((d) => d!.ramadanYear == currentYear, orElse: () => null);
      
      if (debt != null) {
        debt.initialDebt += record.duration;
        debt.currentDebt += record.duration;
        await _fastingRepo.saveDebt(debt);
      } else {
        debt = FastingDebt()
          ..ramadanYear = currentYear
          ..initialDebt = record.duration
          ..currentDebt = record.duration
          ..reason = 'Menstruasi Ramadan'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _fastingRepo.saveDebt(debt);
      }
      
      record.addedToDebt = true;
    }
    
    _notify();
    return record.id;
  }

  @override
  Future<void> deleteRecord(int id) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records[index].deleted = true;
      _notify();
    }
  }

  @override
  Future<void> updateRecord(MenstruationRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      _notify();
    }
  }

  @override
  Future<double> getAverageCycle() async {
    final records = getAllRecordsSync();
    if (records.length < 2) return 28.0;
    
    int totalDays = 0;
    int count = 0;
    
    for (int i = 0; i < records.length - 1; i++) {
      final current = records[i];
      final previous = records[i+1];
      
      final diff = current.startDate.difference(previous.startDate).inDays;
      if (diff > 0 && diff < 100) {
        totalDays += diff;
        count++;
      }
    }
    
    return count > 0 ? (totalDays / count) : 28.0;
  }

  @override
  Future<double> getAverageDuration() async {
    final records = getAllRecordsSync();
    if (records.isEmpty) return 7.0;
    
    int totalDuration = 0;
    for (var r in records) {
      totalDuration += r.duration;
    }
    
    return totalDuration / records.length;
  }

  @override
  Future<DateTime?> predictNextPeriod() async {
    final records = getAllRecordsSync();
    if (records.isEmpty) return null;
    
    final latestRecord = records.first;
    final avgCycle = await getAverageCycle();
    
    return latestRecord.startDate.add(Duration(days: avgCycle.round()));
  }
}
