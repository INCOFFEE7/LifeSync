import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/widgets/custom_numeric_keypad.dart';

class AddEditFinancialNotePage extends ConsumerStatefulWidget {
  final NoteWithItems? existingNote;

  const AddEditFinancialNotePage({super.key, this.existingNote});

  @override
  ConsumerState<AddEditFinancialNotePage> createState() => _AddEditFinancialNotePageState();
}

class _AddEditFinancialNotePageState extends ConsumerState<AddEditFinancialNotePage> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<FinancialItem> _draftItems = [];
  bool _isSaving = false;
  List<String> _existingTitles = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.note.title;
      _notesController.text = widget.existingNote!.note.notes ?? '';
      _selectedDate = widget.existingNote!.note.date;
      _draftItems.addAll(widget.existingNote!.items);
    }
    _loadExistingTitles();
  }

  void _loadExistingTitles() {
    final notesAsync = ref.read(financialNotesNotifierProvider);
    notesAsync.whenData((notes) {
      final titles = notes.map((n) => n.note.title).toSet().toList();
      titles.sort();
      if (mounted) {
        setState(() => _existingTitles = titles);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Helper: Evaluate expression string to double ──────────────────────────
   double _evaluateExpr(String expr) {
    try {
      String sanitized = expr.replaceAll('×', '*').replaceAll('÷', '/');
      // Pisahkan angka dan operator
      final tokens = RegExp(r'(\d+(?:\.\d+)?|[+\-*/])').allMatches(sanitized).map((m) => m.group(0)!).toList();
      if (tokens.isEmpty) return 0.0;
      // Pass 1: Perkalian (*) dan Pembagian (/)
      for (int i = 1; i < tokens.length - 1; i += 2) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double left = double.parse(tokens[i - 1]);
          double right = double.parse(tokens[i + 1]);
          double result = tokens[i] == '*' ? (left * right) : (right == 0 ? 0 : left / right);
          
          tokens[i - 1] = result.toString();
          tokens.removeAt(i); // hapus operator
          tokens.removeAt(i); // hapus angka kanan
          i -= 2; // mundur indeks
        }
      }
      // Pass 2: Penjumlahan (+) dan Pengurangan (-)
      double total = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length - 1; i += 2) {
        String op = tokens[i];
        double nextNum = double.parse(tokens[i + 1]);
        if (op == '+') total += nextNum;
        else if (op == '-') total -= nextNum;
      }
      return total.clamp(0.0, 999999999999.0);
    } catch (_) {
      return 0.0; // Fallback jika ekspresi tidak valid
    }
  }

  // ── Helper: Check if expression has operators ─────────────────────────────
  bool _hasOperator(String expr) {
    return expr.contains('+') || expr.contains('-') || expr.contains('×') || expr.contains('÷');
  }

  // ── Helper: Format currency ───────────────────────────────────────────────
  String _formatCurrency(double val) {
    final fmt = NumberFormat('#,###', 'id_ID');
    return val == 0 ? 'Rp 0' : 'Rp ${fmt.format(val.toInt())}';
  }

  void _showAddItemDialog({FinancialItem? itemToEdit, int? editIndex}) {
    final descController = TextEditingController(text: itemToEdit?.description ?? '');
    String calcExpr = itemToEdit != null ? itemToEdit.amount.toInt().toString() : '0';
    String type = itemToEdit?.type ?? 'expense';
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
                    Text(
                      itemToEdit == null ? 'Tambah Item Transaksi' : 'Edit Item Transaksi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pengeluaran')),
                            selected: type == 'expense',
                            selectedColor: const Color(0xFFEF4444),
                            labelStyle: TextStyle(color: type == 'expense' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold),
                            onSelected: (sel) {
                              if (sel) setModalState(() => type = 'expense');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pemasukan')),
                            selected: type == 'income',
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(color: type == 'income' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold),
                            onSelected: (sel) {
                              if (sel) setModalState(() => type = 'income');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      onTap: () {
                        if (showKeypad) setModalState(() => showKeypad = false);
                      },
                      decoration: InputDecoration(
                        labelText: 'Nama Item (Contoh: Gojek, Shopee, Sayur)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            // Show expression if it contains operators
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
                      onPressed: () {
                        final desc = descController.text.trim();
                        final finalVal = _evaluateExpr(calcExpr);
                        if (desc.isEmpty || finalVal <= 0) return;

                        setState(() {
                          if (itemToEdit != null && editIndex != null) {
                            _draftItems[editIndex] = FinancialItem()
                              ..id = itemToEdit.id
                              ..noteId = itemToEdit.noteId
                              ..description = desc
                              ..amount = finalVal
                              ..type = type;
                          } else {
                            _draftItems.add(FinancialItem()
                              ..description = desc
                              ..amount = finalVal
                              ..type = type);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul Catatan tidak boleh kosong')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final noteNotifier = ref.read(financialNotesNotifierProvider.notifier);

      if (widget.existingNote == null) {
        final newNote = FinancialNote()
          ..title = title
          ..date = _selectedDate
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
        await noteNotifier.addNoteWithItems(newNote, _draftItems);
      } else {
        final existing = widget.existingNote!.note
          ..title = title
          ..date = _selectedDate
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
        await noteNotifier.updateNote(existing);

        // Update items
        final repo = ref.read(financialNoteRepositoryProvider);
        await repo.deleteItemsByNoteId(existing.id);
        for (final item in _draftItems) {
          item.noteId = existing.id;
          await repo.saveItem(item);
        }
        await noteNotifier.loadNotes();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    double totalIncome = _draftItems.where((i) => i.type == 'income').fold(0.0, (s, i) => s + i.amount);
    double totalExpense = _draftItems.where((i) => i.type == 'expense').fold(0.0, (s, i) => s + i.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.existingNote == null ? 'Catatan Baru' : 'Edit Catatan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    // ── Title with suggestions ─────────────────────────────────
                    if (_existingTitles.isNotEmpty && widget.existingNote == null) ...[
                      Text('Pilih judul yang sudah ada:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _existingTitles.map((title) {
                          final isSelected = _titleController.text == title;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _titleController.text = title;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2563EB).withAlpha(25) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('Atau tulis judul baru:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Judul Catatan (Contoh: Catatan Tips, Belanja)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 12),
                            Text('Tanggal Catatan', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                            const Spacer(),
                            Text(
                              DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (Opsional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daftar Item (${_draftItems.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => _showAddItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_draftItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('Belum ada item transaksi. Klik "+ Tambah Item"'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _draftItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = _draftItems[idx];
                          final isIncome = item.type == 'income';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text(
                                  '${isIncome ? '+' : '-'} Rp ${currencyFmt.format(item.amount.toInt())}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showAddItemDialog(itemToEdit: item, editIndex: idx),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => setState(() => _draftItems.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pemasukan'),
                              Text('Rp ${currencyFmt.format(totalIncome.toInt())}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pengeluaran'),
                              Text('Rp ${currencyFmt.format(totalExpense.toInt())}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _saveNote,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Catatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
