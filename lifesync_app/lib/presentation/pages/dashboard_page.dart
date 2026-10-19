import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/pages/create_shopping_page.dart';
import 'package:lifesync_app/presentation/screens/cloud_backup_settings_screen.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/domain/usecases/countdown_usecase.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/pages/settings_page.dart';
import 'package:lifesync_app/presentation/pages/reminders_page.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/config/app_variant.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Set<int> _pinnedReminderIds = {};
  final PageController _recommendationPageController = PageController();
  int _recommendationPage = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void dispose() {
    _recommendationPageController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final rIds = await HomeWidgetService.getPinnedReminderIds();
    if (mounted) {
      setState(() {
        _pinnedReminderIds = rIds.toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final financialSummary = ref.watch(filteredSummaryProvider);
    final shoppingAsync = ref.watch(shoppingItemsProvider);

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    final billsAsync = ref.watch(billsStreamProvider(currentMonthKey));

    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: _buildHeader(),
      body: dashboardAsync.when(
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. PENGINGAT (Agenda Hari Ini & Reminders) ───────────────
                _buildSectionTitle(AppTranslations.get(lang, 'pengingat')),
                const SizedBox(height: 12),
                _buildAgendaSummaryCard(data, lang),
                const SizedBox(height: 12),
                _buildRemindersSection(data.upcomingReminders),
                const SizedBox(height: 24),

                // ── 2. DAFTAR BELANJA BELUM DIBELI ───────────────────────────
                _buildSectionTitle('Daftar Belanja Belum Dibeli'),
                const SizedBox(height: 12),
                _buildShoppingListSection(shoppingAsync, currencyFmt, isDark),
                const SizedBox(height: 24),

                // ── 3. KEUANGAN (Rangkuman Transaksi & Tagihan 7 Hari) ───────
                _buildSectionTitle(AppTranslations.get(lang, 'keuangan')),
                const SizedBox(height: 12),
                _buildFinancialTransactionsSummaryCard(financialSummary, currencyFmt),
                const SizedBox(height: 12),
                billsAsync.when(
                  data: (bills) {
                    // Tagihan belum dibayar yang jatuh tempo dalam kisaran 7 hari
                    final upcomingBills = bills.where((b) {
                      if (b.deleted || b.isPaid) return false;
                      final diffDays = b.dueDate.difference(now).inDays;
                      return diffDays >= -1 && diffDays <= 7;
                    }).toList()
                      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

                    return _buildUpcomingBillsSection(upcomingBills, currencyFmt);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── 4. NABUNG (Total Tabungan & Recommendations) ───────────────
                _buildSectionTitle('Nabung'),
                const SizedBox(height: 12),
                _buildSavingsOverviewCard(data, lang, currencyFmt),
                const SizedBox(height: 16),
                _buildNabungSection(data.topTargets),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAgendaSummaryCard(DashboardData data, String lang) {
    return _buildFlatCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.get(lang, 'agenda_hari_ini'),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.todayRemindersCount} ${AppTranslations.get(lang, 'hari_ini_unit')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total Agenda: ${data.activeRemindersCount}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTransactionsSummaryCard(FinancialSummary summary, NumberFormat fmt) {
    final netPositive = summary.netBalance >= 0;

    return _buildFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rangkuman Transaksi Keuangan',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
              const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF2563EB), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pemasukan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Rp ${fmt.format(summary.totalIncome.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey.shade200),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('Rp ${fmt.format(summary.totalExpense.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey.shade200),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Bersih', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${netPositive ? '+' : '-'}Rp ${fmt.format(summary.netBalance.abs().toInt())}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: netPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBillsSection(List<Bill> upcomingBills, NumberFormat fmt) {
    if (upcomingBills.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RemindersPage()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tagihan Mendatang (7 Hari)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Text('${upcomingBills.length} Tagihan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...upcomingBills.map((b) {
              final daysLeft = b.dueDate.difference(DateTime.now()).inDays;
              String timeText = daysLeft == 0 ? 'Hari ini' : '$daysLeft hari lagi';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.orange.shade200, width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long, color: Colors.orange, size: 20),
                  ),
                  title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Jatuh tempo: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(b.dueDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rp ${fmt.format(b.amount.toInt())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                      Text(timeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsOverviewCard(DashboardData data, String lang, NumberFormat fmt) {
    double progress = data.totalTargetAmount > 0 ? (data.totalSavings / data.totalTargetAmount).clamp(0.0, 1.0) : 0.0;
    int percentage = (progress * 100).toInt();

    return _buildFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppTranslations.get(lang, 'total_tabungan'),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('${data.topTargets.length} Target',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${fmt.format(data.totalSavings.toInt())}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
              Text(
                '$percentage% Tercapai',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'dari Rp ${fmt.format(data.totalTargetAmount.toInt())}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection(List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return _buildEmptyCard('Belum ada pengingat terdekat.');
    }
    return Column(
      children: reminders
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildReminderCard(r),
              ))
          .toList(),
    );
  }

  Widget _buildShoppingItemSecondaryDetails(ShoppingItem item, NumberFormat currencyFmt, bool isDark) {
    final List<Widget> details = [];
    final mutedStyle = TextStyle(
      fontSize: 11,
      color: isDark ? Colors.white54 : Colors.grey.shade600,
    );

    if (item.purchasedBy != null && item.purchasedBy!.trim().isNotEmpty) {
      details.add(Text('Dibeli Oleh: ${item.purchasedBy!.trim()}', style: mutedStyle));
    }
    if (item.price > 0) {
      details.add(Text(
        'Harga: Rp ${currencyFmt.format(item.price.toInt())}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
      ));
    }
    if (item.location != null && item.location!.trim().isNotEmpty) {
      details.add(Text('Tempat: ${item.location!.trim()}', style: mutedStyle));
    }
    if (item.notes != null && item.notes!.trim().isNotEmpty) {
      details.add(Text(
        'Catatan: ${item.notes!.trim()}',
        style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontStyle: FontStyle.italic),
      ));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.map((d) => Padding(padding: const EdgeInsets.only(top: 2), child: d)).toList(),
    );
  }

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

                    // Dibeli Oleh (Opsional)
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

                    // Tempat Membeli (Opsional)
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

                    // Harga (Opsional - Kalkulator)
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

                    // Tanggal Pembayaran
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

  Widget _buildShoppingListSection(AsyncValue<List<ShoppingItem>> shoppingAsync, NumberFormat fmt, bool isDark) {
    return shoppingAsync.when(
      data: (items) {
        final unpurchased = items.where((i) => !i.deleted && !i.isChecked).take(15).toList();
        if (unpurchased.isEmpty) {
          return _buildEmptyCard('Belum ada daftar belanjaan yang belum dibeli.');
        }
        return Column(
          children: unpurchased.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    color: item.isChecked ? Colors.grey.shade400 : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                subtitle: _buildShoppingItemSecondaryDetails(item, fmt, isDark),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNabungSection(List<TargetDashboardInfo> targets) {
    if (targets.isEmpty) {
      return _buildEmptyCard('Belum ada target nabung.');
    }
    return Column(
      children: targets
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildTargetCard(t),
              ))
          .toList(),
    );
  }

  PreferredSizeWidget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      scrolledUnderElevation: 4,
      titleSpacing: 20,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Image.asset(
          AppEnvironment.config.getLogoFullPath(isDark),
          width: 175,
          height: 42,
          cacheWidth: 525,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (c, e, s) => Text(
            AppEnvironment.config.appName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloudBackupSettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 22),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.settings_outlined, color: Color(0xFF2563EB), size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
    );
  }

  Widget _buildTargetCard(TargetDashboardInfo info) {
    final target = info.target;
    double progress = target.targetAmount > 0 ? (info.savings / target.targetAmount) : 0;
    if (progress > 1.0) progress = 1.0;
    int daysLeft = target.endDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) daysLeft = 0;

    return _buildFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  target.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(info.savings.toInt())} / Rp ${NumberFormat('#,###', 'id_ID').format(target.targetAmount.toInt())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$daysLeft hari lagi',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCarousel(List<TargetDashboardInfo> targets, String lang) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _recommendationPageController,
            itemCount: targets.length,
            onPageChanged: (page) {
              setState(() => _recommendationPage = page);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildRecommendationPage(targets[index], lang),
              );
            },
          ),
        ),
        if (targets.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(targets.length, (i) {
              final isActive = i == _recommendationPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendationPage(TargetDashboardInfo info, String lang) {
    final double remainingToday = info.recommendedDailySaving - info.savedToday;
    final bool isDoneToday = remainingToday <= 0;

    return _buildFlatCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.get(lang, 'rekomendasi_tabungan'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                ),
                Text(
                  '(${info.target.name})',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(info.recommendedDailySaving.toInt())}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 6),
                if (isDoneToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      AppTranslations.get(lang, 'selesai_hari_ini'),
                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Text(
                    '${AppTranslations.get(lang, 'kurang')} Rp ${NumberFormat('#,###', 'id_ID').format(remainingToday.toInt())}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights, color: Color(0xFF2563EB), size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder r) {
    final isPinned = _pinnedReminderIds.contains(r.id);
    final status = r.realtimeStatus;
    final isRunning = status == 'Sedang Berjalan';

    final timeStr = '${DateFormat('HH:mm', 'id_ID').format(r.targetDateTime)} - ${DateFormat('HH:mm', 'id_ID').format(r.effectiveEndTime)}';

    return _buildFlatCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRunning ? Colors.orange.withOpacity(0.1) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: isRunning ? Colors.orange : const Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRunning ? Colors.orange.withOpacity(0.15) : const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isRunning ? Colors.orange.shade800 : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd MMM yyyy', 'id_ID').format(r.targetDateTime)} ($timeStr)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 3),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      CountdownUseCase.calculateCountdown(DateTime.now(), r.targetDateTime),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isRunning ? Colors.orange.shade800 : const Color(0xFF2563EB),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await HomeWidgetService.togglePinReminder(r.id);
              if (result == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Maksimal 3 pengingat yang bisa di-pin ke Widget!'),
                        backgroundColor: Colors.orange),
                  );
                }
              } else {
                setState(() => _pinnedReminderIds = result.toSet());
                ref.invalidate(dashboardDataProvider);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(7),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: isPinned ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 15,
                color: isPinned ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return _buildFlatCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ),
      ),
    );
  }

  Widget _buildFlatCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
