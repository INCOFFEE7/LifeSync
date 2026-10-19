import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_bill_page.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

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

              Color diffColor;
              IconData diffIcon;
              String diffLabel;
              Color diffBgColor;
              Color diffBorderColor;

              if (diff < 0) {
                diffColor = const Color(0xFFD97706);
                diffBgColor = const Color(0xFFFFFBEB);
                diffBorderColor = const Color(0xFFFCD34D);
                diffIcon = Icons.warning_amber_rounded;
                diffLabel = 'Kurang: Rp ${currencyFmt.format(diff.abs().toInt())}';
              } else if (diff > 0) {
                diffColor = const Color(0xFF2563EB);
                diffBgColor = const Color(0xFFEFF6FF);
                diffBorderColor = const Color(0xFF93C5FD);
                diffIcon = Icons.trending_up_rounded;
                diffLabel = 'Kelebihan: Rp ${currencyFmt.format(diff.toInt())}';
              } else {
                diffColor = const Color(0xFF10B981);
                diffBgColor = const Color(0xFFF0FDF4);
                diffBorderColor = const Color(0xFF86EFAC);
                diffIcon = Icons.check_circle_outline_rounded;
                diffLabel = 'Sesuai Rencana';
              }

              return Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Konfirmasi Pembayaran',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5),
                                      ),
                                      Text(
                                        bill.name,
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey.shade400),
                                  onPressed: () => Navigator.pop(ctx, false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Nominal Rencana
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Nominal Rencana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                                  Text('Rp ${currencyFmt.format(bill.amount.toInt())}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Input Realisasi (tappable, live update via setDialogState)
                            GestureDetector(
                              onTap: () async {
                                final val = await showCalculatorInputDialog(
                                  context: ctx,
                                  title: 'Input Realisasi Pembayaran',
                                  initialValue: enteredRealization,
                                );
                                if (val != null && val >= 0) {
                                  setDialogState(() => enteredRealization = val);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Nominal Realisasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.3)),
                                          const SizedBox(height: 4),
                                          Text('Rp ${currencyFmt.format(enteredRealization.toInt())}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.calculate_rounded, color: Color(0xFF10B981), size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Badge Kurang / Lebih / Sesuai — live
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: diffBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: diffBorderColor)),
                              child: Row(
                                children: [
                                  Icon(diffIcon, color: diffColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text(diffLabel, style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tanggal Pembayaran
                            GestureDetector(
                              onTap: () async {
                                final pDate = await showDatePicker(context: ctx, initialDate: selectedPaymentDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                                if (pDate != null && ctx.mounted) {
                                  final pTime = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(selectedPaymentDate));
                                  final time = pTime ?? TimeOfDay.fromDateTime(selectedPaymentDate);
                                  setDialogState(() {
                                    selectedPaymentDate = DateTime(pDate.year, pDate.month, pDate.day, time.hour, time.minute);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tanggal Pembayaran', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(selectedPaymentDate),
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Catatan opsional
                            TextFormField(
                              controller: notesController,
                              decoration: InputDecoration(
                                labelText: 'Catatan Realisasi (Opsional)',
                                hintText: 'e.g. Termasuk denda / diskon',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                prefixIcon: Icon(Icons.notes_rounded, color: Colors.grey.shade400, size: 20),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.check_rounded, size: 20),
                                    label: const Text('Konfirmasi Bayar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    onPressed: () => Navigator.pop(ctx, true),
                                  ),
                                ),
                              ],
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
        },
      );

      if (confirm == true) {
        final enteredNotes = notesController.text.trim();
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tagihan "${bill.name}" berhasil dibayar!'), backgroundColor: Colors.green));
        }
      }
    } else {
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status tagihan "${bill.name}" dikembalikan ke Belum Dibayar.'), backgroundColor: Colors.orange));
        }
      }
    }
  }
  Widget _monthNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: LsCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, size: 26, color: LsColors.ink(context)),
              onPressed: _prevMonth,
            ),
            Text(
              DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonthDate),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: LsColors.ink(context)),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, size: 26, color: LsColors.ink(context)),
              onPressed: _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LsEyebrow(label, color: Colors.white70),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(NumberFormat fmt, int paidCount, int totalCount, double totalAmount, double totalRealization, double totalRemaining) {
    final progress = totalCount > 0 ? paidCount / totalCount : 0.0;
    return LsHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LsEyebrow('Sisa Tagihan', color: Colors.white70),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rp ${fmt.format(totalRemaining.toInt())}',
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroStat('Total Rencana', 'Rp ${fmt.format(totalAmount.toInt())}'),
              const SizedBox(width: 10),
              _heroStat('Total Realisasi', 'Rp ${fmt.format(totalRealization.toInt())}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$paidCount / $totalCount tagihan dibayar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(LsColors.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueChip(Bill bill) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    final days = due.difference(today).inDays;
    if (days < 0) return const LsChip('Terlambat', color: LsColors.expense);
    if (days == 0) return const LsChip('Hari ini', color: LsColors.amber);
    return LsChip('$days hari lagi', color: days <= 3 ? LsColors.amber : LsColors.brand);
  }

  Widget _amountCol(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LsEyebrow(label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _billCard(BuildContext context, Bill bill, NumberFormat currencyFmt) {
    final isPaid = bill.isPaid;
    final realization = bill.realizationAmount ?? 0.0;
    final diff = realization - bill.amount;
    final remaining = (bill.amount - realization).clamp(0.0, double.infinity);
    final mute = LsColors.mute(context);

    Widget? diffChip;
    if (isPaid) {
      if (diff > 0) {
        diffChip = LsChip('Kelebihan: Rp ${currencyFmt.format(diff.toInt())}', color: LsColors.expense);
      } else if (diff < 0) {
        diffChip = LsChip('Hemat: Rp ${currencyFmt.format(diff.abs().toInt())}', color: LsColors.income);
      } else {
        diffChip = const LsChip('Sesuai Rencana', color: LsColors.brand);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleBillToggle(bill),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isPaid ? LsColors.income : mute).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isPaid ? LsColors.income : mute,
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
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            decoration: isPaid ? TextDecoration.lineThrough : null,
                            color: isPaid ? mute : LsColors.ink(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Jatuh Tempo: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(bill.dueDate)}',
                          style: TextStyle(fontSize: 12, color: mute),
                        ),
                        if (bill.paidAt != null)
                          Text(
                            'Dibayar: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(bill.paidAt!)}',
                            style: const TextStyle(fontSize: 11, color: LsColors.income, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: mute),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            Icon(Icons.copy_rounded, size: 18, color: LsColors.brand),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (isPaid) const LsChip('Sudah Dibayar', color: LsColors.income) else ...[
                    const LsChip('Belum Dibayar', color: LsColors.expense),
                    _dueChip(bill),
                  ],
                  if (diffChip != null) diffChip,
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LsColors.paper(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _amountCol(context, 'Rencana', 'Rp ${currencyFmt.format(bill.amount.toInt())}', LsColors.ink(context)),
                    _amountCol(context, 'Realisasi', 'Rp ${currencyFmt.format(realization.toInt())}', LsColors.income),
                    if (!isPaid)
                      _amountCol(context, 'Sisa Tagihan', 'Rp ${currencyFmt.format(remaining.toInt())}', LsColors.expense),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsStreamProvider(_currentMonthKey));
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.surface(context),
        elevation: 0,
        surfaceTintColor: LsColors.surface(context),
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Image.asset(
            AppEnvironment.config.getLogoFullPath(isDark),
            width: 175,
            height: 42,
            cacheWidth: 525,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Text(
              AppEnvironment.config.appName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LsColors.brand, letterSpacing: -0.5),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_bill_fab',
        backgroundColor: LsColors.brand,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditBillPage(initialMonth: _currentMonthKey),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tagihan Baru', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _monthNav(context),
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
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(color: LsColors.brand.withValues(alpha: 0.12), shape: BoxShape.circle),
                            child: const Icon(Icons.receipt_long_outlined, size: 40, color: LsColors.brand),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tagihan di bulan ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonthDate)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: LsColors.ink(context)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('Klik "+ Tagihan Baru" untuk mencatatkan tagihan bulanan.', style: TextStyle(fontSize: 13, color: LsColors.mute(context)), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                final paidCount = bills.where((b) => b.isPaid).length;
                final totalCount = bills.length;
                final totalAmount = bills.fold(0.0, (s, b) => s + b.amount);
                final totalRealization = bills.fold(0.0, (s, b) => s + (b.realizationAmount ?? 0.0));
                final totalRemaining = bills
                    .where((b) => !b.isPaid)
                    .fold(0.0, (s, b) => s + (b.amount - (b.realizationAmount ?? 0.0)).clamp(0.0, double.infinity));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  children: [
                    _hero(currencyFmt, paidCount, totalCount, totalAmount, totalRealization, totalRemaining),
                    const SizedBox(height: 20),
                    const LsSectionHeader(title: 'Daftar Tagihan'),
                    const SizedBox(height: 12),
                    for (final bill in bills) _billCard(context, bill, currencyFmt),
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
