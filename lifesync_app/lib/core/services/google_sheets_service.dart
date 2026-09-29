import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:lifesync_app/core/config/google_sheets_config.dart';

class GoogleSheetsService {
  sheets.SheetsApi? _api;

  Future<bool> init() async {
    if (GoogleSheetsConfig.serviceAccountCredentials.isEmpty ||
        GoogleSheetsConfig.spreadsheetId == 'YOUR_SPREADSHEET_ID_HERE') {
      return false; // Credentials not configured
    }

    try {
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(GoogleSheetsConfig.serviceAccountCredentials),
      );

      final scopes = [sheets.SheetsApi.spreadsheetsScope];
      final client = await clientViaServiceAccount(credentials, scopes);
      
      _api = sheets.SheetsApi(client);
      return true;
    } catch (e) {
      print('Error initializing Google Sheets API: $e');
      return false;
    }
  }

  /// Appends a single row to the specified sheet
  Future<void> appendRow(String range, List<String> row) async {
    if (_api == null) return;
    try {
      final valueRange = sheets.ValueRange(values: [row]);
      await _api!.spreadsheets.values.append(
        valueRange,
        GoogleSheetsConfig.spreadsheetId,
        range,
        valueInputOption: 'RAW',
      );
    } catch (e) {
      print('Failed to append row: $e');
      rethrow;
    }
  }

  /// Reads all values from a specified range (e.g. "Records!A:D")
  Future<List<List<dynamic>>> getValues(String range) async {
    if (_api == null) return [];
    try {
      final response = await _api!.spreadsheets.values.get(
        GoogleSheetsConfig.spreadsheetId,
        range,
      );
      return response.values ?? [];
    } catch (e) {
      print('Failed to read sheet: $e');
      return [];
    }
  }

  /// Synchronize default and custom categories to the 'Categories' sheet
  Future<void> syncCategories(List<String> localCustomCategories) async {
    if (_api == null) return;
    try {
      final spreadsheet = await _api!.spreadsheets.get(GoogleSheetsConfig.spreadsheetId);
      final sheetsList = spreadsheet.sheets ?? [];
      bool hasCategoriesSheet = sheetsList.any((s) => s.properties?.title == 'Categories');
      
      if (!hasCategoriesSheet) {
        final request = sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: 'Categories'),
          ),
        );
        final batchRequest = sheets.BatchUpdateSpreadsheetRequest(requests: [request]);
        await _api!.spreadsheets.batchUpdate(batchRequest, GoogleSheetsConfig.spreadsheetId);
        await appendRow('Categories!A:C', ['Category_ID', 'Category_Name', 'Type']);
      }
      
      final existingData = await getValues('Categories!A:A');
      final existingIds = existingData.map((row) => row.isNotEmpty ? row[0].toString() : '').toSet();
      
      // Default categories
      final defaultList = [
        ['salary', 'Gaji', 'income'],
        ['bonus', 'Bonus', 'income'],
        ['freelance', 'Freelance', 'income'],
        ['investment', 'Investasi', 'income'],
        ['gift', 'Hadiah', 'income'],
        ['refund', 'Refund', 'income'],
        ['income_other', 'Lainnya', 'income'],
        ['food', 'Makanan & Minuman', 'expense'],
        ['transportation', 'Transportasi', 'expense'],
        ['shopping', 'Belanja', 'expense'],
        ['bills', 'Tagihan & Utilitas', 'expense'],
        ['entertainment', 'Hiburan', 'expense'],
        ['health', 'Kesehatan', 'expense'],
        ['education', 'Pendidikan', 'expense'],
        ['savings', 'Tabungan', 'expense'],
        ['expense_other', 'Lainnya', 'expense'],
      ];

      for (var item in defaultList) {
        if (!existingIds.contains(item[0])) {
          await appendRow('Categories!A:C', item);
        }
      }

      // Custom categories
      for (var catStr in localCustomCategories) {
        String type = 'expense';
        String name = catStr;
        if (catStr.startsWith('income:')) {
          type = 'income';
          name = catStr.substring(7);
        } else if (catStr.startsWith('expense:')) {
          type = 'expense';
          name = catStr.substring(8);
        }
        final id = 'custom_${type}_$name';
        if (!existingIds.contains(id)) {
          await appendRow('Categories!A:C', [id, name, type]);
        }
      }
    } catch (e) {
      print('Failed to sync categories: $e');
    }
  }
}
