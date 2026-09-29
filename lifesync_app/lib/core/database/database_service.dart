import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/data/migrations/isar_migration_service.dart';

class DatabaseService {
  late Isar _isar;
  bool _isInitialized = false;

  Isar get db {
    if (!_isInitialized) {
      throw Exception('Database not initialized');
    }
    return _isar;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    
    if (kIsWeb) {
      _isInitialized = true;
      return; // Skip Isar initialization on web, as Isar v3 does not support Web. We will use in-memory repositories.
    }

    String dirPath = '';
    final dir = await getApplicationDocumentsDirectory();
    dirPath = dir.path;
    
    _isar = await Isar.open(
      [
        ReminderSchema,
        IncomeTargetSchema,
        DailyIncomeRecordSchema,
        AppSettingsSchema,
        FastingDebtSchema,
        QadhaRecordSchema,
        MenstruationRecordSchema,
        FinancialRecordSchema,
        FinancialNoteSchema,
        FinancialItemSchema,
        BillSchema,
      ],
      directory: dirPath,
    );
    
    // Run migration for cloud sync metadata
    final migrationService = IsarMigrationService(_isar);
    await migrationService.runMigration();
    
    _isInitialized = true;
  }
}
