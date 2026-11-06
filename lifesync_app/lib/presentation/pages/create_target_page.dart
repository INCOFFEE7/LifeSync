import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:lifesync_app/presentation/widgets/ls_date_time_picker_sheet.dart';

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

      if (_targetAmount > 0)
        _targetAmountController.text =
            currencyFmt.format(_targetAmount.toInt());

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
    final date = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      enableTime: false,
      title: 'Pilih Tanggal Mulai',
    );
    if (date != null) {
      setState(() => _startDate = date);
      _calculateFixedDaily();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      enableTime: false,
      title: 'Pilih Batas Waktu Target',
    );
    if (date != null) {
      setState(() => _endDate = date);
      _calculateFixedDaily();
    }
  }

  Future<void> _saveTarget() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final confirm = await showLsConfirmDialog(
        context: context,
        title: widget.existingTarget == null
            ? 'Simpan Target Nabung?'
            : 'Perbarui Target Nabung?',
        message:
            'Apakah detail dan nominal target yang dimasukkan sudah benar?',
        confirmLabel: 'Ya, Simpan',
        cancelLabel: 'Batal',
      );
      if (!confirm || !mounted) return;

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

      if (_category == TargetCategory.other &&
          _customCategoryName != null &&
          _customCategoryName!.trim().isNotEmpty) {
        final db = ref.read(databaseServiceProvider);
        final settings = await db.db.appSettings.get(1);
        if (settings != null) {
          final trimmed = _customCategoryName!.trim();
          if (!settings.customCategories.contains(trimmed)) {
            settings.customCategories = List.from(settings.customCategories)
              ..add(trimmed);
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
    final line = LsColors.line(context);
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: LsColors.mute(context),
          fontWeight: FontWeight.w500,
          fontSize: 13),
      filled: true,
      fillColor: LsColors.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: b(line, 1),
      enabledBorder: b(line, 1),
      focusedBorder: b(LsColors.brand, 2),
      errorBorder: b(LsColors.expense, 1.5),
      focusedErrorBorder: b(LsColors.expense, 2),
    );
  }

  String _categoryLabel(TargetCategory c) {
    switch (c) {
      case TargetCategory.savings:
        return 'Tabungan';
      case TargetCategory.gadget:
        return 'Gadget';
      case TargetCategory.travel:
        return 'Perjalanan';
      case TargetCategory.education:
        return 'Pendidikan';
      case TargetCategory.investment:
        return 'Investasi';
      case TargetCategory.other:
        return 'Lainnya';
    }
  }

  void _selectCategoryValue(String val) {
    setState(() {
      _selectedDropdownValue = val;
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
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LsEyebrow(title, color: LsColors.brand),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _modeSegment(String label, String value, VoidCallback onTap) {
    final selected = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? LsColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? Colors.white : LsColors.mute(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catChip(String label, String value, {bool isAdd = false}) {
    final selected = _selectedDropdownValue == value;
    return GestureDetector(
      onTap: () => _selectCategoryValue(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LsColors.brand : LsColors.paper(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? LsColors.brand : LsColors.line(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdd) ...[
              Icon(Icons.add,
                  size: 14, color: selected ? Colors.white : LsColors.brand),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isAdd ? LsColors.brand : LsColors.ink(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: LsColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LsColors.line(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: LsColors.mute(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 15, color: LsColors.brand),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd MMM yyyy').format(date),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: LsColors.ink(context))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final ink = LsColors.ink(context);

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.paper(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        title: Text(
          widget.existingTarget == null ? 'Target Baru' : 'Edit Target',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.5),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          children: [
            _section('Informasi Target', [
              TextFormField(
                initialValue: _name,
                decoration: _inputDecoration('Nama Target *'),
                style: TextStyle(fontWeight: FontWeight.w600, color: ink),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama target wajib diisi'
                    : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 10),
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
                      _targetAmountController.text =
                          currencyFmt.format(val.toInt());
                      _calculateFixedDaily();
                    });
                  }
                },
                decoration: _inputDecoration('Jumlah Target * (Rp)').copyWith(
                  prefixText: 'Rp ',
                  suffixIcon:
                      const Icon(Icons.calculate, color: LsColors.brand),
                ),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: LsColors.brand),
                validator: (val) {
                  if (_targetAmount <= 0) return 'Nominal harus > 0';
                  return null;
                },
              ),
            ]),
            _section('Mode Nabung', [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: LsColors.paper(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LsColors.line(context)),
                ),
                child: Row(
                  children: [
                    _modeSegment('Nominal Bebas', 'flexible',
                        () => setState(() => _mode = 'flexible')),
                    _modeSegment('Nominal Tetap', 'fixed', () {
                      setState(() => _mode = 'fixed');
                      _calculateFixedDaily();
                    }),
                  ],
                ),
              ),
              if (_mode == 'fixed') ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LsColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: LsColors.income.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: LsColors.income, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nominal Nabung Harian (Otomatis)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: LsColors.income)),
                            const SizedBox(height: 2),
                            Text(
                                'Rp ${currencyFmt.format(_fixedDailyAmount.toInt())} / hari',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: ink)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]),
            _section('Kategori', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...TargetCategory.values
                      .where((c) => c != TargetCategory.other)
                      .map((c) => _catChip(_categoryLabel(c), c.name)),
                  ..._existingCustomCategories.map((c) => _catChip(c, c)),
                  _catChip('Tambah Baru', 'ADD_NEW', isAdd: true),
                ],
              ),
              if (_selectedDropdownValue == 'ADD_NEW') ...[
                const SizedBox(height: 14),
                TextFormField(
                  decoration: _inputDecoration('Nama Kategori Khusus'),
                  style: TextStyle(color: ink),
                  onChanged: (val) {
                    _customCategoryName = val;
                  },
                  validator: (value) {
                    if (_selectedDropdownValue == 'ADD_NEW' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Kategori khusus tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ]),
            _section('Periode & Catatan', [
              Row(
                children: [
                  _dateTile('Tanggal Mulai', _startDate, _selectStartDate),
                  const SizedBox(width: 12),
                  _dateTile('Tanggal Selesai', _endDate, _selectEndDate),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _description,
                decoration: _inputDecoration('Catatan Khusus'),
                style: TextStyle(color: ink),
                maxLines: 3,
                onSaved: (val) => _description = val ?? '',
              ),
            ]),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveTarget,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: LsColors.brand,
                  elevation: 0,
                ),
                child: Text(
                  widget.existingTarget == null
                      ? 'Buat Target'
                      : 'Perbarui Target',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
