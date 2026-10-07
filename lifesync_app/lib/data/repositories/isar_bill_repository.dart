import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/domain/entities/bill.dart';

class IsarBillRepository {
  final DatabaseService _dbService;
  final NotificationService _notifService;

  IsarBillRepository(this._dbService, this._notifService);

  Future<List<Bill>> getBillsByMonth(String month) async {
    if (kIsWeb) return [];
    return await _dbService.db.bills
        .filter()
        .monthEqualTo(month)
        .and()
        .deletedEqualTo(false)
        .sortByDueDate()
        .findAll();
  }

  /// Ambil semua tagihan yang sudah dibayar / memiliki nilai realisasi > 0
  Future<List<Bill>> getPaidBills() async {
    if (kIsWeb) return [];
    return await _dbService.db.bills
        .filter()
        .deletedEqualTo(false)
        .and()
        .group((q) => q.isPaidEqualTo(true).or().realizationAmountGreaterThan(0))
        .sortByDueDateDesc()
        .findAll();
  }

  Stream<List<Bill>> watchBillsByMonth(String month) {
    if (kIsWeb) return Stream.value([]);
    return _dbService.db.bills
        .filter()
        .monthEqualTo(month)
        .and()
        .deletedEqualTo(false)
        .sortByDueDate()
        .watch(fireImmediately: true);
  }

  Future<Bill?> getBillById(int id) async {
    if (kIsWeb) return null;
    return await _dbService.db.bills.get(id);
  }

  Future<bool> checkDuplicateBill(String name, String month, {int? excludeId}) async {
    if (kIsWeb) return false;
    final existing = await _dbService.db.bills
        .filter()
        .monthEqualTo(month)
        .and()
        .nameEqualTo(name, caseSensitive: false)
        .and()
        .deletedEqualTo(false)
        .findAll();

    if (excludeId != null) {
      return existing.any((b) => b.id != excludeId);
    }
    return existing.isNotEmpty;
  }

  Future<int> saveBill(Bill bill) async {
    if (kIsWeb) return 0;

    bill.updatedAt = DateTime.now();
    if (bill.isPaid) {
      bill.paidAt ??= DateTime.now();
    } else {
      bill.paidAt = null;
    }
    
    final id = await _dbService.db.writeTxn(() async {
      return await _dbService.db.bills.put(bill);
    });
    bill.id = id;

    // Schedule or cancel notification
    await _scheduleBillNotification(bill);

    return id;
  }

  Future<void> deleteBill(int id) async {
    if (kIsWeb) return;
    await _dbService.db.writeTxn(() async {
      final bill = await _dbService.db.bills.get(id);
      if (bill != null) {
        bill.deleted = true;
        bill.updatedAt = DateTime.now();
        await _dbService.db.bills.put(bill);
      }
    });
    // Cancel notification using bill id offset
    await _notifService.cancelNotification(id + 800000);
  }

  /// Copy tagihan ke bulan berikutnya (manual)
  Future<Bill> copyBillToMonth(Bill sourceBill, String targetMonth, DateTime targetDueDate) async {
    final newBill = Bill()
      ..name = sourceBill.name
      ..amount = sourceBill.amount
      ..realizationAmount = 0.0        // Realisasi ke 0!
      ..prePaymentRealization = 0.0
      ..month = targetMonth
      ..dueDate = targetDueDate
      ..isPaid = false                 // Status kembali belum dibayar!
      ..paidAt = null
      ..reminderDaysBefore = sourceBill.reminderDaysBefore
      ..notes = sourceBill.notes
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final id = await saveBill(newBill);
    newBill.id = id;
    return newBill;
  }

  Future<void> _scheduleBillNotification(Bill bill) async {
    final notifId = bill.id + 800000; // Unique offset for bill notifications
    
    // Cancellation if paid or deleted or no reminder
    if (bill.isPaid || bill.deleted || bill.reminderDaysBefore < 0) {
      await _notifService.cancelNotification(notifId);
      return;
    }

    // Determine scheduled time using exact dueDate
    final targetDate = bill.dueDate;
    DateTime scheduledDate;
    if (bill.reminderDaysBefore == 0) {
      scheduledDate = targetDate;
    } else {
      scheduledDate = targetDate.subtract(Duration(days: bill.reminderDaysBefore));
    }

    if (scheduledDate.isAfter(DateTime.now())) {
      final payload = jsonEncode({
        'id': bill.id,
        'title': 'Tagihan Jatuh Tempo: ${bill.name}',
        'body': 'Tagihan ${bill.name} sebesar Rp ${bill.amount.toInt()} belum dibayar & jatuh tempo pada ${targetDate.day}/${targetDate.month}/${targetDate.year}.',
        'type': 'bill',
        'amount': bill.amount,
        'dueDate': bill.dueDate.toIso8601String(),
      });

      await _notifService.scheduleNotification(
        id: notifId,
        title: 'Tagihan Jatuh Tempo: ${bill.name}',
        body: 'Tagihan ${bill.name} sebesar Rp ${bill.amount.toInt()} belum dibayar & jatuh tempo segera.',
        scheduledTime: scheduledDate,
        sound: 'silent',
        payload: payload,
      );
    } else {
      await _notifService.cancelNotification(notifId);
    }
  }
}
