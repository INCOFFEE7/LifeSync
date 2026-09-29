import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/utils/thousands_formatter.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';

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
  final _realizationController = TextEditingController();

  late String _name;
  late double _amount;
  double? _realizationAmount;
  double? _prePaymentRealization;
  late String _month;
  late DateTime _dueDate;
  late bool _isPaid;
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
      _isPaid = b.isPaid;
      _realizationAmount = b.realizationAmount;
      _prePaymentRealization = b.prePaymentRealization ?? (_isPaid ? b.amount : b.realizationAmount);
      _month = b.month;
      _dueDate = b.dueDate;
      _reminderDaysBefore = b.reminderDaysBefore;
      _notes = b.notes;

      if (_amount > 0) _amountController.text = currencyFmt.format(_amount.toInt());
      if (_realizationAmount != null && _realizationAmount! > 0) {
        _realizationController.text = currencyFmt.format(_realizationAmount!.toInt());
      } else {
        _realizationController.text = '';
      }
    } else {
      _name = '';
      _amount = 0.0;
      _realizationAmount = 0.0;
      _prePaymentRealization = 0.0;
      _month = defaultMonth;
      _dueDate = DateTime(now.year, now.month, now.day, 8, 0);
      _isPaid = false;
      _reminderDaysBefore = 0; // Hari H
      _notes = null;
      _realizationController.text = '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _realizationController.dispose();
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

      // Otomatis tandai Sudah Dibayar jika realisasi >= amount
      if (_realizationAmount != null && _amount > 0 && _realizationAmount! >= _amount) {
        _isPaid = true;
      }

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
        ..realizationAmount = _realizationAmount
        ..prePaymentRealization = _isPaid ? (_prePaymentRealization ?? _amount) : _realizationAmount
        ..month = _month
        ..dueDate = _dueDate
        ..isPaid = _isPaid
        ..paidAt = _isPaid ? (bill.paidAt ?? DateTime.now()) : null
        ..reminderDaysBefore = _reminderDaysBefore
        ..notes = _notes?.trim().isEmpty == true ? null : _notes?.trim();

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
        title: Text(
          widget.existingBill == null ? 'Tambah Tagihan' : 'Edit Tagihan',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: _inputDecoration('Nama Tagihan (e.g. Listrik, Internet, Air)'),
              style: const TextStyle(fontWeight: FontWeight.bold),
              validator: (val) => val == null || val.trim().isEmpty ? 'Nama tagihan wajib diisi' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 16),
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
              decoration: _inputDecoration('Nominal Tagihan / Amount (Rp)').copyWith(
                prefixText: 'Rp ',
                suffixIcon: const Icon(Icons.calculate, color: Color(0xFF2563EB)),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              validator: (val) {
                if (_amount <= 0) return 'Nominal harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _realizationController,
              readOnly: true,
              onTap: () async {
                final val = await showCalculatorInputDialog(
                  context: context,
                  title: 'Input Realisasi Pembayaran',
                  initialValue: _realizationAmount ?? 0.0,
                );
                if (val != null && mounted) {
                  setState(() {
                    _realizationAmount = val;
                    // Jika realisasi >= amount, otomatis ubah status ke Sudah Dibayar!
                    if (val >= _amount && _amount > 0) {
                      _isPaid = true;
                    } else if (val < _amount) {
                      _isPaid = false;
                    }

                    if (val > 0) {
                      _realizationController.text = currencyFmt.format(val.toInt());
                    } else {
                      _realizationController.text = '';
                    }
                  });
                }
              },
              decoration: _inputDecoration('Nominal Realisasi / Pembayaran (Rp)').copyWith(
                prefixText: 'Rp ',
                suffixIcon: const Icon(Icons.calculate, color: Color(0xFF10B981)),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text('Tanggal & Jam Jatuh Tempo', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(_dueDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                trailing: const Icon(Icons.access_time_filled, color: Color(0xFF2563EB)),
                onTap: _pickDueDate,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: _inputDecoration('Pengingat Tagihan'),
              value: _reminderDaysBefore,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              items: const [
                DropdownMenuItem(value: -1, child: Text('Tidak Ada')),
                DropdownMenuItem(value: 0, child: Text('Pada Hari H (Sesuai Jam Jatuh Tempo)')),
                DropdownMenuItem(value: 1, child: Text('1 Hari Sebelumnya')),
                DropdownMenuItem(value: 3, child: Text('3 Hari Sebelumnya')),
                DropdownMenuItem(value: 7, child: Text('7 Hari Sebelumnya')),
              ],
              onChanged: (val) => setState(() => _reminderDaysBefore = val!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Status Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_isPaid ? 'Sudah Dibayar' : 'Belum Dibayar', style: TextStyle(color: _isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              value: _isPaid,
              activeColor: const Color(0xFF10B981),
              onChanged: (val) {
                setState(() {
                  _isPaid = val;
                  if (_isPaid) {
                    _prePaymentRealization = _realizationAmount ?? 0.0;
                    _realizationAmount = _amount;
                    if (_amount > 0) {
                      _realizationController.text = currencyFmt.format(_amount.toInt());
                    }
                  } else {
                    _realizationAmount = _prePaymentRealization ?? 0.0;
                    if (_realizationAmount! > 0) {
                      _realizationController.text = currencyFmt.format(_realizationAmount!.toInt());
                    } else {
                      _realizationController.text = '';
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _notes,
              decoration: _inputDecoration('Catatan (Opsional)'),
              maxLines: 2,
              onSaved: (val) => _notes = val,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveBill,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.existingBill == null ? 'Simpan Tagihan' : 'Perbarui Tagihan',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
