import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/screens/cloud_backup_settings_screen.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/domain/usecases/countdown_usecase.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/pages/settings_page.dart';
import 'package:lifesync_app/presentation/pages/reminders_page.dart';
import 'package:lifesync_app/presentation/pages/targets_page.dart';
import 'package:lifesync_app/presentation/pages/target_detail_page.dart';
import 'package:lifesync_app/presentation/widgets/calculator_input_dialog.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:lifesync_app/presentation/widgets/ls_date_time_picker_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Set<int> _pinnedReminderIds = {};
  int? _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
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
    final notesAsync = ref.watch(financialNotesNotifierProvider);
    final allNotes = notesAsync.valueOrNull ?? [];
    final availableYears = <int>{DateTime.now().year};
    for (final n in allNotes) {
      availableYears.add(n.note.date.year);
    }
    final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));

    double yearIncome = 0;
    double yearExpense = 0;
    for (final n in allNotes) {
      if (_selectedYear == null || n.note.date.year == _selectedYear) {
        yearIncome += n.totalIncome;
        yearExpense += n.totalExpense;
      }
    }
    final yearSummary = FinancialSummary(
      totalIncome: yearIncome,
      totalExpense: yearExpense,
      netBalance: yearIncome - yearExpense,
    );

    final shoppingAsync = ref.watch(shoppingItemsProvider);

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    final billsAsync = ref.watch(billsStreamProvider(currentMonthKey));

    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: _buildHeader(),
      body: dashboardAsync.when(
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 0. SAPAAN, HERO SALDO & RINGKASAN CEPAT ──────────────────
                _buildGreeting(lang),
                const SizedBox(height: 12),
                _buildHeroBalance(yearSummary, currencyFmt, sortedYears, lang),
                const SizedBox(height: 10),
                _buildQuickTiles(data, shoppingAsync, billsAsync, now, lang),
                const SizedBox(height: 18),

                // ── 1. PENGINGAT (Agenda Hari Ini & Reminders) ───────────────
                _buildSectionTitle(AppTranslations.get(lang, 'pengingat')),
                const SizedBox(height: 10),
                _buildRemindersSection(data.upcomingReminders, lang),
                const SizedBox(height: 18),

                // ── 2. DAFTAR BELANJA BELUM DIBELI ───────────────────────────
                _buildSectionTitle(
                    AppTranslations.get(lang, 'daftar_belanja_belum_dibeli')),
                const SizedBox(height: 10),
                _buildShoppingListSection(
                    shoppingAsync, currencyFmt, isDark, lang),
                const SizedBox(height: 18),

                // ── 3. KEUANGAN (Rangkuman Transaksi & Tagihan 7 Hari) ───────
                _buildSectionTitle(
                    AppTranslations.get(lang, 'tagihan_jatuh_tempo')),
                const SizedBox(height: 10),
                billsAsync.when(
                  data: (bills) {
                    final upcomingBills = bills.where((b) {
                      if (b.deleted || b.isPaid) return false;
                      final diffDays = b.dueDate.difference(now).inDays;
                      return diffDays >= -1 && diffDays <= 7;
                    }).toList()
                      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

                    return _buildUpcomingBillsSection(
                        upcomingBills, currencyFmt, lang);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),

                // ── 4. NABUNG (Total Tabungan & Recommendations) ───────────────
                _buildSectionTitle(AppTranslations.get(lang, 'target_nabung')),
                const SizedBox(height: 10),
                _buildSavingsOverviewCard(data, lang, currencyFmt),
                const SizedBox(height: 12),
                _buildNabungSection(data.topTargets, lang),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildGreeting(String lang) {
    final h = DateTime.now().hour;
    final isEn = lang == 'en';
    final greet = h < 11
        ? (isEn ? 'Good morning' : 'Selamat pagi')
        : h < 15
            ? (isEn ? 'Good afternoon' : 'Selamat siang')
            : h < 18
                ? (isEn ? 'Good evening' : 'Selamat sore')
                : (isEn ? 'Good night' : 'Selamat malam');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LsEyebrow(DateFormat('EEEE, d MMMM yyyy', isEn ? 'en_US' : 'id_ID')
            .format(DateTime.now())),
        const SizedBox(height: 2),
        Text(
          '$greet.',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
              color: LsColors.ink(context)),
        ),
      ],
    );
  }

  Widget _buildHeroBalance(FinancialSummary s, NumberFormat fmt,
      List<int> availableYears, String lang) {
    final positive = s.netBalance >= 0;
    return LsHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LsEyebrow(
                '${AppTranslations.get(lang, 'saldo_bersih')} (${_selectedYear == null ? AppTranslations.get(lang, 'semua_tahun') : '${AppTranslations.get(lang, 'year_label')} $_selectedYear'})',
                color: const Color(0xA6FFFFFF),
              ),
              PopupMenuButton<int?>(
                initialValue: _selectedYear,
                tooltip: AppTranslations.get(lang, 'year_label'),
                onSelected: (year) {
                  setState(() => _selectedYear = year);
                },
                color: LsColors.surface(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _selectedYear == null
                            ? AppTranslations.get(lang, 'semua')
                            : '$_selectedYear',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: Colors.white),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem<int?>(
                    value: null,
                    child: Text(AppTranslations.get(lang, 'semua_tahun'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ...availableYears.map(
                    (y) => PopupMenuItem<int?>(
                      value: y,
                      child: Text('$y',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${positive ? '' : '-'}Rp ${fmt.format(s.netBalance.abs().toInt())}',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _heroFlow(
                      AppTranslations.get(lang, 'pemasukan'),
                      s.totalIncome,
                      const Color(0xFF6EE7B7),
                      Icons.south_west,
                      fmt)),
              const SizedBox(width: 8),
              Expanded(
                  child: _heroFlow(
                      AppTranslations.get(lang, 'pengeluaran'),
                      s.totalExpense,
                      const Color(0xFFFCA5A5),
                      Icons.north_east,
                      fmt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroFlow(
      String label, double v, Color c, IconData icon, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xB3FFFFFF))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(icon, size: 12, color: c),
                const SizedBox(width: 4),
                Text('Rp ${fmt.format(v.toInt())}',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w800, color: c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTiles(
    DashboardData data,
    AsyncValue<List<ShoppingItem>> shoppingAsync,
    AsyncValue<List<Bill>> billsAsync,
    DateTime now,
    String lang,
  ) {
    final unbought = shoppingAsync.valueOrNull
            ?.where((e) => !e.deleted && !e.isChecked)
            .length ??
        0;
    final urgent = billsAsync.valueOrNull?.where((b) {
          if (b.deleted || b.isPaid) return false;
          final d = b.dueDate.difference(now).inDays;
          return d >= -1 && d <= 7;
        }).length ??
        0;
    return Row(
      children: [
        Expanded(
          child: LsStatTile(
            icon: Icons.event_outlined,
            color: LsColors.violet,
            value: '${data.todayRemindersCount}',
            label: AppTranslations.get(lang, 'agenda_hari_ini'),
            unit: AppTranslations.get(lang, 'hari_ini_unit'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RemindersPage(initialIndex: 1)),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LsStatTile(
            icon: Icons.receipt_long_outlined,
            color: urgent > 0 ? LsColors.expense : LsColors.income,
            value: '$urgent',
            label: AppTranslations.get(lang, 'tagihan'),
            unit: '≤ 7 hari',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RemindersPage(initialIndex: 2)),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LsStatTile(
            icon: Icons.shopping_bag_outlined,
            color: LsColors.amber,
            value: '$unbought',
            label: AppTranslations.get(lang, 'belanja'),
            unit: 'belum dibeli',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RemindersPage(initialIndex: 3)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBillsSection(
      List<Bill> upcomingBills, NumberFormat fmt, String lang) {
    if (upcomingBills.isEmpty) {
      return _buildEmptyCard(
          AppTranslations.get(lang, 'belum_ada_tagihan_jatuh_tempo'));
    }

    return Column(
      children: upcomingBills.map((b) {
        final daysLeft = b.dueDate.difference(DateTime.now()).inDays;
        final timeText = daysLeft == 0
            ? 'Hari ini'
            : (daysLeft < 0
                ? 'Terlambat ${daysLeft.abs()} hari'
                : '$daysLeft hari lagi');
        final isOverdue = daysLeft < 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LsCard(
            padding: const EdgeInsets.all(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RemindersPage(initialIndex: 2)),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isOverdue ? LsColors.expense : LsColors.amber)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: isOverdue ? LsColors.expense : LsColors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: LsColors.ink(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jatuh tempo: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(b.dueDate)}',
                        style: TextStyle(
                            fontSize: 11, color: LsColors.mute(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${fmt.format(b.amount.toInt())}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: LsColors.brand),
                    ),
                    const SizedBox(height: 2),
                    LsChip(timeText,
                        color: isOverdue ? LsColors.expense : LsColors.amber),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSavingsOverviewCard(
      DashboardData data, String lang, NumberFormat fmt) {
    double progress = data.totalTargetAmount > 0
        ? (data.totalSavings / data.totalTargetAmount).clamp(0.0, 1.0)
        : 0.0;
    int percentage = (progress * 100).toInt();

    return _buildFlatCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TargetsPage()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppTranslations.get(lang, 'total_tabungan'),
                  style: TextStyle(
                      fontSize: 14,
                      color: LsColors.mute(context),
                      fontWeight: FontWeight.w600)),
              Text(
                  '${data.topTargets.length} ${AppTranslations.get(lang, 'target')}',
                  style: TextStyle(
                      fontSize: 12,
                      color: LsColors.mute(context),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${fmt.format(data.totalSavings.toInt())}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LsColors.brand),
              ),
              Text(
                '$percentage% ${AppTranslations.get(lang, 'tercapai')}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LsColors.income),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${AppTranslations.get(lang, 'dari')} Rp ${fmt.format(data.totalTargetAmount.toInt())}',
            style: TextStyle(
                fontSize: 12,
                color: LsColors.mute(context),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: LsColors.brand.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(LsColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection(List<Reminder> reminders, String lang) {
    if (reminders.isEmpty) {
      return _buildEmptyCard(
          AppTranslations.get(lang, 'belum_ada_pengingat_terdekat'));
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

  Widget _buildShoppingItemSecondaryDetails(
      ShoppingItem item, NumberFormat currencyFmt, bool isDark) {
    final List<Widget> details = [];
    final mutedStyle = TextStyle(
      fontSize: 11,
      color: isDark ? Colors.white54 : Colors.grey.shade600,
    );

    if (item.purchasedBy != null && item.purchasedBy!.trim().isNotEmpty) {
      details.add(
          Text('Dibeli Oleh: ${item.purchasedBy!.trim()}', style: mutedStyle));
    }
    if (item.price > 0) {
      details.add(Text(
        'Harga: Rp ${currencyFmt.format(item.price.toInt())}',
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981)),
      ));
    }
    if (item.location != null && item.location!.trim().isNotEmpty) {
      details.add(Text('Tempat: ${item.location!.trim()}', style: mutedStyle));
    }
    if (item.notes != null && item.notes!.trim().isNotEmpty) {
      details.add(Text(
        'Catatan: ${item.notes!.trim()}',
        style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF2563EB),
            fontStyle: FontStyle.italic),
      ));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details
          .map((d) => Padding(padding: const EdgeInsets.only(top: 2), child: d))
          .toList(),
    );
  }

  Future<void> _showShoppingCheckoffDialog(ShoppingItem item) async {
    final purchasedByController =
        TextEditingController(text: item.purchasedBy ?? '');
    final locationController = TextEditingController(text: item.location ?? '');
    double enteredPrice = item.price;
    DateTime selectedDate = item.purchaseDate ?? DateTime.now();
    final currencyFmt = NumberFormat('#,###', 'id_ID');
    final lang = ref.read(localeProvider).languageCode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: LsColors.surface(ctx),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: LsColors.line(ctx))),
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
                                color: LsColors.income.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined,
                                  color: LsColors.income, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppTranslations.get(lang, 'konfirmasi_dibeli'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: LsColors.ink(ctx),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: LsColors.mute(ctx),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LsColors.brand),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Catatan: ${item.notes}',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: LsColors.mute(ctx))),
                    ],
                    const SizedBox(height: 16),

                    // Dibeli Oleh (Opsional)
                    TextFormField(
                      controller: purchasedByController,
                      style: TextStyle(color: LsColors.ink(ctx)),
                      decoration: InputDecoration(
                        labelText: 'Dibeli Oleh Siapa (Opsional)',
                        hintText: 'e.g. Ibu, Ayah, Siska',
                        hintStyle: TextStyle(color: LsColors.mute(ctx)),
                        labelStyle: TextStyle(color: LsColors.mute(ctx)),
                        filled: true,
                        fillColor: LsColors.paper(ctx),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LsColors.line(ctx))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LsColors.line(ctx))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tempat Membeli (Opsional)
                    TextFormField(
                      controller: locationController,
                      style: TextStyle(color: LsColors.ink(ctx)),
                      decoration: InputDecoration(
                        labelText: 'Tempat Membeli (Opsional)',
                        hintText: 'e.g. Pasar Tradisional, Minimarket',
                        hintStyle: TextStyle(color: LsColors.mute(ctx)),
                        labelStyle: TextStyle(color: LsColors.mute(ctx)),
                        filled: true,
                        fillColor: LsColors.paper(ctx),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LsColors.line(ctx))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LsColors.line(ctx))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Harga (Opsional - Kalkulator)
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: enteredPrice > 0
                            ? currencyFmt.format(enteredPrice.toInt())
                            : '',
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
                        labelStyle: TextStyle(color: LsColors.mute(ctx)),
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                            color: LsColors.income,
                            fontWeight: FontWeight.bold),
                        suffixIcon:
                            const Icon(Icons.calculate, color: LsColors.income),
                        filled: true,
                        fillColor: LsColors.paper(ctx),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LsColors.line(ctx))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LsColors.line(ctx))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: LsColors.income),
                    ),
                    const SizedBox(height: 12),

                    // Tanggal Pembayaran
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: LsColors.line(ctx)),
                      ),
                      title: Text(AppTranslations.get(lang, 'waktu_pembelian'),
                          style: TextStyle(
                              fontSize: 11, color: LsColors.mute(ctx))),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID')
                            .format(selectedDate),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: LsColors.ink(ctx)),
                      ),
                      trailing: const Icon(Icons.calendar_today,
                          color: LsColors.brand, size: 18),
                      onTap: () async {
                        final pDate = await showLsDateTimePickerSheet(
                          context: ctx,
                          initialDateTime: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          enableTime: true,
                          title: AppTranslations.get(
                              lang, 'pilih_waktu_pembelian'),
                        );
                        if (pDate != null) {
                          setModalState(() {
                            selectedDate = pDate;
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: LsColors.line(ctx)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(AppTranslations.get(lang, 'batal'),
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: LsColors.mute(ctx))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LsColors.income,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              item.isChecked = true;
                              item.purchaseDate = selectedDate;
                              item.price = enteredPrice;
                              item.purchasedBy =
                                  purchasedByController.text.trim().isEmpty
                                      ? null
                                      : purchasedByController.text.trim();
                              item.location =
                                  locationController.text.trim().isEmpty
                                      ? null
                                      : locationController.text.trim();
                              item.updatedAt = DateTime.now();

                              final dbService =
                                  ref.read(databaseServiceProvider);
                              if (!kIsWeb) {
                                await dbService.db.writeTxn(() async {
                                  await dbService.db.shoppingItems.put(item);
                                });
                                ref.invalidate(shoppingItemsProvider);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Text(
                                AppTranslations.get(lang, 'konfirmasi_selesai'),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _buildShoppingListSection(AsyncValue<List<ShoppingItem>> shoppingAsync,
      NumberFormat fmt, bool isDark, String lang) {
    return shoppingAsync.when(
      data: (items) {
        final unpurchased =
            items.where((i) => !i.deleted && !i.isChecked).take(15).toList();
        if (unpurchased.isEmpty) {
          return _buildEmptyCard(
              AppTranslations.get(lang, 'belum_ada_belanja_pending'));
        }
        return Column(
          children: unpurchased.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: LsCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onTap: () => _showShoppingCheckoffDialog(item),
                child: Row(
                  children: [
                    Checkbox(
                      activeColor: LsColors.brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      value: item.isChecked,
                      onChanged: (val) {
                        _showShoppingCheckoffDialog(item);
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isChecked
                                  ? LsColors.mute(context)
                                  : LsColors.ink(context),
                            ),
                          ),
                          _buildShoppingItemSecondaryDetails(item, fmt, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: LsColors.mute(context)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNabungSection(List<TargetDashboardInfo> targets, String lang) {
    if (targets.isEmpty) {
      return _buildEmptyCard(AppTranslations.get(lang, 'belum_ada_target'));
    }
    return Column(
      children: targets
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildTargetCard(t, lang),
              ))
          .toList(),
    );
  }

  PreferredSizeWidget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: LsColors.surface(context),
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: LsColors.line(context))),
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
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CloudBackupSettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: LsColors.paper(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LsColors.line(context)),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: LsColors.brand, size: 20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: LsColors.paper(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LsColors.line(context)),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: LsColors.brand, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => LsSectionHeader(title: title);

  Widget _buildTargetCard(TargetDashboardInfo info, String lang) {
    final target = info.target;
    double progress =
        target.targetAmount > 0 ? (info.savings / target.targetAmount) : 0;
    if (progress > 1.0) progress = 1.0;
    int daysLeft = target.endDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) daysLeft = 0;

    return _buildFlatCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TargetDetailPage(target: target),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LsColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: LsColors.brand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  target.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LsColors.ink(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: LsColors.brand),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: LsColors.brand.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(LsColors.brand),
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
                  style: TextStyle(
                      fontSize: 12,
                      color: LsColors.mute(context),
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$daysLeft ${AppTranslations.get(lang, 'hari_lagi')}',
                style: TextStyle(fontSize: 12, color: LsColors.mute(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder r) {
    final isPinned = _pinnedReminderIds.contains(r.id);
    final status = r.realtimeStatus;
    final isRunning = status == 'Sedang Berjalan';
    final isDone = status == 'Selesai';
    final statusColor = isRunning
        ? LsColors.amber
        : (isDone ? LsColors.income : LsColors.brand);

    final timeStr =
        '${DateFormat('HH:mm', 'id_ID').format(r.targetDateTime)} - ${DateFormat('HH:mm', 'id_ID').format(r.effectiveEndTime)}';

    return _buildFlatCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: LsColors.ink(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    LsChip(status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('d MMM yyyy', 'id_ID').format(r.targetDateTime)} ($timeStr)',
                  style:
                      TextStyle(fontSize: 11.5, color: LsColors.mute(context)),
                ),
                const SizedBox(height: 3),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      CountdownUseCase.calculateCountdown(
                          DateTime.now(), r.targetDateTime),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
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
                        content: Text(
                            'Maksimal 3 pengingat yang bisa di-pin ke Widget!'),
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
                color: isPinned
                    ? LsColors.brand
                    : LsColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 15,
                color: isPinned ? Colors.white : LsColors.mute(context),
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
          child: Text(message,
              style: TextStyle(color: LsColors.mute(context), fontSize: 12.5)),
        ),
      ),
    );
  }

  Widget _buildFlatCard({required Widget child, VoidCallback? onTap}) =>
      LsCard(padding: const EdgeInsets.all(13), onTap: onTap, child: child);
}
