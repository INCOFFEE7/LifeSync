import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/pages/add_edit_financial_note_page.dart';
import 'package:lifesync_app/presentation/widgets/custom_numeric_keypad.dart';

class FinancialNoteDetailPage extends ConsumerStatefulWidget {
  final int noteId;

  const FinancialNoteDetailPage({super.key, required this.noteId});

  @override
  ConsumerState<FinancialNoteDetailPage> createState() => _FinancialNoteDetailPageState();
}

class _FinancialNoteDetailPageState extends ConsumerState<FinancialNoteDetailPage> {

  // ── Helper: Evaluate expression string to double ──────────────────────────
  double _evaluateExpr(String expr) {
    try {
      String sanitized = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');
      if (sanitized.isEmpty) return 0.0;

      List<String> tokens = [];
      String currentNum = '';

      for (int i = 0; i < sanitized.length; i++) {
        String char = sanitized[i];
        if (char == '+' || char == '×' || char == '*' || char == '÷' || char == '/') {
          if (currentNum.isNotEmpty) {
            tokens.add(currentNum);
            currentNum = '';
          }
          tokens.add(char);
        } else if (char == '-') {
          if (currentNum.isEmpty && (tokens.isEmpty || tokens.last == '+' || tokens.last == '-' || tokens.last == '*' || tokens.last == '/')) {
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
          double res = tokens[i] == '*' ? (left * right) : (right == 0 ? 0 : left / right);
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
        if (op == '+') total += nextNum;
        else if (op == '-') total -= nextNum;
      }
      return total;
    } catch (_) {
      return double.tryParse(expr.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }
  }

  bool _hasOperator(String expr) {
    return expr.contains('+') || expr.contains('-') || expr.contains('×') || expr.contains('÷');
  }

  String _formatCurrency(double val) {
    final fmt = NumberFormat('#,###', 'id_ID');
    if (val == 0) return 'Rp 0';
    if (val < 0) return '-Rp ${fmt.format(val.abs().toInt())}';
    return 'Rp ${fmt.format(val.toInt())}';
  }

  void _showQuickAddItemDialog(int noteId) {
    final descController = TextEditingController();
    String calcExpr = '0';
    String type = 'expense';
    DateTime itemTimestamp = DateTime.now();
    bool showKeypad = false;

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
                if (k == 'C') {
                  calcExpr = '0';
                  return;
                }
                if (calcExpr == '0' && k != '.' && k != '+' && k != '-' && k != '×' && k != '÷') {
                  calcExpr = k;
                  return;
                }
                final last = calcExpr[calcExpr.length - 1];
                final isOp = (String c) => c == '+' || c == '-' || c == '×' || c == '÷' || c == '.';
                if (isOp(k) && isOp(last)) {
                  calcExpr = calcExpr.substring(0, calcExpr.length - 1) + k;
                  return;
                }
                if (calcExpr.length < 24) calcExpr += k;
              });
            }

            void onDelete() {
              setModalState(() {
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tambah Item Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pengeluaran')),
                            selected: type == 'expense',
                            selectedColor: const Color(0xFFEF4444),
                            labelStyle: TextStyle(color: type == 'expense' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold),
                            onSelected: (sel) { if (sel) setModalState(() => type = 'expense'); },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pemasukan')),
                            selected: type == 'income',
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(color: type == 'income' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold),
                            onSelected: (sel) { if (sel) setModalState(() => type = 'income'); },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      onTap: () { if (showKeypad) setModalState(() => showKeypad = false); },
                      decoration: InputDecoration(
                        labelText: 'Nama Item Transaksi *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Waktu Transaksi Item', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(itemTimestamp),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.access_time_filled, color: Color(0xFF2563EB), size: 20),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: itemTimestamp,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (pickedDate != null && mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(itemTimestamp),
                          );
                          final time = pickedTime ?? TimeOfDay.fromDateTime(itemTimestamp);
                          setModalState(() {
                            itemTimestamp = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, time.hour, time.minute);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setModalState(() => showKeypad = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: showKeypad ? (type == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : Colors.transparent, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text('NOMINAL', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            if (showExpr) ...[
                              Text(
                                calcExpr,
                                style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(formattedAmt, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: type == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ),
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
                        backgroundColor: type == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final desc = descController.text.trim();
                        final finalVal = _evaluateExpr(calcExpr);
                        if (desc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama item transaksi wajib diisi!')),
                          );
                          return;
                        }
                        if (finalVal <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nominal transaksi harus lebih dari 0!')),
                          );
                          return;
                        }

                        final item = FinancialItem()
                          ..noteId = noteId
                          ..description = desc
                          ..amount = finalVal
                          ..type = type
                          ..createdAt = itemTimestamp
                          ..updatedAt = DateTime.now();

                        await ref.read(financialNotesNotifierProvider.notifier).addItemToNote(item);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('+ Tambah ke Catatan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void _confirmDeleteNote(int noteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: const Text('Seluruh item transaksi dalam catatan ini akan ikut terhapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(financialNotesNotifierProvider.notifier).deleteNote(noteId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    final notesAsync = ref.watch(financialNotesNotifierProvider);

    return notesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (allNotes) {
        final noteItem = allNotes.firstWhere(
          (n) => n.note.id == widget.noteId,
          orElse: () => NoteWithItems(note: FinancialNote(), items: []),
        );

        if (noteItem.note.id == 0) {
          return const Scaffold(body: Center(child: Text('Catatan tidak ditemukan')));
        }

        final note = noteItem.note;
        final items = noteItem.items;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(note.title),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditFinancialNotePage(existingNote: noteItem)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDeleteNote(note.id),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Note Info
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(note.date),
                                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ],
                              ),
                              if (note.notes != null && note.notes!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  note.notes!,
                                  style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white54 : Colors.black54),
                                ),
                              ],
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Catatan (${items.length} Item)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp ${currencyFmt.format(noteItem.netTotal.toInt())}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: noteItem.netTotal >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Item List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Daftar Transaksi (${items.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showQuickAddItemDialog(note.id),
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              label: const Text('Tambah Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('Belum ada item transaksi dalam catatan ini'),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final item = items[idx];
                              final isIncome = item.type == 'income';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isIncome ? const Color(0xFF10B981).withAlpha(30) : const Color(0xFFEF4444).withAlpha(30),
                                      child: Icon(
                                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.description,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.createdAt),
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isIncome ? '+' : '-'} Rp ${currencyFmt.format(item.amount.toInt())}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () async {
                                        await ref.read(financialNotesNotifierProvider.notifier).deleteItem(item.id);
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
