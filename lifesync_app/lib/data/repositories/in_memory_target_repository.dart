import 'dart:async';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/repositories/target_repository.dart';

class InMemoryTargetRepository implements TargetRepository {
  final List<IncomeTarget> _targets = [];
  final List<DailyIncomeRecord> _records = [];
  
  final _targetsController = StreamController<List<IncomeTarget>>.broadcast();
  final _recordsController = StreamController<List<DailyIncomeRecord>>.broadcast();
  
  int _nextTargetId = 1;
  int _nextRecordId = 1;

  InMemoryTargetRepository() {
    _emitTargets();
  }

  void _emitTargets() {
    _targetsController.add(List.from(_targets));
  }

  void _emitRecords() {
    _recordsController.add(List.from(_records));
  }

  @override
  Future<List<IncomeTarget>> getAllTargets() async => List.from(_targets);

  @override
  Future<IncomeTarget?> getTargetById(int id) async {
    try { return _targets.firstWhere((t) => t.id == id); } catch (e) { return null; }
  }

  @override
  Future<int> saveTarget(IncomeTarget target) async {
    if (target.id == null || target.id == -1 || target.id == 0) {
      target.id = _nextTargetId++;
      _targets.add(target);
    } else {
      final index = _targets.indexWhere((t) => t.id == target.id);
      if (index != -1) _targets[index] = target;
      else _targets.add(target);
    }
    _emitTargets();
    return target.id!;
  }

  @override
  Future<void> deleteTarget(int id) async {
    _targets.removeWhere((t) => t.id == id);
    _records.removeWhere((r) => r.targetId == id);
    _emitTargets();
    _emitRecords();
  }

  @override
  Stream<List<IncomeTarget>> watchTargets() async* {
    yield List.from(_targets);
    yield* _targetsController.stream;
  }

  @override
  Future<List<DailyIncomeRecord>> getRecordsForTarget(int targetId) async {
    return _records.where((r) => r.targetId == targetId).toList();
  }

  @override
  Future<int> saveRecord(DailyIncomeRecord record) async {
    if (record.id == null || record.id == -1 || record.id == 0) {
      record.id = _nextRecordId++;
      _records.add(record);
    } else {
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) _records[index] = record;
      else _records.add(record);
    }
    _emitRecords();
    return record.id!;
  }

  @override
  Future<void> deleteRecord(int id) async {
    _records.removeWhere((r) => r.id == id);
    _emitRecords();
  }

  @override
  Stream<List<DailyIncomeRecord>> watchRecordsForTarget(int targetId) async* {
    yield _records.where((r) => r.targetId == targetId).toList();
    yield* _recordsController.stream.map((records) => records.where((r) => r.targetId == targetId).toList());
  }
}
