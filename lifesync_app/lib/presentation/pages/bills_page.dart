import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_bill_page.dart';

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

    // Hitung tanggal jatuh tempo baru di bulan depan
    final newDay = bill.dueDate.day.clamp(1, 28);
    final nextDueDate = DateTime(nextMonthDate.year, nextMonthDate.month, newDay);

    final repo = ref.read(billRepositoryProvider);

    // Cek duplikasi
    final isDup = await repo.checkDuplicateBill(bill.name, nextMonthKey);
    if (isDup && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsStreamProvider(_currentMonthKey));
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daftar Tagihan'),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
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
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonthDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tagihan di bulan ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonthDate)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('Klik "+ Tagihan Baru" untuk mencatatkan tagihan bulanan.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                // Rekap Tagihan berdasarkan realisasi parsial & total rencana
                double totalAmount = bills.fold(0.0, (s, b) => s + b.amount);
                double totalRealization = bills.fold(0.0, (s, b) => s + (b.realizationAmount ?? 0.0));
                double totalRemaining = (totalAmount - totalRealization).clamp(0.0, double.infinity);

                return Column(
                  children: [
                    // Summary header for the month
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          final remaining = (bill.amount - realization).clamp(0.0, double.infinity);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isPaid ? Colors.green.shade200 : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Checklist Box
                                      InkWell(
                                        onTap: () async {
                                          final bool newPaidState = !isPaid;
                                          double? newRealization;
                                          double? newPreRealization = bill.prePaymentRealization;

                                          if (newPaidState) {
                                            // CHECK: Simpan realisasi saat ini sebagai prePaymentRealization (misal 50rb), set realization ke amount (90rb)
                                            newPreRealization = bill.realizationAmount ?? 0.0;
                                            newRealization = bill.amount;
                                          } else {
                                            // UNCHECK: Kembalikan realization ke prePaymentRealization (misal 50rb)!
                                            newRealization = newPreRealization ?? 0.0;
                                          }

                                          final updated = bill
                                            ..prePaymentRealization = newPreRealization
                                            ..realizationAmount = newRealization
                                            ..isPaid = newPaidState
                                            ..paidAt = newPaidState ? DateTime.now() : null;

                                          await ref.read(billRepositoryProvider).saveBill(updated);
                                        },
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
                                                color: isPaid ? Colors.grey.shade600 : const Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Jatuh Tempo: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(bill.dueDate)}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                                          Text('Rencana: Rp ${currencyFmt.format(bill.amount.toInt())}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                          Text('Realisasi: Rp ${currencyFmt.format(realization.toInt())}', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                          if (remaining > 0 && !isPaid)
                                            Text('Sisa: Rp ${currencyFmt.format(remaining.toInt())}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
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
