import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/domain/entities/financial_category.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/widgets/custom_numeric_keypad.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';

class AddFinancialRecordPage extends ConsumerStatefulWidget {
  final TransactionType initialType;
  const AddFinancialRecordPage({super.key, this.initialType = TransactionType.expense});

  @override
  ConsumerState<AddFinancialRecordPage> createState() => _AddFinancialRecordPageState();
}

class _AddFinancialRecordPageState extends ConsumerState<AddFinancialRecordPage> {
  late TransactionType _selectedType;
  FinancialCategory? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  
  String _calcExpression = '0';
  bool _showKeypad = false;
  bool _isSaving = false;
  bool _showCustomCategoryInput = false;
  DateTime _selectedDate = DateTime.now();
  List<String> _customIncomeCategories = [];
  List<String> _customExpenseCategories = [];

  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadCustomCategories();

    _descriptionFocusNode.addListener(() {
      if (_descriptionFocusNode.hasFocus) {
        setState(() => _showKeypad = false);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCustomCategories() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final settings = await db.db.appSettings.get(1);
      if (settings != null && mounted) {
        setState(() {
          _customIncomeCategories = List<String>.from(
            settings.customCategories.where((c) => c.startsWith('income:')).map((c) => c.substring(7)),
          );
          _customExpenseCategories = List<String>.from(
            settings.customCategories.where((c) => c.startsWith('expense:')).map((c) => c.substring(8)),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCustomCategory(String name) async {
    try {
      final db = ref.read(databaseServiceProvider);
      final prefix = _selectedType == TransactionType.income ? 'income:' : 'expense:';
      final key = '$prefix$name';
      final isar = db.db;
      await isar.writeTxn(() async {
        final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
        if (!settings.customCategories.contains(key)) {
          settings.customCategories = [...settings.customCategories, key];
          await isar.appSettings.put(settings);
        }
      });
      if (mounted) {
        setState(() {
          if (_selectedType == TransactionType.income) {
            if (!_customIncomeCategories.contains(name)) _customIncomeCategories.add(name);
          } else {
            if (!_customExpenseCategories.contains(name)) _customExpenseCategories.add(name);
          }
        });
      }
    } catch (_) {}
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _calcExpression = '0';
        return;
      }

      if (_calcExpression == '0' && key != '.' && key != '+' && key != '-' && key != '×' && key != '÷') {
        _calcExpression = key;
        return;
      }

      // Avoid double operators
      final lastChar = _calcExpression[_calcExpression.length - 1];
      final isOp = (String char) => char == '+' || char == '-' || char == '×' || char == '÷' || char == '.';

      if (isOp(key) && isOp(lastChar)) {
        _calcExpression = _calcExpression.substring(0, _calcExpression.length - 1) + key;
        return;
      }

      if (_calcExpression.length < 24) {
        _calcExpression += key;
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_calcExpression.length > 1) {
        _calcExpression = _calcExpression.substring(0, _calcExpression.length - 1);
      } else {
        _calcExpression = '0';
      }
    });
  }

  void _onEquals() {
    setState(() {
      final evaluated = _evaluateExpression(_calcExpression);
      _calcExpression = evaluated.toInt().toString();
    });
  }

  double _evaluateExpression(String expr) {
    try {
      String sanitized = expr.replaceAll('×', '*').replaceAll('÷', '/');
      // Simple parse for sequential expressions
      final tokens = RegExp(r'(\d+(?:\.\d+)?|[+\-*/])').allMatches(sanitized).map((m) => m.group(0)!).toList();
      if (tokens.isEmpty) return 0.0;

      double total = double.tryParse(tokens[0]) ?? 0.0;
      for (int i = 1; i < tokens.length - 1; i += 2) {
        final op = tokens[i];
        final nextNum = double.tryParse(tokens[i + 1]) ?? 0.0;
        if (op == '+') total += nextNum;
        else if (op == '-') total -= nextNum;
        else if (op == '*') total *= nextNum;
        else if (op == '/' && nextNum != 0) total /= nextNum;
      }
      return total.clamp(0.0, 999999999999.0);
    } catch (_) {
      return double.tryParse(expr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
  }

  double get _amountValue => _evaluateExpression(_calcExpression);

  String get _formattedAmount {
    final val = _amountValue.toInt();
    if (val == 0 && _calcExpression == '0') return 'Rp 0';
    return 'Rp ${_currencyFormatter.format(val)}';
  }

  bool get _canSave => _selectedCategory != null && _amountValue > 0 && !_isSaving;

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    setState(() => _showKeypad = false);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_canSave) return;

    if (_showCustomCategoryInput && _customCategoryController.text.trim().isNotEmpty) {
      await _saveCustomCategory(_customCategoryController.text.trim());
    }

    setState(() => _isSaving = true);
    try {
      final record = FinancialRecord()
        ..type = _selectedType == TransactionType.income ? 'income' : 'expense'
        ..categoryId = _selectedCategory!.id
        ..description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()
        ..amount = _amountValue
        ..transactionDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, DateTime.now().hour, DateTime.now().minute);

      final repository = ref.read(financialRecordRepositoryProvider);
      await repository.saveRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Transaksi berhasil disimpan!'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = ref.watch(localeProvider).languageCode;

    final defaultCategories = FinancialCategory.getCategoriesByType(_selectedType);
    final customNames = _selectedType == TransactionType.income ? _customIncomeCategories : _customExpenseCategories;
    final customColor = _selectedType == TransactionType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedType == TransactionType.income
              ? AppTranslations.get(lang, 'pemasukan')
              : AppTranslations.get(lang, 'pengeluaran'),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Tutup keypad saat tap di area luar input jumlah
                  if (_showKeypad) setState(() => _showKeypad = false);
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // ── Type Segmented Control ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _typeTab(lang, TransactionType.income, const Color(0xFF10B981), isDark),
                          _typeTab(lang, TransactionType.expense, const Color(0xFFEF4444), isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Amount Display (Tap to show Calculator Keypad) ─────────
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showKeypad = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _showKeypad
                              ? (_selectedType == TransactionType.income ? const Color(0xFF10B981).withAlpha(15) : const Color(0xFFEF4444).withAlpha(15))
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _showKeypad
                                ? (_selectedType == TransactionType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            width: _showKeypad ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'JUMLAH',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_outlined, size: 14, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formattedAmount,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: _selectedType == TransactionType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                            if (_calcExpression.contains(RegExp(r'[+\-×÷]')))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _calcExpression,
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Date Picker Tile ────────────────────────────────────
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            Text(
                              AppTranslations.get(lang, 'tanggal_transaksi'),
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Category Chips ──────────────────────────────────────
                    Text(
                      AppTranslations.get(lang, 'pilih_kategori').toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Wrap(
                        key: ValueKey(_selectedType),
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...defaultCategories.map((cat) {
                            final isOther = cat.id == 'income_other' || cat.id == 'expense_other';
                            if (isOther) return const SizedBox.shrink();
                            return _categoryChip(cat, isDark);
                          }),
                          ...customNames.map((name) {
                            final syntheticCat = FinancialCategory(
                              id: 'custom_${_selectedType.name}_$name',
                              name: name,
                              type: _selectedType,
                              icon: Icons.label_outline,
                              color: customColor,
                            );
                            return _categoryChip(syntheticCat, isDark);
                          }),
                          _otherCategoryChip(isDark, customColor, lang),
                        ],
                      ),
                    ),

                    if (_showCustomCategoryInput) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customCategoryController,
                        autofocus: true,
                        onTap: () {
                          if (_showKeypad) setState(() => _showKeypad = false);
                        },
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: AppTranslations.get(lang, 'nama_kategori_kustom'),
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 14),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: customColor.withAlpha(100))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: customColor, width: 1.5)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            color: customColor,
                            onPressed: () {
                              final name = _customCategoryController.text.trim();
                              if (name.isNotEmpty) {
                                final syntheticCat = FinancialCategory(
                                  id: 'custom_${_selectedType.name}_$name',
                                  name: name,
                                  type: _selectedType,
                                  icon: Icons.label_outline,
                                  color: customColor,
                                );
                                setState(() {
                                  _selectedCategory = syntheticCat;
                                  _showCustomCategoryInput = false;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Description Input (Native Keyboard) ─────────────────
                    Text(
                      AppTranslations.get(lang, 'catatan_opsional').toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'What is this transaction for?',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 14),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

            // ── Save Button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSave ? _saveTransaction : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == TransactionType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _canSave ? 4 : 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          AppTranslations.get(lang, 'simpan_transaksi'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),

            // ── Calculator Keypad (Hidden by default, shown on Amount tap) ───
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: CustomNumericKeypad(
                onKeyPress: _onKeyPress,
                onDelete: _onDelete,
                onEquals: _onEquals,
                onClose: () => setState(() => _showKeypad = false),
              ),
              crossFadeState: _showKeypad ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String lang, TransactionType type, Color color, bool isDark) {
    final selected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _selectedType = type; _selectedCategory = null; _showCustomCategoryInput = false; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            type == TransactionType.income
                ? AppTranslations.get(lang, 'pemasukan')
                : AppTranslations.get(lang, 'pengeluaran'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(FinancialCategory cat, bool isDark) {
    final isSelected = _selectedCategory?.id == cat.id;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() { _selectedCategory = cat; _showCustomCategoryInput = false; });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cat.color.withAlpha(30) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? cat.color : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)), width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 18, color: cat.color),
            const SizedBox(width: 8),
            Text(cat.name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? cat.color : (isDark ? Colors.white70 : const Color(0xFF334155)))),
          ],
        ),
      ),
    );
  }

  Widget _otherCategoryChip(bool isDark, Color color, String lang) {
    final otherId = _selectedType == TransactionType.income ? 'income_other' : 'expense_other';
    final isSelected = _selectedCategory?.id == otherId || _showCustomCategoryInput;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        final otherCat = FinancialCategory.findById(otherId);
        setState(() {
          _selectedCategory = otherCat;
          _showCustomCategoryInput = true;
          _showKeypad = false;
          _customCategoryController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)), width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 18, color: color),
            const SizedBox(width: 8),
            Text('Lainnya', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF334155)))),
          ],
        ),
      ),
    );
  }
}
