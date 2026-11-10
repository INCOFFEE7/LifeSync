import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/domain/entities/bill.dart';

class BillRecurrenceRule {
  /// 'auto' = Bulanan Otomatis, 'range' = Pilih Rentang Bulan, 'single' = 1 Bulan Saja
  final String mode;
  final String startMonth; // 'YYYY-MM'
  final String? endMonth; // 'YYYY-MM' (null if infinite 'auto')
  final List<String>
      excludedMonths; // 'YYYY-MM' months deleted via "Hapus Bulan Ini Saja"
  final int updatedAtMs;

  const BillRecurrenceRule({
    required this.mode,
    required this.startMonth,
    this.endMonth,
    this.excludedMonths = const [],
    required this.updatedAtMs,
  });

  BillRecurrenceRule copyWith({
    String? mode,
    String? startMonth,
    String? endMonth,
    bool clearEndMonth = false,
    List<String>? excludedMonths,
    int? updatedAtMs,
  }) {
    return BillRecurrenceRule(
      mode: mode ?? this.mode,
      startMonth: startMonth ?? this.startMonth,
      endMonth: clearEndMonth ? null : (endMonth ?? this.endMonth),
      excludedMonths: excludedMonths ?? this.excludedMonths,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'startMonth': startMonth,
        'endMonth': endMonth,
        'excludedMonths': excludedMonths,
        'updatedAtMs': updatedAtMs,
      };

  factory BillRecurrenceRule.fromJson(Map<String, dynamic> json) {
    return BillRecurrenceRule(
      mode: (json['mode'] as String?) ?? 'auto',
      startMonth: (json['startMonth'] as String?) ?? '',
      endMonth: json['endMonth'] as String?,
      excludedMonths: (json['excludedMonths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      updatedAtMs: (json['updatedAtMs'] as int?) ?? 0,
    );
  }

  bool shouldGenerateForMonth(String targetMonth, String sourceMonth) {
    if (targetMonth.compareTo(sourceMonth) <= 0) return false;
    if (mode == 'single') return false;
    if (endMonth != null && targetMonth.compareTo(endMonth!) > 0) {
      return false;
    }
    if (excludedMonths.contains(targetMonth)) return false;
    return true;
  }
}

class IsarBillRepository {
  static const String recurrencePrefsKey = 'bill_recurrence_rules_v1';

  final DatabaseService _dbService;
  final NotificationService _notifService;
  Future<void>? _activeEnsureTask;

  IsarBillRepository(this._dbService, this._notifService);

  static String normalizeSeriesKey(String name) => name.trim().toLowerCase();

  static DateTime parseMonthKey(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length == 2) {
      final y = int.tryParse(parts[0]) ?? DateTime.now().year;
      final m = int.tryParse(parts[1]) ?? DateTime.now().month;
      return DateTime(y, m, 1);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static String formatMonthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  static String nextMonthKey(String monthKey) {
    final d = parseMonthKey(monthKey);
    return formatMonthKey(DateTime(d.year, d.month + 1, 1));
  }

  static String prevMonthKey(String monthKey) {
    final d = parseMonthKey(monthKey);
    return formatMonthKey(DateTime(d.year, d.month - 1, 1));
  }

  static List<String> monthsInRange(String startMonth, String endMonth) {
    if (endMonth.compareTo(startMonth) < 0) return [startMonth];
    final result = <String>[];
    var cur = parseMonthKey(startMonth);
    final end = parseMonthKey(endMonth);
    var safety = 0;
    while (!cur.isAfter(end) && safety < 120) {
      result.add(formatMonthKey(cur));
      cur = DateTime(cur.year, cur.month + 1, 1);
      safety++;
    }
    return result;
  }

  static int monthDiff(String fromMonth, String toMonth) {
    final a = parseMonthKey(fromMonth);
    final b = parseMonthKey(toMonth);
    return (b.year - a.year) * 12 + (b.month - a.month);
  }

  static DateTime calculateDueDateForMonth(
    DateTime sourceDueDate,
    String targetMonthKey,
  ) {
    final targetDate = parseMonthKey(targetMonthKey);
    final maxDay = DateUtils.getDaysInMonth(targetDate.year, targetDate.month);
    final clampedDay = sourceDueDate.day.clamp(1, maxDay);
    return DateTime(
      targetDate.year,
      targetDate.month,
      clampedDay,
      sourceDueDate.hour,
      sourceDueDate.minute,
    );
  }

  static String? cleanBillNotesForNextMonth(String? notes) {
    if (notes == null || notes.trim().isEmpty) return null;
    final cleanedLines = notes
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('[Bayar '))
        .toList();
    final joined = cleanedLines.join('\n').trim();
    return joined.isEmpty ? null : joined;
  }

  Future<Map<String, BillRecurrenceRule>> _loadRecurrenceRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(recurrencePrefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          BillRecurrenceRule.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRecurrenceRules(
    Map<String, BillRecurrenceRule> rules,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(rules.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(recurrencePrefsKey, encoded);
  }

  Future<BillRecurrenceRule?> getRecurrenceRule(String billName) async {
    final rules = await _loadRecurrenceRules();
    return rules[normalizeSeriesKey(billName)];
  }

  Future<void> clearRecurrenceRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(recurrencePrefsKey);
  }

  /// Otomatis membuat tagihan bulanan untuk [targetMonth] dari tagihan bulanan
  /// aktif di bulan-bulan sebelumnya apabila belum dibuat dan belum dihentikan.
  Future<void> ensureRecurringBillsForMonth(String targetMonth) async {
    if (kIsWeb) return;
    while (_activeEnsureTask != null) {
      await _activeEnsureTask;
    }
    final completerTask = _ensureRecurringBillsInternal(targetMonth);
    _activeEnsureTask = completerTask;
    try {
      await completerTask;
    } finally {
      if (_activeEnsureTask == completerTask) {
        _activeEnsureTask = null;
      }
    }
  }

  Future<void> _ensureRecurringBillsInternal(String targetMonth) async {
    if (kIsWeb) return;

    final allPreviousActive = await _dbService.db.bills
        .filter()
        .deletedEqualTo(false)
        .and()
        .monthLessThan(targetMonth)
        .findAll();

    if (allPreviousActive.isEmpty) return;

    // Kelompokkan tagihan bulanan berdasarkan nama (ambil bulan terbaru sebelum targetMonth sebagai template)
    final latestBySeries = <String, Bill>{};
    for (final b in allPreviousActive) {
      final bType = b.billType.isEmpty ? 'monthly' : b.billType;
      if (bType != 'monthly') continue;
      final key = normalizeSeriesKey(b.name);
      if (key.isEmpty) continue;
      final existing = latestBySeries[key];
      if (existing == null || b.month.compareTo(existing.month) > 0) {
        latestBySeries[key] = b;
      }
    }

    if (latestBySeries.isEmpty) return;

    final rules = await _loadRecurrenceRules();
    final existingInTargetMonth =
        await _dbService.db.bills.filter().monthEqualTo(targetMonth).findAll();

    for (final entry in latestBySeries.entries) {
      final seriesKey = entry.key;
      final sourceBill = entry.value;

      // Batasi jarak auto-generate maksimal 60 bulan ke depan
      final diffMonths = monthDiff(sourceBill.month, targetMonth);
      if (diffMonths <= 0 || diffMonths > 60) continue;

      final rule = rules[seriesKey];
      if (rule != null) {
        if (!rule.shouldGenerateForMonth(targetMonth, sourceBill.month)) {
          continue;
        }
      }

      // Cek apakah di targetMonth sudah ada tagihan aktif dengan nama sama
      final hasActiveInTarget = existingInTargetMonth.any((b) {
        final bType = b.billType.isEmpty ? 'monthly' : b.billType;
        return !b.deleted &&
            bType == 'monthly' &&
            normalizeSeriesKey(b.name) == seriesKey;
      });
      if (hasActiveInTarget) continue;

      // Cek apakah di targetMonth sudah pernah dihapus (soft-deleted) setelah rule dibuat
      final hasDeletedInTarget = existingInTargetMonth.any((b) {
        final bType = b.billType.isEmpty ? 'monthly' : b.billType;
        if (!b.deleted || bType != 'monthly') return false;
        if (normalizeSeriesKey(b.name) != seriesKey) return false;
        if (rule == null) return true;
        return b.updatedAt.millisecondsSinceEpoch >= rule.updatedAtMs;
      });
      if (hasDeletedInTarget) continue;

      final autoBill = Bill()
        ..name = sourceBill.name
        ..amount = sourceBill.amount
        ..realizationAmount = 0.0
        ..prePaymentRealization = 0.0
        ..month = targetMonth
        ..dueDate = calculateDueDateForMonth(sourceBill.dueDate, targetMonth)
        ..isPaid = false
        ..paidAt = null
        ..reminderDaysBefore = sourceBill.reminderDaysBefore
        ..notes = cleanBillNotesForNextMonth(sourceBill.notes)
        ..billType = 'monthly'
        ..paidBy = sourceBill.paidBy
        ..receivedBy = sourceBill.receivedBy
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await saveBill(autoBill);
    }
  }

  Future<List<Bill>> getBillsByMonth(String month) async {
    if (kIsWeb) return [];
    await ensureRecurringBillsForMonth(month);
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
        .group(
            (q) => q.isPaidEqualTo(true).or().realizationAmountGreaterThan(0))
        .sortByDueDateDesc()
        .findAll();
  }

  Stream<List<Bill>> watchBillsByMonth(String month) async* {
    if (kIsWeb) {
      yield [];
      return;
    }
    await ensureRecurringBillsForMonth(month);
    yield* _dbService.db.bills
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

  Future<bool> checkDuplicateBill(String name, String month,
      {int? excludeId}) async {
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

  /// Simpan tagihan beserta pengaturan periode berulang ('auto', 'range', 'single').
  Future<int> saveBillWithRecurrence({
    required Bill bill,
    required String recurrenceMode, // 'auto' | 'range' | 'single'
    String? rangeEndMonth,
    String? previousBillName,
  }) async {
    final primaryId = await saveBill(bill);
    if (kIsWeb) return primaryId;

    final bType = bill.billType.isEmpty ? 'monthly' : bill.billType;
    if (bType != 'monthly') {
      return primaryId;
    }

    final rules = await _loadRecurrenceRules();
    final newKey = normalizeSeriesKey(bill.name);
    if (previousBillName != null) {
      final oldKey = normalizeSeriesKey(previousBillName);
      if (oldKey != newKey) {
        rules.remove(oldKey);
      }
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existingRule = rules[newKey];

    String? effectiveEndMonth;
    if (recurrenceMode == 'single') {
      effectiveEndMonth = bill.month;
    } else if (recurrenceMode == 'range') {
      effectiveEndMonth =
          (rangeEndMonth != null && rangeEndMonth.compareTo(bill.month) >= 0)
              ? rangeEndMonth
              : bill.month;
    } else {
      effectiveEndMonth = null;
    }

    // Bersihkan bulan yang sedang disimpan (dan bulan rentang) dari daftar excludedMonths
    final monthsToUnexclude = <String>{bill.month};
    if (recurrenceMode == 'range' && effectiveEndMonth != null) {
      monthsToUnexclude.addAll(monthsInRange(bill.month, effectiveEndMonth));
    }

    final updatedExcluded = (existingRule?.excludedMonths ?? const <String>[])
        .where((m) =>
            !monthsToUnexclude.contains(m) && m.compareTo(bill.month) < 0)
        .toList();

    rules[newKey] = BillRecurrenceRule(
      mode: recurrenceMode,
      startMonth: bill.month,
      endMonth: effectiveEndMonth,
      excludedMonths: updatedExcluded,
      updatedAtMs: nowMs,
    );
    await _saveRecurrenceRules(rules);

    // Jika mode 'range', langsung buatkan tagihan untuk setiap bulan dalam rentang
    if (recurrenceMode == 'range' &&
        effectiveEndMonth != null &&
        effectiveEndMonth.compareTo(bill.month) > 0) {
      final rangeMonths = monthsInRange(bill.month, effectiveEndMonth);
      for (final m in rangeMonths) {
        if (m == bill.month) continue;
        final existingInM = await _dbService.db.bills
            .filter()
            .monthEqualTo(m)
            .and()
            .nameEqualTo(bill.name, caseSensitive: false)
            .and()
            .deletedEqualTo(false)
            .findAll();

        if (existingInM.isEmpty) {
          final rangeBill = Bill()
            ..name = bill.name
            ..amount = bill.amount
            ..realizationAmount = 0.0
            ..prePaymentRealization = 0.0
            ..month = m
            ..dueDate = calculateDueDateForMonth(bill.dueDate, m)
            ..isPaid = false
            ..paidAt = null
            ..reminderDaysBefore = bill.reminderDaysBefore
            ..notes = cleanBillNotesForNextMonth(bill.notes)
            ..billType = 'monthly'
            ..paidBy = bill.paidBy
            ..receivedBy = bill.receivedBy
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await saveBill(rangeBill);
        }
      }
    }

    return primaryId;
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

  /// Opsi 1: Hapus tagihan untuk bulan ini saja (bulan-bulan berikutnya tetap berjalan).
  Future<void> deleteBillThisMonthOnly(Bill bill) async {
    if (kIsWeb) return;

    final bType = bill.billType.isEmpty ? 'monthly' : bill.billType;
    if (bType == 'monthly') {
      final rules = await _loadRecurrenceRules();
      final key = normalizeSeriesKey(bill.name);
      final currentRule = rules[key];
      final nextMonth = nextMonthKey(bill.month);

      // Pastikan apabila tagihan bulan ini adalah satu-satunya record sumber yang aktif,
      // kita meneruskan template ke bulan berikutnya terlebih dahulu sebelum menghapus bulan ini.
      final shouldContinueNextMonth = currentRule == null ||
          (currentRule.mode != 'single' &&
              (currentRule.endMonth == null ||
                  nextMonth.compareTo(currentRule.endMonth!) <= 0) &&
              !currentRule.excludedMonths.contains(nextMonth));

      if (shouldContinueNextMonth) {
        final otherActive = await _dbService.db.bills
            .filter()
            .deletedEqualTo(false)
            .and()
            .nameEqualTo(bill.name, caseSensitive: false)
            .findAll();

        final hasOtherMonthActive =
            otherActive.any((b) => b.id != bill.id && b.month != bill.month);

        if (!hasOtherMonthActive) {
          final seedBill = Bill()
            ..name = bill.name
            ..amount = bill.amount
            ..realizationAmount = 0.0
            ..prePaymentRealization = 0.0
            ..month = nextMonth
            ..dueDate = calculateDueDateForMonth(bill.dueDate, nextMonth)
            ..isPaid = false
            ..paidAt = null
            ..reminderDaysBefore = bill.reminderDaysBefore
            ..notes = cleanBillNotesForNextMonth(bill.notes)
            ..billType = 'monthly'
            ..paidBy = bill.paidBy
            ..receivedBy = bill.receivedBy
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await saveBill(seedBill);
        }
      }

      final excluded = <String>{
        ...(currentRule?.excludedMonths ?? const <String>[]),
        bill.month,
      }.toList();

      rules[key] = BillRecurrenceRule(
        mode: currentRule?.mode ?? 'auto',
        startMonth: currentRule?.startMonth ?? bill.month,
        endMonth: currentRule?.endMonth,
        excludedMonths: excluded,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _saveRecurrenceRules(rules);
    }

    await deleteBill(bill.id);
  }

  /// Opsi 2: Hapus tagihan untuk bulan ini dan seluruh bulan berikutnya.
  Future<int> deleteBillThisAndFutureMonths(Bill bill) async {
    if (kIsWeb) return 0;

    final bType = bill.billType.isEmpty ? 'monthly' : bill.billType;
    if (bType != 'monthly') {
      await deleteBill(bill.id);
      return 1;
    }

    final rules = await _loadRecurrenceRules();
    final key = normalizeSeriesKey(bill.name);
    final currentRule = rules[key];
    final stopAtMonth = prevMonthKey(bill.month);

    rules[key] = BillRecurrenceRule(
      mode: currentRule?.mode ?? 'auto',
      startMonth: currentRule?.startMonth ?? bill.month,
      endMonth: stopAtMonth,
      excludedMonths: currentRule?.excludedMonths ?? const [],
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveRecurrenceRules(rules);

    final matchingBills = await _dbService.db.bills
        .filter()
        .deletedEqualTo(false)
        .and()
        .nameEqualTo(bill.name, caseSensitive: false)
        .findAll();

    final toDelete = matchingBills.where((b) {
      final t = b.billType.isEmpty ? 'monthly' : b.billType;
      return b.id == bill.id ||
          (t == 'monthly' && b.month.compareTo(bill.month) >= 0);
    }).toList();

    final now = DateTime.now();
    await _dbService.db.writeTxn(() async {
      for (final b in toDelete) {
        b.deleted = true;
        b.updatedAt = now;
        await _dbService.db.bills.put(b);
      }
    });

    for (final b in toDelete) {
      await _notifService.cancelNotification(b.id + 800000);
    }

    return toDelete.length;
  }

  /// Copy tagihan ke bulan berikutnya (manual)
  Future<Bill> copyBillToMonth(
      Bill sourceBill, String targetMonth, DateTime targetDueDate) async {
    final newBill = Bill()
      ..name = sourceBill.name
      ..amount = sourceBill.amount
      ..realizationAmount = 0.0 // Realisasi ke 0!
      ..prePaymentRealization = 0.0
      ..month = targetMonth
      ..dueDate = targetDueDate
      ..isPaid = false // Status kembali belum dibayar!
      ..paidAt = null
      ..reminderDaysBefore = sourceBill.reminderDaysBefore
      ..notes = cleanBillNotesForNextMonth(sourceBill.notes)
      ..billType = sourceBill.billType.isEmpty ? 'monthly' : sourceBill.billType
      ..paidBy = sourceBill.paidBy
      ..receivedBy = sourceBill.receivedBy
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
      scheduledDate =
          targetDate.subtract(Duration(days: bill.reminderDaysBefore));
    }

    if (scheduledDate.isAfter(DateTime.now())) {
      final payload = jsonEncode({
        'id': bill.id,
        'title': 'Tagihan Jatuh Tempo: ${bill.name}',
        'body':
            'Tagihan ${bill.name} sebesar Rp ${bill.amount.toInt()} belum dibayar & jatuh tempo pada ${targetDate.day}/${targetDate.month}/${targetDate.year}.',
        'type': 'bill',
        'amount': bill.amount,
        'dueDate': bill.dueDate.toIso8601String(),
      });

      await _notifService.scheduleNotification(
        id: notifId,
        title: 'Tagihan Jatuh Tempo: ${bill.name}',
        body:
            'Tagihan ${bill.name} sebesar Rp ${bill.amount.toInt()} belum dibayar & jatuh tempo segera.',
        scheduledTime: scheduledDate,
        sound: 'silent',
        payload: payload,
        featureName: 'Tagihan',
      );
    } else {
      await _notifService.cancelNotification(notifId);
    }
  }
}
