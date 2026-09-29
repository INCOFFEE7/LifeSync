import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';
import 'package:lifesync_app/presentation/providers/beebee_providers.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class AddFastingDebtPage extends ConsumerStatefulWidget {
  const AddFastingDebtPage({super.key});

  @override
  ConsumerState<AddFastingDebtPage> createState() => _AddFastingDebtPageState();
}

class _AddFastingDebtPageState extends ConsumerState<AddFastingDebtPage> {
  final _formKey = GlobalKey<FormState>();
  int _ramadanYear = DateTime.now().year;
  int _initialDebt = 0;
  String _reason = '';
  String _notes = '';

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final debt = FastingDebt()
        ..ramadanYear = _ramadanYear
        ..initialDebt = _initialDebt
        ..currentDebt = _initialDebt
        ..reason = _reason
        ..notes = _notes
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final repo = ref.read(fastingRepositoryProvider);
      await repo.saveDebt(debt);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.get(lang, 'catat_utang_puasa'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              initialValue: '$_ramadanYear',
              decoration: InputDecoration(labelText: AppTranslations.get(lang, 'tahun_ramadan')),
              keyboardType: TextInputType.number,
              validator: (val) => val!.isEmpty ? AppTranslations.get(lang, 'wajib_diisi') : null,
              onSaved: (val) => _ramadanYear = int.parse(val!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: AppTranslations.get(lang, 'jumlah_utang_hari')),
              keyboardType: TextInputType.number,
              validator: (val) => val!.isEmpty ? AppTranslations.get(lang, 'wajib_diisi') : null,
              onSaved: (val) => _initialDebt = int.parse(val!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: AppTranslations.get(lang, 'alasan_opsional')),
              onSaved: (val) => _reason = val ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: AppTranslations.get(lang, 'catatan_tambahan')),
              maxLines: 3,
              onSaved: (val) => _notes = val ?? '',
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saveDebt,
              child: Text(AppTranslations.get(lang, 'simpan')),
            ),
          ],
        ),
      ),
    );
  }
}
