import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifesync_app/main.dart';
import 'package:lifesync_app/config/app_variant.dart';

final googleDriveServiceProvider = Provider((ref) => GoogleDriveService());

class GoogleDriveService {
  
  String get _backupFolderName => '${AppEnvironment.config.appName} Backup';
  String get _spreadsheetName => '${AppEnvironment.config.appName} Data';
  
  Future<String?> getOrCreateBackupFolder(http.Client client) async {
    final driveApi = drive.DriveApi(client);
    
    final q = "mimeType='application/vnd.google-apps.folder' and name='$_backupFolderName' and trashed=false";
    final folderList = await driveApi.files.list(q: q, spaces: 'drive');
    
    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id;
    }
    
    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
      
    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id;
  }
  
  Future<String?> getOrCreateSpreadsheet(http.Client client, String folderId) async {
    final driveApi = drive.DriveApi(client);
    
    final q = "mimeType='application/vnd.google-apps.spreadsheet' and name='$_spreadsheetName' and '$folderId' in parents and trashed=false";
    final fileList = await driveApi.files.list(q: q, spaces: 'drive');
    
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }
    
    final sheetsApi = sheets.SheetsApi(client);
    
    List<sheets.Sheet> initialSheets = [];
    if (AppEnvironment.config.variant == AppVariant.beebee) {
      initialSheets = [
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'FastingDebts'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'QadhaRecords'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'MenstruationRecords'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'SyncLogs'),
      ];
    } else {
      initialSheets = [
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'Targets'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'DailyIncomeRecords'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'Reminders'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'AppSettings'),
        sheets.Sheet()..properties = (sheets.SheetProperties()..title = 'SyncLogs'),
      ];
    }
    
    final spreadsheet = sheets.Spreadsheet()
      ..properties = (sheets.SpreadsheetProperties()..title = _spreadsheetName)
      ..sheets = initialSheets;
      
    final createdSpreadsheet = await sheetsApi.spreadsheets.create(spreadsheet);
    final spreadsheetId = createdSpreadsheet.spreadsheetId;
    
    if (spreadsheetId != null) {
      final file = await driveApi.files.get(spreadsheetId, $fields: 'parents') as drive.File;
      final previousParents = file.parents?.join(',') ?? '';
      
      await driveApi.files.update(
        drive.File(),
        spreadsheetId,
        addParents: folderId,
        removeParents: previousParents,
      );
      
      return spreadsheetId;
    }
    
    return null;
  }
}
