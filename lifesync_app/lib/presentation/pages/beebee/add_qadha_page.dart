import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/domain/entities/qadha_record.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class AddQadhaPage extends ConsumerStatefulWidget {
  const AddQadhaPage({super.key});

  @override
  ConsumerState<AddQadhaPage> createState() => _AddQadhaPageState();
}

class _AddQadhaPageState extends ConsumerState<AddQadhaPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int _amount = 1;
  String _notes = '';
  FastingDebt? _selectedDebt;

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }

        _amount = DateTime(_endDate.year, _endDate.month, _endDate.day)
            .difference(DateTime(_startDate.year, _startDate.month, _startDate.day))
            .inDays + 1;
      });
    }
  }

  Future<void> _saveQadha() async {
    final lang = ref.read(localeProvider).languageCode;
    if (_formKey.currentState!.validate() && _selectedDebt != null) {
      _formKey.currentState!.save();

      if (_amount > _selectedDebt!.currentDebt) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.get(lang, 'jumlah_melebihi_sisa'))),
        );
        return;
      }

      final record = QadhaRecord()
        ..fastingDebtId = _selectedDebt!.id
        ..date = _startDate
        ..amount = _amount
        ..notes = _notes
        ..createdAt = DateTime.now();

      final repo = ref.read(fastingRepositoryProvider);
      await repo.saveQadha(record);

      ref.invalidate(fastingDebtsProvider);
      ref.invalidate(qadhaRecordsProvider);
      ref.invalidate(totalFastingDebtSummaryProvider);

      if (mounted) Navigator.pop(context);
    } else if (_selectedDebt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.get(lang, 'wajib_diisi'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(fastingDebtsProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.get(lang, 'catat_puasa_qadha'))),
      body: debtsAsync.when(
        data: (debts) {
          final activeDebts = debts.where((d) => d.currentDebt > 0).toList();

          if (activeDebts.isEmpty) {
            return Center(child: Text(AppTranslations.get(lang, 'tidak_ada_utang')));
          }

          if (_selectedDebt == null && activeDebts.isNotEmpty) {
            _selectedDebt = activeDebts.first;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<FastingDebt>(
                  decoration: InputDecoration(labelText: AppTranslations.get(lang, 'tujuan_pelunasan')),
                  value: _selectedDebt,
                  items: activeDebts.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text('${AppTranslations.get(lang, 'ramadan')} ${d.ramadanYear} (${AppTranslations.get(lang, 'sisa')}: ${d.currentDebt} ${AppTranslations.get(lang, 'hari')})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDebt = val),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppTranslations.get(lang, 'tanggal_mulai_pelaksanaan'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () => _selectDate(true),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppTranslations.get(lang, 'tanggal_selesai_pelaksanaan'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () => _selectDate(false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_amount),
                  initialValue: '$_amount',
                  decoration: InputDecoration(labelText: AppTranslations.get(lang, 'jumlah_hari')),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? AppTranslations.get(lang, 'wajib_diisi') : null,
                  onSaved: (val) => _amount = int.parse(val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: AppTranslations.get(lang, 'catatan')),
                  maxLines: 2,
                  onSaved: (val) => _notes = val ?? '',
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saveQadha,
                  child: Text(AppTranslations.get(lang, 'simpan')),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
