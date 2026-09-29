import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/entities/daily_income_record.dart';
import 'package:lifesync_app/domain/usecases/target_calculation_usecase.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/pages/create_target_page.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/core/utils/thousands_formatter.dart';

class TargetDetailPage extends ConsumerStatefulWidget {
  final IncomeTarget target;

  const TargetDetailPage({super.key, required this.target});

  @override
  ConsumerState<TargetDetailPage> createState() => _TargetDetailPageState();
}

class _TargetDetailPageState extends ConsumerState<TargetDetailPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.isBefore(widget.target.startDate)) {
      _focusedDay = widget.target.startDate;
    } else if (now.isAfter(widget.target.endDate)) {
      _focusedDay = widget.target.endDate;
    } else {
      _focusedDay = now;
    }
    _selectedDay = _focusedDay;
  }

  Future<void> _deleteTarget(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target?'),
        content: const Text('Tindakan ini akan menghapus target beserta seluruh riwayat nabungnya secara permanen. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(targetRepositoryProvider).deleteTarget(widget.target.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, List<DailyIncomeRecord> records) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Pastikan tanggal berada dalam periode target
    final normalizedSelected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final normalizedStart = DateTime(widget.target.startDate.year, widget.target.startDate.month, widget.target.startDate.day);
    final normalizedEnd = DateTime(widget.target.endDate.year, widget.target.endDate.month, widget.target.endDate.day);

    if (normalizedSelected.isBefore(normalizedStart) || normalizedSelected.isAfter(normalizedEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal di luar periode menabung target ini')),
      );
      return;
    }

    // Cek apakah sudah ada transaksi pada tanggal ini
    DailyIncomeRecord? existingRecord;
    for (var r in records) {
      if (r.date.year == selectedDay.year && r.date.month == selectedDay.month && r.date.day == selectedDay.day) {
        existingRecord = r;
        break;
      }
    }

    if (widget.target.mode == 'fixed') {
      _showFixedModeDialog(context, ref, selectedDay, existingRecord);
    } else {
      _showFlexibleModeDialog(context, ref, selectedDay, existingRecord);
    }
  }

  void _showFixedModeDialog(BuildContext context, WidgetRef ref, DateTime day, DailyIncomeRecord? existingRecord) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(day);
    final isDone = existingRecord != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tanggal $dateStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDone ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDone ? Colors.green.shade200 : Colors.blue.shade200, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(isDone ? Icons.check_circle : Icons.info_outline, color: isDone ? Colors.green : const Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isDone ? 'Status: Sudah Menabung ✓' : 'Status: Belum Menabung', style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? Colors.green.shade800 : const Color(0xFF2563EB))),
                          const SizedBox(height: 4),
                          Text('Nominal Harian: Rp ${currencyFmt.format(widget.target.fixedDailyAmount.toInt())}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone ? Colors.red : const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final repo = ref.read(targetRepositoryProvider);
                    if (isDone) {
                      await repo.deleteRecord(existingRecord.id!);
                    } else {
                      final newRecord = DailyIncomeRecord()
                        ..targetId = widget.target.id!
                        ..incomeAmount = widget.target.fixedDailyAmount
                        ..date = DateTime(day.year, day.month, day.day)
                        ..notes = 'Nabung Tetap Harian';
                      await repo.saveRecord(newRecord);
                    }
                  },
                  icon: Icon(isDone ? Icons.cancel_outlined : Icons.check, color: Colors.white),
                  label: Text(
                    isDone ? 'Batalkan / Hapus Nabung' : 'Checklist / Tandai Sudah Menabung',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFlexibleModeDialog(BuildContext context, WidgetRef ref, DateTime day, DailyIncomeRecord? existingRecord) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(day);
    final amountController = TextEditingController(
      text: existingRecord != null ? currencyFmt.format(existingRecord.incomeAmount.toInt()) : '',
    );
    final notesController = TextEditingController(text: existingRecord?.notes ?? '');
    double inputAmount = existingRecord?.incomeAmount ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(existingRecord == null ? 'Catat Nabung - $dateStr' : 'Edit Nabung - $dateStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                readOnly: true,
                onTap: () async {
                  final val = await showCalculatorInputDialog(
                    context: context,
                    title: 'Input Nominal Nabung',
                    initialValue: inputAmount > 0 ? inputAmount : 0.0,
                  );
                  if (val != null && ctx.mounted) {
                    inputAmount = val;
                    amountController.text = currencyFmt.format(val.toInt());
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Nominal Tabungan (Rp)',
                  prefixText: 'Rp ',
                  suffixIcon: const Icon(Icons.calculate, color: Color(0xFF2563EB)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (existingRecord != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(targetRepositoryProvider).deleteRecord(existingRecord.id!);
                        },
                        child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (inputAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal harus lebih besar dari 0')));
                          return;
                        }
                        Navigator.pop(ctx);
                        final repo = ref.read(targetRepositoryProvider);
                        if (existingRecord != null) {
                          existingRecord
                            ..incomeAmount = inputAmount
                            ..notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                          await repo.saveRecord(existingRecord);
                        } else {
                          final newRecord = DailyIncomeRecord()
                            ..targetId = widget.target.id!
                            ..incomeAmount = inputAmount
                            ..date = DateTime(day.year, day.month, day.day)
                            ..notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                          await repo.saveRecord(newRecord);
                        }
                      },
                      child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(targetRecordsStreamProvider(widget.target.id!));
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(widget.target.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTargetPage(existingTarget: widget.target)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteTarget(context, ref),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          double totalCollected = records.fold(0.0, (sum, record) => sum + record.incomeAmount);
          double progress = (totalCollected / widget.target.targetAmount).clamp(0.0, 1.0);
          double remaining = (widget.target.targetAmount - totalCollected).clamp(0.0, double.infinity);

          final now = DateTime.now();
          TargetStatus status = TargetCalculationUseCase.determineTargetStatus(
            target: widget.target,
            collectedIncome: records,
            currentDate: now,
          );

          Color statusColor;
          String statusText;
          switch (status) {
            case TargetStatus.aheadOfSchedule:
              statusColor = Colors.green;
              statusText = 'Melebihi Target';
              break;
            case TargetStatus.onTrack:
              statusColor = Colors.blue;
              statusText = 'Sesuai Rencana';
              break;
            case TargetStatus.behindSchedule:
              statusColor = Colors.orange;
              statusText = 'Kurang dari Target';
              break;
            case TargetStatus.completed:
              statusColor = Colors.green;
              statusText = 'Tercapai!';
              break;
            case TargetStatus.failed:
              statusColor = Colors.red;
              statusText = 'Waktu Habis';
              break;
            case TargetStatus.notStarted:
              statusColor = Colors.grey;
              statusText = 'Belum Dimulai';
              break;
            case TargetStatus.active:
              statusColor = Colors.blue;
              statusText = 'Aktif';
              break;
          }

          // ── Target Period ──────────────────────────────────────────────
          final DateTime today = DateTime(
            now.year,
            now.month,
            now.day,
          );

          final DateTime startDate = DateTime(
            widget.target.startDate.year,
            widget.target.startDate.month,
            widget.target.startDate.day,
          );

          final DateTime endDate = DateTime(
            widget.target.endDate.year,
            widget.target.endDate.month,
            widget.target.endDate.day,
          );

// Status periode berdasarkan tanggal kalender
          final bool isNotStarted = today.isBefore(startDate);
          final bool isFinished = today.isAfter(endDate);

// Hari sampai target dimulai
          final int daysUntilStart = isNotStarted
              ? startDate.difference(today).inDays
              : 0;

// Hari tersisa dihitung dinamis dari sisa hari yang belum dichecklist / dikumpulkan
          final int daysLeft = TargetCalculationUseCase.calculateRemainingDays(
            target: widget.target,
            collectedIncome: records,
            currentDate: now,
          );

// Total hari dalam periode target
          final int totalDays =
              endDate.difference(startDate).inDays + 1;

          // Map records by normalized date for calendar markers
          final Map<DateTime, DailyIncomeRecord> recordMap = {};
          for (var r in records) {
            recordMap[DateTime(r.date.year, r.date.month, r.date.day)] = r;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Card ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.target.mode == 'fixed' ? Colors.teal.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.target.mode == 'fixed' ? 'Metode: Nominal Tetap' : 'Metode: Nominal Bebas',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.target.mode == 'fixed' ? Colors.teal.shade700 : const Color(0xFF2563EB)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rp ${currencyFmt.format(totalCollected.toInt())}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                          Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Target: Rp ${currencyFmt.format(widget.target.targetAmount.toInt())} (Sisa: Rp ${currencyFmt.format(remaining.toInt())})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Periode: ${DateFormat('dd MMM yyyy', 'id_ID').format(widget.target.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(widget.target.endDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          Text(
                            isNotStarted
                                ? 'Mulai dalam $daysUntilStart hari'
                                : isFinished
                                ? 'Periode selesai'
                                : '$daysLeft hari lagi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Interactive Calendar ─────────────────────────────────────
                const Text('Kalender Nabung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 8),
                Text(
                  widget.target.mode == 'fixed'
                      ? 'Ketuk tanggal untuk mencentang (checklist) setoran harian.'
                      : 'Ketuk tanggal untuk mencatat atau mengedit nominal tabungan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: TableCalendar(
                    firstDay: widget.target.startDate,
                    lastDay: widget.target.endDate,
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) => _onDaySelected(selectedDay, focusedDay, records),
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.3), shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focused) {
                        final norm = DateTime(day.year, day.month, day.day);
                        final hasRecord = recordMap.containsKey(norm);

                        if (hasRecord) {
                          return Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── History List ─────────────────────────────────────────────
                const Text('Riwayat Nabung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 10),
                if (records.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Belum ada riwayat tabungan tercatat.', style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final sortedRecords = List<DailyIncomeRecord>.from(records)..sort((a, b) => b.date.compareTo(a.date));
                      final record = sortedRecords[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.savings, color: Color(0xFF10B981), size: 20),
                          ),
                          title: Text('Rp ${currencyFmt.format(record.incomeAmount.toInt())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(record.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              if (record.notes != null && record.notes!.isNotEmpty)
                                Text(record.notes!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Hapus Catatan Nabung?'),
                                  content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(targetRepositoryProvider).deleteRecord(record.id!);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
