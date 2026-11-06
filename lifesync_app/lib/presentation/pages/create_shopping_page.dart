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
  final _realizationController = TextEditingController();

  double _price = 0.0;
  double? _realizationPrice;
  String _selectedCategory = 'Sembako';
  final List<String> _categories = [
    'Sembako',
    'Perlengkapan Rumah Tangga',
    'Pakaian',
    'Kebersihan Habis Pakai',
    'Lainnya',
  ];

  bool get _isReadOnly =>
      widget.existingItem != null && widget.existingItem!.isChecked;

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
      _realizationPrice = item.realizationPrice;
      if (item.category != null && item.category!.trim().isNotEmpty) {
        if (!_categories.contains(item.category!.trim())) {
          _categories.insert(0, item.category!.trim());
        }
        _selectedCategory = item.category!.trim();
      }
      if (_price > 0) {
        _priceController.text =
            NumberFormat('#,###', 'id_ID').format(_price.toInt());
      }
      if (_realizationPrice != null && _realizationPrice! > 0) {
        _realizationController.text =
            NumberFormat('#,###', 'id_ID').format(_realizationPrice!.toInt());
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
    _realizationController.dispose();
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
            ..category = _selectedCategory
            ..price = _price
            ..realizationPrice = _realizationPrice
            ..notes = _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim()
            ..purchasedBy = _purchasedByController.text.trim().isEmpty
                ? null
                : _purchasedByController.text.trim()
            ..location = _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim()
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await dbService.db.shoppingItems.put(newItem);
        } else {
          final item = widget.existingItem!;
          item.name = name;
          item.category = _selectedCategory;
          item.price = _price;
          item.realizationPrice = _realizationPrice;
          item.notes = _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim();
          item.purchasedBy = _purchasedByController.text.trim().isEmpty
              ? null
              : _purchasedByController.text.trim();
          item.location = _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim();
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
          backgroundColor: LsColors.income,
        ),
      );
      Navigator.pop(context);
    }
  }

  InputDecoration _deco(BuildContext context, String label,
      {String? hint, String? prefixText, Widget? suffixIcon}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
          color: LsColors.mute(context),
          fontWeight: FontWeight.w500,
          fontSize: 13),
      filled: true,
      fillColor: LsColors.paper(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border(LsColors.line(context)),
      enabledBorder: border(LsColors.line(context)),
      focusedBorder: border(LsColors.brand, 1.8),
      errorBorder: border(LsColors.expense),
      focusedErrorBorder: border(LsColors.expense, 1.8),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon,
      Color color, List<Widget> children) {
    return LsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              LsEyebrow(title),
            ],
          ),
          const SizedBox(height: 10),
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
              : (widget.existingItem == null
                  ? 'Tambah Item Belanja'
                  : 'Edit Item Belanja'),
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: LsColors.ink(context)),
        ),
        backgroundColor: LsColors.surface(context),
        surfaceTintColor: LsColors.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LsColors.line(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    border: Border.all(
                        color: LsColors.income.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: LsColors.income, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Item belanja ini sudah dibeli pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.existingItem!.purchaseDate ?? widget.existingItem!.updatedAt)} (Read-Only).',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: LsColors.income,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── 1. Informasi Barang & Kategori ──
              _section(context, 'Informasi Barang',
                  Icons.shopping_basket_rounded, LsColors.brand, [
                TextFormField(
                  controller: _nameController,
                  enabled: !_isReadOnly,
                  decoration: _deco(context, 'Nama Barang *',
                      hint: 'Misal: Beras 5kg, Minyak Goreng, Sabun'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: LsColors.ink(context)),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Nama barang tidak boleh kosong';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: _deco(context, 'Kategori Kebutuhan'),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600))))
                      .toList(),
                  onChanged: _isReadOnly
                      ? null
                      : (val) {
                          if (val != null)
                            setState(() => _selectedCategory = val);
                        },
                ),
              ]),
              const SizedBox(height: 10),

              // ── 2. Harga Estimasi & Realisasi ──
              _section(context, 'Harga', Icons.attach_money_rounded,
                  LsColors.income, [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        readOnly: true,
                        onTap: _isReadOnly
                            ? null
                            : () async {
                                final val = await showCalculatorInputDialog(
                                  context: context,
                                  title: 'Input Harga Estimasi',
                                  initialValue: _price,
                                );
                                if (val != null) {
                                  setState(() {
                                    _price = val;
                                    _priceController.text =
                                        currencyFmt.format(_price.toInt());
                                  });
                                }
                              },
                        decoration: _deco(
                          context,
                          'Harga Estimasi (Rp)',
                          prefixText: 'Rp ',
                          suffixIcon: Icon(Icons.calculate,
                              color: _isReadOnly
                                  ? LsColors.mute(context)
                                  : LsColors.brand),
                        ),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _isReadOnly
                                ? LsColors.mute(context)
                                : LsColors.brand),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _realizationController,
                        readOnly: true,
                        onTap: _isReadOnly
                            ? null
                            : () async {
                                final val = await showCalculatorInputDialog(
                                  context: context,
                                  title: 'Input Harga Realisasi',
                                  initialValue: _realizationPrice ?? _price,
                                );
                                if (val != null) {
                                  setState(() {
                                    _realizationPrice = val;
                                    _realizationController.text =
                                        currencyFmt.format(val.toInt());
                                  });
                                }
                              },
                        decoration: _deco(
                          context,
                          'Harga Realisasi (Rp)',
                          prefixText: 'Rp ',
                          suffixIcon: Icon(Icons.calculate,
                              color: _isReadOnly
                                  ? LsColors.mute(context)
                                  : LsColors.income),
                        ),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _isReadOnly
                                ? LsColors.mute(context)
                                : LsColors.income),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 10),

              // ── 3. Pembelian & Toko ──
              _section(context, 'Pembelian & Toko', Icons.storefront_rounded,
                  LsColors.violet, [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        enabled: !_isReadOnly,
                        decoration: _deco(context, 'Tempat / Toko',
                            hint: 'e.g. Supermarket, Pasar'),
                        style: TextStyle(
                            fontSize: 13.5, color: LsColors.ink(context)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _purchasedByController,
                        enabled: !_isReadOnly,
                        decoration: _deco(context, 'Dibeli Oleh',
                            hint: 'e.g. Ibu, Ayah'),
                        style: TextStyle(
                            fontSize: 13.5, color: LsColors.ink(context)),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 10),

              // ── 4. Catatan ──
              _section(context, 'Catatan Tambahan', Icons.notes_rounded,
                  LsColors.mute(context), [
                TextFormField(
                  controller: _notesController,
                  enabled: !_isReadOnly,
                  maxLines: 2,
                  decoration: _deco(context, 'Catatan (Opsional)',
                      hint: 'e.g. Beli merk Sania jika ada'),
                  style:
                      TextStyle(fontSize: 13.5, color: LsColors.ink(context)),
                ),
              ]),
              const SizedBox(height: 20),

              if (!_isReadOnly)
                FilledButton.icon(
                  onPressed: _saveShoppingItem,
                  style: FilledButton.styleFrom(
                    backgroundColor: LsColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan Barang',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
