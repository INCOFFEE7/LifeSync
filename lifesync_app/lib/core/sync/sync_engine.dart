import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:isar/isar.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/data/providers/google_auth_provider.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:shared_preferences/shared_preferences.dart';

final syncEngineProvider = Provider((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final authService = ref.watch(googleAuthServiceProvider);
  return SyncEngine(dbService.db, authService);
});

class SyncEngine {
  final Isar db;
  final GoogleAuthService authService;
  
  SyncEngine(this.db, this.authService);

  Future<void> performSync() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_deleted_all') == true) {
      debugPrint('[SyncEngine] Skipped sync because user performed delete-all.');
      return;
    }

    final client = await authService.getAuthenticatedClient();
    if (client == null) throw Exception('User not authenticated');
    
    final spreadsheetId = await authService.getSpreadsheetId();
    if (spreadsheetId == null) throw Exception('Spreadsheet not configured');
    
    final sheetsApi = sheets.SheetsApi(client);
    
    // Sync ALL LifeHaven modules
    await _syncReminders(sheetsApi, spreadsheetId);
    await _syncFinancialNotes(sheetsApi, spreadsheetId);
    await _syncFinancialItems(sheetsApi, spreadsheetId);
    await _syncBills(sheetsApi, spreadsheetId);
    await _syncTargets(sheetsApi, spreadsheetId);
    await _syncShoppingItems(sheetsApi, spreadsheetId);
    
    // Sync BeeNest modules if in beebee flavor
    if (AppEnvironment.config.variant == AppVariant.beebee) {
      await _syncFastingDebts(sheetsApi, spreadsheetId);
      await _syncQadhaRecords(sheetsApi, spreadsheetId);
      await _syncMenstruationRecords(sheetsApi, spreadsheetId);
    }
  }

  // ── 1. Reminders Sync ──────────────────────────────────────────────────────
  Future<void> _syncReminders(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'Reminders!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localReminders = await db.reminders.where().findAll();
    final Map<String, Reminder> localMap = {for (var r in localReminders) r.syncId: r};

    final List<List<Object?>> rowsToAppend = [];
    final List<Reminder> localToUpdate = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = row;
        }
      }
    }

    for (final local in localMap.values) {
      if (cloudMap.containsKey(local.syncId)) {
        local.syncStatus = 'synced';
        localToUpdate.add(local);
        cloudMap.remove(local.syncId);
      } else {
        rowsToAppend.add(_reminderToRow(local));
        local.syncStatus = 'synced';
        localToUpdate.add(local);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }

    await db.writeTxn(() async {
      await db.reminders.putAll(localToUpdate);
    });
  }

  List<Object?> _reminderToRow(Reminder r) {
    return [
      r.syncId,
      r.updatedAt.toIso8601String(),
      r.deleted.toString(),
      r.title,
      r.description ?? '',
      r.category.name,
      r.priority.name,
      r.targetDateTime.toIso8601String(),
      r.status.name,
      r.createdAt.toIso8601String(),
    ];
  }

  // ── 2. Financial Notes Sync ───────────────────────────────────────────────
  Future<void> _syncFinancialNotes(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'FinancialNotes!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localNotes = await db.financialNotes.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localNotes) {
      if (!cloudMap.containsKey(local.id.toString())) {
        rowsToAppend.add([local.id.toString(), local.title, local.date.toIso8601String(), local.notes ?? '', local.updatedAt.toIso8601String()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 3. Financial Items Sync ───────────────────────────────────────────────
  Future<void> _syncFinancialItems(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'FinancialItems!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localItems = await db.financialItems.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localItems) {
      if (!cloudMap.containsKey(local.id.toString())) {
        rowsToAppend.add([local.id.toString(), local.noteId.toString(), local.description, local.amount.toString(), local.type, local.updatedAt.toIso8601String()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 4. Bills Sync ─────────────────────────────────────────────────────────
  Future<void> _syncBills(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'Bills!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localBills = await db.bills.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localBills) {
      if (!cloudMap.containsKey(local.id.toString())) {
        rowsToAppend.add([local.id.toString(), local.name, local.amount.toString(), local.isPaid.toString(), local.dueDate.toIso8601String(), local.realizationAmount?.toString() ?? '0', local.updatedAt.toIso8601String()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 5. Savings Targets Sync ───────────────────────────────────────────────
  Future<void> _syncTargets(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'IncomeTargets!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localTargets = await db.incomeTargets.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localTargets) {
      if (!cloudMap.containsKey(local.syncId)) {
        rowsToAppend.add([local.syncId, local.name, local.targetAmount.toString(), local.mode, local.fixedDailyAmount.toString(), local.updatedAt.toIso8601String()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 6. Shopping Items Sync ────────────────────────────────────────────────
  Future<void> _syncShoppingItems(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'ShoppingItems!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localShopping = await db.shoppingItems.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localShopping) {
      if (!cloudMap.containsKey(local.syncId)) {
        rowsToAppend.add([local.syncId, local.name, local.isChecked.toString(), local.purchaseDate?.toIso8601String() ?? '', local.updatedAt.toIso8601String()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 7. BeeNest Fasting Debts Sync ─────────────────────────────────────────
  Future<void> _syncFastingDebts(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'FastingDebts!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localData = await db.fastingDebts.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localData) {
      if (!cloudMap.containsKey(local.syncId)) {
        rowsToAppend.add([local.syncId, local.ramadanYear.toString(), local.initialDebt.toString(), local.currentDebt.toString(), local.updatedAt.toIso8601String()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 8. BeeNest Qadha Records Sync ──────────────────────────────────────────
  Future<void> _syncQadhaRecords(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'QadhaRecords!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localData = await db.qadhaRecords.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localData) {
      if (!cloudMap.containsKey(local.syncId)) {
        rowsToAppend.add([local.syncId, local.fastingDebtId.toString(), local.date.toIso8601String(), local.amount.toString()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }

  // ── 9. BeeNest Menstruation Records Sync ──────────────────────────────────
  Future<void> _syncMenstruationRecords(sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'MenstruationRecords!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localData = await db.menstruationRecords.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final Map<String, List<Object?>> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (var row in cloudData.values!) {
        if (row.isNotEmpty) cloudMap[row[0].toString()] = row;
      }
    }

    for (final local in localData) {
      if (!cloudMap.containsKey(local.syncId)) {
        rowsToAppend.add([local.syncId, local.startDate.toIso8601String(), local.endDate.toIso8601String(), local.duration.toString(), local.isRamadan.toString()]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(appendRequest, spreadsheetId, range, valueInputOption: 'USER_ENTERED');
    }
  }
}
