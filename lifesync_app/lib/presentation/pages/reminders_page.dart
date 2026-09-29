import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/usecases/countdown_usecase.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/pages/create_reminder_page.dart';
import 'package:intl/intl.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> with WidgetsBindingObserver {
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
    final lang = ref.watch(localeProvider).languageCode;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          titleSpacing: 20,
          title: Image.asset(
            'assets/images/logofull.png',
            width: 140,
            cacheWidth: 420,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Text(
              'LifeSync',
              style: TextStyle(
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
            tabs: [
              Tab(text: AppTranslations.get(lang, 'sedang_berjalan')),
              Tab(text: AppTranslations.get(lang, 'akan_datang')),
              Tab(text: AppTranslations.get(lang, 'selesai_tab')),
            ],
          ),
        ),
        body: remindersAsync.when(
          data: (reminders) {
            final activeReminders = reminders.where((r) => !r.deleted).toList();

            final runningReminders = activeReminders
                .where((r) => r.realtimeStatus == 'Sedang Berjalan')
                .toList()
              ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

            final upcomingReminders = activeReminders
                .where((r) => r.realtimeStatus == 'Akan Datang')
                .toList()
              ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

            final completedReminders = activeReminders
                .where((r) => r.realtimeStatus == 'Selesai')
                .toList()
              ..sort((a, b) => b.targetDateTime.compareTo(a.targetDateTime));

            return TabBarView(
              children: [
                _buildReminderList(runningReminders, lang == 'en' ? 'No active running reminders.' : 'Belum ada pengingat sedang berjalan.', Colors.orange, lang: lang),
                _buildReminderList(upcomingReminders, lang == 'en' ? 'No upcoming reminders.' : 'Belum ada pengingat akan datang.', const Color(0xFF2563EB), lang: lang),
                _buildReminderList(completedReminders, lang == 'en' ? 'No completed events.' : 'Belum ada event selesai.', Colors.green, isSpecialEvent: true, lang: lang),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'reminders_fab',
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReminderPage()));
          },
          icon: const Icon(Icons.add_alarm, size: 24),
          label: Text(AppTranslations.get(lang, 'buat_pengingat'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildReminderList(List<Reminder> items, String emptyMessage, Color accentColor, {bool isSpecialEvent = false, required String lang}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSpecialEvent ? Icons.stars_outlined : Icons.alarm, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final reminder = items[index];
        final isCompleted = isSpecialEvent || reminder.realtimeStatus == 'Selesai';

        final timeRangeStr = '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(reminder.targetDateTime)} - ${DateFormat('HH:mm', 'id_ID').format(reminder.effectiveEndTime)}';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCompleted ? Colors.green.shade200 : accentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green.shade50 : accentColor.withOpacity(0.1),
              child: Icon(
                isCompleted ? Icons.stars : Icons.alarm,
                color: isCompleted ? Colors.green : accentColor,
              ),
            ),
            title: Text(
              reminder.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isCompleted ? Colors.grey.shade800 : const Color(0xFF1F2937),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  timeRangeStr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reminder.description!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                isCompleted
                    ? Text(
                        AppTranslations.get(lang, 'event_selesai'),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      )
                    : StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          return Text(
                            CountdownUseCase.calculateCountdown(DateTime.now(), reminder.targetDateTime),
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        },
                      ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReminderPage(existingReminder: reminder)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Hapus Pengingat?'),
                        content: const Text('Apakah Anda yakin ingin menghapus pengingat ini?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(reminderRepositoryProvider).deleteReminder(reminder.id);
                      ref.invalidate(dashboardDataProvider);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

