import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/services/financial_migration_service.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';

enum NoteFilterMode { all, specificDate, weekly, monthly }

class FilterState {
  final NoteFilterMode mode;
  final DateTime selectedDate;

  FilterState({
    this.mode = NoteFilterMode.all,
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? DateTime.now();

  FilterState copyWith({NoteFilterMode? mode, DateTime? selectedDate}) {
    return FilterState(
      mode: mode ?? this.mode,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

final noteFilterProvider = StateProvider<FilterState>((ref) => FilterState());

class NoteWithItems {
  final FinancialNote note;
  final List<FinancialItem> items;

  NoteWithItems({required this.note, required this.items});

  double get totalIncome => items
      .where((i) => i.type == 'income')
      .fold(0.0, (sum, i) => sum + i.amount);

  double get totalExpense => items
      .where((i) => i.type == 'expense')
      .fold(0.0, (sum, i) => sum + i.amount);

  double get netTotal => totalIncome - totalExpense;

  int get itemCount => items.length;
}

final financialNotesNotifierProvider = StateNotifierProvider<FinancialNotesNotifier, AsyncValue<List<NoteWithItems>>>((ref) {
  return FinancialNotesNotifier(ref);
});

class FinancialNotesNotifier extends StateNotifier<AsyncValue<List<NoteWithItems>>> {
  final Ref _ref;

  FinancialNotesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      state = const AsyncValue.loading();
      final dbService = _ref.read(databaseServiceProvider);
      try {
        final migration = FinancialMigrationService(dbService.db);
        await migration.migrateLegacyRecordsIfNeeded();
      } catch (_) {}

      final repo = _ref.read(financialNoteRepositoryProvider);
      final notes = await repo.getAllNotes();
      final allItems = await repo.getAllItems();

      final List<NoteWithItems> result = [];
      for (final note in notes) {
        final noteItems = allItems.where((i) => i.noteId == note.id).toList();
        result.add(NoteWithItems(note: note, items: noteItems));
      }

      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNoteWithItems(FinancialNote note, List<FinancialItem> items) async {
    final repo = _ref.read(financialNoteRepositoryProvider);
    final noteId = await repo.saveNote(note);
    for (final item in items) {
      item.noteId = noteId;
      await repo.saveItem(item);
    }
    await loadNotes();
  }

  Future<void> updateNote(FinancialNote note) async {
    final repo = _ref.read(financialNoteRepositoryProvider);
    await repo.saveNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(int noteId) async {
    final repo = _ref.read(financialNoteRepositoryProvider);
    await repo.deleteNote(noteId);
    await loadNotes();
  }

  Future<void> addItemToNote(FinancialItem item) async {
    final repo = _ref.read(financialNoteRepositoryProvider);
    await repo.saveItem(item);
    await loadNotes();
  }

  Future<void> updateItem(FinancialItem item) async {
    final repo = _ref.read(financialNoteRepositoryProvider);
    await repo.saveItem(item);
    await loadNotes();
  }

  Future<void> deleteItem(int itemId) async {
    final repo = _ref.read(financialNoteRepositoryProvider);
    await repo.deleteItem(itemId);
    await loadNotes();
  }
}

final filteredNotesProvider = Provider<List<NoteWithItems>>((ref) {
  final notesAsync = ref.watch(financialNotesNotifierProvider);
  final filter = ref.watch(noteFilterProvider);

  return notesAsync.maybeWhen(
    data: (notes) {
      return notes.where((item) {
        final d = item.note.date;
        final target = filter.selectedDate;

        switch (filter.mode) {
          case NoteFilterMode.all:
            return true;
          case NoteFilterMode.specificDate:
            return d.year == target.year && d.month == target.month && d.day == target.day;
          case NoteFilterMode.weekly:
            final startOfWeek = target.subtract(Duration(days: target.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
            return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(endOfWeek);
          case NoteFilterMode.monthly:
            return d.year == target.year && d.month == target.month;
        }
      }).toList();
    },
    orElse: () => [],
  );
});

final filteredSummaryProvider = Provider<FinancialSummary>((ref) {
  final filteredNotes = ref.watch(filteredNotesProvider);

  double income = 0;
  double expense = 0;

  for (final noteItem in filteredNotes) {
    income += noteItem.totalIncome;
    expense += noteItem.totalExpense;
  }

  return FinancialSummary(
    totalIncome: income,
    totalExpense: expense,
    netBalance: income - expense,
  );
});

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
  });
}
