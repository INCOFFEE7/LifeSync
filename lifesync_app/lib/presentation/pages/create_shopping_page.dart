import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';

class SubShoppingItem {
  String name;
  bool isChecked;
  DateTime? boughtDate;
  double price;

  SubShoppingItem({
    required this.name,
    this.isChecked = false,
    this.boughtDate,
    this.price = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isChecked': isChecked,
        'boughtDate': boughtDate?.toIso8601String(),
        'price': price,
      };

  factory SubShoppingItem.fromJson(Map<String, dynamic> json) => SubShoppingItem(
        name: json['name'] ?? '',
        isChecked: json['isChecked'] ?? false,
        boughtDate: json['boughtDate'] != null ? DateTime.tryParse(json['boughtDate']) : null,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class CreateShoppingPage extends ConsumerStatefulWidget {
  final ShoppingItem? existingItem;

  const CreateShoppingPage({super.key, this.existingItem});

  @override
  ConsumerState<CreateShoppingPage> createState() => _CreateShoppingPageState();
}

class _CreateShoppingPageState extends ConsumerState<CreateShoppingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  DateTime _reminderDate = DateTime.now();
  List<SubShoppingItem> _subItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _titleController.text = item.name;
      _reminderDate = item.purchaseDate ?? DateTime.now();

      if (item.itemsList.isNotEmpty) {
        _subItems = item.itemsList.map((str) {
          try {
            return SubShoppingItem.fromJson(jsonDecode(str));
          } catch (_) {
            return SubShoppingItem(name: str);
          }
        }).toList();
      }
    }
  }

  // Tambah Barang - CUMA INPUT NAMA (tanpa harga/tanggal)
  void _addSubItem() {
    final subNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Barang Belanjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: subNameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nama Barang',
              hintText: 'e.g. Minyak Goreng, Beras, Telur',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final name = subNameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _subItems.add(SubShoppingItem(name: name));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _toggleCheckSubItem(SubShoppingItem item) async {
    if (!item.isChecked) {
      // Prompt untuk Tanggal Dibeli saat menceklis
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        helpText: 'Pilih Tanggal Dibeli untuk "${item.name}"',
      );
      if (pickedDate != null) {
        setState(() {
          item.isChecked = true;
          item.boughtDate = pickedDate;
        });
      }
    } else {
      setState(() {
        item.isChecked = false;
        item.boughtDate = null;
      });
    }
  }

  Future<void> _saveShoppingReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final serializedList = _subItems.map((item) => jsonEncode(item.toJson())).toList();
    final isAllBought = _subItems.isNotEmpty && _subItems.every((item) => item.isChecked);

    final dbService = ref.read(databaseServiceProvider);
    if (!kIsWeb) {
      await dbService.db.writeTxn(() async {
        if (widget.existingItem == null) {
          final newItem = ShoppingItem()
            ..name = title
            ..isChecked = isAllBought
            ..purchaseDate = _reminderDate
            ..itemsList = serializedList
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await dbService.db.shoppingItems.put(newItem);
        } else {
          final item = widget.existingItem!;
          item.name = title;
          item.isChecked = isAllBought;
          item.purchaseDate = _reminderDate;
          item.itemsList = serializedList;
          item.updatedAt = DateTime.now();
          await dbService.db.shoppingItems.put(item);
        }
      });
      ref.invalidate(shoppingItemsProvider);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catatan belanja "$title" berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boughtCount = _subItems.where((i) => i.isChecked).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.existingItem == null ? 'Buat Pengingat Belanja' : 'Edit Pengingat Belanja'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul Pengingat Belanja
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Catatan Belanja',
                  hintText: 'e.g. Belanja Bulanan, Dapur',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Tanggal & Waktu Pengingat
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                title: const Text('Waktu Pengingat Belanja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(_reminderDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                trailing: const Icon(Icons.alarm, color: Color(0xFF2563EB)),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _reminderDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (pickedDate != null && mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_reminderDate),
                    );
                    final time = pickedTime ?? TimeOfDay.fromDateTime(_reminderDate);
                    setState(() {
                      _reminderDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, time.hour, time.minute);
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Sub-items List Header dengan Progres
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daftar Barang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                      if (_subItems.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: boughtCount == _subItems.length ? Colors.green.withOpacity(0.1) : const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$boughtCount / ${_subItems.length} Dibeli',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: boughtCount == _subItems.length ? Colors.green : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _addSubItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Barang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_subItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada barang. Klik "+ Tambah Barang".',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subItems.length,
                  itemBuilder: (context, idx) {
                    final sub = _subItems[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Checkbox(
                          activeColor: const Color(0xFF2563EB),
                          value: sub.isChecked,
                          onChanged: (_) => _toggleCheckSubItem(sub),
                        ),
                        title: Text(
                          sub.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: sub.isChecked ? TextDecoration.lineThrough : null,
                            color: sub.isChecked ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        subtitle: sub.boughtDate != null
                            ? Text('Dibeli: ${DateFormat('dd MMM yyyy', 'id_ID').format(sub.boughtDate!)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))
                            : const Text('Belum dibeli', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _subItems.removeAt(idx);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saveShoppingReminder,
                child: const Text('Simpan Catatan Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
