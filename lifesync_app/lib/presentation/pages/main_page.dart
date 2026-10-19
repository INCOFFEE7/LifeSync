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

import 'dart:async';
import 'package:intl/intl.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription? _popupSubscription;
  Timer? _dueCheckTimer;
  final Set<int> _triggeredPopupIds = {};

  final GlobalKey<State<FinancialRecordsHomePage>> _financialPageKey = GlobalKey();
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
    _popupSubscription = NotificationService().onInAppPopupTriggered.listen((data) {
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
          final records = await ref.read(targetRepositoryProvider).getRecordsForTarget(t.id);
          final hasSavedToday = records.any((rec) => DateFormat('yyyy-MM-dd').format(rec.date) == todayKey);

          if (!hasSavedToday && now.hour >= 18) {
            final notifId = (t.id + 9999).hashCode & 0x7FFFFFFF;
            if (!_triggeredPopupIds.contains(notifId)) {
              _triggeredPopupIds.add(notifId);

              NotificationService().triggerInAppPopup({
                'id': t.id,
                'title': 'Belum Nabung Hari Ini',
                'body': 'Kamu belum menyelesaikan tabungan "${t.name}" hari ini.',
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
            timeDisplay = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(start);
            if (end != null) {
              timeDisplay += ' - ${DateFormat('HH:mm', 'id_ID').format(end)}';
            }
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.notifications_active, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(timeDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (body.toString().isNotEmpty)
                Text(
                  body.toString(),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
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
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 68,
          backgroundColor: LsColors.surface(context),
          surfaceTintColor: Colors.transparent,
          indicatorColor: LsColors.brand.withValues(alpha: 0.14),
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 11.5,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
                color: states.contains(WidgetState.selected) ? LsColors.brand : LsColors.mute(context),
              )),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected) ? LsColors.brand : LsColors.mute(context),
              )),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: LsColors.line(context))),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: AppTranslations.get(lang, 'beranda'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet),
                label: AppTranslations.get(lang, 'keuangan'),
              ),
              const NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings),
                label: 'Nabung',
              ),
              NavigationDestination(
                icon: const Icon(Icons.notifications_none_outlined),
                selectedIcon: const Icon(Icons.notifications),
                label: AppTranslations.get(lang, 'pengingat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
