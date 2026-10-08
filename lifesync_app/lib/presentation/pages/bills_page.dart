import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_bill_page.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/config/app_variant.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage> {
  late DateTime _selectedMonthDate;

  @override
  void initState() {
    super.initState();
    _selectedMonthDate = DateTime(DateTime.now().year, DateTime.now().month);
  }

  String get _currentMonthKey => DateFormat('yyyy-MM').format(_selectedMonthDate);

  void _nextMonth() {
    setState(() {
      _selectedMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _selectedMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month - 1);
    });
  }

  Future<void> _copyBillToNextMonth(Bill bill) async {
    final nextMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month + 1);
    final nextMonthKey = DateFormat('yyyy-MM').format(nextMonthDate);

    final newDay = bill.dueDate.day.clamp(1, 28);
    final nextDueDate = DateTime(nextMonthDate.year, nextMonthDate.month, newDay);

    final repo = ref.read(billRepositoryProvider);

    final isDup = await repo.checkDuplicateBill(bill.name, nextMonthKey);
    if (isDup && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Duplikasi Tagihan'),
          content: Text('Tagihan "${bill.name}" untuk bulan ${DateFormat('MMMM yyyy', 'id_ID').format(nextMonthDate)} sudah tersedia.\n\nApakah Anda ingin membuat salinan baru?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Salin', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await repo.copyBillToMonth(bill, nextMonthKey, nextDueDate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tagihan "${bill.name}" berhasil disalin ke ${DateFormat('MMMM yyyy', 'id_ID').format(nextMonthDate)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleBillToggle(Bill bill) async {
    final isPaid = bill.isPaid;

    if (!isPaid) {
      // PROSES BAYAR TAGIHAN
      double enteredRealization = bill.amount;
      DateTime selectedPaymentDate = DateTime.now();
      final notesController = TextEditingController();
      final currencyFmt = NumberFormat('#,###', 'id_ID');

      final confirm = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              final diff = enteredRealization - bill.amount;

              return Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 24, left: 24, right: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Bayar: ${bill.name}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nominal Rencana Tagihan:', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            Text('Rp ${currencyFmt.format(bill.amount.toInt())}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: currencyFmt.format(enteredRealization.toInt()),
                        ),
                        onTap: () async {
                          final val = await showCalculatorInputDialog(
                            context: ctx,
                            title: 'Input Realisasi Pembayaran',
                            initialValue: enteredRealization,
                          );
                          if (val != null && val >= 0) {
                            setDialogState(() {
                              enteredRealization = val;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Nominal Realisasi Pembayaran (Rp)',
                          prefixText: 'Rp ',
                          suffixIcon: const Icon(Icons.calculate, color: Color(0xFF10B981)),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 10),
                      // Perbandingan nominal
                      if (diff < 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kurang (Sisa): Rp ${currencyFmt.format(diff.abs().toInt())}',
                                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (diff > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kelebihan: Rp ${currencyFmt.format(diff.toInt())}',
                                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lunas Sesuai Rencana',
                                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        title: const Text('Tanggal Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(
                          DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(selectedPaymentDate),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 20),
                        onTap: () async {
                          final pDate = await showDatePicker(
                            context: ctx,
                            initialDate: selectedPaymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (pDate != null && ctx.mounted) {
                            final pTime = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(selectedPaymentDate),
                            );
                            final time = pTime ?? TimeOfDay.fromDateTime(selectedPaymentDate);
                            setDialogState(() {
                              selectedPaymentDate = DateTime(pDate.year, pDate.month, pDate.day, time.hour, time.minute);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Catatan Realisasi (Opsional)',
                          hintText: 'e.g. Termasuk denda / diskon',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Konfirmasi Bayar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (confirm == true) {
        final enteredNotes = notesController.text.trim();

        // 1. Save Bill State
        bill.isPaid = true;
        bill.realizationAmount = enteredRealization;
        bill.paidAt = selectedPaymentDate;
        bill.updatedAt = DateTime.now();
        if (enteredNotes.isNotEmpty) {
          bill.notes = (bill.notes != null && bill.notes!.isNotEmpty)
              ? '${bill.notes}\n[Bayar ${DateFormat('dd/MM/yy').format(selectedPaymentDate)}]: $enteredNotes'
              : '[Bayar ${DateFormat('dd/MM/yy').format(selectedPaymentDate)}]: $enteredNotes';
        }

        await ref.read(billRepositoryProvider).saveBill(bill);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tagihan "${bill.name}" berhasil dibayar!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // BATALKAN PEMBAYARAN TAGIHAN
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Batalkan Pembayaran?'),
          content: Text('Status tagihan "${bill.name}" akan dikembalikan menjadi Belum Dibayar.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        bill.isPaid = false;
        bill.realizationAmount = 0.0;
        bill.paidAt = null;
        bill.updatedAt = DateTime.now();

        await ref.read(billRepositoryProvider).saveBill(bill);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status tagihan "${bill.name}" dikembalikan ke Belum Dibayar.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsStreamProvider(_currentMonthKey));
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(25),
        surfaceTintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        scrolledUnderElevation: 4,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Image.asset(
          AppEnvironment.config.getLogoFullPath(isDark),
          width: 140,
          cacheWidth: 420,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Text(
            AppEnvironment.config.appName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: -0.5),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_bill_fab',
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditBillPage(initialMonth: _currentMonthKey),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tagihan Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Month Selector Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonthDate),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 28),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // ── Bills List ─────────────────────────────────────────────────────
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (bills) {
                if (bills.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tagihan di bulan ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonthDate)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('Klik "+ Tagihan Baru" untuk mencatatkan tagihan bulanan.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                double totalAmount = bills.fold(0.0, (s, b) => s + b.amount);
                double totalRealization = bills.fold(0.0, (s, b) => s + (b.realizationAmount ?? 0.0));
                double totalRemaining = bills
                    .where((b) => !b.isPaid)
                    .fold(0.0, (s, b) => s + (b.amount - (b.realizationAmount ?? 0.0)).clamp(0.0, double.infinity));

                return Column(
                  children: [
                    // Summary header for the month
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Rencana', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Rp ${currencyFmt.format(totalAmount.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: Colors.grey.shade200),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Realisasi', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('Rp ${currencyFmt.format(totalRealization.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 32, color: Colors.grey.shade200),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sisa Tagihan', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('Rp ${currencyFmt.format(totalRemaining.toInt())}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: totalRemaining > 0 ? Colors.red : Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: bills.length,
                        itemBuilder: (context, idx) {
                          final bill = bills[idx];
                          final isPaid = bill.isPaid;
                          final realization = bill.realizationAmount ?? 0.0;
                          final diff = realization - bill.amount;
                          final remaining = (bill.amount - realization).clamp(0.0, double.infinity);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isPaid ? Colors.green.shade200 : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Checklist Box
                                      InkWell(
                                        onTap: () => _handleBillToggle(bill),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isPaid ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isPaid ? Icons.check_box : Icons.check_box_outline_blank,
                                            color: isPaid ? const Color(0xFF10B981) : Colors.grey.shade400,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bill.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                decoration: isPaid ? TextDecoration.lineThrough : null,
                                                color: isPaid ? Colors.grey.shade500 : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Jatuh Tempo: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(bill.dueDate)}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                            if (bill.paidAt != null)
                                              Text(
                                                'Dibayar: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(bill.paidAt!)}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isPaid ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Rencana: Rp ${currencyFmt.format(bill.amount.toInt())}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                          Text('Realisasi: Rp ${currencyFmt.format(realization.toInt())}', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                          if (isPaid) ...[
                                            if (diff > 0)
                                              Text('Kelebihan: Rp ${currencyFmt.format(diff.toInt())}', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))
                                            else if (diff < 0)
                                              Text('Hemat: Rp ${currencyFmt.format(diff.abs().toInt())}', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold))
                                            else
                                              Text('Sesuai Rencana', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                          ] else ...[
                                            Text('Sisa Tagihan: Rp ${currencyFmt.format(remaining.toInt())}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                          ],
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                            onSelected: (val) async {
                                              if (val == 'copy') {
                                                await _copyBillToNextMonth(bill);
                                              } else if (val == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AddEditBillPage(existingBill: bill),
                                                  ),
                                                );
                                              } else if (val == 'delete') {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    title: const Text('Hapus Tagihan?'),
                                                    content: Text('Apakah Anda yakin ingin menghapus tagihan "${bill.name}"?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await ref.read(billRepositoryProvider).deleteBill(bill.id);
                                                }
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'copy',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2563EB)),
                                                    SizedBox(width: 8),
                                                    Text('Copy ke Bulan Berikutnya'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                                    SizedBox(width: 8),
                                                    Text('Edit Tagihan'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus Tagihan', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
