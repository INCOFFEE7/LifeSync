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

class _RemindersPageState extends ConsumerState<RemindersPage> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
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

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: Image.asset(
            AppEnvironment.config.getLogoFullPath(isDark),
            width: 140,
            cacheWidth: 420,
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
          bottom: TabBar(
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
        body: Stack(
          children: [
            Column(
              children: [
                // Reusable Month & Day Strip Picker Widget
                MonthDayPickerWidget(
                  selectedDate: _selectedDate,
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 0: Dashboard Pengingat Terdekat & Ter-urgent
                      _buildRemindersDashboard(remindersAsync, billsAsync, shoppingAsync, isDark, currencyFmt),

                      // Tab 1: Agenda
                      remindersAsync.when(
                        data: (reminders) {
                          final activeReminders = reminders.where((r) => !r.deleted).toList();
                          final filtered = activeReminders.where((r) =>
                            r.targetDateTime.year == _selectedDate.year &&
                            r.targetDateTime.month == _selectedDate.month &&
                            r.targetDateTime.day == _selectedDate.day
                          ).toList()..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

                          return _buildAgendaList(filtered, lang);
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Error: $e')),
                      ),

                      // Tab 2: Tagihan (Bills Hub)
                      billsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (bills) {
                          if (bills.isEmpty) {
                            return Center(
                              child: Text('Belum ada tagihan di bulan ini.', style: TextStyle(color: Colors.grey.shade500)),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bills.length,
                            itemBuilder: (context, idx) {
                              final bill = bills[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: bill.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                                    child: Icon(
                                      bill.isPaid ? Icons.check_circle : Icons.receipt_long,
                                      color: bill.isPaid ? Colors.green : Colors.redAccent,
                                    ),
                                  ),
                                  title: Text(bill.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Jatuh tempo: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}'),
                                  trailing: Text('Rp ${currencyFmt.format(bill.amount.toInt())}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Tab 3: Belanja (Shopping Checklist Hub)
                      shoppingAsync.when(
                        data: (items) {
                          final filtered = items.where((item) {
                            if (item.purchaseDate == null) return true;
                            return item.purchaseDate!.year == _selectedDate.year &&
                                item.purchaseDate!.month == _selectedDate.month &&
                                item.purchaseDate!.day == _selectedDate.day;
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('Belum ada pengingat belanja di tanggal ini.', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final subCount = item.itemsList.length;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Checkbox(
                                    activeColor: const Color(0xFF2563EB),
                                    value: item.isChecked,
                                    onChanged: (val) async {
                                      bool isChecked = val ?? false;
                                      if (isChecked) {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2035),
                                          helpText: 'Pilih Tanggal Dibeli',
                                        );
                                        if (pickedDate != null) {
                                          item.purchaseDate = pickedDate;
                                        }
                                      }
                                      item.isChecked = isChecked;
                                      item.updatedAt = DateTime.now();
                                      final dbService = ref.read(databaseServiceProvider);
                                      if (!kIsWeb) {
                                        await dbService.db.writeTxn(() async {
                                          await dbService.db.shoppingItems.put(item);
                                        });
                                        ref.invalidate(shoppingItemsProvider);
                                      }
                                    },
                                  ),
                                  title: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                      color: item.isChecked ? Colors.grey.shade400 : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (item.price > 0)
                                        Text('Harga Beli: Rp ${currencyFmt.format(item.price.toInt())}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                      if (item.purchaseDate != null)
                                        Text('Tanggal Dibeli: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.purchaseDate!)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      if (subCount > 0)
                                        Text('$subCount barang belanjaan', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateShoppingPage(existingItem: item)));
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
                    ],
                  ),
                ),
              ],
            ),

            // Circular Action Menu
            CircularFabMenu(
              onAddAgenda: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReminderPage()));
              },
              onAddBill: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBillPage()));
              },
              onAddShopping: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateShoppingPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersDashboard(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Pusat Pengingat Terurgent',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Agenda, tagihan, dan daftar belanjaan terdekat Anda disajikan secara terpadu.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Tagihan Urgent (Mendatang)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937))),
          const SizedBox(height: 10),
          billsAsync.when(
            data: (bills) {
              final unpaidBills = bills.where((b) => !b.isPaid).toList();
              if (unpaidBills.isEmpty) {
                return Text('Tidak ada tagihan mendesak.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
              }
              return Column(
                children: unpaidBills.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.redAccent),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Jatuh tempo: ${DateFormat('dd MMM yyyy').format(b.dueDate)}'),
                    trailing: Text('Rp ${fmt.format(b.amount.toInt())}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                )).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error: $e'),
          ),

          const SizedBox(height: 20),
          Text('Agenda Terdekat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937))),
          const SizedBox(height: 10),
          remindersAsync.when(
            data: (reminders) {
              final active = reminders.where((r) => !r.deleted && r.realtimeStatus != 'Selesai').toList();
              if (active.isEmpty) {
                return Text('Tidak ada agenda mendesak.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
              }
              return Column(
                children: active.take(3).map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.alarm, color: Color(0xFF2563EB)),
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(r.targetDateTime)),
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

  Widget _buildAgendaList(List<Reminder> items, String lang) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada agenda di tanggal ini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final reminder = items[index];
        final timeRangeStr = '${DateFormat('HH:mm', 'id_ID').format(reminder.targetDateTime)} - ${DateFormat('HH:mm', 'id_ID').format(reminder.effectiveEndTime)}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF2563EB).withOpacity(0.3), width: 1.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.alarm, color: Colors.white, size: 20),
            ),
            title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(timeRangeStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                if (reminder.description != null && reminder.description!.isNotEmpty)
                  Text(reminder.description!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
