import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:isar/isar.dart';
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
      debugPrint(
          '[SyncEngine] Skipped sync because user performed delete-all.');
      return;
    }

    final client = await authService.getAuthenticatedClient();
    if (client == null) throw Exception('User not authenticated');

    final spreadsheetId = await authService.getSpreadsheetId();
    if (spreadsheetId == null) throw Exception('Spreadsheet not configured');

    final sheetsApi = sheets.SheetsApi(client);

    // Auto-provision any missing sheets/tabs in older spreadsheets
    await _ensureRequiredSheetsExist(sheetsApi, spreadsheetId);

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

  Future<void> _ensureRequiredSheetsExist(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    try {
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final existingTitles = spreadsheet.sheets
              ?.map((s) => s.properties?.title)
              .whereType<String>()
              .toSet() ??
          <String>{};

      final Map<String, List<Object?>> requiredHeaders = {
        'Reminders': [
          'SyncID',
          'UpdatedAt',
          'Deleted',
          'Title',
          'Description',
          'Category',
          'Priority',
          'TargetDateTime',
          'Status',
          'CreatedAt',
          'CompletedAt'
        ],
        'FinancialNotes': ['ID', 'Title', 'Date', 'Notes', 'UpdatedAt'],
        'FinancialItems': [
          'ID',
          'NoteID',
          'Description',
          'Amount',
          'Type',
          'CreatedAt',
          'UpdatedAt'
        ],
        'Bills': [
          'ID',
          'Title',
          'Amount',
          'DueDate',
          'IsPaid',
          'Category',
          'Notes',
          'UpdatedAt'
        ],
        'Targets': [
          'ID',
          'Name',
          'TargetAmount',
          'CurrentAmount',
          'Deadline',
          'Category',
          'IsCompleted',
          'Notes',
          'UpdatedAt'
        ],
        'ShoppingItems': [
          'ID',
          'Name',
          'EstimatedPrice',
          'IsChecked',
          'Category',
          'Notes',
          'UpdatedAt'
        ],
        'DailyIncomeRecords': ['ID', 'Date', 'Amount', 'Notes', 'UpdatedAt'],
        'AppSettings': ['Key', 'Value', 'UpdatedAt'],
        'SyncLogs': ['Timestamp', 'Status', 'Message'],
      };

      if (AppEnvironment.config.variant == AppVariant.beebee) {
        requiredHeaders.addAll({
          'FastingDebts': [
            'ID',
            'Year',
            'TotalDays',
            'DaysPaid',
            'Notes',
            'UpdatedAt'
          ],
          'QadhaRecords': ['ID', 'Date', 'Days', 'Notes', 'UpdatedAt'],
          'MenstruationRecords': [
            'ID',
            'StartDate',
            'EndDate',
            'PeriodType',
            'Notes',
            'UpdatedAt'
          ],
        });
      }

      final List<sheets.Request> requests = [];
      for (final title in requiredHeaders.keys) {
        if (!existingTitles.contains(title)) {
          requests.add(sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(title: title),
            ),
          ));
        }
      }

      if (requests.isNotEmpty) {
        final batchUpdateReq =
            sheets.BatchUpdateSpreadsheetRequest(requests: requests);
        await sheetsApi.spreadsheets.batchUpdate(batchUpdateReq, spreadsheetId);

        // Add header rows to the newly created sheets
        final List<sheets.ValueRange> headerRanges = [];
        for (final title in requiredHeaders.keys) {
          if (!existingTitles.contains(title)) {
            headerRanges.add(sheets.ValueRange(
              range: '$title!A1',
              values: [requiredHeaders[title]!],
            ));
          }
        }
        if (headerRanges.isNotEmpty) {
          await sheetsApi.spreadsheets.values.batchUpdate(
            sheets.BatchUpdateValuesRequest(
              data: headerRanges,
              valueInputOption: 'USER_ENTERED',
            ),
            spreadsheetId,
          );
        }
      }
    } catch (e) {
      debugPrint('[SyncEngine] Error auto-provisioning missing sheets: $e');
    }
  }

  bool _isRowModified(List<Object?> localRow, List<Object?> cloudRow) {
    for (int i = 0; i < localRow.length; i++) {
      final localVal = localRow[i]?.toString() ?? '';
      final cloudVal =
          i < cloudRow.length ? (cloudRow[i]?.toString() ?? '') : '';
      if (localVal != cloudVal) return true;
    }
    return false;
  }

  // ── 1. Reminders Sync ──────────────────────────────────────────────────────
  Future<void> _syncReminders(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'Reminders!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localReminders = await db.reminders.where().findAll();
    final Map<String, Reminder> localMap = {
      for (var r in localReminders) r.syncId: r
    };

    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final List<Reminder> localToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localMap.values) {
      final localRow = _reminderToRow(local);
      if (cloudMap.containsKey(local.syncId)) {
        final cloudEntry = cloudMap[local.syncId]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'Reminders!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
        local.syncStatus = 'synced';
        localToUpdate.add(local);
        cloudMap.remove(local.syncId);
      } else {
        rowsToAppend.add(localRow);
        local.syncStatus = 'synced';
        localToUpdate.add(local);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
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
      r.completedAt?.toIso8601String() ?? '',
    ];
  }

  // ── 2. Financial Notes Sync ───────────────────────────────────────────────
  Future<void> _syncFinancialNotes(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'FinancialNotes!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localNotes = await db.financialNotes.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localNotes) {
      final localRow = [
        local.id.toString(),
        local.title,
        local.date.toIso8601String(),
        local.notes ?? '',
        local.updatedAt.toIso8601String()
      ];
      if (cloudMap.containsKey(local.id.toString())) {
        final cloudEntry = cloudMap[local.id.toString()]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'FinancialNotes!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  // ── 3. Financial Items Sync ───────────────────────────────────────────────
  Future<void> _syncFinancialItems(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'FinancialItems!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localItems = await db.financialItems.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localItems) {
      final localRow = [
        local.id.toString(),
        local.noteId.toString(),
        local.description,
        local.amount.toString(),
        local.type,
        local.updatedAt.toIso8601String()
      ];
      if (cloudMap.containsKey(local.id.toString())) {
        final cloudEntry = cloudMap[local.id.toString()]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'FinancialItems!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  // ── 4. Bills Sync ─────────────────────────────────────────────────────────
  Future<void> _syncBills(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'Bills!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localBills = await db.bills.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localBills) {
      final localRow = _billToRow(local);
      if (cloudMap.containsKey(local.id.toString())) {
        final cloudEntry = cloudMap[local.id.toString()]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range = 'Bills!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  List<Object?> _billToRow(Bill local) {
    return [
      local.id.toString(),
      local.name,
      local.amount.toString(),
      local.isPaid.toString(),
      local.dueDate.toIso8601String(),
      local.realizationAmount?.toString() ?? '0',
      local.billType,
      local.paidBy ?? '',
      local.receivedBy ?? '',
      local.month,
      local.updatedAt.toIso8601String(),
      local.deleted.toString(),
    ];
  }

  // ── 5. Savings Targets Sync ───────────────────────────────────────────────
  Future<void> _syncTargets(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'IncomeTargets!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localTargets = await db.incomeTargets.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localTargets) {
      final localRow = [
        local.syncId,
        local.name,
        local.targetAmount.toString(),
        local.mode,
        local.fixedDailyAmount.toString(),
        local.updatedAt.toIso8601String()
      ];
      if (cloudMap.containsKey(local.syncId)) {
        final cloudEntry = cloudMap[local.syncId]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'IncomeTargets!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  // ── 6. Shopping Items Sync ────────────────────────────────────────────────
  Future<void> _syncShoppingItems(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'ShoppingItems!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localShopping = await db.shoppingItems.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localShopping) {
      final localRow = _shoppingItemToRow(local);
      if (cloudMap.containsKey(local.syncId)) {
        final cloudEntry = cloudMap[local.syncId]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'ShoppingItems!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  List<Object?> _shoppingItemToRow(ShoppingItem local) {
    return [
      local.syncId,
      local.name,
      local.isChecked.toString(),
      local.purchaseDate?.toIso8601String() ?? '',
      local.price.toString(),
      local.realizationPrice?.toString() ?? '0',
      local.category ?? '',
      local.location ?? '',
      local.purchasedBy ?? '',
      local.notes ?? '',
      local.updatedAt.toIso8601String(),
      local.deleted.toString(),
    ];
  }

  // ── 7. BeeNest Fasting Debts Sync ─────────────────────────────────────────
  Future<void> _syncFastingDebts(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'FastingDebts!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localData = await db.fastingDebts.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localData) {
      final localRow = [
        local.syncId,
        local.ramadanYear.toString(),
        local.initialDebt.toString(),
        local.currentDebt.toString(),
        local.updatedAt.toIso8601String()
      ];
      if (cloudMap.containsKey(local.syncId)) {
        final cloudEntry = cloudMap[local.syncId]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'FastingDebts!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  // ── 8. BeeNest Qadha Records Sync ──────────────────────────────────────────
  Future<void> _syncQadhaRecords(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'QadhaRecords!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localData = await db.qadhaRecords.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localData) {
      final localRow = [
        local.syncId,
        local.fastingDebtId.toString(),
        local.date.toIso8601String(),
        local.amount.toString()
      ];
      if (cloudMap.containsKey(local.syncId)) {
        final cloudEntry = cloudMap[local.syncId]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'QadhaRecords!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }

  // ── 9. BeeNest Menstruation Records Sync ──────────────────────────────────
  Future<void> _syncMenstruationRecords(
      sheets.SheetsApi sheetsApi, String spreadsheetId) async {
    final range = 'MenstruationRecords!A2:Z';
    sheets.ValueRange? cloudData;
    try {
      cloudData = await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    } catch (_) {}

    final localData = await db.menstruationRecords.where().findAll();
    final List<List<Object?>> rowsToAppend = [];
    final List<sheets.ValueRange> rowsToUpdate = [];
    final Map<String, ({int sheetRow, List<Object?> row})> cloudMap = {};

    if (cloudData != null && cloudData.values != null) {
      for (int i = 0; i < cloudData.values!.length; i++) {
        final row = cloudData.values![i];
        if (row.isNotEmpty) {
          cloudMap[row[0].toString()] = (sheetRow: i + 2, row: row);
        }
      }
    }

    for (final local in localData) {
      final localRow = [
        local.syncId,
        local.startDate.toIso8601String(),
        local.endDate.toIso8601String(),
        local.duration.toString(),
        local.isRamadan.toString()
      ];
      if (cloudMap.containsKey(local.syncId)) {
        final cloudEntry = cloudMap[local.syncId]!;
        if (_isRowModified(localRow, cloudEntry.row)) {
          rowsToUpdate.add(sheets.ValueRange()
            ..range =
                'MenstruationRecords!A${cloudEntry.sheetRow}:Z${cloudEntry.sheetRow}'
            ..values = [localRow]);
        }
      } else {
        rowsToAppend.add(localRow);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final appendRequest = sheets.ValueRange()..values = rowsToAppend;
      await sheetsApi.spreadsheets.values.append(
          appendRequest, spreadsheetId, range,
          valueInputOption: 'USER_ENTERED');
    }
    if (rowsToUpdate.isNotEmpty) {
      final batchRequest = sheets.BatchUpdateValuesRequest()
        ..data = rowsToUpdate
        ..valueInputOption = 'USER_ENTERED';
      await sheetsApi.spreadsheets.values
          .batchUpdate(batchRequest, spreadsheetId);
    }
  }
}
