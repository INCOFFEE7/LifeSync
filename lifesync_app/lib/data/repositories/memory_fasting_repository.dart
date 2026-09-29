import 'dart:async';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/domain/repositories/fasting_repository.dart';

class MemoryFastingRepository implements FastingRepository {
  final List<FastingDebt> _debts = [];
  final List<QadhaRecord> _qadha = [];
  int _nextDebtId = 1;
  int _nextQadhaId = 1;
  
  final _debtsController = StreamController<List<FastingDebt>>.broadcast();
  final _qadhaController = StreamController<List<QadhaRecord>>.broadcast();

  MemoryFastingRepository() {
    _debtsController.add(_debts.where((d) => !d.deleted).toList());
    _qadhaController.add(_qadha.where((q) => !q.deleted).toList());
  }

  void _notifyDebts() => _debtsController.add(getAllDebtsSync());
  void _notifyQadha() => _qadhaController.add(getAllQadhaSync());

  List<FastingDebt> getAllDebtsSync() => _debts.where((d) => !d.deleted).toList();
  List<QadhaRecord> getAllQadhaSync() => _qadha.where((q) => !q.deleted).toList();

  @override
  Future<List<FastingDebt>> getAllDebts() async => getAllDebtsSync();

  @override
  Stream<List<FastingDebt>> watchDebts() async* {
    yield getAllDebtsSync();
    yield* _debtsController.stream;
  }

  @override
  Future<FastingDebt?> getDebtById(int id) async {
    try {
      return _debts.firstWhere((d) => d.id == id && !d.deleted);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> saveDebt(FastingDebt debt) async {
    if (debt.id == -1 || debt.id == 0) {
      debt.id = _nextDebtId++;
      _debts.add(debt);
    } else {
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) _debts[index] = debt;
      else _debts.add(debt);
    }
    _notifyDebts();
    return debt.id;
  }

  @override
  Future<int> updateDebt(FastingDebt debt) async {
    final index = _debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      _debts[index] = debt;
      _notifyDebts();
      return debt.id;
    }
    return -1;
  }

  @override
  Future<void> deleteDebt(int id) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _debts[index].deleted = true;
      _notifyDebts();
    }
  }

  @override
  Future<List<QadhaRecord>> getAllQadha() async => getAllQadhaSync();

  @override
  Stream<List<QadhaRecord>> watchQadha() async* {
    yield getAllQadhaSync();
    yield* _qadhaController.stream;
  }

  @override
  Future<List<QadhaRecord>> getQadhaByDebtId(int debtId) async {
    return _qadha.where((q) => q.fastingDebtId == debtId && !q.deleted).toList();
  }

  @override
  Future<int> saveQadha(QadhaRecord qadha) async {
    if (qadha.id == -1 || qadha.id == 0) {
      qadha.id = _nextQadhaId++;
      _qadha.add(qadha);
    } else {
      final index = _qadha.indexWhere((q) => q.id == qadha.id);
      if (index != -1) _qadha[index] = qadha;
      else _qadha.add(qadha);
    }
    
    // Update debt
    final debt = await getDebtById(qadha.fastingDebtId);
    if (debt != null) {
      debt.currentDebt -= qadha.amount;
      await saveDebt(debt);
    }
    
    _notifyQadha();
    return qadha.id;
  }

  @override
  Future<int> updateQadha(QadhaRecord qadha) async {
    final index = _qadha.indexWhere((q) => q.id == qadha.id);
    if (index != -1) {
      final oldQadha = _qadha[index];
      final amountDiff = qadha.amount - oldQadha.amount;
      _qadha[index] = qadha;
      
      if (amountDiff != 0) {
        final debt = await getDebtById(qadha.fastingDebtId);
        if (debt != null) {
          debt.currentDebt -= amountDiff;
          await updateDebt(debt);
        }
      }
      
      _notifyQadha();
      return qadha.id;
    }
    return -1;
  }

  @override
  Future<void> deleteQadha(int id) async {
    final index = _qadha.indexWhere((q) => q.id == id);
    if (index != -1) {
      final qadha = _qadha[index];
      qadha.deleted = true;
      
      // Revert debt
      final debt = await getDebtById(qadha.fastingDebtId);
      if (debt != null) {
        debt.currentDebt += qadha.amount;
        await saveDebt(debt);
      }
      
      _notifyQadha();
    }
  }

  @override
  Future<int> getTotalCurrentDebt() async {
    final debts = getAllDebtsSync();
    return debts.fold<int>(0, (sum, debt) => sum + debt.currentDebt);
  }
}
