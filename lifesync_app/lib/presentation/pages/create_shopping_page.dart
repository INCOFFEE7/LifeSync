import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

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

  InputDecoration _deco(BuildContext context, String label, {String? hint, String? prefixText, Widget? suffixIcon}) {
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: LsColors.mute(context), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: LsColors.paper(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(LsColors.line(context)),
      enabledBorder: border(LsColors.line(context)),
      focusedBorder: border(LsColors.brand, 1.8),
      errorBorder: border(LsColors.expense),
      focusedErrorBorder: border(LsColors.expense, 1.8),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, Color color, List<Widget> children) {
    return LsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              LsEyebrow(title),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        title: Text(
          _isReadOnly
              ? 'Detail Item Belanja (Sudah Dibeli)'
              : (widget.existingItem == null ? 'Tambah Item Belanja' : 'Edit Item Belanja'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: LsColors.ink(context)),
        ),
        backgroundColor: LsColors.surface(context),
        surfaceTintColor: LsColors.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LsColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LsColors.income.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: LsColors.income, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Item belanja ini sudah dibeli pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.existingItem!.purchaseDate ?? widget.existingItem!.updatedAt)} (Read-Only).',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: LsColors.income, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _section(context, 'Informasi Barang', Icons.shopping_basket_rounded, LsColors.brand, [
                TextFormField(
                  controller: _nameController,
                  readOnly: _isReadOnly,
                  decoration: _deco(context, 'Nama Barang / Item *', hint: 'e.g. Minyak Goreng, Beras, Telur'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama Barang wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  readOnly: _isReadOnly,
                  decoration: _deco(context, 'Catatan / Notes (Opsional)', hint: 'e.g. Merk Sania 2 Liter'),
                ),
              ]),
              const SizedBox(height: 16),

              _section(context, 'Pembelian', Icons.storefront_rounded, LsColors.violet, [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasedByController,
                        readOnly: _isReadOnly,
                        decoration: _deco(context, 'Dibeli Oleh (Opsional)', hint: 'e.g. Ibu, Ayah'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        readOnly: _isReadOnly,
                        decoration: _deco(context, 'Tempat / Toko (Opsional)', hint: 'e.g. Pasar, Minimarket'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                  decoration: _deco(
                    context,
                    'Harga / Estimasi (Opsional)',
                    prefixText: 'Rp ',
                    suffixIcon: Icon(Icons.calculate, color: _isReadOnly ? LsColors.mute(context) : LsColors.brand),
                  ),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _isReadOnly ? LsColors.mute(context) : LsColors.brand),
                ),
              ]),
              const SizedBox(height: 28),

              // Save or Exit Button
              if (_isReadOnly)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: LsColors.line(context)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.exit_to_app, color: LsColors.mute(context)),
                  label: Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: LsColors.mute(context))),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LsColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveShoppingItem,
                  child: Text(widget.existingItem == null ? 'Simpan Item Belanja' : 'Simpan Perubahan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
