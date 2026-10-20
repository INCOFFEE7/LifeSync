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
import 'package:lifesync_app/presentation/pages/create_reminder_page.dart';
import 'package:lifesync_app/presentation/pages/add_edit_bill_page.dart';
import 'package:lifesync_app/presentation/pages/create_shopping_page.dart';
import 'package:lifesync_app/presentation/widgets/circular_fab_menu.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
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
  String _periodScope = 'month'; // 'month', 'all', 'range'
  DateTimeRange? _selectedDateRange;
  String _agendaFilterMode = 'upcoming'; // 'upcoming', 'completed', 'all'
  String _shoppingFilterMode = 'unbought'; // 'unbought', 'bought', 'all'
  String _billFilterMode = 'all'; // 'all', 'unpaid', 'paid'
  bool _purchasedExpanded = false;

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
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
                            color: agendaColor.withValues(alpha: 0.1),
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
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                        color: (r.priority == PriorityLevel.high ? Colors.red : (r.priority == PriorityLevel.medium ? Colors.orange : Colors.green)).withValues(alpha: 0.1),
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
                          color: Colors.amber.shade700.withValues(alpha: 0.1),
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
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
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
                        color: (isCompleted ? Colors.green : (r.realtimeStatus == 'Sedang Berjalan' ? Colors.blue : Colors.grey)).withValues(alpha: 0.1),
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
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
                  color: Colors.red.withValues(alpha: 0.1),
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

  List<int> _computeStats(
    AsyncValue<List<Reminder>> remindersAsync,
    AsyncValue<List<Bill>> billsAsync,
    AsyncValue<List<ShoppingItem>> shoppingAsync,
  ) {
    final reminders = (remindersAsync.valueOrNull ?? const <Reminder>[]).where((r) => !r.deleted).toList();
    final bills = billsAsync.valueOrNull ?? const <Bill>[];
    final shopping = (shoppingAsync.valueOrNull ?? const <ShoppingItem>[]).where((i) => !i.deleted).toList();
    return [
      reminders.length,
      reminders.where((r) => r.realtimeStatus == 'Selesai').length,
      bills.length,
      bills.where((b) => b.isPaid).length,
      shopping.length,
      shopping.where((i) => i.isChecked).length,
    ];
  }

  // ── Navigasi periode & filter ─────────────────────────────────────────────
  bool _matchesPeriod(DateTime date) {
    if (_periodScope == 'all') return true;
    if (_periodScope == 'range' && _selectedDateRange != null) {
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
    }
    return date.year == _selectedDate.year && date.month == _selectedDate.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _periodScope = 'month';
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(_selectedDate.year, _selectedDate.month, 1),
        end: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: LsColors.brand,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _periodScope = 'range';
      });
    }
  }

  Widget _monthNav() {
    String label;
    if (_periodScope == 'all') {
      label = 'Semua Data';
    } else if (_periodScope == 'range' && _selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      label = '${DateFormat('d MMM', 'id_ID').format(s)} – ${DateFormat('d MMM yyyy', 'id_ID').format(e)}';
    } else {
      label = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);
    }

    final isMonth = _periodScope == 'month';

    Widget arrow(IconData icon, int delta) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isMonth ? () => _shiftMonth(delta) : null,
          child: Opacity(
            opacity: isMonth ? 1.0 : 0.25,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: LsColors.paper(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LsColors.line(context)),
              ),
              child: Icon(icon, size: 18, color: LsColors.ink(context)),
            ),
          ),
        );

    return Row(
      children: [
        arrow(Icons.chevron_left_rounded, -1),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (_periodScope == 'range') {
                _pickDateRange();
              } else {
                _pickMonth();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  const LsEyebrow('Periode'),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: LsColors.ink(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        arrow(Icons.chevron_right_rounded, 1),
      ],
    );
  }

  Widget _filterHeader({Widget? extraDropdown}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: LsColors.surface(context),
        border: Border(bottom: BorderSide(color: LsColors.line(context))),
      ),
      child: Column(
        children: [
          _monthNav(),
          const SizedBox(height: 8),
          Row(
            children: [
              LsCapsuleDropdown<String>(
                width: 135,
                value: _periodScope,
                isHighlighted: _periodScope != 'all',
                options: const [
                  LsDropdownOption(value: 'month', label: 'Bulan Ini', icon: Icons.calendar_today_outlined),
                  LsDropdownOption(value: 'all', label: 'Semua Data', icon: Icons.all_inclusive_outlined),
                  LsDropdownOption(value: 'range', label: 'Pilih Rentang', icon: Icons.date_range_outlined),
                ],
                onSelected: (val) {
                  if (val == 'range') {
                    _pickDateRange();
                  } else {
                    setState(() {
                      _periodScope = val;
                      if (val == 'month') _selectedDate = DateTime.now();
                    });
                  }
                },
              ),
              if (extraDropdown != null) ...[
                const SizedBox(width: 8),
                extraDropdown,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: LsColors.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: LsColors.brand),
          ),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: LsColors.mute(context), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pillTabBar(List<int> counts) {
    const labels = ['Ringkasan', 'Agenda', 'Tagihan', 'Belanja'];
    final badge = [null, counts[0] - counts[1], counts[2] - counts[3], counts[4] - counts[5]];
    return Container(
      color: LsColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: LsColors.paper(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LsColors.line(context)),
        ),
        child: Row(
          children: List.generate(4, (i) {
            final sel = _tabController.index == i;
            final n = badge[i];
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tabController.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? LsColors.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          labels[i],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: sel ? Colors.white : LsColors.mute(context),
                          ),
                        ),
                      ),
                      if (n != null && n > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withValues(alpha: 0.25) : LsColors.brand.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: sel ? Colors.white : LsColors.brand),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersStreamProvider);
    final shoppingAsync = ref.watch(shoppingItemsProvider);
    final monthKey = DateFormat('yyyy-MM').format(_selectedDate);
    final billsAsync = ref.watch(billsStreamProvider(monthKey));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final counts = _computeStats(remindersAsync, billsAsync, shoppingAsync);

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LsColors.brand),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _pillTabBar(counts),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersDashboard7Days(remindersAsync, billsAsync, shoppingAsync, currencyFmt),
          _buildAgendaTab(remindersAsync),
          _buildBillsTab(billsAsync, currencyFmt),
          _buildShoppingTab(shoppingAsync, currencyFmt),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Tab Agenda ──────────────────────────────────────────────────────────────
  Widget _buildAgendaTab(AsyncValue<List<Reminder>> remindersAsync) {
    return Column(
      children: [
        _filterHeader(
          extraDropdown: LsCapsuleDropdown<String>(
            width: 140,
            value: _agendaFilterMode,
            isHighlighted: _agendaFilterMode != 'all',
            activeColor: _agendaFilterMode == 'completed' ? LsColors.income : LsColors.brand,
            options: const [
              LsDropdownOption(value: 'upcoming', label: 'Mendatang', icon: Icons.upcoming_outlined),
              LsDropdownOption(value: 'completed', label: 'Selesai', icon: Icons.check_circle_outline),
              LsDropdownOption(value: 'all', label: 'Semua Agenda', icon: Icons.list_alt_rounded),
            ],
            onSelected: (val) => setState(() => _agendaFilterMode = val),
          ),
        ),
        Expanded(
          child: remindersAsync.when(
            data: (reminders) {
              final activeReminders = reminders.where((r) => !r.deleted).toList();
              final periodFiltered = activeReminders.where((r) => _matchesPeriod(r.targetDateTime)).toList();

              final filtered = periodFiltered.where((r) {
                if (_agendaFilterMode == 'upcoming') {
                  return r.realtimeStatus != 'Selesai';
                } else if (_agendaFilterMode == 'completed') {
                  return r.realtimeStatus == 'Selesai';
                }
                return true;
              }).toList()
                ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

              return _buildAgendaList(filtered);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  // ── Tab Tagihan ─────────────────────────────────────────────────────────────
  Future<void> _copyBillToNextMonth(Bill bill) async {
    final nextMonthDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    final nextMonthKey = DateFormat('yyyy-MM').format(nextMonthDate);

    final newDay = bill.dueDate.day.clamp(1, 28);
    final nextDueDate = DateTime(nextMonthDate.year, nextMonthDate.month, newDay);

    final repo = ref.read(billRepositoryProvider);

    final isDup = await repo.checkDuplicateBill(bill.name, nextMonthKey);
    if (isDup && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Duplikasi Tagihan'),
          content: Text('Tagihan "${bill.name}" untuk bulan ${DateFormat('MMMM yyyy', 'id_ID').format(nextMonthDate)} sudah tersedia.\n\nApakah Anda ingin membuat salinan baru?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Salin', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await repo.copyBillToMonth(bill, nextMonthKey, nextDueDate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tagihan "${bill.name}" berhasil disalin ke ${DateFormat('MMMM yyyy', 'id_ID').format(nextMonthDate)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDeleteBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tagihan?'),
        content: Text('Apakah Anda yakin ingin menghapus tagihan "${bill.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(billRepositoryProvider).deleteBill(bill.id);
    }
  }

  Widget _buildBillsTab(AsyncValue<List<Bill>> billsAsync, NumberFormat fmt) {
    return Column(
      children: [
        _filterHeader(
          extraDropdown: LsCapsuleDropdown<String>(
            width: 140,
            value: _billFilterMode,
            isHighlighted: _billFilterMode != 'all',
            activeColor: _billFilterMode == 'paid' ? LsColors.income : (_billFilterMode == 'unpaid' ? LsColors.expense : LsColors.brand),
            options: const [
              LsDropdownOption(value: 'all', label: 'Semua Tagihan', icon: Icons.receipt_long_outlined),
              LsDropdownOption(value: 'unpaid', label: 'Belum Lunas', icon: Icons.hourglass_empty_rounded, color: LsColors.expense),
              LsDropdownOption(value: 'paid', label: 'Lunas', icon: Icons.check_circle_outline, color: LsColors.income),
            ],
            onSelected: (val) => setState(() => _billFilterMode = val),
          ),
        ),
        Expanded(
          child: billsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (bills) {
              final periodFiltered = bills.where((b) => !b.deleted && _matchesPeriod(b.dueDate)).toList();
              final displayBills = periodFiltered.where((b) {
                if (_billFilterMode == 'unpaid') return !b.isPaid;
                if (_billFilterMode == 'paid') return b.isPaid;
                return true;
              }).toList();

              if (displayBills.isEmpty) {
                return _emptyState(Icons.receipt_long_outlined, 'Belum ada data tagihan.');
              }

              double totalPlan = 0, totalReal = 0, totalRemaining = 0;
              int paid = 0;
              for (final b in displayBills) {
                final real = b.realizationAmount ?? 0.0;
                totalPlan += b.amount;
                totalReal += real;
                if (b.isPaid) {
                  paid++;
                } else {
                  totalRemaining += (b.amount - real).clamp(0.0, double.infinity);
                }
              }
              final progress = displayBills.isEmpty ? 0.0 : paid / displayBills.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  LsHeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: LsEyebrow('Sisa Tagihan', color: Colors.white70)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                              child: Text('$paid / ${displayBills.length} Lunas', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rp ${fmt.format(totalRemaining.toInt())}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.5),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            color: LsColors.income,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _heroStat('Total Rencana', 'Rp ${fmt.format(totalPlan.toInt())}')),
                            const SizedBox(width: 10),
                            Expanded(child: _heroStat('Total Realisasi', 'Rp ${fmt.format(totalReal.toInt())}')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const LsSectionHeader(title: 'Daftar Tagihan'),
                  const SizedBox(height: 12),
                  for (final bill in displayBills) _buildBillCard(bill, fmt),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _heroStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white70)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(Bill bill, NumberFormat fmt) {
    final realization = bill.realizationAmount ?? 0.0;
    final diff = realization - bill.amount;
    final remaining = (bill.amount - realization).clamp(0.0, double.infinity);
    final today = DateTime.now();
    final overdue = !bill.isPaid && bill.dueDate.isBefore(DateTime(today.year, today.month, today.day));

    String statusText;
    Color statusColor;
    if (bill.isPaid) {
      if (diff > 0) {
        statusText = 'Kelebihan: Rp ${fmt.format(diff.toInt())}';
        statusColor = LsColors.brand;
      } else if (diff < 0) {
        statusText = 'Hemat: Rp ${fmt.format(diff.abs().toInt())}';
        statusColor = LsColors.amber;
      } else {
        statusText = 'Lunas Sesuai Rencana';
        statusColor = LsColors.income;
      }
    } else {
      statusText = 'Sisa Tagihan: Rp ${fmt.format(remaining.toInt())}';
      statusColor = LsColors.expense;
    }
    final accent = bill.isPaid ? LsColors.income : LsColors.expense;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LsCard(
        onTap: () => _handleBillToggle(bill),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(bill.isPaid ? Icons.check_circle_rounded : Icons.receipt_long_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bill.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: LsColors.ink(context)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (bill.isPaid) const LsChip('Lunas', color: LsColors.income) else if (overdue) const LsChip('Terlambat', color: LsColors.expense),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                    style: TextStyle(fontSize: 11.5, color: LsColors.mute(context)),
                  ),
                  const SizedBox(height: 3),
                  Text(statusText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: statusColor)),
                ],
              ),
            ),
            Text(
              'Rp ${fmt.format(bill.amount.toInt())}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: LsColors.brand),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: LsColors.mute(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) async {
                if (val == 'copy') {
                  await _copyBillToNextMonth(bill);
                } else if (val == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditBillPage(existingBill: bill)));
                } else if (val == 'delete') {
                  await _confirmDeleteBill(bill);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(children: [
                    Icon(Icons.copy_rounded, size: 18, color: LsColors.brand),
                    SizedBox(width: 8),
                    Text('Copy ke Bulan Berikutnya'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text('Edit Tagihan'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: LsColors.expense),
                    SizedBox(width: 8),
                    Text('Hapus Tagihan', style: TextStyle(color: LsColors.expense)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Belanja ─────────────────────────────────────────────────────────────
  Widget _buildShoppingTab(AsyncValue<List<ShoppingItem>> shoppingAsync, NumberFormat fmt) {
    return Column(
      children: [
        _filterHeader(
          extraDropdown: LsCapsuleDropdown<String>(
            width: 140,
            value: _shoppingFilterMode,
            isHighlighted: _shoppingFilterMode != 'all',
            activeColor: _shoppingFilterMode == 'bought' ? LsColors.income : LsColors.amber,
            options: const [
              LsDropdownOption(value: 'unbought', label: 'Belum Dibeli', icon: Icons.radio_button_unchecked),
              LsDropdownOption(value: 'bought', label: 'Sudah Dibeli', icon: Icons.check_circle_outline),
              LsDropdownOption(value: 'all', label: 'Semua Belanja', icon: Icons.shopping_bag_outlined),
            ],
            onSelected: (val) => setState(() => _shoppingFilterMode = val),
          ),
        ),
        Expanded(
          child: shoppingAsync.when(
            data: (items) {
              final activeItems = items.where((i) => !i.deleted).toList();
              final periodFiltered = activeItems.where((item) {
                if (item.purchaseDate == null) return true;
                return _matchesPeriod(item.purchaseDate!);
              }).toList();

              final filtered = periodFiltered.where((i) {
                if (_shoppingFilterMode == 'unbought') return !i.isChecked;
                if (_shoppingFilterMode == 'bought') return i.isChecked;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return _emptyState(Icons.shopping_cart_outlined, 'Belum ada pengingat belanja.');
              }

              final pending = filtered.where((i) => !i.isChecked).toList();
              final bought = filtered.where((i) => i.isChecked).toList();
              final byStore = <String, List<ShoppingItem>>{};
              for (final i in pending) {
                final store = (i.location != null && i.location!.trim().isNotEmpty) ? i.location!.trim() : 'Belum Ditentukan';
                byStore.putIfAbsent(store, () => []).add(i);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  for (final entry in byStore.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 16, color: LsColors.amber),
                          const SizedBox(width: 6),
                          Expanded(child: LsEyebrow(entry.key)),
                          LsChip('${entry.value.length} item', color: LsColors.amber),
                        ],
                      ),
                    ),
                    for (final item in entry.value) _buildShoppingRow(item, fmt),
                    const SizedBox(height: 8),
                  ],
                  if (pending.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('Semua barang sudah dibeli.', style: TextStyle(color: LsColors.mute(context), fontWeight: FontWeight.w600))),
                    ),
                  if (bought.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    LsCard(
                      onTap: () => setState(() => _purchasedExpanded = !_purchasedExpanded),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: LsColors.income.withValues(alpha: 0.14), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 18, color: LsColors.income),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Sudah dibeli', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: LsColors.ink(context))),
                          ),
                          LsChip('${bought.length}', color: LsColors.income),
                          const SizedBox(width: 6),
                          Icon(_purchasedExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: LsColors.mute(context)),
                        ],
                      ),
                    ),
                    if (_purchasedExpanded) ...[
                      const SizedBox(height: 10),
                      for (final item in bought) _buildShoppingRow(item, fmt),
                    ],
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingRow(ShoppingItem item, NumberFormat fmt) {
    final mute = LsColors.mute(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LsCard(
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        onTap: () {
          if (item.isChecked) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CreateShoppingPage(existingItem: item)));
          } else {
            _showShoppingCheckoffDialog(item);
          }
        },
        child: Row(
          children: [
            Checkbox(
              activeColor: LsColors.income,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              value: item.isChecked,
              onChanged: (val) {
                if (!item.isChecked) {
                  _showShoppingCheckoffDialog(item);
                } else {
                  _uncheckShoppingItem(item);
                }
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        color: item.isChecked ? mute : LsColors.ink(context),
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text('Catatan: ${item.notes}', style: const TextStyle(fontSize: 11, color: LsColors.brand, fontStyle: FontStyle.italic)),
                    if (item.purchasedBy != null && item.purchasedBy!.isNotEmpty)
                      Text('Dibeli Oleh: ${item.purchasedBy}', style: TextStyle(fontSize: 11, color: mute)),
                    if (item.location != null && item.location!.isNotEmpty)
                      Text('Tempat: ${item.location}', style: TextStyle(fontSize: 11, color: mute)),
                    if (item.price > 0)
                      Text('Harga: Rp ${fmt.format(item.price.toInt())}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: LsColors.income)),
                    if (item.isChecked && item.purchaseDate != null)
                      Text('Dibeli: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.purchaseDate!)}', style: const TextStyle(fontSize: 11, color: LsColors.income, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: mute),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateShoppingPage(existingItem: item)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: LsColors.expense),
              padding: const EdgeInsets.all(6),
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
  }


  Widget _buildFAB() {
    switch (_tabController.index) {
      case 1:
        return LsCompactFab(
          heroTag: 'fab_agenda',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReminderPage()));
          },
          label: 'Pengingat Agenda',
        );
      case 2:
        return LsCompactFab(
          heroTag: 'fab_bill',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBillPage()));
          },
          label: 'Pengingat Tagihan',
        );
      case 3:
        return LsCompactFab(
          heroTag: 'fab_shopping',
          onPressed: _showQuickAddShoppingDialog,
          label: 'Pengingat Belanja',
        );
      default:
        return Container(
          margin: const EdgeInsets.only(bottom: 22, right: 4),
          child: CircularFabMenu(
            onAddAgenda: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReminderPage()));
            },
            onAddBill: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBillPage()));
            },
            onAddShopping: _showQuickAddShoppingDialog,
          ),
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

  Widget _buildRemindersDashboard7Days(
    AsyncValue<List<Reminder>> remindersAsync,
    AsyncValue<List<Bill>> billsAsync,
    AsyncValue<List<ShoppingItem>> shoppingAsync,
    NumberFormat fmt,
  ) {
    final s = _computeStats(remindersAsync, billsAsync, shoppingAsync);
    final totalAll = s[0] + s[2] + s[4];
    final doneAll = s[1] + s[3] + s[5];
    final progress = totalAll > 0 ? doneAll / totalAll : 0.0;

    Widget heroPill(String label, int done, int total) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 2),
                Text('$done / $total', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LsHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LsRing(
                      progress: progress,
                      size: 92,
                      stroke: 10,
                      color: LsColors.income,
                      child: Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LsEyebrow('Pengingat Tersisa', color: Colors.white70),
                          const SizedBox(height: 4),
                          Text('${totalAll - doneAll}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1.05, letterSpacing: -1)),
                          Text('$doneAll dari $totalAll selesai', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    heroPill('Agenda', s[1], s[0]),
                    const SizedBox(width: 8),
                    heroPill('Tagihan', s[3], s[2]),
                    const SizedBox(width: 8),
                    heroPill('Belanja', s[5], s[4]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSplitBillSummaryCards(billsAsync, fmt),
          const SizedBox(height: 24),

          _buildOverviewMatrix(s),
          const SizedBox(height: 24),

          remindersAsync.when(
            data: (reminders) {
              final active = reminders.where((r) => !r.deleted && r.realtimeStatus != 'Selesai').toList()
                ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));
              final top10 = active.take(10).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: LsSectionHeader(title: 'Agenda Terdekat')),
                      LsChip('Total: ${active.length} Agenda', color: LsColors.brand),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (top10.isEmpty)
                    Text('Tidak ada agenda mendatang.', style: TextStyle(color: LsColors.mute(context), fontSize: 13))
                  else
                    Column(children: top10.map((r) => _buildAgendaRow(r, showDelete: false)).toList()),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),

          const SizedBox(height: 24),

          const LsSectionHeader(title: 'Daftar Belanja Belum Dibeli'),
          const SizedBox(height: 12),
          shoppingAsync.when(
            data: (items) {
              final activeShopping = items.where((i) => !i.deleted && !i.isChecked).take(15).toList();

              if (activeShopping.isEmpty) {
                return Text('Tidak ada daftar belanjaan yang belum dibeli.', style: TextStyle(color: LsColors.mute(context), fontSize: 13));
              }
              return Column(
                children: activeShopping
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LsCard(
                            padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
                            onTap: () => _showShoppingCheckoffDialog(item),
                            child: Row(
                              children: [
                                Checkbox(
                                  activeColor: LsColors.income,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  value: item.isChecked,
                                  onChanged: (val) => _showShoppingCheckoffDialog(item),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: LsColors.ink(context))),
                                      if (item.notes != null)
                                        Text(item.notes!, style: const TextStyle(fontSize: 11, color: LsColors.brand, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBillSummaryCards(AsyncValue<List<Bill>> billsAsync, NumberFormat fmt) {
    return billsAsync.when(
      data: (bills) {
        final top3 = (bills.where((b) => !b.isPaid).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate))).take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LsSectionHeader(title: '3 Tagihan Terdekat Jatuh Tempo'),
            const SizedBox(height: 12),
            if (top3.isEmpty)
              LsCard(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: LsColors.income),
                    const SizedBox(width: 10),
                    Text('Tidak ada tagihan yang belum dibayar.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LsColors.mute(context))),
                  ],
                ),
              )
            else
              LsCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    for (int i = 0; i < top3.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: LsColors.line(context)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(color: LsColors.expense.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Text(DateFormat('dd').format(top3[i].dueDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: LsColors.expense, height: 1)),
                                  Text(DateFormat('MMM', 'id_ID').format(top3[i].dueDate).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: LsColors.expense)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(top3[i].name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: LsColors.ink(context))),
                                  const SizedBox(height: 2),
                                  Text('Jatuh tempo: ${DateFormat('dd MMM yyyy', 'id_ID').format(top3[i].dueDate)}', style: TextStyle(fontSize: 11, color: LsColors.mute(context))),
                                ],
                              ),
                            ),
                            Text('Rp ${fmt.format(top3[i].amount.toInt())}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LsColors.brand)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildOverviewMatrix(List<int> s) {
    Widget row(int tab, IconData icon, Color color, String label, int total, int done, String doneLabel) {
      final p = total > 0 ? done / total : 0.0;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _tabController.animateTo(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: LsColors.ink(context)))),
                        Text('$done $doneLabel', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: p, minHeight: 6, backgroundColor: LsColors.line(context), color: color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text('$total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: LsColors.ink(context))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: LsSectionHeader(title: 'Statistik & Ringkasan Pengingat')),
            LsChip('Total: ${s[0] + s[2] + s[4]}', color: LsColors.brand),
          ],
        ),
        const SizedBox(height: 12),
        LsCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              row(1, Icons.event_note_rounded, LsColors.brand, 'Agenda', s[0], s[1], 'Selesai'),
              Divider(height: 1, color: LsColors.line(context)),
              row(2, Icons.receipt_long_rounded, LsColors.income, 'Tagihan', s[2], s[3], 'Lunas'),
              Divider(height: 1, color: LsColors.line(context)),
              row(3, Icons.shopping_basket_rounded, LsColors.amber, 'Belanjaan', s[4], s[5], 'Dibeli'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaRow(Reminder r, {bool showDelete = true}) {
    final prio = r.priority == PriorityLevel.high
        ? LsColors.expense
        : (r.priority == PriorityLevel.medium ? LsColors.amber : LsColors.income);
    final status = r.realtimeStatus;
    final statusColor = status == 'Selesai' ? LsColors.income : (status == 'Sedang Berjalan' ? LsColors.amber : LsColors.brand);
    final category = r.category == ReminderCategory.other && (r.customCategory?.isNotEmpty ?? false)
        ? r.customCategory!
        : '${r.category.name[0].toUpperCase()}${r.category.name.substring(1)}';
    final mute = LsColors.mute(context);

    final String timeTop;
    final String timeBottom;
    if (r.isRange) {
      timeTop = DateFormat('dd MMM', 'id_ID').format(r.targetDateTime);
      timeBottom = 's/d ${DateFormat('dd MMM', 'id_ID').format(r.effectiveEndTime)}';
    } else if (r.isAllDay) {
      timeTop = 'Seharian';
      timeBottom = 'Full Day';
    } else {
      timeTop = DateFormat('HH:mm', 'id_ID').format(r.targetDateTime);
      timeBottom = DateFormat('HH:mm', 'id_ID').format(r.effectiveEndTime);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LsCard(
        padding: EdgeInsets.zero,
        onTap: () => _showReminderDetailBottomSheet(r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(color: prio, borderRadius: const BorderRadius.horizontal(left: Radius.circular(19))),
              ),
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(timeTop, textAlign: TextAlign.center, style: TextStyle(fontSize: r.isAllDay && !r.isRange ? 12 : 15, fontWeight: FontWeight.w800, color: LsColors.ink(context))),
                    const SizedBox(height: 2),
                    Text(timeBottom, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mute)),
                  ],
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: LsColors.line(context), indent: 10, endIndent: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: LsColors.ink(context))),
                      if (r.description != null && r.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(r.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: mute, fontSize: 11.5, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          LsChip(category, color: LsColors.violet),
                          LsChip(status, color: statusColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (showDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: LsColors.expense, size: 18),
                  onPressed: () async {
                    await ref.read(reminderRepositoryProvider).deleteReminder(r.id);
                    ref.invalidate(dashboardDataProvider);
                  },
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaList(List<Reminder> items) {
    if (items.isEmpty) {
      return _emptyState(Icons.event_note_outlined, 'Belum ada agenda.');
    }

    final entries = <Object>[];
    DateTime? lastDay;
    for (final r in items) {
      final d = DateTime(r.targetDateTime.year, r.targetDateTime.month, r.targetDateTime.day);
      if (lastDay == null || d != lastDay) {
        entries.add(d);
        lastDay = d;
      }
      entries.add(r);
    }
    final perDay = <DateTime, int>{};
    for (final r in items) {
      final d = DateTime(r.targetDateTime.year, r.targetDateTime.month, r.targetDateTime.day);
      perDay[d] = (perDay[d] ?? 0) + 1;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        if (e is DateTime) {
          final isToday = e == today;
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                Expanded(child: LsEyebrow(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(e), color: isToday ? LsColors.brand : null)),
                if (isToday) ...[const LsChip('Hari Ini', color: LsColors.brand), const SizedBox(width: 6)],
                LsChip('${perDay[e]} agenda', color: LsColors.mute(context)),
              ],
            ),
          );
        }
        return _buildAgendaRow(e as Reminder);
      },
    );
  }
}
