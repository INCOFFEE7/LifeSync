import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

class AddEditBillPage extends ConsumerStatefulWidget {
  final Bill? existingBill;
  final String? initialMonth;

  const AddEditBillPage({super.key, this.existingBill, this.initialMonth});

  @override
  ConsumerState<AddEditBillPage> createState() => _AddEditBillPageState();
}

class _AddEditBillPageState extends ConsumerState<AddEditBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late String _name;
  late double _amount;
  late String _month;
  late DateTime _dueDate;
  late int _reminderDaysBefore;
  String? _notes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultMonth = widget.initialMonth ?? DateFormat('yyyy-MM').format(now);
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    if (widget.existingBill != null) {
      final b = widget.existingBill!;
      _name = b.name;
      _amount = b.amount;
      _month = b.month;
      _dueDate = b.dueDate;
      _reminderDaysBefore = b.reminderDaysBefore;
      _notes = b.notes;

      if (_amount > 0) _amountController.text = currencyFmt.format(_amount.toInt());
    } else {
      _name = '';
      _amount = 0.0;
      _month = defaultMonth;
      _dueDate = DateTime(now.year, now.month, now.day, 8, 0);
      _reminderDaysBefore = 0; // Hari H
      _notes = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _dueDate.hour,
            _dueDate.minute,
          );
        });
      }
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(billRepositoryProvider);

      // Check duplicate in month
      final isDup = await repo.checkDuplicateBill(_name.trim(), _month, excludeId: widget.existingBill?.id);
      if (isDup && mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tagihan Sudah Ada'),
            content: Text('Tagihan "$_name" untuk bulan $_month sudah tersedia. Apakah Anda ingin tetap membuatnya?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tetap Buat', style: TextStyle(color: Color(0xFF2563EB)))),
            ],
          ),
        );
        if (confirm != true) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final bill = widget.existingBill ?? Bill();
      bill
        ..name = _name.trim()
        ..amount = _amount
        ..month = _month
        ..dueDate = _dueDate
        ..reminderDaysBefore = _reminderDaysBefore
        ..notes = _notes?.trim().isEmpty == true ? null : _notes?.trim()
        ..createdAt = bill.createdAt
        ..updatedAt = DateTime.now();

      if (widget.existingBill == null) {
        bill.isPaid = false;
        bill.realizationAmount = 0.0;
        bill.paidAt = null;
      }

      await repo.saveBill(bill);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    final c = context;
    OutlineInputBorder border(Color col, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: col, width: w));
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: LsColors.mute(c), fontWeight: FontWeight.w500, fontSize: 13),
      filled: true,
      fillColor: LsColors.paper(c),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border(LsColors.line(c)),
      enabledBorder: border(LsColors.line(c)),
      focusedBorder: border(LsColors.brand, 1.8),
      errorBorder: border(LsColors.expense),
      focusedErrorBorder: border(LsColors.expense, 1.8),
    );
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    return LsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              LsEyebrow(title),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    const reminderOptions = <int, String>{
      -1: 'Tidak Ada',
      0: 'Pada Hari H (Sesuai Jam Jatuh Tempo)',
      1: '1 Hari Sebelumnya',
      3: '3 Hari Sebelumnya',
      7: '7 Hari Sebelumnya',
    };

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.surface(context),
        surfaceTintColor: LsColors.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
        title: Text(
          widget.existingBill == null ? 'Tambah Tagihan' : 'Edit Tagihan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: LsColors.ink(context)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            _section('Detail Tagihan', Icons.receipt_long_rounded, LsColors.brand, [
              TextFormField(
                initialValue: _name,
                decoration: _inputDecoration('Nama Tagihan * (e.g. Listrik, Internet, Air)'),
                style: const TextStyle(fontWeight: FontWeight.bold),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama tagihan wajib diisi' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                readOnly: true,
                onTap: () async {
                  final val = await showCalculatorInputDialog(
                    context: context,
                    title: 'Input Nominal Tagihan',
                    initialValue: _amount,
                  );
                  if (val != null && mounted) {
                    setState(() {
                      _amount = val;
                      _amountController.text = currencyFmt.format(val.toInt());
                    });
                  }
                },
                decoration: _inputDecoration('Nominal Rencana Tagihan * (Rp)').copyWith(
                  prefixText: 'Rp ',
                  suffixIcon: const Icon(Icons.calculate, color: LsColors.brand),
                ),
                style: const TextStyle(fontWeight: FontWeight.w800, color: LsColors.brand),
                validator: (val) {
                  if (_amount <= 0) return 'Nominal harus > 0';
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 10),
            _section('Jadwal & Pengingat', Icons.event_rounded, LsColors.violet, [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: LsColors.paper(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LsColors.line(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal & Jam Jatuh Tempo', style: TextStyle(color: LsColors.mute(context), fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(_dueDate),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: LsColors.ink(context)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.access_time_filled, color: LsColors.brand),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pengingat Tagihan', style: TextStyle(color: LsColors.mute(context), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reminderOptions.entries.map((e) {
                  final selected = _reminderDaysBefore == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _reminderDaysBefore = e.key),
                    selectedColor: LsColors.brand,
                    backgroundColor: LsColors.paper(context),
                    side: BorderSide(color: selected ? LsColors.brand : LsColors.line(context)),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : LsColors.ink(context),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 10),
            _section('Catatan', Icons.notes_rounded, LsColors.amber, [
              TextFormField(
                initialValue: _notes,
                decoration: _inputDecoration('Catatan (Opsional)'),
                maxLines: 2,
                onSaved: (val) => _notes = val,
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LsColors.brand,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _saveBill,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.existingBill == null ? 'Simpan Tagihan' : 'Perbarui Tagihan',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
