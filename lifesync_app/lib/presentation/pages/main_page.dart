import 'package:flutter/material.dart';
import 'package:lifesync_app/presentation/pages/dashboard_page.dart';
import 'package:lifesync_app/presentation/pages/targets_page.dart';
import 'package:lifesync_app/presentation/pages/reminders_page.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

import 'package:lifesync_app/presentation/pages/financial_records_home_page.dart';
import 'package:lifesync_app/presentation/pages/create_reminder_page.dart';
import 'package:lifesync_app/presentation/pages/add_edit_bill_page.dart';
import 'package:lifesync_app/presentation/pages/create_shopping_page.dart';
import 'package:lifesync_app/presentation/pages/create_target_page.dart';
import 'package:lifesync_app/presentation/pages/add_edit_financial_note_page.dart';
import 'package:lifesync_app/presentation/providers/financial_note_providers.dart';

import 'dart:async';
import 'package:intl/intl.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription? _popupSubscription;
  Timer? _dueCheckTimer;
  final Set<int> _triggeredPopupIds = {};

  final GlobalKey<State<FinancialRecordsHomePage>> _financialPageKey =
      GlobalKey();
  final GlobalKey<State<RemindersPage>> _remindersPageKey = GlobalKey();

  late final List<Widget> _pages = [
    const DashboardPage(),
    FinancialRecordsHomePage(key: _financialPageKey),
    const TargetsPage(),
    RemindersPage(key: _remindersPageKey),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().requestPermissions();
    NotificationService().checkLaunchNotification();
    _popupSubscription =
        NotificationService().onInAppPopupTriggered.listen((data) {
      if (mounted) {
        _showInAppReminderDialog(data);
      }
    });
    _startDueCheckTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _popupSubscription?.cancel();
    _dueCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDueItems();
    }
  }

  void _startDueCheckTimer() {
    _dueCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDueItems();
    });
  }

  Future<void> _checkDueItems() async {
    try {
      final now = DateTime.now();

      // Agenda: Notifikasi mengikuti alarm yang telah dijadwalkan (zonedSchedule), tidak perlu spam notif instan saat sedang berjalan
      // Hanya biarkan target dan shopping yang memiliki periodic reminder di foreground
      final targets = await ref.read(targetRepositoryProvider).getAllTargets();
      for (var t in targets) {
        if (!t.deleted && t.mode == 'fixed' && t.fixedDailyAmount > 0) {
          final todayKey = DateFormat('yyyy-MM-dd').format(now);
          final records = await ref
              .read(targetRepositoryProvider)
              .getRecordsForTarget(t.id);
          final hasSavedToday = records.any(
              (rec) => DateFormat('yyyy-MM-dd').format(rec.date) == todayKey);

          if (!hasSavedToday && now.hour >= 18) {
            final notifId = (t.id + 9999).hashCode & 0x7FFFFFFF;
            if (!_triggeredPopupIds.contains(notifId)) {
              _triggeredPopupIds.add(notifId);

              NotificationService().triggerInAppPopup({
                'id': t.id,
                'title': 'Belum Nabung Hari Ini',
                'body':
                    'Kamu belum menyelesaikan tabungan "${t.name}" hari ini.',
                'type': 'fixed_target',
              });

              NotificationService().showSystemNotification(
                id: notifId,
                title: 'Belum Nabung Hari Ini',
                body: 'Jangan lupa menyelesaikan tabungan ${t.name} hari ini.',
                featureName: 'Target Nabung',
              );
            }
          }
        }
      }

      final shoppingItems = await ref.read(shoppingItemsProvider.future);
      for (var s in shoppingItems) {
        if (!s.deleted && !s.isChecked && s.purchaseDate != null) {
          if (now.isAfter(s.purchaseDate!) || isSameDay(now, s.purchaseDate!)) {
            final notifId = (s.id + 88888).hashCode & 0x7FFFFFFF;
            if (!_triggeredPopupIds.contains(notifId)) {
              _triggeredPopupIds.add(notifId);

              // Popup TANPA suara musik/alarm
              NotificationService().triggerInAppPopup({
                'id': s.id,
                'title': 'Pengingat Belanjaan',
                'body': 'Ada barang di catatan "${s.name}" yang belum dibeli!',
                'type': 'shopping',
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking due items: $e');
    }
  }

  void _showInAppReminderDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final title = data['title'] ?? 'Pengingat';
        final body = data['body'] ?? data['description'] ?? '';
        final startTimeStr = data['startTime'];
        final endTimeStr = data['endTime'];
        String timeDisplay = '';
        if (startTimeStr != null) {
          final start = DateTime.tryParse(startTimeStr);
          final end = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;
          if (start != null) {
            timeDisplay =
                DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(start);
            if (end != null) {
              timeDisplay += ' - ${DateFormat('HH:mm', 'id_ID').format(end)}';
            }
          }
        }

        final lang = ref.watch(localeProvider).languageCode;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: LsColors.line(ctx), width: 1.2),
          ),
          backgroundColor: LsColors.surface(ctx),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LsColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.notifications_active,
                    color: LsColors.brand, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: LsColors.ink(ctx)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timeDisplay.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: LsColors.paper(ctx),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: LsColors.line(ctx)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          size: 16, color: LsColors.brand),
                      const SizedBox(width: 8),
                      Text(timeDisplay,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: LsColors.ink(ctx))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (body.toString().isNotEmpty)
                Text(
                  body.toString(),
                  style: TextStyle(fontSize: 14, color: LsColors.mute(ctx)),
                ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: LsColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppTranslations.get(lang, 'tutup'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      final state = _financialPageKey.currentState;
      if (state != null) {
        (state as dynamic).resetToToday();
      }
    } else if (index == 3) {
      final state = _remindersPageKey.currentState;
      if (state != null) {
        (state as dynamic).resetToDashboard();
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAddSheet() {
    final selectedFinDate = ref.read(selectedFinancialDateProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final actions = <_AddAction>[
      _AddAction(
          'transaksi',
          AppTranslations.get(lang, 'catat_transaksi'),
          'Catat pemasukan atau pengeluaran harian',
          Icons.account_balance_wallet_rounded,
          LsColors.brand,
          (_) => AddEditFinancialNotePage(initialDate: selectedFinDate)),
      _AddAction(
          'agenda',
          AppTranslations.get(lang, 'agenda'),
          'Jadwal dan kegiatan penting',
          Icons.event_rounded,
          LsColors.violet,
          (_) => const CreateReminderPage()),
      _AddAction(
          'tagihan',
          AppTranslations.get(lang, 'tagihan_bulanan'),
          'Tagihan rutin bulanan',
          Icons.receipt_long_rounded,
          LsColors.expense,
          (_) => const AddEditBillPage(initialBillType: 'monthly')),
      _AddAction(
          'piutang',
          AppTranslations.get(lang, 'tagihan_piutang'),
          'Catatan penagihan piutang orang lain',
          Icons.handshake_rounded,
          LsColors.income,
          (_) => const AddEditBillPage(initialBillType: 'receivable')),
      _AddAction(
          'belanja',
          AppTranslations.get(lang, 'daftar_belanja'),
          'Daftar kebutuhan belanjaan',
          Icons.shopping_cart_rounded,
          LsColors.amber,
          (_) => const CreateShoppingPage()),
      _AddAction(
          'target',
          AppTranslations.get(lang, 'target'),
          'Mulai menabung untuk tujuan baru',
          Icons.savings_rounded,
          LsColors.income,
          (_) => const CreateTargetPage()),
    ];
    final preferred = switch (_currentIndex) {
      1 => 'transaksi',
      2 => 'target',
      3 => 'agenda',
      _ => 'transaksi',
    };
    actions.sort((a, b) =>
        (a.id == preferred ? 0 : 1).compareTo(b.id == preferred ? 0 : 1));

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LsColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: LsColors.line(sheetContext),
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                const LsEyebrow('Buat'),
                const SizedBox(height: 4),
                Text('Tambah Baru',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: LsColors.ink(sheetContext),
                        letterSpacing: -0.4)),
                const SizedBox(height: 14),
                for (final a in actions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AddActionRow(
                      action: a,
                      highlighted: a.id == preferred,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                            context, MaterialPageRoute(builder: a.builder));
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData selectedIcon, String label) {
    final selected = _currentIndex == index;
    final color = selected ? LsColors.brand : LsColors.mute(context);
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? LsColors.brand.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(selected ? selectedIcon : icon,
                    color: color, size: 21),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: LsColors.surface(context),
          border: Border(top: BorderSide(color: LsColors.line(context))),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Row(
                children: [
                  _navItem(0, Icons.home_outlined, Icons.home_rounded,
                      AppTranslations.get(lang, 'beranda')),
                  _navItem(
                      1,
                      Icons.account_balance_wallet_outlined,
                      Icons.account_balance_wallet,
                      AppTranslations.get(lang, 'keuangan')),
                  const Expanded(child: SizedBox(height: 56)),
                  _navItem(2, Icons.savings_outlined, Icons.savings,
                      AppTranslations.get(lang, 'target')),
                  _navItem(
                      3,
                      Icons.notifications_none_outlined,
                      Icons.notifications,
                      AppTranslations.get(lang, 'pengingat')),
                ],
              ),
              Positioned(
                top: -16,
                child: Semantics(
                  button: true,
                  label: 'Tambah Baru',
                  child: Material(
                    color: LsColors.brand,
                    shape: const CircleBorder(),
                    elevation: 5,
                    shadowColor: LsColors.brand.withValues(alpha: 0.4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _showAddSheet,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: LsColors.surface(context), width: 3),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _AddAction(
      this.id, this.title, this.subtitle, this.icon, this.color, this.builder);
}

class _AddActionRow extends StatelessWidget {
  final _AddAction action;
  final bool highlighted;
  final VoidCallback onTap;
  const _AddActionRow(
      {required this.action, required this.highlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? action.color.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: highlighted
                    ? action.color.withValues(alpha: 0.5)
                    : LsColors.line(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle),
                child: Icon(action.icon, color: action.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context))),
                    Text(action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5, color: LsColors.mute(context))),
                  ],
                ),
              ),
              if (highlighted) LsChip('Disarankan', color: action.color),
              if (!highlighted)
                Icon(Icons.chevron_right_rounded,
                    color: LsColors.mute(context)),
            ],
          ),
        ),
      ),
    );
  }
}
