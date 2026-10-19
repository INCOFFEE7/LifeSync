import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';

class CreateShoppingPage extends ConsumerStatefulWidget {
  final ShoppingItem? existingItem;

  const CreateShoppingPage({super.key, this.existingItem});

  @override
  ConsumerState<CreateShoppingPage> createState() => _CreateShoppingPageState();
}

class _CreateShoppingPageState extends ConsumerState<CreateShoppingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _purchasedByController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();

  double _price = 0.0;

  bool get _isReadOnly => widget.existingItem != null && widget.existingItem!.isChecked;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _notesController.text = item.notes ?? '';
      _purchasedByController.text = item.purchasedBy ?? '';
      _locationController.text = item.location ?? '';
      _price = item.price;
      if (_price > 0) {
        _priceController.text = NumberFormat('#,###', 'id_ID').format(_price.toInt());
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _purchasedByController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveShoppingItem() async {
    if (_isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    final dbService = ref.read(databaseServiceProvider);
    if (!kIsWeb) {
      await dbService.db.writeTxn(() async {
        if (widget.existingItem == null) {
          final newItem = ShoppingItem()
            ..name = name
            ..isChecked = false
            ..price = _price
            ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim()
            ..purchasedBy = _purchasedByController.text.trim().isEmpty ? null : _purchasedByController.text.trim()
            ..location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim()
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await dbService.db.shoppingItems.put(newItem);
        } else {
          final item = widget.existingItem!;
          item.name = name;
          item.price = _price;
          item.notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
          item.purchasedBy = _purchasedByController.text.trim().isEmpty ? null : _purchasedByController.text.trim();
          item.location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
          item.updatedAt = DateTime.now();
          await dbService.db.shoppingItems.put(item);
        }
      });
      ref.invalidate(shoppingItemsProvider);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item belanja "$name" berhasil disimpan!'),
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
        title: Text(_isReadOnly
            ? 'Detail Item Belanja (Sudah Dibeli)'
            : (widget.existingItem == null ? 'Tambah Item Belanja' : 'Edit Item Belanja')),
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
              if (_isReadOnly) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Item belanja ini sudah dibeli pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.existingItem!.purchaseDate ?? widget.existingItem!.updatedAt)} (Read-Only).',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Nama Barang (Wajib)
              TextFormField(
                controller: _nameController,
                readOnly: _isReadOnly,
                decoration: InputDecoration(
                  labelText: 'Nama Barang / Item *',
                  hintText: 'e.g. Minyak Goreng, Beras, Telur',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama Barang wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // 2. Catatan / Notes (Opsional)
              TextFormField(
                controller: _notesController,
                readOnly: _isReadOnly,
                decoration: InputDecoration(
                  labelText: 'Catatan / Notes (Opsional)',
                  hintText: 'e.g. Merk Sania 2 Liter',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Dibeli Oleh & Tempat / Toko (Opsional)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasedByController,
                      readOnly: _isReadOnly,
                      decoration: InputDecoration(
                        labelText: 'Dibeli Oleh (Opsional)',
                        hintText: 'e.g. Ibu, Ayah',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      readOnly: _isReadOnly,
                      decoration: InputDecoration(
                        labelText: 'Tempat / Toko (Opsional)',
                        hintText: 'e.g. Pasar, Minimarket',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Harga / Estimasi (Opsional)
              TextFormField(
                controller: _priceController,
                readOnly: true,
                onTap: _isReadOnly
                    ? null
                    : () async {
                        final val = await showCalculatorInputDialog(
                          context: context,
                          title: 'Input Harga / Estimasi (Opsional)',
                          initialValue: _price,
                        );
                        if (val != null) {
                          setState(() {
                            _price = val;
                            _priceController.text = currencyFmt.format(_price.toInt());
                          });
                        }
                      },
                decoration: InputDecoration(
                  labelText: 'Harga / Estimasi (Opsional)',
                  prefixText: 'Rp ',
                  suffixIcon: Icon(Icons.calculate, color: _isReadOnly ? Colors.grey : const Color(0xFF2563EB)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _isReadOnly ? Colors.grey : const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 32),

              // Save or Exit Button
              if (_isReadOnly)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.exit_to_app, color: Colors.grey),
                  label: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saveShoppingItem,
                  child: Text(widget.existingItem == null ? 'Simpan Item Belanja' : 'Simpan Perubahan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
