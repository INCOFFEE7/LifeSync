import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/presentation/pages/create_reminder_page.dart';
import 'package:lifesync_app/presentation/pages/add_edit_bill_page.dart';
import 'package:lifesync_app/presentation/pages/create_shopping_page.dart';
import 'package:lifesync_app/presentation/widgets/circular_fab_menu.dart';
import 'package:lifesync_app/presentation/widgets/month_day_picker_widget.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:intl/intl.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _showAllAgenda = false;
  bool _showAllBills = false;
  bool _showAllShopping = false;
  String _agendaFilterMode = 'upcoming'; // 'upcoming', 'completed', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void resetToDashboard() {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  // ── Quick Pop-Up Tambah Belanja Baru (Standardized Bottom Sheet) ──────────
  Future<void> _showQuickAddShoppingDialog() async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 24, left: 24, right: 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_shopping_cart, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tambah Item Belanja',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nama Barang / Item *',
                    hintText: 'e.g. Minyak Goreng, Beras, Telur',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan / Notes (Opsional)',
                    hintText: 'e.g. Merk Sania 2 Liter',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama barang/item belanja wajib diisi!')),
                            );
                            return;
                          }

                          final newItem = ShoppingItem()
                            ..name = name
                            ..notes = notesController.text.trim().isEmpty ? null : notesController.text.trim()
                            ..isChecked = false
                            ..createdAt = DateTime.now()
                            ..updatedAt = DateTime.now();

                          final dbService = ref.read(databaseServiceProvider);
                          if (!kIsWeb) {
                            await dbService.db.writeTxn(() async {
                              await dbService.db.shoppingItems.put(newItem);
                            });
                            ref.invalidate(shoppingItemsProvider);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Simpan Item', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Modal Konfirmasi Ceklist Item Belanja (Dengan Form Opsional) ─────────
  Future<void> _showShoppingCheckoffDialog(ShoppingItem item) async {
    final purchasedByController = TextEditingController(text: item.purchasedBy ?? '');
    final locationController = TextEditingController(text: item.location ?? '');
    double enteredPrice = item.price;
    DateTime selectedDate = item.purchaseDate ?? DateTime.now();
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24, left: 24, right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Konfirmasi Dibeli',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Catatan: ${item.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: purchasedByController,
                      decoration: InputDecoration(
                        labelText: 'Dibeli Oleh Siapa (Opsional)',
                        hintText: 'e.g. Ibu, Ayah, Siska',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Tempat Membeli (Opsional)',
                        hintText: 'e.g. Pasar Tradisional, Minimarket',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: enteredPrice > 0 ? currencyFmt.format(enteredPrice.toInt()) : '',
                      ),
                      onTap: () async {
                        final val = await showCalculatorInputDialog(
                          context: ctx,
                          title: 'Input Harga Pembelian',
                          initialValue: enteredPrice,
                        );
                        if (val != null) {
                          setModalState(() {
                            enteredPrice = val;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Harga Pembelian (Opsional)',
                        prefixText: 'Rp ',
                        suffixIcon: const Icon(Icons.calculate, color: Color(0xFF10B981)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: const Text('Waktu Pembelian', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(selectedDate),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 18),
                      onTap: () async {
                        final pDate = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (pDate != null && ctx.mounted) {
                          final pTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          final time = pTime ?? TimeOfDay.fromDateTime(selectedDate);
                          setModalState(() {
                            selectedDate = DateTime(pDate.year, pDate.month, pDate.day, time.hour, time.minute);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              item.isChecked = true;
                              item.purchaseDate = selectedDate;
                              item.price = enteredPrice;
                              item.purchasedBy = purchasedByController.text.trim().isEmpty ? null : purchasedByController.text.trim();
                              item.location = locationController.text.trim().isEmpty ? null : locationController.text.trim();
                              item.updatedAt = DateTime.now();

                              final dbService = ref.read(databaseServiceProvider);
                              if (!kIsWeb) {
                                await dbService.db.writeTxn(() async {
                                  await dbService.db.shoppingItems.put(item);
                                });
                                ref.invalidate(shoppingItemsProvider);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Text('Konfirmasi Selesai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  String _formatReminderTime(Reminder r) {
    if (r.isRange) {
      final startStr = DateFormat('dd MMM yyyy', 'id_ID').format(r.targetDateTime);
      final endStr = DateFormat('dd MMM yyyy', 'id_ID').format(r.effectiveEndTime);
      if (r.isAllDay) {
        return '$startStr - $endStr (Full Day)';
      } else {
        final startHour = DateFormat('HH:mm', 'id_ID').format(r.targetDateTime);
        final endHour = DateFormat('HH:mm', 'id_ID').format(r.effectiveEndTime);
        return '$startStr $startHour - $endStr $endHour';
      }
    } else {
      final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(r.targetDateTime);
      if (r.isAllDay) {
        return '$dateStr (Full Day)';
      } else {
        final startHour = DateFormat('HH:mm', 'id_ID').format(r.targetDateTime);
        final endHour = DateFormat('HH:mm', 'id_ID').format(r.effectiveEndTime);
        return '$dateStr, $startHour - $endHour';
      }
    }
  }

  Color _getAgendaColor(Reminder r) {
    if (r.isRange) return const Color(0xFF8B5CF6); // Ungu untuk rentang waktu
    if (r.isAllDay) return Colors.amber.shade700; // Amber untuk seharian/full day
    return const Color(0xFF2563EB); // Biru untuk 1 hari dengan waktu
  }

  // ── View-Only Pop-Up Detail Agenda (Card yang Diperbesar) ────────────────────
  void _showReminderDetailBottomSheet(Reminder r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final timeDisplay = _formatReminderTime(r);
        final agendaColor = _getAgendaColor(r);
        final isCompleted = r.realtimeStatus == 'Selesai';

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: agendaColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.event_note_outlined, color: agendaColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text('Detail Agenda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),

                Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: agendaColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        timeDisplay,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: agendaColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Badges: Kategori, Prioritas, Full Day / Rentang, Status
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Kategori: ${r.category == ReminderCategory.other && (r.customCategory?.isNotEmpty ?? false) ? r.customCategory! : r.category.name.toUpperCase()}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (r.priority == PriorityLevel.high ? Colors.red : (r.priority == PriorityLevel.medium ? Colors.orange : Colors.green)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Prioritas: ${r.priority.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: r.priority == PriorityLevel.high ? Colors.red : (r.priority == PriorityLevel.medium ? Colors.orange : Colors.green),
                        ),
                      ),
                    ),
                    if (r.isAllDay)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Full Day',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                        ),
                      ),
                    if (r.isRange)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rentang Waktu',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isCompleted ? Colors.green : (r.realtimeStatus == 'Sedang Berjalan' ? Colors.blue : Colors.grey)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Status: ${r.realtimeStatus}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : (r.realtimeStatus == 'Sedang Berjalan' ? Colors.blue : Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (r.description != null && r.description!.trim().isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      r.description!.trim(),
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    if (!isCompleted && r.isRange) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            r.status = ReminderStatus.completed;
                            r.updatedAt = DateTime.now();
                            await ref.read(reminderRepositoryProvider).saveReminder(r);
                            ref.invalidate(dashboardDataProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text('Agenda "${r.title}" berhasil diselesaikan!')),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Agenda Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReminderPage(existingReminder: r)));
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ── Modal Bayar / Batalkan Tagihan ─────────────────────────────────────────
  Future<void> _handleBillToggle(Bill bill) async {
    final isPaid = bill.isPaid;

    if (!isPaid) {
      double enteredRealization = bill.amount;
      DateTime selectedPaymentDate = DateTime.now();
      final notesController = TextEditingController();
      final currencyFmt = NumberFormat('#,###', 'id_ID');

      final confirm = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              final diff = enteredRealization - bill.amount;

              return Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 24, left: 24, right: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Bayar: ${bill.name}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nominal Rencana Tagihan:', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            Text('Rp ${currencyFmt.format(bill.amount.toInt())}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: currencyFmt.format(enteredRealization.toInt()),
                        ),
                        onTap: () async {
                          final val = await showCalculatorInputDialog(
                            context: ctx,
                            title: 'Input Realisasi Pembayaran',
                            initialValue: enteredRealization,
                          );
                          if (val != null && val >= 0) {
                            setDialogState(() {
                              enteredRealization = val;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Nominal Realisasi Pembayaran (Rp)',
                          prefixText: 'Rp ',
                          suffixIcon: const Icon(Icons.calculate, color: Color(0xFF10B981)),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 10),
                      if (diff < 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kurang (Sisa): Rp ${currencyFmt.format(diff.abs().toInt())}',
                                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (diff > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kelebihan: Rp ${currencyFmt.format(diff.toInt())}',
                                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lunas Sesuai Rencana',
                                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        title: const Text('Tanggal Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(
                          DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(selectedPaymentDate),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 20),
                        onTap: () async {
                          final pDate = await showDatePicker(
                            context: ctx,
                            initialDate: selectedPaymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (pDate != null && ctx.mounted) {
                            final pTime = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(selectedPaymentDate),
                            );
                            final time = pTime ?? TimeOfDay.fromDateTime(selectedPaymentDate);
                            setDialogState(() {
                              selectedPaymentDate = DateTime(pDate.year, pDate.month, pDate.day, time.hour, time.minute);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Catatan Realisasi (Opsional)',
                          hintText: 'e.g. Termasuk denda / diskon',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Konfirmasi Bayar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (confirm == true) {
        final enteredNotes = notesController.text.trim();

        bill.isPaid = true;
        bill.realizationAmount = enteredRealization;
        bill.paidAt = selectedPaymentDate;
        bill.updatedAt = DateTime.now();
        if (enteredNotes.isNotEmpty) {
          bill.notes = (bill.notes != null && bill.notes!.isNotEmpty)
              ? '${bill.notes}\n[Bayar ${DateFormat('dd/MM/yy').format(selectedPaymentDate)}]: $enteredNotes'
              : '[Bayar ${DateFormat('dd/MM/yy').format(selectedPaymentDate)}]: $enteredNotes';
        }

        await ref.read(billRepositoryProvider).saveBill(bill);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tagihan "${bill.name}" berhasil dibayar!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Batalkan Pembayaran?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              'Status tagihan "${bill.name}" akan dikembalikan menjadi Belum Dibayar.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (confirm == true) {
        bill.isPaid = false;
        bill.realizationAmount = 0.0;
        bill.paidAt = null;
        bill.updatedAt = DateTime.now();

        await ref.read(billRepositoryProvider).saveBill(bill);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status tagihan "${bill.name}" dikembalikan ke Belum Dibayar.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersStreamProvider);
    final shoppingAsync = ref.watch(shoppingItemsProvider);
    final monthKey = DateFormat('yyyy-MM').format(_selectedDate);
    final billsAsync = ref.watch(billsStreamProvider(monthKey));

    final lang = ref.watch(localeProvider).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Image.asset(
            AppEnvironment.config.getLogoFullPath(isDark),
            width: 175,
            height: 42,
            cacheWidth: 525,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => Text(
              AppEnvironment.config.appName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2563EB),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Agenda'),
            Tab(text: 'Tagihan'),
            Tab(text: 'Belanja'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
              // ── Tab 0: Dashboard Pengingat
              _buildRemindersDashboard7Days(remindersAsync, billsAsync, shoppingAsync, isDark, currencyFmt),

              // ── Tab 1: Agenda ───────────────────────────────────────────
              Column(
                children: [
                  MonthDayPickerWidget(
                    selectedDate: _selectedDate,
                    isSeeAll: _showAllAgenda,
                    showDayStrip: false,
                    dateScope: _showAllAgenda ? 'all' : 'this_month',
                    onDateScopeChanged: (scope) {
                      setState(() {
                        _showAllAgenda = scope == 'all';
                        if (!_showAllAgenda) _selectedDate = DateTime.now();
                      });
                    },
                    statusFilter: _agendaFilterMode,
                    onStatusFilterChanged: (status) {
                      setState(() {
                        _agendaFilterMode = status;
                      });
                    },
                    onDateChanged: (date) => setState(() {
                      _selectedDate = date;
                      _showAllAgenda = false;
                    }),
                  ),
                  Expanded(
                    child: remindersAsync.when(
                      data: (reminders) {
                        final activeReminders = reminders.where((r) => !r.deleted).toList();
                        final monthFiltered = _showAllAgenda
                            ? activeReminders
                            : activeReminders.where((r) =>
                                r.targetDateTime.year == _selectedDate.year &&
                                r.targetDateTime.month == _selectedDate.month
                              ).toList();

                        final filtered = monthFiltered.where((r) {
                          if (_agendaFilterMode == 'upcoming') {
                            return r.realtimeStatus != 'Selesai';
                          } else if (_agendaFilterMode == 'completed') {
                            return r.realtimeStatus == 'Selesai';
                          }
                          return true;
                        }).toList()..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

                        return _buildAgendaList(filtered, lang);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),

              // ── Tab 2: Tagihan ───────────────────────────────────────────
              Column(
                children: [
                  MonthDayPickerWidget(
                    selectedDate: _selectedDate,
                    isSeeAll: _showAllBills,
                    showDayStrip: false,
                    dateScope: _showAllBills ? 'all' : 'this_month',
                    onDateScopeChanged: (scope) {
                      setState(() {
                        _showAllBills = scope == 'all';
                        if (!_showAllBills) _selectedDate = DateTime.now();
                      });
                    },
                    onDateChanged: (date) => setState(() {
                      _selectedDate = date;
                      _showAllBills = false;
                    }),
                  ),
                  Expanded(
                    child: billsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                      data: (bills) {
                        final displayBills = _showAllBills
                            ? bills
                            : bills.where((b) => b.dueDate.year == _selectedDate.year && b.dueDate.month == _selectedDate.month).toList();

                        if (displayBills.isEmpty) {
                          return Center(
                            child: Text('Belum ada data tagihan.', style: TextStyle(color: Colors.grey.shade500)),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayBills.length,
                          itemBuilder: (context, idx) {
                            final bill = displayBills[idx];
                            final realization = bill.realizationAmount ?? 0.0;
                            final diff = realization - bill.amount;
                            final remaining = (bill.amount - realization).clamp(0.0, double.infinity);

                            String statusText = '';
                            Color statusColor = Colors.grey;

                            if (bill.isPaid) {
                              if (diff > 0) {
                                statusText = 'Kelebihan: Rp ${currencyFmt.format(diff.toInt())}';
                                statusColor = const Color(0xFF2563EB);
                              } else if (diff < 0) {
                                statusText = 'Hemat: Rp ${currencyFmt.format(diff.abs().toInt())}';
                                statusColor = Colors.amber.shade900;
                              } else {
                                statusText = 'Lunas Sesuai Rencana';
                                statusColor = Colors.green;
                              }
                            } else {
                              statusText = 'Sisa Tagihan: Rp ${currencyFmt.format(remaining.toInt())}';
                              statusColor = Colors.red;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                onTap: () => _handleBillToggle(bill),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: bill.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Icon(
                                    bill.isPaid ? Icons.check_circle : Icons.receipt_long,
                                    color: bill.isPaid ? Colors.green : Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                                title: Text(bill.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jatuh tempo: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}', style: const TextStyle(fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                                  ],
                                ),
                                trailing: Text('Rp ${currencyFmt.format(bill.amount.toInt())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

                // ── Tab 3: Belanja ───────────────────────────────────────────
                Column(
                  children: [
                    MonthDayPickerWidget(
                      selectedDate: _selectedDate,
                      isSeeAll: _showAllShopping,
                      showDayStrip: false,
                      dateScope: _showAllShopping ? 'all' : 'this_month',
                      onDateScopeChanged: (scope) {
                        setState(() {
                          _showAllShopping = scope == 'all';
                          if (!_showAllShopping) _selectedDate = DateTime.now();
                        });
                      },
                      onDateChanged: (date) => setState(() {
                        _selectedDate = date;
                        _showAllShopping = false;
                      }),
                    ),
                    Expanded(
                      child: shoppingAsync.when(
                        data: (items) {
                          final activeItems = items.where((i) => !i.deleted).toList();
                          final filtered = _showAllShopping
                              ? activeItems
                              : activeItems.where((item) {
                                  if (item.purchaseDate == null) return true;
                                  return item.purchaseDate!.year == _selectedDate.year &&
                                      item.purchaseDate!.month == _selectedDate.month;
                                }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('Belum ada pengingat belanja.', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  onTap: () {
                                    if (item.isChecked) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => CreateShoppingPage(existingItem: item)));
                                    } else {
                                      _showShoppingCheckoffDialog(item);
                                    }
                                  },
                                  leading: Checkbox(
                                    activeColor: const Color(0xFF2563EB),
                                    value: item.isChecked,
                                    onChanged: (val) {
                                      if (!item.isChecked) {
                                        _showShoppingCheckoffDialog(item);
                                      } else {
                                        _uncheckShoppingItem(item);
                                      }
                                    },
                                  ),
                                  title: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: item.isChecked ? Colors.grey.shade400 : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.notes != null && item.notes!.isNotEmpty)
                                        Text('Catatan: ${item.notes}', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontStyle: FontStyle.italic)),
                                      if (item.purchasedBy != null && item.purchasedBy!.isNotEmpty)
                                        Text('Dibeli Oleh: ${item.purchasedBy}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      if (item.location != null && item.location!.isNotEmpty)
                                        Text('Tempat: ${item.location}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      if (item.price > 0)
                                        Text('Harga: Rp ${currencyFmt.format(item.price.toInt())}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      if (item.isChecked && item.purchaseDate != null)
                                        Text('Dibeli: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.purchaseDate!)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateShoppingPage(existingItem: item)));
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          final dbService = ref.read(databaseServiceProvider);
                                          if (!kIsWeb) {
                                            await dbService.db.writeTxn(() async {
                                              item.deleted = true;
                                              item.updatedAt = DateTime.now();
                                              await dbService.db.shoppingItems.put(item);
                                            });
                                            ref.invalidate(shoppingItemsProvider);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          heroTag: 'fab_agenda',
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReminderPage()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Pengingat Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'fab_bill',
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBillPage()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Pengingat Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'fab_shopping',
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          onPressed: _showQuickAddShoppingDialog,
          icon: const Icon(Icons.add),
          label: const Text('Pengingat Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      default:
        return CircularFabMenu(
          onAddAgenda: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReminderPage()));
          },
          onAddBill: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBillPage()));
          },
          onAddShopping: _showQuickAddShoppingDialog,
        );
    }
  }

  Future<void> _uncheckShoppingItem(ShoppingItem item) async {
    item.isChecked = false;
    item.purchaseDate = null;
    item.updatedAt = DateTime.now();

    final dbService = ref.read(databaseServiceProvider);
    if (!kIsWeb) {
      await dbService.db.writeTxn(() async {
        await dbService.db.shoppingItems.put(item);
      });
      ref.invalidate(shoppingItemsProvider);
    }
  }

  Widget _buildAgendaFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _agendaFilterMode,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                items: const [
                  DropdownMenuItem(value: 'upcoming', child: Text('Mendatang')),
                  DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                  DropdownMenuItem(value: 'all', child: Text('Semua Agenda')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _agendaFilterMode = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeAllHeader(String category, bool isSeeAll, VoidCallback onToggle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isSeeAll ? 'Menampilkan Semua Data $category' : 'Sesuai Filter Tanggal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSeeAll ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSeeAll ? const Color(0xFF2563EB) : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(isSeeAll ? Icons.filter_list_off : Icons.list_alt, size: 14, color: isSeeAll ? const Color(0xFF2563EB) : Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(
                    isSeeAll ? 'Filter Tanggal' : 'Lihat Semua',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSeeAll ? const Color(0xFF2563EB) : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersDashboard7Days(
    AsyncValue<List<Reminder>> remindersAsync,
    AsyncValue<List<Bill>> billsAsync,
    AsyncValue<List<ShoppingItem>> shoppingAsync,
    bool isDark,
    NumberFormat fmt,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Statistik Informatif ──────────────────────────────────────────
          _buildInformativeStatsCard(remindersAsync, billsAsync, shoppingAsync, isDark),
          const SizedBox(height: 20),

          // ── Summary Tagihan Dipisah Dalam Card-Card Terpisah ──────────────
          _buildSplitBillSummaryCards(billsAsync, isDark, fmt),
          const SizedBox(height: 20),

          // 2. Agenda Terdekat (10 Item Terdekat)
          remindersAsync.when(
            data: (reminders) {
              final active = reminders.where((r) => !r.deleted && r.realtimeStatus != 'Selesai').toList()
                ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));
              final top10 = active.take(10).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Agenda Terdekat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text('Total: ${active.length} Agenda', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (top10.isEmpty)
                    Text('Tidak ada agenda mendatang.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
                  else
                    Column(
                      children: top10.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () {
                            _showReminderDetailBottomSheet(r);
                          },
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: _getAgendaColor(r).withOpacity(0.12),
                            child: Icon(
                              Icons.event_note_outlined,
                              color: _getAgendaColor(r),
                              size: 18,
                            ),
                          ),
                          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            _formatReminderTime(r),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getAgendaColor(r)),
                          ),
                        ),
                      )).toList(),
                    ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error: $e'),
          ),

          const SizedBox(height: 20),

          // 3. Daftar Belanja Belum Dibeli (15 Item)
          Text('Daftar Belanja Belum Dibeli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937))),
          const SizedBox(height: 10),
          shoppingAsync.when(
            data: (items) {
              final activeShopping = items.where((i) => !i.deleted && !i.isChecked).take(15).toList();

              if (activeShopping.isEmpty) {
                return Text('Tidak ada daftar belanjaan yang belum dibeli.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
              }
              return Column(
                children: activeShopping.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    onTap: () {
                      _showShoppingCheckoffDialog(item);
                    },
                    leading: Checkbox(
                      activeColor: const Color(0xFF2563EB),
                      value: item.isChecked,
                      onChanged: (val) {
                        _showShoppingCheckoffDialog(item);
                      },
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: item.notes != null ? Text(item.notes!, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontStyle: FontStyle.italic)) : null,
                  ),
                )).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBillSummaryCards(AsyncValue<List<Bill>> billsAsync, bool isDark, NumberFormat fmt) {
    return billsAsync.when(
      data: (bills) {
        // Filter tagihan sesuai bulan dan tahun terpilih agar progres reset per bulan berjalan
        final monthlyBills = bills.where((b) => b.dueDate.year == _selectedDate.year && b.dueDate.month == _selectedDate.month).toList();
        final paidCount = monthlyBills.where((b) => b.isPaid).length;
        final totalCount = monthlyBills.length;
        double progress = totalCount > 0 ? (paidCount / totalCount).clamp(0.0, 1.0) : 0.0;
        final top3Unpaid = bills.where((b) => !b.isPaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final top3 = top3Unpaid.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title disamakan dengan "Agenda Terdekat" & "Daftar Belanja Belum Dibeli"
            Text(
              'Status Pembayaran Tagihan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 10),

            // Card 1: X / Y Tagihan Dibayar Counter Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Tagihan Terbayar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: paidCount == totalCount && totalCount > 0 ? Colors.green.withOpacity(0.1) : const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$paidCount / $totalCount Tagihan Dibayar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: paidCount == totalCount && totalCount > 0 ? Colors.green : const Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Card 2: Progress Bar dengan Persentase % Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progres Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Card 3: 3 Tagihan Teratas Mendekati Jatuh Tempo (Menampilkan Tanggal Jatuh Tempo)
            if (top3.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3 Tagihan Terdekat Jatuh Tempo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    const SizedBox(height: 10),
                    Column(
                      children: top3.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('Jatuh tempo: ${DateFormat('dd MMM yyyy', 'id_ID').format(b.dueDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Text('Rp ${fmt.format(b.amount.toInt())}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildInformativeStatsCard(
    AsyncValue<List<Reminder>> remindersAsync,
    AsyncValue<List<Bill>> billsAsync,
    AsyncValue<List<ShoppingItem>> shoppingAsync,
    bool isDark,
  ) {
    int totalAgenda = 0, doneAgenda = 0;
    int totalBills = 0, doneBills = 0;
    int totalShopping = 0, doneShopping = 0;

    remindersAsync.whenData((list) {
      final active = list.where((r) => !r.deleted).toList();
      totalAgenda = active.length;
      doneAgenda = active.where((r) => r.realtimeStatus == 'Selesai').length;
    });

    billsAsync.whenData((list) {
      totalBills = list.length;
      doneBills = list.where((b) => b.isPaid).length;
    });

    shoppingAsync.whenData((list) {
      final active = list.where((i) => !i.deleted).toList();
      totalShopping = active.length;
      doneShopping = active.where((i) => i.isChecked).length;
    });

    final totalAll = totalAgenda + totalBills + totalShopping;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart_outline, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Statistik & Ringkasan Pengingat',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Total: $totalAll', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (totalAll > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (totalAgenda > 0)
                      Expanded(flex: totalAgenda, child: Container(color: const Color(0xFF2563EB))),
                    if (totalBills > 0)
                      Expanded(flex: totalBills, child: Container(color: const Color(0xFF10B981))),
                    if (totalShopping > 0)
                      Expanded(flex: totalShopping, child: Container(color: const Color(0xFFF59E0B))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Table(
            border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(2.0),
            },
            children: [
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('Kategori', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500), textAlign: TextAlign.right)),
                ],
              ),
              _buildTableRow('Agenda', '$totalAgenda', '$doneAgenda Selesai', const Color(0xFF2563EB), isDark),
              _buildTableRow('Tagihan', '$totalBills', '$doneBills Lunas', const Color(0xFF10B981), isDark),
              _buildTableRow('Belanjaan', '$totalShopping', '$doneShopping Dibeli', const Color(0xFFF59E0B), isDark),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String category, String total, String status, Color color, bool isDark) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1F2937))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(total, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)), textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildAgendaList(List<Reminder> items, String lang) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada agenda.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final reminder = items[index];
        final agendaColor = _getAgendaColor(reminder);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: agendaColor.withOpacity(0.3), width: 1.5),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            onTap: () {
              _showReminderDetailBottomSheet(reminder);
            },
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: agendaColor,
              child: const Icon(
                Icons.event_note_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _formatReminderTime(reminder),
                  style: TextStyle(color: agendaColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (reminder.description != null && reminder.description!.isNotEmpty)
                  Text(reminder.description!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () async {
                await ref.read(reminderRepositoryProvider).deleteReminder(reminder.id);
                ref.invalidate(dashboardDataProvider);
              },
            ),
          ),
        );
      },
    );
  }
}
