import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_financial_note_page.dart';
import 'package:lifesync_app/presentation/pages/financial_note_detail_page.dart';
import 'package:lifesync_app/presentation/pages/bills_page.dart';

class FinancialRecordsHomePage extends ConsumerStatefulWidget {
  const FinancialRecordsHomePage({super.key});

  @override
  ConsumerState<FinancialRecordsHomePage> createState() => _FinancialRecordsHomePageState();
}

class _FinancialRecordsHomePageState extends ConsumerState<FinancialRecordsHomePage> {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');

  String _formatAmount(double amount) => 'Rp ${_fmt.format(amount.toInt())}';

  Future<void> _pickDate(BuildContext context) async {
    final filter = ref.read(noteFilterProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(noteFilterProvider.notifier).state = filter.copyWith(
        mode: NoteFilterMode.specificDate,
        selectedDate: picked,
      );
    }
  }

  String _getFilterLabel(NoteFilterMode mode) {
    switch (mode) {
      case NoteFilterMode.all:
        return 'Semua';
      case NoteFilterMode.specificDate:
        return 'Hari Tertentu';
      case NoteFilterMode.weekly:
        return 'Mingguan';
      case NoteFilterMode.monthly:
        return 'Bulanan';
    }
  }

  void _showNewNoteTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  const Text(
                    'Pilih Jenis Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note, color: Color(0xFF2563EB), size: 24),
                ),
                title: const Text('Transaksi Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Catat transaksi umum/pemasukan/pengeluaran harian', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditFinancialNotePage()));
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 24),
                ),
                title: const Text('Transaksi Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Pilih tagihan yang sudah dibayar untuk dicatatkan', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBillTransactionSelectorSheet(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBillTransactionSelectorSheet(BuildContext context) async {
    final billRepo = ref.read(billRepositoryProvider);
    final isar = ref.read(databaseServiceProvider).db;

    final paidBills = await billRepo.getPaidBills();

    if (paidBills.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Belum Ada Tagihan Dibayar'),
            content: const Text('Belum ada tagihan dengan status sudah dibayar atau memiliki realisasi pembayaran.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
            ],
          ),
        );
      }
      return;
    }

    // Cek item mana saja yang sudah pernah dicatat ke Keuangan
    final Map<int, bool> recordedMap = {};
    for (var b in paidBills) {
      final tag = '[Bill#${b.id}]';
      final existing = await isar.financialItems.filter().descriptionStartsWith(tag).findAll();
      recordedMap[b.id] = existing.isNotEmpty;
    }

    final Set<int> selectedBillIds = {};

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            final currencyFmt = NumberFormat('#,###', 'id_ID');

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Transaksi Tagihan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const Text(
                    'Pilih tagihan yang sudah dibayar untuk dicatatkan ke Keuangan:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: paidBills.length,
                      itemBuilder: (lCtx, idx) {
                        final b = paidBills[idx];
                        final isRecorded = recordedMap[b.id] ?? false;
                        final isSelected = selectedBillIds.contains(b.id) || isRecorded;
                        final realization = b.realizationAmount ?? b.amount;
                        final dateStr = DateFormat('d MMM yyyy', 'id_ID').format(b.paidAt ?? b.dueDate);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isRecorded ? Colors.green.shade200 : (isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200),
                              width: 1.5,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            enabled: !isRecorded, // Nonaktifkan jika sudah dicatat agar tidak duplikat
                            activeColor: isRecorded ? Colors.green : const Color(0xFF2563EB),
                            title: Text(
                              b.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text('Realisasi: Rp ${currencyFmt.format(realization.toInt())}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Dibayar: $dateStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                if (isRecorded) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('✓ Sudah dicatat ke Keuangan', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            onChanged: isRecorded ? null : (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedBillIds.add(b.id);
                                } else {
                                  selectedBillIds.remove(b.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: selectedBillIds.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(sheetCtx);
                              await _recordSelectedBillsToFinancialNotes(context, paidBills.where((b) => selectedBillIds.contains(b.id)).toList());
                            },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text('Catat Transaksi (${selectedBillIds.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _recordSelectedBillsToFinancialNotes(BuildContext context, List<Bill> selectedBills) async {
    final isar = ref.read(databaseServiceProvider).db;

    int recordedCount = 0;

    for (var bill in selectedBills) {
      final billTag = '[Bill#${bill.id}]';
      final date = bill.paidAt ?? bill.dueDate;
      final dateOnly = DateTime(date.year, date.month, date.day);

      await isar.writeTxn(() async {
        // Cari/buat FinancialNote untuk tanggal ini
        var notes = await isar.financialNotes.filter().dateEqualTo(dateOnly).findAll();
        FinancialNote targetNote;
        if (notes.isNotEmpty) {
          targetNote = notes.first;
        } else {
          targetNote = FinancialNote()
            ..title = 'Catatan Keuangan ${date.day}/${date.month}/${date.year}'
            ..date = dateOnly
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          final noteId = await isar.financialNotes.put(targetNote);
          targetNote.id = noteId;
        }

        // Cek apakah item dengan tag ini sudah ada (mencegah duplikasi)
        final existingItems = await isar.financialItems
            .filter()
            .descriptionStartsWith(billTag)
            .findAll();

        if (existingItems.isEmpty) {
          final newItem = FinancialItem()
            ..noteId = targetNote.id
            ..description = '$billTag ${bill.name}' // Default title = Nama Tagihan (editable oleh pengguna!)
            ..amount = bill.realizationAmount ?? bill.amount
            ..type = 'expense'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.financialItems.put(newItem);
          recordedCount++;
        }
      });
    }

    ref.invalidate(financialNotesNotifierProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$recordedCount transaksi tagihan berhasil dicatat ke Keuangan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(noteFilterProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final summary = ref.watch(filteredSummaryProvider);
    final notesAsync = ref.watch(financialNotesNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(25),
        surfaceTintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titleSpacing: 20,
        title: Image.asset(
          'assets/images/logofull.png',
          width: 140,
          cacheWidth: 420,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const Text(
            'LifeSync',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: -0.5),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFF2563EB).withAlpha(15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsPage()));
              },
              icon: const Icon(Icons.receipt_long, size: 20),
              label: const Text('Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'financial_note_fab',
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showNewNoteTypeSelector(context),
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Catatan Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (_) => Column(
          children: [
            // ── Single Filter Dropdown Bar ─────────────────────────────────
            _buildFilterBar(filter, isDark, context),

            // ── Period Summary (Total Pemasukan, Total Pengeluaran, Saldo) ──
            _buildSummaryHeader(summary, isDark),

            // ── Notes List ─────────────────────────────────────────────────
            Expanded(
              child: filteredNotes.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, i) {
                        final noteItem = filteredNotes[i];
                        return _buildNoteCard(noteItem, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(FilterState filter, bool isDark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 20, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              const SizedBox(width: 8),
              Text(
                'Saring berdasarkan:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2563EB).withAlpha(60)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<NoteFilterMode>(
                value: filter.mode,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2563EB)),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                onChanged: (mode) {
                  if (mode == null) return;
                  if (mode == NoteFilterMode.specificDate) {
                    _pickDate(context);
                  } else {
                    ref.read(noteFilterProvider.notifier).state = filter.copyWith(mode: mode);
                  }
                },
                items: NoteFilterMode.values.map((mode) {
                  return DropdownMenuItem<NoteFilterMode>(
                    value: mode,
                    child: Text(_getFilterLabel(mode)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(FinancialSummary summary, bool isDark) {
    final netPositive = summary.netBalance >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          _summaryTile(_formatAmount(summary.totalIncome), 'Pemasukan', const Color(0xFF10B981), isDark),
          _vertDivider(isDark),
          _summaryTile(_formatAmount(summary.totalExpense), 'Pengeluaran', const Color(0xFFEF4444), isDark),
          _vertDivider(isDark),
          _summaryTile(
            '${netPositive ? '+' : '-'}${_formatAmount(summary.netBalance.abs())}',
            'Saldo Bersih',
            netPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String amount, String label, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _vertDivider(bool isDark) {
    return Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 4), color: isDark ? Colors.white10 : const Color(0xFFE2E8F0));
  }

  Widget _buildNoteCard(NoteWithItems noteItem, bool isDark) {
    final note = noteItem.note;
    final net = noteItem.netTotal;
    final netPositive = net >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FinancialNoteDetailPage(noteId: note.id)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: (netPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${netPositive ? '+' : '-'}${_formatAmount(net.abs())}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: netPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(note.date),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.list_alt, size: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    '${noteItem.itemCount} Item',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                  ),
                ],
              ),
              if (note.notes != null && note.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.notes!,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.white38 : Colors.black45),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 72, color: isDark ? Colors.white24 : const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan keuangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat catatan baru seperti di buku kas harian menggunakan tombol "+" di bawah',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
