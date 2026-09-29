import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class FinancialCategory {
  final String id;
  final String name;
  final TransactionType type;
  final IconData icon;
  final Color color;

  const FinancialCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  static const List<FinancialCategory> defaultCategories = [
    // Income Categories
    FinancialCategory(
      id: 'salary',
      name: 'Gaji',
      type: TransactionType.income,
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF10B981),
    ),
    FinancialCategory(
      id: 'bonus',
      name: 'Bonus',
      type: TransactionType.income,
      icon: Icons.card_giftcard_outlined,
      color: Color(0xFF059669),
    ),
    FinancialCategory(
      id: 'freelance',
      name: 'Freelance',
      type: TransactionType.income,
      icon: Icons.laptop_mac_outlined,
      color: Color(0xFF3B82F6),
    ),
    FinancialCategory(
      id: 'investment',
      name: 'Investasi',
      type: TransactionType.income,
      icon: Icons.show_chart_outlined,
      color: Color(0xFF8B5CF6),
    ),
    FinancialCategory(
      id: 'gift',
      name: 'Hadiah',
      type: TransactionType.income,
      icon: Icons.redeem_outlined,
      color: Color(0xFFEC4899),
    ),
    FinancialCategory(
      id: 'refund',
      name: 'Refund',
      type: TransactionType.income,
      icon: Icons.replay_outlined,
      color: Color(0xFF14B8A6),
    ),
    FinancialCategory(
      id: 'income_other',
      name: 'Lainnya',
      type: TransactionType.income,
      icon: Icons.more_horiz_outlined,
      color: Color(0xFF6B7280),
    ),

    // Expense Categories
    FinancialCategory(
      id: 'food',
      name: 'Makanan & Minuman',
      type: TransactionType.expense,
      icon: Icons.restaurant_outlined,
      color: Color(0xFFEF4444),
    ),
    FinancialCategory(
      id: 'transportation',
      name: 'Transportasi',
      type: TransactionType.expense,
      icon: Icons.directions_car_outlined,
      color: Color(0xFFF97316),
    ),
    FinancialCategory(
      id: 'shopping',
      name: 'Belanja',
      type: TransactionType.expense,
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFF59E0B),
    ),
    FinancialCategory(
      id: 'bills',
      name: 'Tagihan & Utilitas',
      type: TransactionType.expense,
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF6366F1),
    ),
    FinancialCategory(
      id: 'entertainment',
      name: 'Hiburan',
      type: TransactionType.expense,
      icon: Icons.sports_esports_outlined,
      color: Color(0xFFA855F7),
    ),
    FinancialCategory(
      id: 'health',
      name: 'Kesehatan',
      type: TransactionType.expense,
      icon: Icons.medical_services_outlined,
      color: Color(0xFF06B6D4),
    ),
    FinancialCategory(
      id: 'education',
      name: 'Pendidikan',
      type: TransactionType.expense,
      icon: Icons.school_outlined,
      color: Color(0xFF3B82F6),
    ),
    FinancialCategory(
      id: 'savings',
      name: 'Tabungan',
      type: TransactionType.expense,
      icon: Icons.savings_outlined,
      color: Color(0xFF10B981),
    ),
    FinancialCategory(
      id: 'expense_other',
      name: 'Lainnya',
      type: TransactionType.expense,
      icon: Icons.more_horiz_outlined,
      color: Color(0xFF6B7280),
    ),
  ];

  static List<FinancialCategory> getCategoriesByType(TransactionType type) {
    return defaultCategories.where((c) => c.type == type).toList();
  }

  static FinancialCategory findById(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => const FinancialCategory(
        id: 'unknown',
        name: 'Transaksi',
        type: TransactionType.expense,
        icon: Icons.category_outlined,
        color: Color(0xFF6B7280),
      ),
    );
  }
}
