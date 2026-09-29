import 'dart:async';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/domain/repositories/financial_record_repository.dart';

class InMemoryFinancialRecordRepository implements FinancialRecordRepository {
  final List<FinancialRecord> _records = [];
  final _controller = StreamController<List<FinancialRecord>>.broadcast();

  InMemoryFinancialRecordRepository() {
    _notify();
  }

  void _notify() {
    final active = _records.where((r) => !r.deleted).toList();
    active.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    _controller.add(active);
  }

  @override
  Future<List<FinancialRecord>> getAllRecords() async {
    final active = _records.where((r) => !r.deleted).toList();
    active.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return active;
  }

  @override
  Future<FinancialRecord?> getRecordById(int id) async {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecord(FinancialRecord record) async {
    record.updatedAt = DateTime.now();
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _records[index] = record;
    } else {
      if (record.id == 0) {
        record.id = DateTime.now().millisecondsSinceEpoch;
      }
      _records.add(record);
    }
    _notify();
  }

  @override
  Future<void> deleteRecord(int id) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _records[index].deleted = true;
      _records[index].deletedAt = DateTime.now();
      _records[index].updatedAt = DateTime.now();
      _notify();
    }
  }

  @override
  Stream<List<FinancialRecord>> watchAllRecords() {
    return _controller.stream;
  }
}
