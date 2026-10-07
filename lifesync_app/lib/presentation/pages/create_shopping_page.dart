import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/core/utils/thousands_formatter.dart';

class SubShoppingItem {
  String name;
  double price;
  DateTime boughtDate;
  bool isChecked;

  SubShoppingItem({
    required this.name,
    this.price = 0.0,
    required this.boughtDate,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'boughtDate': boughtDate.toIso8601String(),
        'isChecked': isChecked,
      };

  factory SubShoppingItem.fromJson(Map<String, dynamic> json) => SubShoppingItem(
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        boughtDate: DateTime.tryParse(json['boughtDate'] ?? '') ?? DateTime.now(),
        isChecked: json['isChecked'] ?? false,
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
  final _priceController = TextEditingController();
  
  DateTime _reminderDate = DateTime.now();
  double _totalPrice = 0.0;
  List<SubShoppingItem> _subItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _titleController.text = item.name;
      _totalPrice = item.price;
      _priceController.text = NumberFormat('#,###', 'id_ID').format(_totalPrice.toInt());
      _reminderDate = item.purchaseDate ?? DateTime.now();

      if (item.itemsList.isNotEmpty) {
        _subItems = item.itemsList.map((str) {
          try {
            return SubShoppingItem.fromJson(jsonDecode(str));
          } catch (_) {
            return SubShoppingItem(name: str, boughtDate: DateTime.now());
          }
        }).toList();
      }
    }
  }

  void _addSubItem() {
    final subNameController = TextEditingController();
    double subPrice = 0.0;
    DateTime subDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final currencyFmt = NumberFormat('#,###', 'id_ID');
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Tambah Barang Belanjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        hintText: 'e.g. Minyak Goreng, Beras',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: currencyFmt.format(subPrice.toInt())),
                      onTap: () async {
                        final val = await showCalculatorInputDialog(
                          context: ctx,
                          title: 'Input Harga Beli',
                          initialValue: subPrice,
                        );
                        if (val != null) {
                          setDlgState(() => subPrice = val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Harga Beli (Rp)',
                        prefixText: 'Rp ',
                        suffixIcon: const Icon(Icons.calculate, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanggal Dibeli', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(subDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: subDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setDlgState(() => subDate = picked);
                      },
                    ),
                  ],
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
                        _subItems.add(SubShoppingItem(name: name, price: subPrice, boughtDate: subDate));
                        _recalculateTotalPrice();
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
      },
    );
  }

  void _recalculateTotalPrice() {
    double sum = 0.0;
    for (var item in _subItems) {
      sum += item.price;
    }
    if (sum > 0) {
      _totalPrice = sum;
      _priceController.text = NumberFormat('#,###', 'id_ID').format(_totalPrice.toInt());
    }
  }

  Future<void> _saveShoppingReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final serializedList = _subItems.map((item) => jsonEncode(item.toJson())).toList();

    final dbService = ref.read(databaseServiceProvider);
    if (!kIsWeb) {
      await dbService.db.writeTxn(() async {
        if (widget.existingItem == null) {
          final newItem = ShoppingItem()
            ..name = title
            ..price = _totalPrice
            ..purchaseDate = _reminderDate
            ..itemsList = serializedList
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await dbService.db.shoppingItems.put(newItem);
        } else {
          final item = widget.existingItem!;
          item.name = title;
          item.price = _totalPrice;
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
          content: Text('Pengingat belanja "$title" berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'id_ID');

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
                  labelText: 'Judul Catatan / Pengingat Belanja',
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
              const SizedBox(height: 16),

              // Total Harga Beli (Rp)
              TextFormField(
                controller: _priceController,
                readOnly: true,
                onTap: () async {
                  final val = await showCalculatorInputDialog(
                    context: context,
                    title: 'Input Total Estimasi Harga Beli',
                    initialValue: _totalPrice,
                  );
                  if (val != null) {
                    setState(() {
                      _totalPrice = val;
                      _priceController.text = currencyFmt.format(_totalPrice.toInt());
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Estimasi Total Harga Beli (Rp)',
                  prefixText: 'Rp ',
                  suffixIcon: const Icon(Icons.calculate, color: Color(0xFF2563EB)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 24),

              // Sub-items List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Barang (${_subItems.length})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
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
                      'Belum ada barang di catatan ini. Klik "+ Tambah Barang".',
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
                          onChanged: (val) {
                            setState(() {
                              sub.isChecked = val ?? false;
                            });
                          },
                        ),
                        title: Text(
                          sub.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: sub.isChecked ? TextDecoration.lineThrough : null,
                            color: sub.isChecked ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        subtitle: Text(
                          'Harga: Rp ${currencyFmt.format(sub.price.toInt())} • Tanggal: ${DateFormat('dd/MM/yy').format(sub.boughtDate)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _subItems.removeAt(idx);
                              _recalculateTotalPrice();
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
                child: const Text('Simpan Pengingat Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
