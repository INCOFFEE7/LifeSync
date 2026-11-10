import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';

class DatabaseBackupService {
  static const String backupMagicHeader = 'WTDBACKUP_V1:';
  static const int _xorKey =
      0x5A; // Reversible byte mask for encrypted snapshot

  /// Mengompilasi seluruh koleksi Isar menjadi JSON map
  static Future<Map<String, dynamic>> exportSnapshotMap(Isar db) async {
    final notes = await db.financialNotes.where().findAll();
    final items = await db.financialItems.where().findAll();
    final bills = await db.bills.where().findAll();
    final shopping = await db.shoppingItems.where().findAll();
    final targets = await db.incomeTargets.where().findAll();
    final incomeRecords = await db.dailyIncomeRecords.where().findAll();
    final reminders = await db.reminders.where().findAll();

    return {
      'meta': {
        'appName': 'WhatToDo',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'totalRecords': notes.length +
            items.length +
            bills.length +
            shopping.length +
            targets.length +
            incomeRecords.length +
            reminders.length,
      },
      'financialNotes': notes
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'date': n.date.toIso8601String(),
                'notes': n.notes,
                'createdAt': n.createdAt.toIso8601String(),
                'updatedAt': n.updatedAt.toIso8601String(),
              })
          .toList(),
      'financialItems': items
          .map((i) => {
                'id': i.id,
                'noteId': i.noteId,
                'description': i.description,
                'amount': i.amount,
                'type': i.type,
                'createdAt': i.createdAt.toIso8601String(),
                'updatedAt': i.updatedAt.toIso8601String(),
                'previousAmount': i.previousAmount,
              })
          .toList(),
      'bills': bills
          .map((b) => {
                'id': b.id,
                'syncId': b.syncId,
                'name': b.name,
                'amount': b.amount,
                'realizationAmount': b.realizationAmount,
                'prePaymentRealization': b.prePaymentRealization,
                'month': b.month,
                'dueDate': b.dueDate.toIso8601String(),
                'isPaid': b.isPaid,
                'paidAt': b.paidAt?.toIso8601String(),
                'reminderDaysBefore': b.reminderDaysBefore,
                'notes': b.notes,
                'billType': b.billType,
                'paidBy': b.paidBy,
                'receivedBy': b.receivedBy,
                'createdAt': b.createdAt.toIso8601String(),
                'updatedAt': b.updatedAt.toIso8601String(),
                'deleted': b.deleted,
              })
          .toList(),
      'shoppingItems': shopping
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'isChecked': s.isChecked,
                'category': s.category,
                'price': s.price,
                'realizationPrice': s.realizationPrice,
                'purchaseDate': s.purchaseDate?.toIso8601String(),
                'notes': s.notes,
                'purchasedBy': s.purchasedBy,
                'location': s.location,
                'createdAt': s.createdAt.toIso8601String(),
                'updatedAt': s.updatedAt.toIso8601String(),
                'deleted': s.deleted,
              })
          .toList(),
      'incomeTargets': targets
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'targetAmount': t.targetAmount,
                'startDate': t.startDate.toIso8601String(),
                'endDate': t.endDate.toIso8601String(),
                'category': t.category.name,
                'customCategory': t.customCategory,
                'status': t.status.name,
                'mode': t.mode,
                'fixedDailyAmount': t.fixedDailyAmount,
              })
          .toList(),
      'dailyIncomeRecords': incomeRecords
          .map((r) => {
                'id': r.id,
                'targetId': r.targetId,
                'incomeAmount': r.incomeAmount,
                'date': r.date.toIso8601String(),
                'notes': r.notes,
              })
          .toList(),
      'reminders': reminders
          .map((r) => {
                'id': r.id,
                'syncId': r.syncId,
                'title': r.title,
                'description': r.description,
                'category': r.category.name,
                'customCategory': r.customCategory,
                'priority': r.priority.name,
                'targetDateTime': r.targetDateTime.toIso8601String(),
                'endTime': r.endTime?.toIso8601String(),
                'status': r.status.name,
                'createdAt': r.createdAt.toIso8601String(),
                'completedAt': r.completedAt?.toIso8601String(),
                'isAllDay': r.isAllDay,
                'customSound': r.customSound,
                'notificationPreferenceMinutes':
                    r.notificationPreferenceMinutes,
                'deleted': r.deleted,
              })
          .toList(),
    };
  }

  /// Mengenkripsi Map menjadi string terenkripsi aman
  static String encryptSnapshot(Map<String, dynamic> data) {
    final rawJson = jsonEncode(data);
    final rawBytes = utf8.encode(rawJson);
    final encryptedBytes = rawBytes.map((b) => b ^ _xorKey).toList();
    final base64Payload = base64.encode(encryptedBytes);
    return '$backupMagicHeader$base64Payload';
  }

  /// Mendekripsi string kembali menjadi Map data
  static Map<String, dynamic>? decryptSnapshot(String payload) {
    try {
      final clean = payload.trim();
      if (!clean.startsWith(backupMagicHeader)) {
        // Coba parsing langsung jika pengguna membuka JSON mentah
        final decoded = jsonDecode(clean);
        if (decoded is Map<String, dynamic> && decoded.containsKey('meta')) {
          return decoded;
        }
        return null;
      }

      final base64Part = clean.substring(backupMagicHeader.length);
      final encryptedBytes = base64.decode(base64Part);
      final decryptedBytes = encryptedBytes.map((b) => b ^ _xorKey).toList();
      final decryptedJson = utf8.decode(decryptedBytes);
      final parsed = jsonDecode(decryptedJson);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan berkas cadangan ke direktori lokal perangkat
  static Future<File> saveBackupToFile(String encryptedPayload) async {
    Directory dir;
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null && extDir.existsSync()) {
        dir = extDir;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'WhatToDo_Backup_$dateStr.wtdbackup';
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(encryptedPayload, encoding: utf8);
    return file;
  }

  /// Memulihkan (Restore) database dari Map snapshot
  static Future<int> restoreFromSnapshotMap({
    required Isar db,
    required Map<String, dynamic> snapshot,
  }) async {
    int restoredCount = 0;

    await db.writeTxn(() async {
      // 1. Financial Notes
      if (snapshot['financialNotes'] is List) {
        for (final raw in snapshot['financialNotes']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final n = FinancialNote()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..title = (m['title'] as String?) ?? ''
            ..date =
                DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now()
            ..notes = m['notes'] as String?
            ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now()
            ..updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
                DateTime.now();
          await db.financialNotes.put(n);
          restoredCount++;
        }
      }

      // 2. Financial Items
      if (snapshot['financialItems'] is List) {
        for (final raw in snapshot['financialItems']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final i = FinancialItem()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..noteId = (m['noteId'] as int?) ?? 0
            ..description = (m['description'] as String?) ?? ''
            ..amount = ((m['amount'] as num?) ?? 0).toDouble()
            ..type = (m['type'] as String?) ?? 'expense'
            ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now()
            ..updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
                DateTime.now()
            ..previousAmount = (m['previousAmount'] as num?)?.toDouble();
          await db.financialItems.put(i);
          restoredCount++;
        }
      }

      // 3. Bills
      if (snapshot['bills'] is List) {
        for (final raw in snapshot['bills']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final b = Bill()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..syncId = (m['syncId'] as String?) ?? ''
            ..name = (m['name'] as String?) ?? ''
            ..amount = ((m['amount'] as num?) ?? 0).toDouble()
            ..realizationAmount = (m['realizationAmount'] as num?)?.toDouble()
            ..prePaymentRealization =
                (m['prePaymentRealization'] as num?)?.toDouble()
            ..month = (m['month'] as String?) ?? ''
            ..dueDate = DateTime.tryParse(m['dueDate'] as String? ?? '') ??
                DateTime.now()
            ..isPaid = (m['isPaid'] as bool?) ?? false
            ..paidAt = DateTime.tryParse(m['paidAt'] as String? ?? '')
            ..reminderDaysBefore = (m['reminderDaysBefore'] as int?) ?? 0
            ..notes = m['notes'] as String?
            ..billType = (m['billType'] as String?) ?? 'monthly'
            ..paidBy = m['paidBy'] as String?
            ..receivedBy = m['receivedBy'] as String?
            ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now()
            ..updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
                DateTime.now()
            ..deleted = (m['deleted'] as bool?) ?? false;
          await db.bills.put(b);
          restoredCount++;
        }
      }

      // 4. Shopping Items
      if (snapshot['shoppingItems'] is List) {
        for (final raw in snapshot['shoppingItems']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final s = ShoppingItem()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..name = (m['name'] as String?) ?? ''
            ..isChecked = (m['isChecked'] as bool?) ?? false
            ..category = m['category'] as String?
            ..price = ((m['price'] as num?) ?? 0).toDouble()
            ..realizationPrice = (m['realizationPrice'] as num?)?.toDouble()
            ..purchaseDate =
                DateTime.tryParse(m['purchaseDate'] as String? ?? '')
            ..notes = m['notes'] as String?
            ..purchasedBy = m['purchasedBy'] as String?
            ..location = m['location'] as String?
            ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now()
            ..updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
                DateTime.now()
            ..deleted = (m['deleted'] as bool?) ?? false;
          await db.shoppingItems.put(s);
          restoredCount++;
        }
      }

      // 5. Income Targets
      if (snapshot['incomeTargets'] is List) {
        for (final raw in snapshot['incomeTargets']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final t = IncomeTarget()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..name = (m['name'] as String?) ?? ''
            ..targetAmount = ((m['targetAmount'] as num?) ?? 0).toDouble()
            ..startDate = DateTime.tryParse(m['startDate'] as String? ?? '') ??
                DateTime.now()
            ..endDate = DateTime.tryParse(m['endDate'] as String? ?? '') ??
                DateTime.now()
            ..category = TargetCategory.values.firstWhere(
              (e) => e.name == m['category'],
              orElse: () => TargetCategory.savings,
            )
            ..customCategory = m['customCategory'] as String?
            ..status = TargetStatus.values.firstWhere(
              (e) => e.name == m['status'],
              orElse: () => TargetStatus.active,
            )
            ..mode = (m['mode'] as String?) ?? 'flexible'
            ..fixedDailyAmount =
                ((m['fixedDailyAmount'] as num?) ?? 0).toDouble();
          await db.incomeTargets.put(t);
          restoredCount++;
        }
      }

      // 6. Daily Income Records
      if (snapshot['dailyIncomeRecords'] is List) {
        for (final raw in snapshot['dailyIncomeRecords']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final r = DailyIncomeRecord()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..targetId = (m['targetId'] as int?) ?? 0
            ..incomeAmount = ((m['incomeAmount'] as num?) ?? 0).toDouble()
            ..date =
                DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now()
            ..notes = (m['notes'] as String?) ?? '';
          await db.dailyIncomeRecords.put(r);
          restoredCount++;
        }
      }

      // 7. Reminders
      if (snapshot['reminders'] is List) {
        for (final raw in snapshot['reminders']) {
          final m = Map<String, dynamic>.from(raw as Map);
          final r = Reminder()
            ..id = (m['id'] as int?) ?? Isar.autoIncrement
            ..syncId = (m['syncId'] as String?) ?? ''
            ..title = (m['title'] as String?) ?? ''
            ..description = m['description'] as String?
            ..category = ReminderCategory.values.firstWhere(
              (e) => e.name == m['category'],
              orElse: () => ReminderCategory.other,
            )
            ..customCategory = m['customCategory'] as String?
            ..priority = PriorityLevel.values.firstWhere(
              (e) => e.name == m['priority'],
              orElse: () => PriorityLevel.medium,
            )
            ..targetDateTime =
                DateTime.tryParse(m['targetDateTime'] as String? ?? '') ??
                    DateTime.now()
            ..endTime = DateTime.tryParse(m['endTime'] as String? ?? '')
            ..status = ReminderStatus.values.firstWhere(
              (e) => e.name == m['status'],
              orElse: () => ReminderStatus.pending,
            )
            ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now()
            ..completedAt = DateTime.tryParse(m['completedAt'] as String? ?? '')
            ..isAllDay = (m['isAllDay'] as bool?) ?? false
            ..customSound = m['customSound'] as String?
            ..notificationPreferenceMinutes =
                (m['notificationPreferenceMinutes'] as int?) ?? 15
            ..deleted = (m['deleted'] as bool?) ?? false;
          await db.reminders.put(r);
          restoredCount++;
        }
      }
    });

    return restoredCount;
  }

  /// Alur UI: Buat Cadangan Database Baru
  static Future<void> performCreateBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final db = ref.read(databaseServiceProvider).db;
      final snapshot = await exportSnapshotMap(db);
      final encrypted = encryptSnapshot(snapshot);
      final file = await saveBackupToFile(encrypted);

      if (context.mounted) {
        final totalRec = snapshot['meta']?['totalRecords'] ?? 0;
        await showLsInfoDialog(
          context: context,
          title: 'Cadangan Berhasil Dibuat',
          message:
              'Total $totalRec data berhasil diamankan dalam berkas terenkripsi:\n\n${file.path}',
          buttonLabel: 'Mengerti',
          icon: Icons.verified_user_rounded,
          color: LsColors.income,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showLsInfoDialog(
          context: context,
          title: 'Gagal Membuat Cadangan',
          message: 'Terjadi kesalahan saat memproses cadangan: $e',
          buttonLabel: 'Tutup',
          icon: Icons.error_outline_rounded,
          color: LsColors.expense,
        );
      }
    }
  }

  /// Alur UI: Pilih File Cadangan & Pulihkan
  static Future<void> performRestoreBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final path = result.files.single.path!;
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Berkas tidak ditemukan.');
      }

      final content = await file.readAsString();
      final snapshot = decryptSnapshot(content);

      if (snapshot == null) {
        if (context.mounted) {
          showLsInfoDialog(
            context: context,
            title: 'Berkas Tidak Valid',
            message:
                'Format berkas cadangan tidak dikenali atau rusak. Pastikan memilih file cadangan resmi (.wtdbackup).',
            buttonLabel: 'Tutup',
            icon: Icons.warning_amber_rounded,
            color: LsColors.expense,
          );
        }
        return;
      }

      final meta = snapshot['meta'] as Map<String, dynamic>?;
      final totalRecords = meta?['totalRecords'] ?? 0;
      final exportDate = meta?['exportedAt'] != null
          ? DateFormat('d MMMM yyyy, HH:mm', 'id_ID')
              .format(DateTime.parse(meta!['exportedAt'] as String))
          : 'Tidak diketahui';

      if (!context.mounted) return;

      final confirm = await showLsConfirmDialog(
        context: context,
        title: 'Pulihkan Data?',
        message:
            'Ditemukan cadangan dibuat pada $exportDate berisi sekitar $totalRecords catatan.\n\nData lokal saat ini akan diselaraskan dengan cadangan tersebut. Lanjutkan?',
        confirmLabel: 'Ya, Pulihkan Sekarang',
        cancelLabel: 'Batal',
        isDanger: false,
      );

      if (confirm != true || !context.mounted) return;

      final db = ref.read(databaseServiceProvider).db;
      final count = await restoreFromSnapshotMap(db: db, snapshot: snapshot);

      // Invalidate providers
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(financialNotesNotifierProvider);
      ref.invalidate(shoppingItemsProvider);
      ref.invalidate(targetsStreamProvider);
      ref.invalidate(remindersStreamProvider);
      ref.invalidate(billsStreamProvider);

      if (context.mounted) {
        showLsInfoDialog(
          context: context,
          title: 'Pemulihan Berhasil',
          message: 'Sebanyak $count data berhasil dipulihkan ke aplikasi.',
          buttonLabel: 'Selesai',
          icon: Icons.check_circle_rounded,
          color: LsColors.income,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showLsInfoDialog(
          context: context,
          title: 'Gagal Memulihkan Data',
          message: 'Terjadi kesalahan saat memulihkan: $e',
          buttonLabel: 'Tutup',
          icon: Icons.error_outline_rounded,
          color: LsColors.expense,
        );
      }
    }
  }
}
