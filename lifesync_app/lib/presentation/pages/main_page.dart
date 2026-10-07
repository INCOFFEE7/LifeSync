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

  final List<Widget> _pages = [
    const DashboardPage(),
    const FinancialRecordsHomePage(),
    const TargetsPage(),
    const RemindersPage(),
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
      final reminders = await ref.read(reminderRepositoryProvider).getAllReminders();
      final now = DateTime.now();

      for (var r in reminders) {
        if (!r.deleted && r.realtimeStatus == 'Sedang Berjalan') {
          if (!_triggeredPopupIds.contains(r.id)) {
            _triggeredPopupIds.add(r.id);
            final notifId = r.id.hashCode & 0x7FFFFFFF;

            NotificationService().triggerInAppPopup({
              'id': r.id,
              'title': r.title,
              'body': r.description ?? 'Agenda Anda sedang berlangsung.',
              'startTime': r.targetDateTime.toIso8601String(),
              'endTime': r.effectiveEndTime.toIso8601String(),
              'type': 'reminder',
            });

            NotificationService().showSystemNotification(
              id: notifId,
              title: 'Pengingat Agenda: ${r.title}',
              body: 'Agenda Anda sedang berlangsung saat ini.',
            );
          }
        }
      }

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppTranslations.get(lang, 'beranda'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: AppTranslations.get(lang, 'keuangan'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.savings_outlined),
              activeIcon: const Icon(Icons.savings),
              label: 'Nabung',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_none_outlined),
              activeIcon: const Icon(Icons.notifications),
              label: AppTranslations.get(lang, 'pengingat'),
            ),
          ],
        ),
      ),
    );
  }
}
