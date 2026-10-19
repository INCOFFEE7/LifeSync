import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/app_settings.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/providers/settings_provider.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

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
  int _notificationMinutes = 0; // Default: Tepat waktu
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
      
      // Clamp ID ke int32 — Android notification ID harus int32 (max 2.1 miliar).
      // Isar ID berbasis millisecondsSinceEpoch (~1.7 triliun) akan overflow jika langsung dipakai.
      final notifId = id & 0x7FFFFFFF;

      // Schedule notification
      final notifService = ref.read(notificationServiceProvider);
      DateTime scheduledTime;
      if (_isAllDay) {
        // All‑day reminder fires at 06:00 on the target date
        scheduledTime = DateTime(_targetDateTime.year, _targetDateTime.month, _targetDateTime.day, 6, 0);
      } else {
        scheduledTime = _targetDateTime.subtract(Duration(minutes: _notificationMinutes));
      }
      
      final now = DateTime.now();
      if (!scheduledTime.isAfter(now)) {
        if (_targetDateTime.isAfter(now)) {
          // Jika waktu minus offset sudah lewat, fallback ke waktu mulai agenda
          scheduledTime = _targetDateTime;
        } else if (_endTime.isAfter(now)) {
          // Jika waktu mulai juga lewat namun agenda masih berjalan, bunyikan 5 detik lagi
          scheduledTime = now.add(const Duration(seconds: 5));
        }
      }

      debugPrint('[CreateReminder] Scheduling notif id=$notifId at $scheduledTime (now=$now)');
      
      final sound = _selectedSound ?? ref.read(defaultSoundProvider);
      
      try {
        if (scheduledTime.isAfter(now)) {
          await notifService.scheduleNotification(
            id: notifId,
            title: _title,
            body: _description.trim().isNotEmpty
                ? _description.trim()
                : 'Pengingat agenda Anda telah tiba.',
            scheduledTime: scheduledTime,
            sound: sound,
            featureName: 'Pengingat Agenda',
          );
          debugPrint('[CreateReminder] Notification scheduled successfully at $scheduledTime.');
        } else {
          debugPrint('[CreateReminder] Agenda sudah selesai sepenuhnya, notif tidak dijadwalkan.');
        }
      } catch (e) {
        debugPrint('[CreateReminder] Failed to schedule notification: $e');
      } finally {
        if (mounted) {
          // Invalidate dashboard so it auto-updates
          ref.invalidate(dashboardDataProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.existingReminder == null
                          ? 'Pengingat "${reminder.title}" berhasil dibuat!'
                          : 'Pengingat "${reminder.title}" berhasil diperbarui!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2563EB),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    final line = LsColors.line(context);
    OutlineInputBorder b(Color c, double w) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: LsColors.mute(context), fontWeight: FontWeight.w500, fontSize: 14),
      filled: true,
      fillColor: LsColors.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(line, 1),
      enabledBorder: b(line, 1),
      focusedBorder: b(LsColors.brand, 2),
      errorBorder: b(LsColors.expense, 1.5),
      focusedErrorBorder: b(LsColors.expense, 2),
    );
  }

  Future<void> _showEditCategoryDialog(String currentCategory) async {
    final textController = TextEditingController(text: currentCategory);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ubah Nama Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perubahan hanya berlaku untuk pengingat yang dibuat saat ini dan seterusnya.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nama Kategori Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LsColors.brand),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) Navigator.pop(ctx, val);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentCategory) {
      final db = ref.read(databaseServiceProvider).db;
      db.writeTxnSync(() {
        final settings = db.appSettings.getSync(1) ?? AppSettings()..id = 1;
        final list = List<String>.from(settings.customCategories);
        final index = list.indexOf(currentCategory);
        if (index != -1) {
          list[index] = newName;
        } else {
          list.add(newName);
        }
        settings.customCategories = list;
        db.appSettings.putSync(settings);
      });

      setState(() {
        final idx = _existingCustomCategories.indexOf(currentCategory);
        if (idx != -1) {
          _existingCustomCategories[idx] = newName;
        }
        _selectedCategoryValue = newName;
        _customCategory = newName;
      });
    }
  }

  String _categoryLabel(ReminderCategory c) {
    switch (c) {
      case ReminderCategory.work:
        return 'Kerja';
      case ReminderCategory.personal:
        return 'Pribadi';
      case ReminderCategory.health:
        return 'Kesehatan';
      case ReminderCategory.finance:
        return 'Keuangan';
      case ReminderCategory.other:
        return 'Lainnya';
    }
  }

  void _selectCategoryValue(String val) {
    setState(() {
      _selectedCategoryValue = val;
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
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LsEyebrow(title, color: LsColors.brand),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool selected, Color color, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : LsColors.paper(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : LsColors.line(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : LsColors.ink(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prioritySegment(String label, PriorityLevel value, Color color) {
    final selected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeTile(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: LsColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LsColors.line(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: LsColors.mute(context), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LsColors.ink(context))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = LsColors.ink(context);
    const notifyOptions = <int, String>{
      0: 'Tepat waktu',
      60: '1 jam sebelumnya',
      1440: '1 hari sebelumnya',
      4320: '3 hari sebelumnya',
      10080: '7 hari sebelumnya',
    };

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        backgroundColor: LsColors.paper(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        title: Text(
          widget.existingReminder == null ? 'Buat Pengingat' : 'Edit Pengingat',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _section('Detail Agenda', [
              TextFormField(
                initialValue: _title,
                decoration: _inputDecoration('Judul Pengingat *'),
                style: TextStyle(fontWeight: FontWeight.w600, color: ink),
                validator: (val) => val == null || val.trim().isEmpty ? 'Judul pengingat wajib diisi' : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _description,
                decoration: _inputDecoration('Deskripsi/Catatan'),
                style: TextStyle(color: ink),
                maxLines: 3,
                onSaved: (val) => _description = val ?? '',
              ),
            ]),
            _section('Kategori', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...ReminderCategory.values
                      .where((c) => c != ReminderCategory.other)
                      .map((c) => _pill(_categoryLabel(c), _selectedCategoryValue == c.name, LsColors.brand, () => _selectCategoryValue(c.name))),
                  ..._existingCustomCategories.map((c) => _pill(c, _selectedCategoryValue == c, LsColors.brand, () => _selectCategoryValue(c))),
                  _pill('Lainnya', _selectedCategoryValue == 'ADD_NEW', LsColors.brand, () => _selectCategoryValue('ADD_NEW'), icon: Icons.add),
                  if (_existingCustomCategories.contains(_selectedCategoryValue))
                    InkWell(
                      onTap: () => _showEditCategoryDialog(_selectedCategoryValue),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: LsColors.brand.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, size: 14, color: LsColors.brand),
                      ),
                    ),
                ],
              ),
              if (_selectedCategoryValue == 'ADD_NEW') ...[
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: _customCategory,
                  decoration: _inputDecoration('Nama Kategori Lainnya'),
                  style: TextStyle(fontWeight: FontWeight.w600, color: ink),
                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  onSaved: (val) => _customCategory = val,
                ),
              ],
            ]),
            _section('Prioritas', [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: LsColors.paper(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LsColors.line(context)),
                ),
                child: Row(
                  children: [
                    _prioritySegment('Rendah', PriorityLevel.low, LsColors.income),
                    _prioritySegment('Sedang', PriorityLevel.medium, LsColors.amber),
                    _prioritySegment('Tinggi', PriorityLevel.high, LsColors.expense),
                  ],
                ),
              ),
            ]),
            _section('Waktu', [
              Row(
                children: [
                  Expanded(
                    child: Text('Seharian Penuh (All Day)', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                  ),
                  Switch(
                    value: _isAllDay,
                    activeColor: LsColors.brand,
                    onChanged: (val) {
                      setState(() {
                        _isAllDay = val;
                        if (val) {
                          _targetDateTime = DateTime(_targetDateTime.year, _targetDateTime.month, _targetDateTime.day);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _timeTile(
                    'Waktu Mulai',
                    _isAllDay ? DateFormat('dd MMM yyyy').format(_targetDateTime) : DateFormat('dd MMM yyyy, HH:mm').format(_targetDateTime),
                    _selectStartDateTime,
                  ),
                  const SizedBox(width: 10),
                  _timeTile(
                    'Waktu Selesai',
                    _isAllDay ? DateFormat('dd MMM yyyy').format(_endTime) : DateFormat('dd MMM yyyy, HH:mm').format(_endTime),
                    _selectEndDateTime,
                  ),
                ],
              ),
            ]),
            _section('Ingatkan Saya', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notifyOptions.entries
                    .map((e) => _pill(e.value, _notificationMinutes == e.key, LsColors.violet, () => setState(() => _notificationMinutes = e.key), icon: Icons.notifications_none_rounded))
                    .toList(),
              ),
            ]),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveReminder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: LsColors.brand,
                  elevation: 0,
                ),
                child: const Text('Simpan Pengingat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
