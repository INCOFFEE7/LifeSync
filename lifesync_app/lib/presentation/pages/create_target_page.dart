import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';

class CreateTargetPage extends ConsumerStatefulWidget {
  final IncomeTarget? existingTarget;
  const CreateTargetPage({super.key, this.existingTarget});

  @override
  ConsumerState<CreateTargetPage> createState() => _CreateTargetPageState();
}

class _CreateTargetPageState extends ConsumerState<CreateTargetPage> {
  final _formKey = GlobalKey<FormState>();
  final _targetAmountController = TextEditingController();
  
  String _name = '';
  String _description = '';
  double _targetAmount = 0.0;
  TargetCategory _category = TargetCategory.savings;
  String? _customCategoryName;
  DateTime _startDate = DateTime.now();
  String _selectedDropdownValue = TargetCategory.savings.name;
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _mode = 'flexible';
  double _fixedDailyAmount = 0.0;
  List<String> _existingCustomCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    if (widget.existingTarget != null) {
      _name = widget.existingTarget!.name;
      _description = widget.existingTarget!.description ?? '';
      _targetAmount = widget.existingTarget!.targetAmount;
      _category = widget.existingTarget!.category;
      _customCategoryName = widget.existingTarget!.customCategory;
      _startDate = widget.existingTarget!.startDate;
      _endDate = widget.existingTarget!.endDate;
      _mode = widget.existingTarget!.mode;
      _fixedDailyAmount = widget.existingTarget!.fixedDailyAmount;

      if (_targetAmount > 0) _targetAmountController.text = currencyFmt.format(_targetAmount.toInt());
      
      if (_category == TargetCategory.other && _customCategoryName != null) {
        _selectedDropdownValue = _customCategoryName!;
      } else {
        _selectedDropdownValue = _category.name;
      }
    } else {
      _calculateFixedDaily();
    }
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    super.dispose();
  }

  void _calculateFixedDaily() {
    if (_targetAmount > 0) {
      final totalDays = _endDate.difference(_startDate).inDays + 1;
      if (totalDays > 0) {
        setState(() {
          _fixedDailyAmount = (_targetAmount / totalDays).roundToDouble();
        });
      }
    }
  }

  Future<void> _loadCustomCategories() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.db.appSettings.get(1);
    if (settings != null) {
      setState(() {
        _existingCustomCategories = settings.customCategories;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _startDate = date);
      _calculateFixedDaily();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _endDate = date);
      _calculateFixedDaily();
    }
  }

  Future<void> _saveTarget() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final target = widget.existingTarget ?? IncomeTarget();
      if (widget.existingTarget == null) {
        target.id = DateTime.now().millisecondsSinceEpoch;
      }
      
      target
        ..name = _name
        ..description = _description
        ..targetAmount = _targetAmount
        ..category = _category
        ..customCategory = _customCategoryName
        ..startDate = _startDate
        ..endDate = _endDate
        ..mode = _mode
        ..fixedDailyAmount = _mode == 'fixed' ? _fixedDailyAmount : 0.0
        ..status = widget.existingTarget?.status ?? TargetStatus.notStarted;

      if (_category == TargetCategory.other && _customCategoryName != null && _customCategoryName!.trim().isNotEmpty) {
        final db = ref.read(databaseServiceProvider);
        final settings = await db.db.appSettings.get(1);
        if (settings != null) {
          final trimmed = _customCategoryName!.trim();
          if (!settings.customCategories.contains(trimmed)) {
            settings.customCategories = List.from(settings.customCategories)..add(trimmed);
            await db.db.writeTxn(() async {
              await db.db.appSettings.put(settings);
            });
          }
        }
      }
        
      final repo = ref.read(targetRepositoryProvider);
      await repo.saveTarget(target);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
        centerTitle: false,
        title: Text(
          widget.existingTarget == null ? 'Target Baru' : 'Edit Target',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: _inputDecoration('Nama Target'),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _targetAmountController,
              readOnly: true,
              onTap: () async {
                final val = await showCalculatorInputDialog(
                  context: context,
                  title: 'Input Jumlah Target',
                  initialValue: _targetAmount,
                );
                if (val != null && mounted) {
                  setState(() {
                    _targetAmount = val;
                    _targetAmountController.text = currencyFmt.format(val.toInt());
                    _calculateFixedDaily();
                  });
                }
              },
              decoration: _inputDecoration('Jumlah Target (Rp)').copyWith(
                prefixText: 'Rp ',
                suffixIcon: const Icon(Icons.calculate, color: Color(0xFF2563EB)),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              validator: (val) {
                if (_targetAmount <= 0) return 'Nominal harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            // ── Mode Nabung (Flexible / Fixed) ─────────────────────
            Text('Mode Nabung', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Nominal Bebas')),
                    selected: _mode == 'flexible',
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: _mode == 'flexible' ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _mode = 'flexible');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Nominal Tetap')),
                    selected: _mode == 'fixed',
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: _mode == 'fixed' ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() => _mode = 'fixed');
                        _calculateFixedDaily();
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_mode == 'fixed') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nominal Nabung Harian (Otomatis)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 2),
                          Text('Rp ${currencyFmt.format(_fixedDailyAmount.toInt())} / hari', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Kategori'),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4B5563)),
              value: _selectedDropdownValue,
              items: [
                ...TargetCategory.values
                    .where((c) => c != TargetCategory.other)
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name.toUpperCase()))),
                ..._existingCustomCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))),
                const DropdownMenuItem(value: 'ADD_NEW', child: Text('TAMBAH BARU...')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedDropdownValue = val!;
                  if (val == 'ADD_NEW') {
                    _category = TargetCategory.other;
                    _customCategoryName = '';
                  } else {
                    try {
                      _category = TargetCategory.values.firstWhere((c) => c.name == val);
                      _customCategoryName = null;
                    } catch (e) {
                      _category = TargetCategory.other;
                      _customCategoryName = val;
                    }
                  }
                });
              },
            ),
            if (_selectedDropdownValue == 'ADD_NEW') ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Nama Kategori Khusus'),
                onChanged: (val) {
                  _customCategoryName = val;
                },
                validator: (value) {
                  if (_selectedDropdownValue == 'ADD_NEW' && (value == null || value.trim().isEmpty)) {
                    return 'Kategori khusus tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text('Tanggal Mulai', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                      onTap: _selectStartDate,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text('Tanggal Selesai', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                      onTap: _selectEndDate,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _description,
              decoration: _inputDecoration('Catatan Khusus'),
              style: const TextStyle(color: Color(0xFF1F2937)),
              maxLines: 3,
              onSaved: (val) => _description = val ?? '',
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveTarget,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 4,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.3),
                ),
                child: Text(
                  widget.existingTarget == null ? 'Buat Target' : 'Perbarui Target',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
