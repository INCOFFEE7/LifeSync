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
import 'package:lifesync_app/presentation/widgets/ls_date_time_picker_sheet.dart';

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
  DateTime? _customReminderTime;
  bool _isAllDay = false;
  String? _selectedSound; // Selected notification sound
  String? _customCategory;

  static const _presetOptions = <int, String>{
    0: 'Tepat waktu',
    15: '15 menit sebelumnya',
    60: '1 jam sebelumnya',
    1440: '1 hari sebelumnya',
    4320: '3 hari sebelumnya',
    10080: '7 hari sebelumnya',
    -1: 'Tidak ada',
  };

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
      _notificationMinutes =
          widget.existingReminder!.notificationPreferenceMinutes;
      if (_notificationMinutes > 0 &&
          !_presetOptions.containsKey(_notificationMinutes)) {
        _customReminderTime =
            _targetDateTime.subtract(Duration(minutes: _notificationMinutes));
      }
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

  Future<void> _pickStartDate() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _targetDateTime,
      enableTime: false,
      title: 'Tanggal Mulai Agenda',
      confirmLabel: 'Atur Tanggal',
    );
    if (picked != null && mounted) {
      setState(() {
        _targetDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _isAllDay ? 0 : _targetDateTime.hour,
          _isAllDay ? 0 : _targetDateTime.minute,
        );
        if (_endTime.isBefore(_targetDateTime) ||
            _endTime.isAtSameMomentAs(_targetDateTime)) {
          _endTime = _isAllDay
              ? DateTime(picked.year, picked.month, picked.day, 23, 59)
              : _targetDateTime.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _targetDateTime,
      enableTime: true,
      title: 'Waktu Mulai Agenda',
      confirmLabel: 'Atur Waktu',
    );
    if (picked != null && mounted) {
      setState(() {
        _targetDateTime = picked;
        if (_endTime.isBefore(_targetDateTime) ||
            _endTime.isAtSameMomentAs(_targetDateTime)) {
          _endTime = _isAllDay
              ? DateTime(picked.year, picked.month, picked.day, 23, 59)
              : _targetDateTime.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime:
          _endTime.isBefore(_targetDateTime) ? _targetDateTime : _endTime,
      minimumDate: _targetDateTime,
      enableTime: false,
      title: 'Tanggal Selesai Agenda',
      confirmLabel: 'Atur Tanggal',
    );
    if (picked != null && mounted) {
      setState(() {
        _endTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _isAllDay ? 23 : _endTime.hour,
          _isAllDay ? 59 : _endTime.minute,
        );
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime:
          _endTime.isBefore(_targetDateTime) ? _targetDateTime : _endTime,
      minimumDate: _targetDateTime,
      enableTime: true,
      title: 'Waktu Selesai Agenda',
      confirmLabel: 'Atur Waktu',
    );
    if (picked != null && mounted) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _pickCustomReminderDateTime() async {
    final picked = await showLsDateTimePickerSheet(
      context: context,
      initialDateTime: _customReminderTime ??
          (_targetDateTime.isAfter(DateTime.now())
              ? _targetDateTime
              : DateTime.now()),
      title: 'Waktu Notifikasi Pengingat',
      confirmLabel: 'Pasang Pengingat',
    );
    if (picked != null && mounted) {
      setState(() {
        _customReminderTime = picked;
        final diff = _targetDateTime.difference(picked).inMinutes;
        _notificationMinutes = diff > 0 ? diff : 0;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_endTime.isBefore(_targetDateTime) ||
          _endTime.isAtSameMomentAs(_targetDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu selesai harus lebih lambat dari waktu mulai!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final confirm = await showLsConfirmDialog(
        context: context,
        title: widget.existingReminder == null
            ? 'Simpan Agenda?'
            : 'Perbarui Agenda?',
        message:
            'Apakah detail dan jadwal agenda yang dimasukkan sudah sesuai?',
        confirmLabel: 'Ya, Simpan',
        cancelLabel: 'Batal',
      );
      if (!confirm || !mounted) return;

      final reminder = Reminder()
        ..id =
            widget.existingReminder?.id ?? DateTime.now().millisecondsSinceEpoch
        ..title = _title
        ..description = _description
        ..category = _category
        ..customCategory =
            _category == ReminderCategory.other ? _customCategory : null
        ..priority = _priority
        ..targetDateTime = _isAllDay
            ? DateTime(_targetDateTime.year, _targetDateTime.month,
                _targetDateTime.day)
            : _targetDateTime
        ..endTime = _isAllDay
            ? DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59)
            : _endTime
        ..isAllDay = _isAllDay
        ..status = widget.existingReminder?.status ?? ReminderStatus.pending
        ..createdAt = widget.existingReminder?.createdAt ?? DateTime.now()
        ..notificationPreferenceMinutes = _notificationMinutes
        ..customSound = _selectedSound;

      if (_category == ReminderCategory.other &&
          _customCategory != null &&
          _customCategory!.isNotEmpty) {
        // Save to AppSettings custom categories (future task sync)
        final db = ref.read(databaseServiceProvider).db;
        db.writeTxnSync(() {
          final settings = db.appSettings.getSync(1) ?? AppSettings()
            ..id = 1;
          if (!settings.customCategories.contains(_customCategory)) {
            settings.customCategories = List.from(settings.customCategories)
              ..add(_customCategory!);
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
      try {
        if (_notificationMinutes == -1) {
          debugPrint('[CreateReminder] Notif dimatikan (Tidak Ada).');
        } else {
          DateTime scheduledTime;
          if (_customReminderTime != null) {
            scheduledTime = _customReminderTime!;
          } else if (_isAllDay) {
            // All‑day reminder fires at 06:00 on the target date
            scheduledTime = DateTime(_targetDateTime.year,
                _targetDateTime.month, _targetDateTime.day, 6, 0);
          } else {
            scheduledTime = _targetDateTime
                .subtract(Duration(minutes: _notificationMinutes));
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

          debugPrint(
              '[CreateReminder] Scheduling notif id=$notifId at $scheduledTime (now=$now)');

          final sound = _selectedSound ?? ref.read(defaultSoundProvider);

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
            debugPrint(
                '[CreateReminder] Notification scheduled successfully at $scheduledTime.');
          } else {
            debugPrint(
                '[CreateReminder] Agenda sudah selesai sepenuhnya, notif tidak dijadwalkan.');
          }
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
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: LsColors.mute(context),
          fontWeight: FontWeight.w500,
          fontSize: 13),
      filled: true,
      fillColor: LsColors.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: LsColors.line(ctx), width: 1.2),
        ),
        backgroundColor: LsColors.surface(ctx),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LsColors.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: LsColors.brand.withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Icon(Icons.edit_note_rounded,
                  size: 22, color: LsColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ubah Nama Kategori',
                style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: LsColors.ink(ctx)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perubahan hanya berlaku untuk pengingat yang dibuat saat ini dan seterusnya.',
              style: TextStyle(fontSize: 12, color: LsColors.mute(ctx)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nama Kategori Baru *',
                filled: true,
                fillColor: LsColors.paper(ctx),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: LsColors.line(ctx), width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Batal',
                        style: TextStyle(
                            color: LsColors.ink(ctx),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: LsColors.brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final val = textController.text.trim();
                      if (val.isNotEmpty) Navigator.pop(ctx, val);
                    },
                    child: const Text('Simpan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentCategory) {
      final db = ref.read(databaseServiceProvider).db;
      db.writeTxnSync(() {
        final settings = db.appSettings.getSync(1) ?? AppSettings()
          ..id = 1;
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
      padding: const EdgeInsets.only(bottom: 12),
      child: LsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LsEyebrow(title, color: LsColors.brand),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool selected, Color color, VoidCallback onTap,
      {IconData? icon}) {
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

  Widget _pickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: LsColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LsColors.line(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: LsColors.mute(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LsColors.ink(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getReminderLabel() {
    if (_customReminderTime != null) {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID')
          .format(_customReminderTime!);
    }
    if (_presetOptions.containsKey(_notificationMinutes)) {
      return _presetOptions[_notificationMinutes]!;
    }
    if (_notificationMinutes < 0) {
      return 'Tidak ada';
    }
    if (_notificationMinutes % 1440 == 0) {
      return '${_notificationMinutes ~/ 1440} hari sebelumnya';
    } else if (_notificationMinutes % 60 == 0) {
      return '${_notificationMinutes ~/ 60} jam sebelumnya';
    } else {
      return '$_notificationMinutes menit sebelumnya';
    }
  }

  Widget _buildReminderSelectorTile() {
    return InkWell(
      onTap: _showReminderModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LsColors.paper(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LsColors.line(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Waktu Pengingat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LsColors.ink(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: LsColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: LsColors.brand.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getReminderLabel(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: LsColors.brand,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 18, color: LsColors.brand),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderModal() async {
    const customOptionKey = -999;
    final currentVal =
        _customReminderTime != null ? customOptionKey : _notificationMinutes;

    final selected = await showLsOptionsSheet<int>(
      context: context,
      title: 'Waktu Pengingat',
      subtitle: 'Pilih kapan notifikasi pengingat agenda dikirimkan',
      headerIcon: Icons.notifications_active_outlined,
      selectedValue: currentVal,
      options: [
        ..._presetOptions.entries.map(
          (e) => LsOptionItem<int>(
            value: e.key,
            title: e.value,
            icon: e.key < 0
                ? Icons.notifications_off_outlined
                : Icons.alarm_rounded,
            iconColor: e.key < 0 ? LsColors.mute(context) : LsColors.brand,
          ),
        ),
        LsOptionItem<int>(
          value: customOptionKey,
          title: 'Pilih Kalender & Waktu Kustom...',
          subtitle: _customReminderTime != null
              ? DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                  .format(_customReminderTime!)
              : 'Atur tanggal dan jam pengingat secara spesifik',
          icon: Icons.edit_calendar_rounded,
          iconColor: LsColors.violet,
        ),
      ],
    );

    if (selected == null || !mounted) return;
    if (selected == customOptionKey) {
      await _pickCustomReminderDateTime();
    } else {
      setState(() {
        _customReminderTime = null;
        _notificationMinutes = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = LsColors.ink(context);

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
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.5),
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
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Judul pengingat wajib diisi'
                    : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 10),
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
                      .map((c) => _pill(
                          _categoryLabel(c),
                          _selectedCategoryValue == c.name,
                          LsColors.brand,
                          () => _selectCategoryValue(c.name))),
                  ..._existingCustomCategories.map((c) => _pill(
                      c,
                      _selectedCategoryValue == c,
                      LsColors.brand,
                      () => _selectCategoryValue(c))),
                  _pill('Lainnya', _selectedCategoryValue == 'ADD_NEW',
                      LsColors.brand, () => _selectCategoryValue('ADD_NEW'),
                      icon: Icons.add),
                  if (_existingCustomCategories
                      .contains(_selectedCategoryValue))
                    InkWell(
                      onTap: () =>
                          _showEditCategoryDialog(_selectedCategoryValue),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: LsColors.brand.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 14, color: LsColors.brand),
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
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Wajib diisi' : null,
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
                    _prioritySegment(
                        'Rendah', PriorityLevel.low, LsColors.income),
                    _prioritySegment(
                        'Sedang', PriorityLevel.medium, LsColors.amber),
                    _prioritySegment(
                        'Tinggi', PriorityLevel.high, LsColors.expense),
                  ],
                ),
              ),
            ]),
            _section('Waktu', [
              Row(
                children: [
                  Expanded(
                    child: Text('Seharian Penuh (All Day)',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, color: ink)),
                  ),
                  Switch(
                    value: _isAllDay,
                    activeThumbColor: LsColors.brand,
                    onChanged: (val) {
                      setState(() {
                        _isAllDay = val;
                        if (val) {
                          _targetDateTime = DateTime(_targetDateTime.year,
                              _targetDateTime.month, _targetDateTime.day);
                          _endTime = DateTime(
                              _targetDateTime.year,
                              _targetDateTime.month,
                              _targetDateTime.day,
                              23,
                              59);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Waktu Mulai',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: LsColors.mute(context)),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _pickerTile(
                    label: 'Tanggal Mulai',
                    value: DateFormat('dd MMM yyyy', 'id_ID')
                        .format(_targetDateTime),
                    onTap: _pickStartDate,
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(width: 8),
                    _pickerTile(
                      label: 'Jam Mulai',
                      value:
                          DateFormat('HH:mm', 'id_ID').format(_targetDateTime),
                      onTap: _pickStartTime,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Waktu Selesai',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: LsColors.mute(context)),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _pickerTile(
                    label: 'Tanggal Selesai',
                    value: DateFormat('dd MMM yyyy', 'id_ID').format(_endTime),
                    onTap: _pickEndDate,
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(width: 8),
                    _pickerTile(
                      label: 'Jam Selesai',
                      value: DateFormat('HH:mm', 'id_ID').format(_endTime),
                      onTap: _pickEndTime,
                    ),
                  ],
                ],
              ),
            ]),
            _section('Ingatkan Saya', [
              _buildReminderSelectorTile(),
            ]),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveReminder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: LsColors.brand,
                  elevation: 0,
                ),
                child: const Text('Simpan Pengingat',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
