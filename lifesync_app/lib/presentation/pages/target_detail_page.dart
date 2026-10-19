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
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

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
            child: const Text('Hapus', style: TextStyle(color: LsColors.expense)),
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
      backgroundColor: LsColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                  Text('Tanggal $dateStr', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LsColors.ink(ctx))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDone ? LsColors.income : LsColors.brand).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (isDone ? LsColors.income : LsColors.brand).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(isDone ? Icons.check_circle : Icons.info_outline, color: isDone ? LsColors.income : LsColors.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isDone ? 'Status: Sudah Menabung ✓' : 'Status: Belum Menabung', style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? LsColors.income : LsColors.brand)),
                          const SizedBox(height: 4),
                          Text('Nominal Harian: Rp ${currencyFmt.format(widget.target.fixedDailyAmount.toInt())}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: LsColors.ink(ctx))),
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
                    backgroundColor: isDone ? LsColors.expense : LsColors.income,
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
      backgroundColor: LsColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                  Text(existingRecord == null ? 'Catat Nabung - $dateStr' : 'Edit Nabung - $dateStr', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LsColors.ink(ctx))),
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
                  fillColor: LsColors.paper(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LsColors.line(context))),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  filled: true,
                  fillColor: LsColors.paper(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LsColors.line(context))),
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
                          foregroundColor: LsColors.expense,
                          side: const BorderSide(color: LsColors.expense, width: 1.5),
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
                        backgroundColor: LsColors.brand,
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

  Widget _deleteRecordButton(DailyIncomeRecord record) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: LsColors.expense, size: 20),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Hapus Catatan Nabung?'),
            content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: LsColors.expense))),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(targetRepositoryProvider).deleteRecord(record.id!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(targetRecordsStreamProvider(widget.target.id!));
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final ink = LsColors.ink(context);
    final mute = LsColors.mute(context);

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.paper(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: ink),
        title: Text(widget.target.name, style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: ink)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: LsColors.brand),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTargetPage(existingTarget: widget.target)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: LsColors.expense),
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
              statusColor = LsColors.income;
              statusText = 'Melebihi Target';
              break;
            case TargetStatus.onTrack:
              statusColor = LsColors.brand;
              statusText = 'Sesuai Rencana';
              break;
            case TargetStatus.behindSchedule:
              statusColor = LsColors.amber;
              statusText = 'Kurang dari Target';
              break;
            case TargetStatus.completed:
              statusColor = LsColors.income;
              statusText = 'Tercapai!';
              break;
            case TargetStatus.failed:
              statusColor = LsColors.expense;
              statusText = 'Waktu Habis';
              break;
            case TargetStatus.notStarted:
              statusColor = mute;
              statusText = 'Belum Dimulai';
              break;
            case TargetStatus.active:
              statusColor = LsColors.brand;
              statusText = 'Aktif';
              break;
          }

          // ── Target Period ──────────────────────────────────────────────
          final DateTime today = DateTime(now.year, now.month, now.day);
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
          final int daysUntilStart = isNotStarted ? startDate.difference(today).inDays : 0;

          // Hari tersisa dihitung dinamis dari sisa hari yang belum dichecklist / dikumpulkan
          final int daysLeft = TargetCalculationUseCase.calculateRemainingDays(
            target: widget.target,
            collectedIncome: records,
            currentDate: now,
          );

          // Rekomendasi nabung harian
          final bool isFixed = widget.target.mode == 'fixed';
          final double dailyRecommendation = isFixed
              ? widget.target.fixedDailyAmount
              : (daysLeft > 0 ? remaining / daysLeft : remaining);
          final bool showRecommendation = remaining > 0 && !isFinished && status != TargetStatus.completed;

          // Map records by normalized date for calendar markers
          final Map<DateTime, DailyIncomeRecord> recordMap = {};
          for (var r in records) {
            recordMap[DateTime(r.date.year, r.date.month, r.date.day)] = r;
          }

          final sortedRecords = List<DailyIncomeRecord>.from(records)..sort((a, b) => b.date.compareTo(a.date));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Card ────────────────────────────────────────────────
                LsHeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isFixed ? 'Nominal Tetap' : 'Nominal Bebas',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          LsRing(
                            progress: progress,
                            size: 112,
                            stroke: 10,
                            color: LsColors.income,
                            child: Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LsEyebrow('Terkumpul', color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Rp ${currencyFmt.format(totalCollected.toInt())}',
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.05, color: Colors.white, letterSpacing: -0.8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LsEyebrow('Target', color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(height: 2),
                                Text(
                                  'Rp ${currencyFmt.format(widget.target.targetAmount.toInt())}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sisa: Rp ${currencyFmt.format(remaining.toInt())}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.75)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (showRecommendation) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tips_and_updates_outlined, size: 18, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sisihkan Rp ${currencyFmt.format(dailyRecommendation.round())} hari ini',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${DateFormat('dd MMM yyyy', 'id_ID').format(widget.target.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(widget.target.endDate)}',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isNotStarted
                                ? 'Mulai dalam $daysUntilStart hari'
                                : isFinished
                                    ? 'Periode selesai'
                                    : '$daysLeft hari lagi',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Interactive Calendar ─────────────────────────────────────
                const LsSectionHeader(title: 'Kalender Nabung'),
                const SizedBox(height: 8),
                Text(
                  isFixed
                      ? 'Ketuk tanggal untuk mencentang (checklist) setoran harian.'
                      : 'Ketuk tanggal untuk mencatat atau mengedit nominal tabungan.',
                  style: TextStyle(fontSize: 12, color: mute),
                ),
                const SizedBox(height: 12),
                LsCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
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
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mute),
                      weekendStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mute),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, color: ink),
                      weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, color: ink),
                      outsideTextStyle: TextStyle(color: mute.withValues(alpha: 0.5)),
                      disabledTextStyle: TextStyle(color: mute.withValues(alpha: 0.4)),
                      todayTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: LsColors.brand),
                      selectedTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                      todayDecoration: BoxDecoration(color: LsColors.brand.withValues(alpha: 0.14), shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(color: LsColors.brand, shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(color: LsColors.income, shape: BoxShape.circle),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink),
                      leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: LsColors.brand),
                      rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: LsColors.brand),
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
                                color: LsColors.income.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: LsColors.income, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: LsColors.income),
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
                const LsSectionHeader(title: 'Riwayat Nabung'),
                const SizedBox(height: 12),
                if (records.isEmpty)
                  LsCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('Belum ada riwayat tabungan tercatat.', style: TextStyle(color: mute)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedRecords.length,
                    itemBuilder: (context, index) {
                      final record = sortedRecords[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LsCard(
                          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: LsColors.income.withValues(alpha: 0.14), shape: BoxShape.circle),
                                child: const Icon(Icons.savings, color: LsColors.income, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rp ${currencyFmt.format(record.incomeAmount.toInt())}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ink)),
                                    const SizedBox(height: 2),
                                    Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(record.date), style: TextStyle(fontSize: 12, color: mute)),
                                    if (record.notes != null && record.notes!.isNotEmpty)
                                      Text(record.notes!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: mute)),
                                  ],
                                ),
                              ),
                              _deleteRecordButton(record),
                            ],
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
