import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/menstruation_record.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class AddMenstruationPage extends ConsumerStatefulWidget {
  /// Optional: pre-filled start date from "Mulai Haid" flow.
  final DateTime? prefillStartDate;

  const AddMenstruationPage({super.key, this.prefillStartDate});

  @override
  ConsumerState<AddMenstruationPage> createState() => _AddMenstruationPageState();
}

class _AddMenstruationPageState extends ConsumerState<AddMenstruationPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isRamadan = false;
  String _notes = '';

  @override
  void initState() {
    super.initState();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (widget.prefillStartDate != null) {
      _startDate = widget.prefillStartDate!;
      _endDate = today.isAfter(_startDate) ? today : _startDate;
    } else {
      _startDate = today.subtract(const Duration(days: 4));
      _endDate = today;
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = date;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final utcEnd = DateTime.utc(_endDate.year, _endDate.month, _endDate.day);
      final utcStart = DateTime.utc(_startDate.year, _startDate.month, _startDate.day);

      final record = MenstruationRecord()
        ..startDate = _startDate
        ..endDate = _endDate
        ..duration = utcEnd.difference(utcStart).inDays + 1
        ..isRamadan = _isRamadan
        ..notes = _notes
        ..createdAt = DateTime.now();

      final repo = ref.read(menstruationRepositoryProvider);
      await repo.saveRecord(record);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final utcEnd = DateTime.utc(_endDate.year, _endDate.month, _endDate.day);
    final utcStart = DateTime.utc(_startDate.year, _startDate.month, _startDate.day);
    int duration = utcEnd.difference(utcStart).inDays + 1;

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.get(lang, 'catatan_datang_bulan'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.prefillStartDate != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFE91E8C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${AppTranslations.get(lang, 'mulai_sejak')}: ${DateFormat('dd MMM yyyy').format(widget.prefillStartDate!)}',
                        style: const TextStyle(color: Color(0xFFE91E8C), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppTranslations.get(lang, 'tanggal_mulai_haid'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _selectDate(true),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppTranslations.get(lang, 'tanggal_selesai_haid'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _selectDate(false),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse, color: Color(0xFFE91E8C)),
                  const SizedBox(width: 12),
                  Text('${AppTranslations.get(lang, 'durasi_label')}: $duration ${AppTranslations.get(lang, 'hari')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E8C))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppTranslations.get(lang, 'terjadi_di_ramadan')),
              subtitle: Text(AppTranslations.get(lang, 'otomatis_tambah_utang')),
              activeColor: const Color(0xFFE91E8C),
              value: _isRamadan,
              onChanged: (val) => setState(() => _isRamadan = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: AppTranslations.get(lang, 'catatan_opsional')),
              maxLines: 2,
              onSaved: (val) => _notes = val ?? '',
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saveRecord,
              child: Text(AppTranslations.get(lang, 'simpan_catatan')),
            ),
          ],
        ),
      ),
    );
  }
}
