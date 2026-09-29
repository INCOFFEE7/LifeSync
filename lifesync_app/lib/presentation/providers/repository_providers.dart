import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/data/repositories/isar_reminder_repository.dart';
import 'package:lifesync_app/data/repositories/isar_target_repository.dart';
import 'package:lifesync_app/data/repositories/in_memory_reminder_repository.dart';
import 'package:lifesync_app/data/repositories/in_memory_target_repository.dart';
import 'package:lifesync_app/domain/repositories/reminder_repository.dart';
import 'package:lifesync_app/domain/repositories/target_repository.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/core/services/google_sheets_service.dart';
import 'package:lifesync_app/domain/usecases/sync_usecase.dart';

import 'package:lifesync_app/data/repositories/isar_financial_record_repository.dart';
import 'package:lifesync_app/data/repositories/in_memory_financial_record_repository.dart';
import 'package:lifesync_app/domain/repositories/financial_record_repository.dart';
import 'package:lifesync_app/domain/repositories/financial_note_repository.dart';
import 'package:lifesync_app/data/repositories/isar_financial_note_repository.dart';
import 'package:lifesync_app/data/repositories/isar_bill_repository.dart';
import 'package:lifesync_app/domain/entities/bill.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  if (kIsWeb) return InMemoryReminderRepository();
  final dbService = ref.watch(databaseServiceProvider);
  return IsarReminderRepository(dbService);
});

final targetRepositoryProvider = Provider<TargetRepository>((ref) {
  if (kIsWeb) return InMemoryTargetRepository();
  final dbService = ref.watch(databaseServiceProvider);
  return IsarTargetRepository(dbService);
});

final financialRecordRepositoryProvider = Provider<FinancialRecordRepository>((ref) {
  if (kIsWeb) return InMemoryFinancialRecordRepository();
  final dbService = ref.watch(databaseServiceProvider);
  return IsarFinancialRecordRepository(dbService);
});

final financialNoteRepositoryProvider = Provider<FinancialNoteRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return IsarFinancialNoteRepository(dbService.db);
});

final billRepositoryProvider = Provider<IsarBillRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final notifService = ref.watch(notificationServiceProvider);
  return IsarBillRepository(dbService, notifService);
});

final billsStreamProvider = StreamProvider.family<List<Bill>, String>((ref, month) {
  final repo = ref.watch(billRepositoryProvider);
  return repo.watchBillsByMonth(month);
});

final targetRecordsStreamProvider = StreamProvider.family<List<DailyIncomeRecord>, int>((ref, targetId) {
  final repository = ref.watch(targetRepositoryProvider);
  return repository.watchRecordsForTarget(targetId);
});

final googleSheetsServiceProvider = Provider<GoogleSheetsService>((ref) {
  return GoogleSheetsService();
});

final syncUseCaseProvider = Provider<SyncUseCase>((ref) {
  final sheetsService = ref.watch(googleSheetsServiceProvider);
  final targetRepo = ref.watch(targetRepositoryProvider);
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final financialRecordRepo = ref.watch(financialRecordRepositoryProvider);
  final dbService = ref.watch(databaseServiceProvider);
  return SyncUseCase(
    sheetsService: sheetsService, 
    targetRepository: targetRepo,
    reminderRepository: reminderRepo,
    financialRecordRepository: financialRecordRepo,
    databaseService: dbService,
  );
});

// Streams for UI
final remindersStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.watchReminders();
});

final targetsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(targetRepositoryProvider);
  return repo.watchTargets();
});
