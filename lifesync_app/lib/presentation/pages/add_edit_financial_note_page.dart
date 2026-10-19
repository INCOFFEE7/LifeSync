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
  final DateTime? initialDate;

  const AddEditFinancialNotePage({super.key, this.existingNote, this.initialDate});

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

  final _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.note.title;
      _notesController.text = widget.existingNote!.note.notes ?? '';
      _selectedDate = widget.existingNote!.note.date;
      _draftItems.addAll(widget.existingNote!.items);
    } else if (widget.initialDate != null) {
      _selectedDate = DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day, 0, 0);
    } else {
      _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0);
    }
    _titleFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
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
    _titleFocusNode.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 0, 0);
      });
    }
  }

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

  // ── Helper: Check if expression has operators ─────────────────────────────
  bool _hasOperator(String expr) {
    return expr.contains('+') || expr.contains('-') || expr.contains('×') || expr.contains('÷');
  }

  // ── Helper: Format currency ───────────────────────────────────────────────
  String _formatCurrency(double val) {
    final fmt = NumberFormat('#,###', 'id_ID');
    if (val == 0) return 'Rp 0';
    if (val < 0) return '-Rp ${fmt.format(val.abs().toInt())}';
    return 'Rp ${fmt.format(val.toInt())}';
  }

  void _showAddItemDialog({FinancialItem? itemToEdit, int? editIndex}) {
    final descController = TextEditingController(text: itemToEdit?.description ?? '');
    String calcExpr = itemToEdit != null ? itemToEdit.amount.toInt().toString() : '0';
    String type = itemToEdit?.type ?? 'expense';
    DateTime itemTimestamp = itemToEdit != null ? itemToEdit.createdAt : DateTime.now();
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
                        labelText: 'Nama Item * (Contoh: Gojek, Shopee, Sayur)',
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
                    const SizedBox(height: 12),
                    // Item Timestamp selector
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
                        final evaluatedVal = _evaluateExpr(calcExpr);
                        if (desc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama item transaksi wajib diisi!')),
                          );
                          return;
                        }
                        if (evaluatedVal == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nominal transaksi harus lebih dari 0!')),
                          );
                          return;
                        }

                        double finalVal = evaluatedVal;
                        String finalType = type;
                        if (finalVal < 0) {
                          finalType = 'expense';
                          finalVal = finalVal.abs();
                        }

                        setState(() {
                          if (itemToEdit != null && editIndex != null) {
                            _draftItems[editIndex] = FinancialItem()
                              ..id = itemToEdit.id
                              ..noteId = itemToEdit.noteId
                              ..description = desc
                              ..amount = finalVal
                              ..type = finalType
                              ..createdAt = itemTimestamp
                              ..updatedAt = DateTime.now();
                          } else {
                            _draftItems.add(FinancialItem()
                              ..description = desc
                              ..amount = finalVal
                              ..type = finalType
                              ..createdAt = itemTimestamp
                              ..updatedAt = DateTime.now());
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    double totalIncome = _draftItems.where((i) => i.type == 'income').fold(0.0, (s, i) => s + i.amount);
    double totalExpense = _draftItems.where((i) => i.type == 'expense').fold(0.0, (s, i) => s + i.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Catatan Keuangan'),
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
                    // ── 1. Title Input with Clear (X) Button & Google-like Suggestions ──
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Judul Catatan * (Contoh: Catatan Tips, Belanja)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
                        suffixIcon: _titleController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _titleController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                    ),

                    // ── 2. Google-Style Dropdown Suggestions ────────────────────
                    Builder(
                      builder: (ctx) {
                        if (_existingTitles.isEmpty || widget.existingNote != null) {
                          return const SizedBox.shrink();
                        }

                        final query = _titleController.text.trim().toLowerCase();
                        // Filter matching titles or show recent when focused
                        final matchingTitles = query.isEmpty
                            ? (_titleFocusNode.hasFocus ? _existingTitles.take(5).toList() : <String>[])
                            : _existingTitles.where((t) => t.toLowerCase().contains(query)).take(5).toList();

                        if (matchingTitles.isEmpty) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: matchingTitles.map((title) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _titleController.text = title;
                                      _titleFocusNode.unfocus();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.history, size: 16, color: Colors.grey.shade400),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.north_west, size: 14, color: Colors.grey.shade400),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── 3. Total Income & Expenses directly below Title ─────────
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
                              const Text('Total Pemasukan', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Rp ${currencyFmt.format(totalIncome.toInt())}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pengeluaran', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Rp ${currencyFmt.format(totalExpense.toInt())}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 4. Transaction List (Daftar Item / Daftar Transaksi) ────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.existingNote == null
                              ? 'Daftar Transaksi (${_draftItems.length})'
                              : 'Daftar Transaksi (${_draftItems.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: () => _showAddItemDialog(),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text('Tambah Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.createdAt),
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
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

                    const SizedBox(height: 24),

                    // ── 5. Notes Section (Moved below transaction list) ────────
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (Opsional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
