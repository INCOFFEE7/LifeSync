import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';

abstract class FinancialNoteRepository {
  Future<List<FinancialNote>> getAllNotes();
  Future<FinancialNote?> getNoteById(int id);
  Future<int> saveNote(FinancialNote note);
  Future<void> deleteNote(int id);

  Future<List<FinancialItem>> getItemsByNoteId(int noteId);
  Future<int> saveItem(FinancialItem item);
  Future<void> deleteItem(int itemId);
  Future<void> deleteItemsByNoteId(int noteId);

  Future<List<FinancialItem>> getAllItems();
}
