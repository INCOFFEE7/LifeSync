import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync_app/domain/entities/financial_category.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';

void main() {
  group('Financial Record & Category Tests', () {
    test('Categories are correctly categorized by Income and Expense', () {
      final incomeCategories = FinancialCategory.getCategoriesByType(TransactionType.income);
      final expenseCategories = FinancialCategory.getCategoriesByType(TransactionType.expense);

      expect(incomeCategories.every((c) => c.type == TransactionType.income), isTrue);
      expect(expenseCategories.every((c) => c.type == TransactionType.expense), isTrue);

      expect(incomeCategories.any((c) => c.id == 'salary'), isTrue);
      expect(expenseCategories.any((c) => c.id == 'food'), isTrue);
    });

    test('FinancialCategory.findById returns correct category or fallback', () {
      final category = FinancialCategory.findById('food');
      expect(category.name, 'Makanan & Minuman');
      expect(category.type, TransactionType.expense);

      final unknown = FinancialCategory.findById('invalid_id');
      expect(unknown.id, 'unknown');
    });

    test('FinancialRecord entity initialization', () {
      final record = FinancialRecord()
        ..type = 'income'
        ..categoryId = 'salary'
        ..amount = 5000000.0
        ..description = 'Monthly Salary'
        ..transactionDate = DateTime(2026, 7, 22);

      expect(record.type, 'income');
      expect(record.categoryId, 'salary');
      expect(record.amount, 5000000.0);
      expect(record.description, 'Monthly Salary');
    });
  });
}
