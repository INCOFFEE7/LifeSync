import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:isar/isar.dart';

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
  List<String> _categories = [
    'Sembako',
    'Perlengkapan Rumah Tangga',
    'Pakaian',
    'Kebersihan Habis Pakai',
    'Lainnya',
  ];

  bool get _isReadOnly => widget.existingItem != null && widget.existingItem!.isChecked;

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _notesController.text = item.notes ?? '';
      _purchasedByController.text = item.purchasedBy ?? '';
      _locationController.text = item.location ?? '';
      _price = item.price;
      _realizationPrice = item.realizationPrice;
      _selectedCategory = item.category ?? 'Sembako';
      if (_price > 0) {
        _priceController.text = NumberFormat('#,###', 'id_ID').format(_price.toInt());
      }
      if (_realizationPrice != null && _realizationPrice! > 0) {
        _realizationController.text = NumberFormat('#,###', 'id_ID').format(_realizationPrice!.toInt());
      }
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final settings = await db.db.appSettings.get(1);
      if (settings != null && mounted) {
        final savedCats = settings.customCategories
            .where((c) => c.startsWith('shop_cat:'))
            .map((c) => c.substring(9))
            .toList();
        if (savedCats.isNotEmpty) {
          setState(() {
            final merged = {..._categories, ...savedCats}.toList();
            _categories = merged;
            if (widget.existingItem != null && widget.existingItem!.category != null) {
              _selectedCategory = widget.existingItem!.category!;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCustomCategory(String name) async {
    try {
      final db = ref.read(databaseServiceProvider);
      final isar = db.db;
      await isar.writeTxn(() async {
        final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
        final key = 'shop_cat:$name';
        if (!settings.customCategories.contains(key)) {
          settings.customCategories = [...settings.customCategories, key];
          await isar.appSettings.put(settings);
        }
      });
    } catch (_) {}
  }

  Future<void> _renameCategory(String oldName, String newName) async {
    if (oldName == newName || newName.trim().isEmpty) return;
    final trimmedNew = newName.trim();
    final db = ref.read(databaseServiceProvider);
    final isar = db.db;

    await isar.writeTxn(() async {
      // 1. Update appSettings
      final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
      final oldKey = 'shop_cat:$oldName';
      final newKey = 'shop_cat:$trimmedNew';
      settings.customCategories = settings.customCategories.map((c) => c == oldKey ? newKey : c).toList();
      if (!settings.customCategories.contains(newKey)) {
        settings.customCategories.add(newKey);
      }
      await isar.appSettings.put(settings);

      // 2. Cascade rename all items using oldCategory
      final itemsToUpdate = await isar.shoppingItems.filter().categoryEqualTo(oldName).findAll();
      for (final it in itemsToUpdate) {
        it.category = trimmedNew;
        it.updatedAt = DateTime.now();
        await isar.shoppingItems.put(it);
      }
    });

    setState(() {
      final idx = _categories.indexOf(oldName);
      if (idx != -1) {
        _categories[idx] = trimmedNew;
      } else {
        _categories.add(trimmedNew);
      }
      if (_selectedCategory == oldName) {
        _selectedCategory = trimmedNew;
      }
    });
    ref.invalidate(shoppingItemsProvider);
  }

  Future<void> _promptAddOrEditCategory({String? editOldName}) async {
    final textCtrl = TextEditingController(text: editOldName ?? '');
    final isEdit = editOldName != null;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: LsColors.line(ctx), width: 1.2),
        ),
        backgroundColor: LsColors.surface(ctx),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LsColors.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: LsColors.brand.withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Icon(Icons.category_rounded, size: 22, color: LsColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEdit ? 'Edit Kategori Belanja' : 'Tambah Kategori Belanja',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: LsColors.ink(ctx),
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nama Kategori *',
            hintText: 'Contoh: Sembako, Kosmetik, Snack',
            filled: true,
            fillColor: LsColors.paper(ctx),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: LsColors.line(ctx), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Batal', style: TextStyle(color: LsColors.ink(ctx), fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: LsColors.brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final val = textCtrl.text.trim();
                      if (val.isNotEmpty) Navigator.pop(ctx, val);
                    },
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (isEdit) {
        await _renameCategory(editOldName, result);
      } else {
        await _saveCustomCategory(result);
        setState(() {
          if (!_categories.contains(result)) {
            _categories.add(result);
          }
          _selectedCategory = result;
        });
      }
    }
  }

  Future<void> _deleteCategory(String catName) async {
    final db = ref.read(databaseServiceProvider);
    final count = await db.db.shoppingItems.filter().categoryEqualTo(catName).count();

    if (count > 0) {
      if (!mounted) return;
      await showLsInfoDialog(
        context: context,
        title: 'Kategori Sedang Dipakai',
        message: 'Kategori "$catName" saat ini digunakan oleh $count barang belanjaan.\n\nKategori tidak dapat dihapus. Silakan gunakan opsi Edit Kategori untuk mengubah namanya atau pindahkan barang ke kategori lain.',
        icon: Icons.warning_amber_rounded,
        color: LsColors.amber,
      );
      return;
    }

    final confirm = await showLsConfirmDialog(
      context: context,
      title: 'Hapus Kategori?',
      message: 'Apakah Anda yakin ingin menghapus kategori "$catName"?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDanger: true,
    );
    if (!confirm || !mounted) return;

    await db.db.writeTxn(() async {
      final settings = await db.db.appSettings.get(1);
      if (settings != null) {
        settings.customCategories = settings.customCategories.where((c) => c != 'shop_cat:$catName').toList();
        await db.db.appSettings.put(settings);
      }
    });

    setState(() {
      _categories.remove(catName);
      if (_selectedCategory == catName) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : 'Sembako';
      }
    });
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

    final confirm = await showLsConfirmDialog(
      context: context,
      title: widget.existingItem == null ? 'Simpan Item Belanja?' : 'Perbarui Item Belanja?',
      message: 'Simpan "$name" ke dalam kategori $_selectedCategory?',
      confirmLabel: 'Ya, Simpan',
      cancelLabel: 'Batal',
    );
    if (!confirm || !mounted) return;

    final dbService = ref.read(databaseServiceProvider);
    if (!kIsWeb) {
      await dbService.db.writeTxn(() async {
        if (widget.existingItem == null) {
          final newItem = ShoppingItem()
            ..name = name
            ..isChecked = false
            ..price = _price
            ..realizationPrice = _realizationPrice
            ..category = _selectedCategory
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
          item.realizationPrice = _realizationPrice;
          item.category = _selectedCategory;
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
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: LsColors.mute(context), fontWeight: FontWeight.w500, fontSize: 13),
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

  Widget _section(BuildContext context, String title, IconData icon, Color color, List<Widget> children, {Widget? trailing}) {
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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(child: LsEyebrow(title)),
              if (trailing != null) trailing,
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

              // Seksi Kategori Belanja Reusable
              _section(
                context,
                'Kategori Kebutuhan',
                Icons.category_rounded,
                LsColors.brand,
                [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedCategory),
                          initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : null,
                          decoration: _deco(context, 'Pilih Kategori Kebutuhan *'),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          onChanged: _isReadOnly ? null : (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                          validator: (v) => (v == null || v.isEmpty) ? 'Kategori wajib dipilih' : null,
                        ),
                      ),
                      if (!_isReadOnly) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Edit Kategori Terpilih',
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _promptAddOrEditCategory(editOldName: _selectedCategory),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Hapus Kategori Terpilih',
                          icon: const Icon(Icons.delete_outline, size: 18, color: LsColors.expense),
                          onPressed: () => _deleteCategory(_selectedCategory),
                        ),
                      ],
                    ],
                  ),
                  if (!_isReadOnly) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _promptAddOrEditCategory(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Kategori Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              _section(context, 'Informasi Barang', Icons.shopping_basket_rounded, LsColors.amber, [
                TextFormField(
                  controller: _nameController,
                  readOnly: _isReadOnly,
                  decoration: _deco(context, 'Nama Barang / Item *', hint: 'e.g. Minyak Goreng, Beras, Telur'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama Barang wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  readOnly: _isReadOnly,
                  decoration: _deco(context, 'Catatan / Notes (Opsional)', hint: 'e.g. Merk Sania 2 Liter'),
                ),
              ]),
              const SizedBox(height: 10),

              _section(context, 'Harga Estimasi & Realisasi', Icons.attach_money_rounded, LsColors.income, [
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
                                    _priceController.text = currencyFmt.format(_price.toInt());
                                  });
                                }
                              },
                        decoration: _deco(
                          context,
                          'Harga Estimasi (Rp)',
                          prefixText: 'Rp ',
                          suffixIcon: Icon(Icons.calculate, color: _isReadOnly ? LsColors.mute(context) : LsColors.brand),
                        ),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _isReadOnly ? LsColors.mute(context) : LsColors.brand),
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
                                    _realizationController.text = currencyFmt.format(val.toInt());
                                  });
                                }
                              },
                        decoration: _deco(
                          context,
                          'Harga Realisasi (Rp)',
                          prefixText: 'Rp ',
                          suffixIcon: Icon(Icons.calculate, color: _isReadOnly ? LsColors.mute(context) : LsColors.income),
                        ),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _isReadOnly ? LsColors.mute(context) : LsColors.income),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 10),

              _section(context, 'Pembelian & Toko', Icons.storefront_rounded, LsColors.violet, [
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
              ]),
              const SizedBox(height: 14),

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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saveShoppingItem,
                  child: Text(widget.existingItem == null ? 'Simpan Item Belanja' : 'Simpan Perubahan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
