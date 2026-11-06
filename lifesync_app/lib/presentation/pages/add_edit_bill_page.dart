import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:lifesync_app/presentation/widgets/ls_date_time_picker_sheet.dart';

class AddEditBillPage extends ConsumerStatefulWidget {
  final Bill? existingBill;
  final String? initialMonth;
  final String? initialBillType; // 'monthly' atau 'receivable'

  const AddEditBillPage({
    super.key,
    this.existingBill,
    this.initialMonth,
    this.initialBillType,
  });

  @override
  ConsumerState<AddEditBillPage> createState() => _AddEditBillPageState();
}

class _AddEditBillPageState extends ConsumerState<AddEditBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paidByController = TextEditingController();
  final _receivedByController = TextEditingController();

  late String _billType; // 'monthly' | 'receivable'
  late String _name;
  late double _amount;
  late String _month;
  late DateTime _dueDate;
  late int _reminderDaysBefore;
  DateTime? _customReminderDateTime;
  String? _notes;
  bool _isPaid = false;
  bool _isSaving = false;

  static const _billReminderPresets = <int, String>{
    0: 'Hari H (Jatuh Tempo)',
    1: '1 hari sebelumnya',
    3: '3 hari sebelumnya',
    7: '7 hari sebelumnya',
    -1: 'Tidak ada pengingat',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultMonth =
        widget.initialMonth ?? DateFormat('yyyy-MM').format(now);
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    if (widget.existingBill != null) {
      final b = widget.existingBill!;
      _billType = b.billType;
      _name = b.name;
      _amount = b.amount;
      _month = b.month;
      _dueDate = b.dueDate;
      _reminderDaysBefore = b.reminderDaysBefore;
      if (_reminderDaysBefore > 0 &&
          !_billReminderPresets.containsKey(_reminderDaysBefore)) {
        _customReminderDateTime =
            _dueDate.subtract(Duration(days: _reminderDaysBefore));
      }
      _notes = b.notes;
      _isPaid = b.isPaid;
      _paidByController.text = b.paidBy ?? '';
      _receivedByController.text = b.receivedBy ?? '';

      if (_amount > 0)
        _amountController.text = currencyFmt.format(_amount.toInt());
    } else {
      _billType = widget.initialBillType ?? 'monthly';
      _name = '';
      _amount = 0.0;
      _month = defaultMonth;
      _dueDate = DateTime(now.year, now.month, now.day, 8, 0);
      _reminderDaysBefore = 0; // Hari H
      _notes = null;
      _isPaid = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paidByController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _dueDate,
      enableTime: false,
      title: _billType == 'receivable'
          ? 'Tanggal Tagih Piutang'
          : 'Tanggal Jatuh Tempo',
      confirmLabel: 'Atur Tanggal',
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _dueDate,
      enableTime: true,
      title: _billType == 'receivable'
          ? 'Jadwal Tagih Piutang'
          : 'Jatuh Tempo & Jam Tagihan',
      confirmLabel: 'Atur Jadwal',
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickCustomReminderDateTime() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _customReminderDateTime ??
          (_dueDate.isAfter(DateTime.now()) ? _dueDate : DateTime.now()),
      title: 'Waktu Pengingat Tagihan',
      confirmLabel: 'Pasang Pengingat',
    );
    if (picked != null && mounted) {
      setState(() {
        _customReminderDateTime = picked;
        final diffDays = _dueDate.difference(picked).inDays;
        _reminderDaysBefore = diffDays >= 0 ? diffDays : 0;
      });
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final confirm = await showLsConfirmDialog(
      context: context,
      title: widget.existingBill == null
          ? (_billType == 'receivable' ? 'Simpan Piutang?' : 'Simpan Tagihan?')
          : (_billType == 'receivable'
              ? 'Perbarui Piutang?'
              : 'Perbarui Tagihan?'),
      message: 'Pastikan data dan nominal yang diinput sudah sesuai.',
      confirmLabel: 'Ya, Simpan',
      cancelLabel: 'Batal',
    );
    if (!confirm || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(billRepositoryProvider);

      if (_billType == 'monthly') {
        final isDup = await repo.checkDuplicateBill(_name.trim(), _month,
            excludeId: widget.existingBill?.id);
        if (isDup && mounted) {
          final allowDup = await showLsConfirmDialog(
            context: context,
            title: 'Tagihan Sudah Ada',
            message:
                'Tagihan "$_name" untuk bulan $_month sudah tersedia. Apakah Anda ingin tetap membuatnya?',
            confirmLabel: 'Tetap Buat',
            cancelLabel: 'Batal',
          );
          if (allowDup != true) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final bill = widget.existingBill ?? Bill();
      bill
        ..billType = _billType
        ..name = _name.trim()
        ..amount = _amount
        ..month = _month
        ..dueDate = _dueDate
        ..reminderDaysBefore = _reminderDaysBefore
        ..paidBy = _paidByController.text.trim().isEmpty
            ? null
            : _paidByController.text.trim()
        ..receivedBy = _receivedByController.text.trim().isEmpty
            ? null
            : _receivedByController.text.trim()
        ..notes = _notes?.trim().isEmpty == true ? null : _notes?.trim()
        ..createdAt = bill.createdAt
        ..updatedAt = DateTime.now();

      if (widget.existingBill == null) {
        bill.isPaid = _isPaid;
        bill.realizationAmount = _isPaid ? _amount : 0.0;
        bill.paidAt = _isPaid ? DateTime.now() : null;
      } else {
        bill.isPaid = _isPaid;
        if (_isPaid &&
            (bill.realizationAmount == null || bill.realizationAmount == 0)) {
          bill.realizationAmount = _amount;
          bill.paidAt = DateTime.now();
        } else if (!_isPaid) {
          bill.realizationAmount = 0.0;
          bill.paidAt = null;
        }
      }

      await repo.saveBill(bill);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    final c = context;
    OutlineInputBorder border(Color col, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: col, width: w));
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: LsColors.mute(c), fontWeight: FontWeight.w500, fontSize: 13),
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

  Widget _section(
      String title, IconData icon, Color color, List<Widget> children) {
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
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle),
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

  String _getBillReminderLabel() {
    if (_customReminderDateTime != null) {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID')
          .format(_customReminderDateTime!);
    }
    if (_billReminderPresets.containsKey(_reminderDaysBefore)) {
      return _billReminderPresets[_reminderDaysBefore]!;
    }
    if (_reminderDaysBefore < 0) {
      return 'Tidak Ada';
    }
    return '$_reminderDaysBefore hari sebelumnya';
  }

  Widget _buildBillReminderSelectorTile() {
    return InkWell(
      onTap: _showBillReminderModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LsColors.paper(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LsColors.line(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Waktu Pengingat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LsColors.ink(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: LsColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: LsColors.brand.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getBillReminderLabel(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: LsColors.brand,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 18, color: LsColors.brand),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillReminderModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LsColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Waktu Pengingat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: LsColors.ink(ctx),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ..._billReminderPresets.entries.map((e) {
                        final isSelected = _customReminderDateTime == null &&
                            _reminderDaysBefore == e.key;
                        return ListTile(
                          title: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? LsColors.brand
                                  : LsColors.ink(ctx),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: LsColors.brand, size: 20)
                              : null,
                          onTap: () {
                            setState(() {
                              _customReminderDateTime = null;
                              _reminderDaysBefore = e.key;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                      ListTile(
                        title: Text(
                          'Pilih Kalender & Waktu Kustom...',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: _customReminderDateTime != null
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: _customReminderDateTime != null
                                ? LsColors.brand
                                : LsColors.ink(ctx),
                          ),
                        ),
                        trailing: _customReminderDateTime != null
                            ? const Icon(Icons.check_rounded,
                                color: LsColors.brand, size: 20)
                            : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickCustomReminderDateTime();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final currencyFmt = NumberFormat('#,###', lang == 'en' ? 'en_US' : 'id_ID');

    final isReceivable = _billType == 'receivable';

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.surface(context),
        surfaceTintColor: LsColors.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
        title: Text(
          widget.existingBill == null
              ? (isReceivable
                  ? AppTranslations.get(lang, 'piutang_baru')
                  : AppTranslations.get(lang, 'tagihan_baru'))
              : (isReceivable
                  ? 'Edit ${AppTranslations.get(lang, 'tagihan_piutang')}'
                  : AppTranslations.get(lang, 'edit_tagihan')),
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: LsColors.ink(context)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            // Segmented Switch Tipe
            if (widget.existingBill == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: LsColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LsColors.line(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _billType = 'monthly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _billType == 'monthly'
                                  ? LsColors.brand
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppTranslations.get(lang, 'tagihan_bulanan'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _billType == 'monthly'
                                    ? Colors.white
                                    : LsColors.mute(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _billType = 'receivable'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _billType == 'receivable'
                                  ? LsColors.income
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppTranslations.get(lang, 'tagihan_piutang'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _billType == 'receivable'
                                    ? Colors.white
                                    : LsColors.mute(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            _section(
              isReceivable ? 'Detail Piutang' : 'Detail Tagihan',
              isReceivable
                  ? Icons.handshake_rounded
                  : Icons.receipt_long_rounded,
              isReceivable ? LsColors.income : LsColors.brand,
              [
                TextFormField(
                  initialValue: _name,
                  decoration: _inputDecoration(
                    isReceivable
                        ? 'Nama Piutang * (e.g. Pinjaman Budi, Piutang Usaha)'
                        : 'Nama Tagihan * (e.g. Listrik, Internet, Air)',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                  onSaved: (val) => _name = val!,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  readOnly: true,
                  onTap: () async {
                    final val = await showCalculatorInputDialog(
                      context: context,
                      title: isReceivable
                          ? 'Input Nominal Piutang'
                          : 'Input Nominal Tagihan',
                      initialValue: _amount,
                    );
                    if (val != null && mounted) {
                      setState(() {
                        _amount = val;
                        _amountController.text =
                            currencyFmt.format(val.toInt());
                      });
                    }
                  },
                  decoration: _inputDecoration(isReceivable
                          ? 'Nominal Piutang * (Rp)'
                          : 'Nominal Rencana Tagihan * (Rp)')
                      .copyWith(
                    prefixText: 'Rp ',
                    suffixIcon:
                        const Icon(Icons.calculate, color: LsColors.brand),
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: LsColors.brand),
                  validator: (val) {
                    if (_amount <= 0) return 'Nominal harus > 0';
                    return null;
                  },
                ),
                if (isReceivable) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _paidByController,
                    decoration: _inputDecoration(
                        'Dibayar Oleh / Peminjam (e.g. Budi Hartono)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _receivedByController,
                    decoration: _inputDecoration(
                        'Diterima Oleh (e.g. Saya / Rekening BCA)'),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: _isPaid,
                    activeColor: LsColors.income,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tandai Langsung Terbayar / Lunas',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Simpan timestamp pembayaran sekarang jika piutang sudah diterima.',
                        style: TextStyle(fontSize: 11)),
                    onChanged: (v) => setState(() => _isPaid = v ?? false),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _section(
                'Jadwal & Pengingat', Icons.event_rounded, LsColors.violet, [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: LsColors.paper(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LsColors.line(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReceivable
                                  ? 'Tanggal Tagih'
                                  : 'Tanggal Jatuh Tempo',
                              style: TextStyle(
                                  color: LsColors.mute(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(_dueDate),
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: LsColors.ink(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDueTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: LsColors.paper(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LsColors.line(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jam',
                              style: TextStyle(
                                  color: LsColors.mute(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('HH:mm', 'id_ID').format(_dueDate),
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: LsColors.ink(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBillReminderSelectorTile(),
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
                  backgroundColor:
                      isReceivable ? LsColors.income : LsColors.brand,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _saveBill,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.existingBill == null
                            ? (isReceivable
                                ? 'Simpan Piutang'
                                : 'Simpan Tagihan')
                            : (isReceivable
                                ? 'Perbarui Piutang'
                                : 'Perbarui Tagihan'),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
