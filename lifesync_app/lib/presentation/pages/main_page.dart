import 'package:flutter/material.dart';
import 'package:lifesync_app/presentation/pages/dashboard_page.dart';
import 'package:lifesync_app/presentation/pages/targets_page.dart';
import 'package:lifesync_app/presentation/pages/reminders_page.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/notifications/notification_service.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';

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

    // Cek pengingat & tagihan jatuh tempo secara berkala (setiap 10 detik) dan saat app dibuka
    _checkDueRemindersAndBills();
    _dueCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkDueRemindersAndBills();
    });
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
      _checkDueRemindersAndBills();
    }
  }

  Future<void> _checkDueRemindersAndBills() async {
    try {
      final now = DateTime.now();

      // 1. Cek Pengingat Agenda
      final repo = ref.read(reminderRepositoryProvider);
      final allReminders = await repo.getAllReminders();

      for (var r in allReminders) {
        if (r.deleted) continue;
        if (r.targetDateTime.isBefore(now) || r.targetDateTime.isAtSameMomentAs(now)) {
          final diff = now.difference(r.targetDateTime);
          if (diff.inHours <= 24 && !_triggeredPopupIds.contains(r.id)) {
            _triggeredPopupIds.add(r.id);
            NotificationService().triggerInAppPopup({
              'id': r.id,
              'title': 'Pengingat: ${r.title}',
              'body': (r.description != null && r.description!.isNotEmpty) 
                  ? r.description! 
                  : 'Waktu pengingat Anda telah tiba!',
              'startTime': r.targetDateTime.toIso8601String(),
              'endTime': r.effectiveEndTime.toIso8601String(),
              'type': 'reminder',
            });
            NotificationService().showImmediateNotification(
              title: 'LifeSync Pengingat: ${r.title}',
              body: (r.description != null && r.description!.isNotEmpty) 
                  ? r.description! 
                  : 'Waktu pengingat Anda telah tiba!',
              sound: r.customSound,
            );
          }
        }
      }

      // 2. Cek Tagihan Belum Dibayar (Jatuh tempo hari ini / terlewat)
      final billRepo = ref.read(billRepositoryProvider);
      final monthKey = DateFormat('yyyy-MM').format(now);
      final bills = await billRepo.getBillsByMonth(monthKey);

      final unpaidDueBills = bills.where((b) {
        if (b.deleted || b.isPaid) return false;
        return b.dueDate.isBefore(now) || b.dueDate.isAtSameMomentAs(now);
      }).toList();

      if (unpaidDueBills.isNotEmpty) {
        final batchId = 888888;
        if (!_triggeredPopupIds.contains(batchId)) {
          _triggeredPopupIds.add(batchId);

          final currencyFmt = NumberFormat('#,###', 'id_ID');
          if (unpaidDueBills.length == 1) {
            final b = unpaidDueBills.first;
            final remaining = (b.amount - (b.realizationAmount ?? 0.0)).clamp(0.0, double.infinity);
            NotificationService().triggerInAppPopup({
              'id': b.id,
              'title': 'Tagihan Jatuh Tempo: ${b.name}',
              'body': 'Tagihan ${b.name} sebesar Rp ${currencyFmt.format(remaining.toInt())} belum dibayar.',
              'startTime': b.dueDate.toIso8601String(),
              'type': 'bill',
            });
            NotificationService().showSystemNotification(
              id: batchId,
              title: 'Tagihan Jatuh Tempo: ${b.name}',
              body: 'Tagihan ${b.name} sebesar Rp ${currencyFmt.format(remaining.toInt())} belum dibayar.',
            );
          } else {
            // Gabungkan lebih dari satu tagihan menjadi satu list di notifikasi sistem!
            final buffer = StringBuffer('Terdapat ${unpaidDueBills.length} tagihan belum dibayar:\n');
            for (var b in unpaidDueBills) {
              final remaining = (b.amount - (b.realizationAmount ?? 0.0)).clamp(0.0, double.infinity);
              buffer.writeln('• ${b.name}: Rp ${currencyFmt.format(remaining.toInt())}');
            }

            NotificationService().triggerInAppPopup({
              'id': batchId,
              'title': 'Tagihan Jatuh Tempo (${unpaidDueBills.length})',
              'body': buffer.toString(),
              'type': 'bill',
            });
            NotificationService().showSystemNotification(
              id: batchId,
              title: 'Tagihan Jatuh Tempo (${unpaidDueBills.length})',
              body: buffer.toString(),
            );
          }
        }
      }

      // 3. Cek Target Nominal Tetap (Pengingat Jam 20:00 jika belum nabung hari ini)
      final targetRepo = ref.read(targetRepositoryProvider);
      final allTargets = await targetRepo.getAllTargets();

      for (var t in allTargets) {
        if (t.deleted || t.mode != 'fixed') continue;

        final normToday = DateTime(now.year, now.month, now.day);
        final normStart = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
        final normEnd = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);

        if (!normToday.isBefore(normStart) && !normToday.isAfter(normEnd)) {
          final records = await targetRepo.getRecordsForTarget(t.id!);
          bool savedToday = records.any((r) => r.date.year == now.year && r.date.month == now.month && r.date.day == now.day);

          final notifId = t.id! + 700000;
          if (!savedToday && now.hour >= 20) {
            if (!_triggeredPopupIds.contains(notifId)) {
              _triggeredPopupIds.add(notifId);
              final currencyFmt = NumberFormat('#,###', 'id_ID');

              NotificationService().triggerInAppPopup({
                'id': t.id,
                'title': 'Belum Nabung Hari Ini',
                'body': 'Kamu belum menyelesaikan tabungan "${t.name}" hari ini.\nNominal Harian: Rp ${currencyFmt.format(t.fixedDailyAmount.toInt())}',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timeDisplay.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(timeDisplay, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (body.toString().isNotEmpty)
                Text(
                  body.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Tutup'),
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
              color: Colors.black.withOpacity(0.05),
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
