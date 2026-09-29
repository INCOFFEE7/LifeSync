import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class BeebeeCalendarPage extends ConsumerStatefulWidget {
  const BeebeeCalendarPage({super.key});

  @override
  ConsumerState<BeebeeCalendarPage> createState() => _BeebeeCalendarPageState();
}

class _BeebeeCalendarPageState extends ConsumerState<BeebeeCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(AppTranslations.get(lang, 'menstrual_tracker_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF333333),
          bottom: TabBar(
            indicatorColor: const Color(0xFFE91E8C),
            indicatorWeight: 3,
            labelColor: const Color(0xFFE91E8C),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: AppTranslations.get(lang, 'kalender')),
              Tab(text: AppTranslations.get(lang, 'riwayat_haid')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCalendarTab(context, lang),
            _buildHistoryTab(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab(BuildContext context, String lang) {
    final recordsAsync = ref.watch(menstruationRecordsProvider);
    final statsAsync = ref.watch(menstrualStatsProvider);
    final qadhaAsync = ref.watch(qadhaRecordsProvider);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFE91E8C)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFE91E8C)),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.redAccent),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFE91E8C).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.bold),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFFE91E8C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))
                ],
              ),
            ),
            eventLoader: (day) {
              List<String> events = [];

              if (recordsAsync.value != null) {
                for (var record in recordsAsync.value!) {
                  if (day.isAfter(record.startDate.subtract(const Duration(days: 1))) && 
                      day.isBefore(record.endDate.add(const Duration(days: 1)))) {
                    events.add('Haid');
                    break;
                  }
                }
              }

              if (statsAsync.value?.nextPrediction != null) {
                if (isSameDay(day, statsAsync.value!.nextPrediction!)) {
                  events.add('Prediksi');
                }
              }

              if (qadhaAsync.value != null) {
                for (var qadha in qadhaAsync.value!) {
                  if (isSameDay(day, qadha.date)) {
                    events.add('Qadha');
                    break;
                  }
                }
              }

              return events;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();

                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((event) {
                      Color color;
                      if (event == 'Haid') color = const Color(0xFFE91E8C);
                      else if (event == 'Prediksi') color = const Color(0xFFC77DFF);
                      else color = Colors.green; // Qadha

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppTranslations.get(lang, 'legenda_kalender'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF333333))),
                const SizedBox(height: 20),
                _buildLegendRow(const Color(0xFFE91E8C), AppTranslations.get(lang, 'hari_menstruasi')),
                const SizedBox(height: 12),
                _buildLegendRow(const Color(0xFFC77DFF), AppTranslations.get(lang, 'prediksi_haid_berikutnya')),
                const SizedBox(height: 12),
                _buildLegendRow(Colors.green, AppTranslations.get(lang, 'pembayaran_puasa_qadha')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context, String lang) {
    final recordsAsync = ref.watch(menstruationRecordsProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(AppTranslations.get(lang, 'belum_ada_riwayat_haid'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: const Color(0xFFFDE8E9), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.water_drop, color: Color(0xFFE91E8C), size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('dd MMM yyyy').format(record.startDate)} - ${DateFormat('dd MMM yyyy').format(record.endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF333333)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${AppTranslations.get(lang, 'durasi_label')}: ${record.duration} ${AppTranslations.get(lang, 'hari')}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          if (record.notes != null && record.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(record.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                          if (record.isRamadan) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.nights_stay, size: 14, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(AppTranslations.get(lang, 'bulan_ramadan'), style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 26),
                          onPressed: () => _showEditHaidDialog(context, lang, record),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 26),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(AppTranslations.get(lang, 'hapus_catatan_haid'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                content: Text(AppTranslations.get(lang, 'yakin_hapus_haid')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false), 
                                    child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey))
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => Navigator.pop(c, true), 
                                    child: Text(AppTranslations.get(lang, 'hapus'))
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(menstruationRepositoryProvider).deleteRecord(record.id);
                            }
                          },
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditHaidDialog(BuildContext context, String lang, MenstruationRecord record) {
    DateTime startDate = record.startDate;
    DateTime endDate = record.endDate;
    bool isRamadan = record.isRamadan;
    String notes = record.notes ?? '';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          final utcEnd = DateTime.utc(endDate.year, endDate.month, endDate.day);
          final utcStart = DateTime.utc(startDate.year, startDate.month, startDate.day);
          int duration = utcEnd.difference(utcStart).inDays + 1;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppTranslations.get(lang, 'edit_catatan_haid'), style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppTranslations.get(lang, 'tanggal_mulai_haid'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(startDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_month, color: Color(0xFFE91E8C)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate.add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppTranslations.get(lang, 'tanggal_selesai_haid'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(endDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_month, color: Color(0xFFE91E8C)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                          if (startDate.isAfter(endDate)) {
                            startDate = endDate.subtract(const Duration(days: 1));
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timelapse, color: Color(0xFFE91E8C), size: 20),
                        const SizedBox(width: 8),
                        Text('${AppTranslations.get(lang, 'durasi_label')}: $duration ${AppTranslations.get(lang, 'hari')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E8C))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppTranslations.get(lang, 'terjadi_di_ramadan'), style: const TextStyle(fontSize: 13)),
                    activeColor: const Color(0xFFE91E8C),
                    value: isRamadan,
                    onChanged: (val) => setState(() => isRamadan = val),
                  ),
                  TextFormField(
                    initialValue: notes,
                    decoration: InputDecoration(
                      labelText: AppTranslations.get(lang, 'catatan_opsional'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (val) => notes = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(AppTranslations.get(lang, 'batal'), style: const TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  record.startDate = startDate;
                  record.endDate = endDate;
                  record.isRamadan = isRamadan;
                  record.notes = notes;
                  await ref.read(menstruationRepositoryProvider).updateRecord(record);
                  if (context.mounted) Navigator.pop(c);
                },
                child: Text(AppTranslations.get(lang, 'simpan')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF555555), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
