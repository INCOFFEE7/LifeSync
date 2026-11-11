import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_financial_note_page.dart';
import 'package:lifesync_app/presentation/widgets/custom_numeric_keypad.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:lifesync_app/presentation/widgets/ls_date_time_picker_sheet.dart';

class FinancialNoteDetailPage extends ConsumerStatefulWidget {
  final int noteId;

  const FinancialNoteDetailPage({super.key, required this.noteId});

  @override
  ConsumerState<FinancialNoteDetailPage> createState() =>
      _FinancialNoteDetailPageState();
}

class _FinancialNoteDetailPageState
    extends ConsumerState<FinancialNoteDetailPage> {
  // ── Helper: Evaluate expression string to double ──────────────────────────
  double _evaluateExpr(String expr) {
    try {
      String sanitized =
          expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');
      if (sanitized.isEmpty) return 0.0;

      List<String> tokens = [];
      String currentNum = '';

      for (int i = 0; i < sanitized.length; i++) {
        String char = sanitized[i];
        if (char == '+' ||
            char == '×' ||
            char == '*' ||
            char == '÷' ||
            char == '/') {
          if (currentNum.isNotEmpty) {
            tokens.add(currentNum);
            currentNum = '';
          }
          tokens.add(char);
        } else if (char == '-') {
          if (currentNum.isEmpty &&
              (tokens.isEmpty ||
                  tokens.last == '+' ||
                  tokens.last == '-' ||
                  tokens.last == '*' ||
                  tokens.last == '/')) {
            currentNum += char;
          } else {
            if (currentNum.isNotEmpty) {
              tokens.add(currentNum);
              currentNum = '';
            }
            tokens.add('-');
          }
        } else {
          currentNum += char;
        }
      }
      if (currentNum.isNotEmpty) {
        tokens.add(currentNum);
      }

      if (tokens.isEmpty) return 0.0;

      for (int i = 1; i < tokens.length - 1; i += 2) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double left = double.parse(tokens[i - 1]);
          double right = double.parse(tokens[i + 1]);
          double res = tokens[i] == '*'
              ? (left * right)
              : (right == 0 ? 0 : left / right);
          tokens[i - 1] = res.toString();
          tokens.removeAt(i);
          tokens.removeAt(i);
          i -= 2;
        }
      }

      double total = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length - 1; i += 2) {
        String op = tokens[i];
        double nextNum = double.parse(tokens[i + 1]);
        if (op == '+')
          total += nextNum;
        else if (op == '-') total -= nextNum;
      }
      return total;
    } catch (_) {
      return double.tryParse(expr.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }
  }

  bool _hasOperator(String expr) {
    return expr.contains('+') ||
        expr.contains('-') ||
        expr.contains('×') ||
        expr.contains('÷');
  }

  String _formatCurrency(double val) {
    final fmt = NumberFormat('#,###', 'id_ID');
    if (val == 0) return 'Rp 0';
    if (val < 0) return '-Rp ${fmt.format(val.abs().toInt())}';
    return 'Rp ${fmt.format(val.toInt())}';
  }

  void _showQuickAddItemDialog(int noteId, DateTime noteDate) {
    final descController = TextEditingController();
    String calcExpr = '0';
    String type = 'expense';
    DateTime itemTimestamp = DateTime.now();
    bool showKeypad = false;
    String? descError;
    String? nominalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final evaluated = _evaluateExpr(calcExpr);
            final formattedAmt = _formatCurrency(evaluated);
            final showExpr = _hasOperator(calcExpr);

            void onKeyPress(String k) {
              setModalState(() {
                if (nominalError != null) nominalError = null;
                if (k == 'C') {
                  calcExpr = '0';
                  return;
                }
                if (calcExpr == '0' &&
                    k != '.' &&
                    k != '+' &&
                    k != '-' &&
                    k != '×' &&
                    k != '÷') {
                  calcExpr = k;
                  return;
                }
                final last = calcExpr[calcExpr.length - 1];
                final isOp = (String c) =>
                    c == '+' || c == '-' || c == '×' || c == '÷' || c == '.';
                if (isOp(k) && isOp(last)) {
                  calcExpr = calcExpr.substring(0, calcExpr.length - 1) + k;
                  return;
                }
                if (calcExpr.length < 24) calcExpr += k;
              });
            }

            void onDelete() {
              setModalState(() {
                if (nominalError != null) nominalError = null;
                if (calcExpr.length > 1) {
                  calcExpr = calcExpr.substring(0, calcExpr.length - 1);
                } else {
                  calcExpr = '0';
                }
              });
            }

            void onEquals() {
              setModalState(() {
                calcExpr = evaluated.toInt().toString();
              });
            }

            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 20,
                  left: 20,
                  right: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tambah Item Transaksi',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: LsColors.paper(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LsColors.line(context)),
                      ),
                      child: Row(
                        children: [
                          for (final opt in const [
                            ['expense', 'Pengeluaran'],
                            ['income', 'Pemasukan']
                          ])
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => type = opt[0]),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: type == opt[0]
                                        ? (opt[0] == 'income'
                                            ? LsColors.income
                                            : LsColors.expense)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Text(
                                    opt[1],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: type == opt[0]
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      onTap: () {
                        if (showKeypad) setModalState(() => showKeypad = false);
                      },
                      onChanged: (val) {
                        if (descError != null)
                          setModalState(() => descError = null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Nama Item Transaksi *',
                        errorText: descError,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Waktu Transaksi Item',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID')
                            .format(itemTimestamp),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.access_time_filled,
                          color: Color(0xFF2563EB), size: 20),
                      onTap: () async {
                        final picked = await showLsDateTimePickerSheet(
                          context: context,
                          initialDateTime: itemTimestamp,
                          enableTime: true,
                          title: 'Pilih Tanggal & Waktu Item',
                          confirmLabel: 'Atur Waktu',
                        );
                        if (picked != null && mounted) {
                          setModalState(() {
                            itemTimestamp = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setModalState(() {
                          showKeypad = true;
                          if (nominalError != null) nominalError = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: nominalError != null
                                  ? const Color(0xFFEF4444)
                                  : (showKeypad
                                      ? (type == 'income'
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      : Colors.transparent),
                              width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text('NOMINAL',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            if (showExpr) ...[
                              Text(
                                calcExpr,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(formattedAmt,
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: type == 'income'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ),
                    if (nominalError != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          nominalError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (showKeypad) ...[
                      const SizedBox(height: 12),
                      CustomNumericKeypad(
                        onKeyPress: onKeyPress,
                        onDelete: onDelete,
                        onEquals: onEquals,
                        onClose: () => setModalState(() => showKeypad = false),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type == 'income'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final desc = descController.text.trim();
                        final finalVal = _evaluateExpr(calcExpr);
                        bool hasError = false;
                        if (desc.isEmpty) {
                          descError = 'Nama item transaksi wajib diisi!';
                          hasError = true;
                        }
                        if (finalVal <= 0) {
                          nominalError =
                              'Nominal transaksi harus lebih dari 0!';
                          hasError = true;
                        }
                        if (hasError) {
                          setModalState(() {});
                          return;
                        }

                        final confirm = await showLsConfirmDialog(
                          context: context,
                          title: 'Tambah Item Transaksi',
                          message:
                              'Apakah Anda yakin ingin menambahkan transaksi "$desc"?',
                        );
                        if (!confirm) return;

                        final item = FinancialItem()
                          ..noteId = noteId
                          ..description = desc
                          ..amount = finalVal
                          ..type = type
                          ..createdAt = itemTimestamp
                          ..updatedAt = itemTimestamp;

                        await ref
                            .read(financialNotesNotifierProvider.notifier)
                            .addItemToNote(item);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('+ Tambah ke Catatan Ini',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showItemHistoryModal(BuildContext context, FinancialItem item) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final isEdited = item.updatedAt.isAfter(item.createdAt) &&
        item.updatedAt.difference(item.createdAt).inSeconds > 5;
    final isIncome = item.type == 'income';
    final sign = isIncome ? '+' : '-';
    final c = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 22, color: LsColors.brand),
                  const SizedBox(width: 8),
                  Text(
                    'Riwayat Transaksi Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LsColors.ink(ctx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LsColors.ink(ctx),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule,
                        size: 14, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dibuat Pertama Kali',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          DateFormat('dd MMMM yyyy, HH:mm', 'id_ID')
                              .format(item.createdAt),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (item.previousAmount != null)
                          Text(
                            'Nominal Awal: $sign Rp ${currencyFmt.format(item.previousAmount!.toInt())}',
                            style: TextStyle(
                                fontSize: 12, color: LsColors.mute(ctx)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isEdited) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 11),
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                        width: 1, thickness: 1, color: Colors.grey),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Terakhir Diedit',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w600)),
                          Text(
                            DateFormat('dd MMMM yyyy, HH:mm', 'id_ID')
                                .format(item.updatedAt),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Nominal Saat Ini: $sign Rp ${currencyFmt.format(item.amount.toInt())}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: c),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteNote(int noteId) async {
    final confirm = await showLsConfirmDialog(
      context: context,
      title: 'Hapus Catatan?',
      message:
          'Seluruh item transaksi dalam catatan ini akan ikut terhapus. Lanjutkan?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDanger: true,
    );
    if (confirm) {
      await ref
          .read(financialNotesNotifierProvider.notifier)
          .deleteNote(noteId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    final notesAsync = ref.watch(financialNotesNotifierProvider);

    return notesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (allNotes) {
        final noteItem = allNotes.firstWhere(
          (n) => n.note.id == widget.noteId,
          orElse: () => NoteWithItems(note: FinancialNote(), items: []),
        );

        if (noteItem.note.id == 0) {
          return const Scaffold(
              body: Center(child: Text('Catatan tidak ditemukan')));
        }

        final note = noteItem.note;
        final items = noteItem.items;

        final net = noteItem.netTotal;
        return Scaffold(
          backgroundColor: LsColors.paper(context),
          appBar: AppBar(
            title: Text(note.title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: LsColors.surface(context),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            shape: Border(bottom: BorderSide(color: LsColors.line(context))),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddEditFinancialNotePage(existingNote: noteItem)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: LsColors.expense),
                onPressed: () => _confirmDeleteNote(note.id),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LsHeroCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEEE, d MMMM yyyy, HH:mm',
                                              'id_ID')
                                          .format(note.date),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              LsEyebrow('Total Catatan (${items.length} Item)',
                                  color: Colors.white70),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${net < 0 ? '-' : ''}Rp ${currencyFmt.format(net.abs().toInt())}',
                                  style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                      letterSpacing: -1,
                                      color: Colors.white),
                                ),
                              ),
                              if (note.notes != null &&
                                  note.notes!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  note.notes!,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                      color: Colors.white70),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                                child: LsSectionHeader(
                                    title:
                                        'Daftar Transaksi (${items.length})')),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LsColors.brand,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () =>
                                  _showQuickAddItemDialog(note.id, note.date),
                              icon: const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                              label: const Text('Tambah',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          LsCard(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                  'Belum ada item transaksi dalam catatan ini',
                                  style:
                                      TextStyle(color: LsColors.mute(context))),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final item = items[idx];
                              final isIncome = item.type == 'income';
                              final c =
                                  isIncome ? LsColors.income : LsColors.expense;
                              return LsCard(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 4, 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                          color: c.withValues(alpha: 0.14),
                                          shape: BoxShape.circle),
                                      child: Icon(
                                          isIncome
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: c,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showItemHistoryModal(
                                            context, item),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.description,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: LsColors.ink(context)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: DateFormat(
                                                            'dd MMM yyyy, HH:mm',
                                                            'id_ID')
                                                        .format(item.createdAt),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: LsColors.mute(
                                                            context)),
                                                  ),
                                                  if (item.updatedAt.isAfter(
                                                          item.createdAt) &&
                                                      item.updatedAt
                                                              .difference(item
                                                                  .createdAt)
                                                              .inSeconds >
                                                          5) ...[
                                                    const TextSpan(text: '  '),
                                                    TextSpan(
                                                      text:
                                                          '• Diedit: ${DateFormat('dd MMM, HH:mm', 'id_ID').format(item.updatedAt)}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color:
                                                            Color(0xFFF59E0B),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${isIncome ? '+' : '-'} Rp ${currencyFmt.format(item.amount.toInt())}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: c),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18,
                                          color: LsColors.mute(context)),
                                      onPressed: () async {
                                        final confirm =
                                            await showLsConfirmDialog(
                                          context: context,
                                          title: 'Hapus Item Transaksi',
                                          message:
                                              'Apakah Anda yakin ingin menghapus item transaksi "${item.description}"?',
                                          confirmLabel: 'Hapus',
                                          isDanger: true,
                                        );
                                        if (confirm) {
                                          await ref
                                              .read(
                                                  financialNotesNotifierProvider
                                                      .notifier)
                                              .deleteItem(item.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
