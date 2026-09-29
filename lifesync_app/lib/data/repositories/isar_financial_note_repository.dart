import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/domain/repositories/financial_note_repository.dart';

class IsarFinancialNoteRepository implements FinancialNoteRepository {
  final Isar isar;

  IsarFinancialNoteRepository(this.isar);

  @override
  Future<List<FinancialNote>> getAllNotes() async {
    if (kIsWeb) return [];
    return await isar.financialNotes.where().sortByDateDesc().findAll();
  }

  @override
  Future<FinancialNote?> getNoteById(int id) async {
    if (kIsWeb) return null;
    return await isar.financialNotes.get(id);
  }

  @override
  Future<int> saveNote(FinancialNote note) async {
    if (kIsWeb) return 0;
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.financialNotes.put(note);
    });
  }

  @override
  Future<void> deleteNote(int id) async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.financialItems.filter().noteIdEqualTo(id).deleteAll();
      await isar.financialNotes.delete(id);
    });
  }

  @override
  Future<List<FinancialItem>> getItemsByNoteId(int noteId) async {
    if (kIsWeb) return [];
    return await isar.financialItems.filter().noteIdEqualTo(noteId).findAll();
  }

  @override
  Future<int> saveItem(FinancialItem item) async {
    if (kIsWeb) return 0;
    item.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.financialItems.put(item);
    });
  }

  @override
  Future<void> deleteItem(int itemId) async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.financialItems.delete(itemId);
    });
  }

  @override
  Future<void> deleteItemsByNoteId(int noteId) async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.financialItems.filter().noteIdEqualTo(noteId).deleteAll();
    });
  }

  @override
  Future<List<FinancialItem>> getAllItems() async {
    if (kIsWeb) return [];
    return await isar.financialItems.where().findAll();
  }
}
