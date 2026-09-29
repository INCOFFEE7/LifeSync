import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/core/utils/thousands_formatter.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';

class AddIncomeDialog extends ConsumerStatefulWidget {
  final int targetId;
  final IncomeTarget? target;
  const AddIncomeDialog({super.key, required this.targetId, this.target});

  @override
  ConsumerState<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends ConsumerState<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  double _amount = 0.0;
  DateTime _date = DateTime.now();
  String _notes = '';

  @override
  void initState() {
    super.initState();
    if (widget.target != null && widget.target!.mode == 'fixed' && widget.target!.fixedDailyAmount > 0) {
      _amount = widget.target!.fixedDailyAmount;
      _amountController.text = NumberFormat('#,###', 'id_ID').format(_amount.toInt());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _openCalculator() async {
    final val = await showCalculatorInputDialog(
      context: context,
      title: 'Kalkulator Nabung',
      initialValue: _amount,
    );
    if (val != null && mounted) {
      setState(() {
        _amount = val;
        _amountController.text = NumberFormat('#,###', 'id_ID').format(val.toInt());
      });
    }
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final record = DailyIncomeRecord()
        ..id = DateTime.now().millisecondsSinceEpoch
        ..targetId = widget.targetId
        ..incomeAmount = _amount
        ..date = _date
        ..notes = _notes;

      final repo = ref.read(targetRepositoryProvider);
      await repo.saveRecord(record);

      ref.invalidate(dashboardDataProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catat Nabung'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixText: 'Rp ',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calculate, color: Color(0xFF2563EB)),
                    tooltip: 'Buka Kalkulator',
                    onPressed: _openCalculator,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  String cleanVal = val.replaceAll('.', '');
                  if (double.tryParse(cleanVal) == null) return 'Harus berupa angka';
                  if (double.parse(cleanVal) <= 0) return 'Harus lebih dari nol';
                  return null;
                },
                onSaved: (val) => _amount = double.parse(val!.replaceAll('.', '')),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 2,
                onSaved: (val) => _notes = val ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveIncome,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
