import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/providers/settings_provider.dart';

class CreateReminderPage extends ConsumerStatefulWidget {
  final Reminder? existingReminder;
  const CreateReminderPage({super.key, this.existingReminder});

  @override
  ConsumerState<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends ConsumerState<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  ReminderCategory _category = ReminderCategory.personal;
  PriorityLevel _priority = PriorityLevel.medium;
  DateTime _targetDateTime = DateTime.now().add(const Duration(minutes: 30));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  int _notificationMinutes = 60; // 1 hour before
  bool _isAllDay = false;
  String? _selectedSound; // Selected notification sound
  String? _customCategory;
  
  String _selectedCategoryValue = ReminderCategory.personal.name;
  List<String> _existingCustomCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _title = widget.existingReminder!.title;
      _description = widget.existingReminder!.description ?? '';
      _category = widget.existingReminder!.category;
      _priority = widget.existingReminder!.priority;
      _targetDateTime = widget.existingReminder!.targetDateTime;
      _endTime = widget.existingReminder!.effectiveEndTime;
      _notificationMinutes = widget.existingReminder!.notificationPreferenceMinutes;
      _isAllDay = widget.existingReminder!.isAllDay;
      _customCategory = widget.existingReminder!.customCategory;
      
      if (_category == ReminderCategory.other && _customCategory != null) {
        _selectedCategoryValue = _customCategory!;
      } else {
        _selectedCategoryValue = _category.name;
      }
    }
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.db.appSettings.get(1);
    if (settings != null) {
      setState(() {
        _existingCustomCategories = settings.customCategories;
      });
    }
  }

  Future<void> _selectStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) {
      if (_isAllDay) {
        setState(() {
          _targetDateTime = DateTime(date.year, date.month, date.day);
          _endTime = DateTime(date.year, date.month, date.day, 23, 59);
        });
      } else {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_targetDateTime),
        );
        if (time != null) {
          setState(() {
            _targetDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            if (_endTime.isBefore(_targetDateTime) || _endTime.isAtSameMomentAs(_targetDateTime)) {
              _endTime = _targetDateTime.add(const Duration(hours: 1));
            }
          });
        }
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime.isBefore(_targetDateTime) ? _targetDateTime : _endTime,
      firstDate: _targetDateTime,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) {
      if (_isAllDay) {
        setState(() {
          _endTime = DateTime(date.year, date.month, date.day, 23, 59);
        });
      } else {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_endTime),
        );
        if (time != null) {
          setState(() {
            _endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          });
        }
      }
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_endTime.isBefore(_targetDateTime) || _endTime.isAtSameMomentAs(_targetDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu selesai harus lebih lambat dari waktu mulai!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final reminder = Reminder()
        ..id = widget.existingReminder?.id ?? DateTime.now().millisecondsSinceEpoch
        ..title = _title
        ..description = _description
        ..category = _category
        ..customCategory = _category == ReminderCategory.other ? _customCategory : null
        ..priority = _priority
        ..targetDateTime = _isAllDay ? DateTime(_targetDateTime.year, _targetDateTime.month, _targetDateTime.day) : _targetDateTime
        ..endTime = _isAllDay ? DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59) : _endTime
        ..isAllDay = _isAllDay
        ..status = widget.existingReminder?.status ?? ReminderStatus.pending
        ..createdAt = widget.existingReminder?.createdAt ?? DateTime.now()
        ..notificationPreferenceMinutes = _notificationMinutes
        ..customSound = _selectedSound;
        
      if (_category == ReminderCategory.other && _customCategory != null && _customCategory!.isNotEmpty) {
        // Save to AppSettings custom categories (future task sync)
        final db = ref.read(databaseServiceProvider).db;
        db.writeTxnSync(() {
          final settings = db.appSettings.getSync(1) ?? AppSettings()..id = 1;
          if (!settings.customCategories.contains(_customCategory)) {
            settings.customCategories = List.from(settings.customCategories)..add(_customCategory!);
            db.appSettings.putSync(settings);
          }
        });
      }
        
      final repo = ref.read(reminderRepositoryProvider);
      final id = await repo.saveReminder(reminder);
      
      // Schedule notification
      final notifService = ref.read(notificationServiceProvider);
      DateTime scheduledTime;
      if (_isAllDay) {
        // All‑day reminder fires at 06:00 on the target date
        scheduledTime = DateTime(_targetDateTime.year, _targetDateTime.month, _targetDateTime.day, 6, 0);
      } else {
        scheduledTime = _targetDateTime.subtract(Duration(minutes: _notificationMinutes));
      }
      
      final sound = _selectedSound ?? ref.read(defaultSoundProvider);
      
      try {
        if (scheduledTime.isAfter(DateTime.now())) {
          await notifService.scheduleNotification(
            id: id,
            title: 'LifeSync Reminder: $_title',
            body: 'Your reminder is due in $_notificationMinutes minutes!',
            scheduledTime: scheduledTime,
            sound: sound,
          );
        }
      } catch (e) {
        debugPrint('Failed to schedule notification: $e');
      } finally {
        if (mounted) {
          // Invalidate dashboard so it auto-updates
          ref.invalidate(dashboardDataProvider);
          Navigator.pop(context);
        }
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
        centerTitle: false,
        title: Text(
          widget.existingReminder == null ? 'Buat Pengingat' : 'Edit Pengingat',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            TextFormField(
              initialValue: _title,
              decoration: _inputDecoration('Judul Pengingat'),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              onSaved: (val) => _title = val!,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _description,
              decoration: _inputDecoration('Deskripsi/Catatan'),
              style: const TextStyle(color: Color(0xFF1F2937)),
              maxLines: 3,
              onSaved: (val) => _description = val ?? '',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Kategori'),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4B5563)),
                    value: _selectedCategoryValue,
                    items: [
                      ...ReminderCategory.values
                          .where((c) => c != ReminderCategory.other)
                          .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name.toUpperCase()))),
                      ..._existingCustomCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))),
                      const DropdownMenuItem(value: 'ADD_NEW', child: Text('TAMBAH BARU...')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryValue = val!;
                        if (val == 'ADD_NEW') {
                          _category = ReminderCategory.other;
                          _customCategory = '';
                        } else {
                          try {
                            _category = ReminderCategory.values.firstWhere((c) => c.name == val);
                            _customCategory = null;
                          } catch (e) {
                            _category = ReminderCategory.other;
                            _customCategory = val;
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<PriorityLevel>(
                    decoration: _inputDecoration('Prioritas'),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4B5563)),
                    value: _priority,
                    items: PriorityLevel.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                ),
              ],
            ),
            if (_selectedCategoryValue == 'ADD_NEW') ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _customCategory,
                decoration: _inputDecoration('Nama Kategori Lainnya'),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                onSaved: (val) => _customCategory = val,
              ),
            ],
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Seharian Penuh (All Day)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              value: _isAllDay,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                setState(() {
                  _isAllDay = val;
                  if (val) {
                    _targetDateTime = DateTime(_targetDateTime.year, _targetDateTime.month, _targetDateTime.day);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Text('Waktu Mulai', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _isAllDay ? DateFormat('dd MMM yyyy').format(_targetDateTime) : DateFormat('dd MMM yyyy, HH:mm').format(_targetDateTime),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                        ),
                      ),
                      onTap: _selectStartDateTime,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Text('Waktu Selesai', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _isAllDay ? DateFormat('dd MMM yyyy').format(_endTime) : DateFormat('dd MMM yyyy, HH:mm').format(_endTime),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                        ),
                      ),
                      onTap: _selectEndDateTime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              decoration: _inputDecoration('Ingatkan saya'),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4B5563)),
              value: _notificationMinutes,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Tepat waktu')),
                DropdownMenuItem(value: 60, child: Text('1 jam sebelumnya')),
                DropdownMenuItem(value: 1440, child: Text('1 hari sebelumnya')),
                DropdownMenuItem(value: 4320, child: Text('3 hari sebelumnya')),
                DropdownMenuItem(value: 10080, child: Text('7 hari sebelumnya')),
              ],
              onChanged: (val) => setState(() => _notificationMinutes = val!),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveReminder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 4,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.3),
                ),
                child: const Text('Simpan Pengingat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
