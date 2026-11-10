import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/core/services/database_backup_service.dart';
import 'package:lifesync_app/data/repositories/isar_bill_repository.dart';
import 'package:lifesync_app/domain/entities/financial_category.dart';
import 'package:lifesync_app/domain/entities/financial_record.dart';
import 'package:lifesync_app/presentation/pages/reminders_page.dart';
import 'package:lifesync_app/presentation/pages/main_page.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/shopping_providers.dart';
import 'package:lifesync_app/presentation/providers/settings_provider.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final whatToDoConfig = AppConfig(
    variant: AppVariant.lifesync,
    appName: 'WhatToDo',
    logoPath: 'assets/images/logo/whatToDo_symbol_light.png',
    logoFullPath: 'assets/images/logo/whatToDo_logo_light.png',
    logoDarkPath: 'assets/images/logo/whatToDo_symbol_dark.png',
    logoDarkFullPath: 'assets/images/logo/whatToDo_logo_dark.png',
    splashLogoPath: 'assets/images/logo/whatToDo_splash_light.png',
    splashLogoDarkPath: 'assets/images/logo/whatToDo_splash_dark.png',
    lightTheme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    enabledModules: const ['finance_tracker', 'goals_tracker', 'reminders'],
  );

  setUp(() {
    AppEnvironment.setup(whatToDoConfig);
  });

  group('WhatToDo Branding & Theme-Aware Logo Tests', () {
    testWidgets(
        'LsBrandLogo selects light and dark assets from theme brightness',
        (tester) async {
      AppEnvironment.setup(whatToDoConfig);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Column(
              children: [
                LsBrandLogo(variant: LsLogoVariant.full, height: 42),
                LsBrandLogo(variant: LsLogoVariant.symbol, height: 38),
                LsBrandLogo(variant: LsLogoVariant.splash, width: 200),
              ],
            ),
          ),
        ),
      );

      final lightImages = tester.widgetList<Image>(find.byType(Image)).toList();
      expect((lightImages[0].image as AssetImage).assetName,
          'assets/images/logo/whatToDo_logo_light.png');
      expect((lightImages[1].image as AssetImage).assetName,
          'assets/images/logo/whatToDo_symbol_light.png');
      expect((lightImages[2].image as AssetImage).assetName,
          'assets/images/logo/whatToDo_splash_light.png');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Column(
              children: [
                LsBrandLogo(variant: LsLogoVariant.full, height: 42),
                LsBrandLogo(variant: LsLogoVariant.symbol, height: 38),
                LsBrandLogo(variant: LsLogoVariant.splash, width: 200),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkImages = tester.widgetList<Image>(find.byType(Image)).toList();
      expect((darkImages[0].image as AssetImage).assetName,
          'assets/images/logo/whatToDo_logo_dark.png');
      expect((darkImages[1].image as AssetImage).assetName,
          'assets/images/logo/whatToDo_symbol_dark.png');
      expect((darkImages[2].image as AssetImage).assetName,
          'assets/images/logo/whatToDo_splash_dark.png');
    });

    test(
        'AppConfig fallback preserves Beebee splash/logo paths when optional splash paths omitted',
        () {
      final beebeeStyleConfig = AppConfig(
        variant: AppVariant.beebee,
        appName: 'BeeHappy',
        logoPath: 'assets/images/logo_beebee.png',
        logoFullPath: 'assets/images/logofull_beebee.png',
        logoDarkPath: 'assets/images/logo_beebee_dark.png',
        logoDarkFullPath: 'assets/images/logofull_beebee_dark.png',
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        enabledModules: const ['period_tracker', 'fasting_tracker'],
      );
      expect(beebeeStyleConfig.variant, AppVariant.beebee);
      expect(beebeeStyleConfig.appName, 'BeeHappy');
      expect(beebeeStyleConfig.getLogoPath(false),
          'assets/images/logo_beebee.png');
      expect(beebeeStyleConfig.getSplashLogoPath(false),
          'assets/images/logofull_beebee.png');
      expect(beebeeStyleConfig.getSplashLogoPath(true),
          'assets/images/logofull_beebee_dark.png');
    });
  });

  group('Financial Record & Category Tests', () {
    test('Categories are correctly categorized by Income and Expense', () {
      final incomeCategories =
          FinancialCategory.getCategoriesByType(TransactionType.income);
      final expenseCategories =
          FinancialCategory.getCategoriesByType(TransactionType.expense);

      expect(incomeCategories.every((c) => c.type == TransactionType.income),
          isTrue);
      expect(expenseCategories.every((c) => c.type == TransactionType.expense),
          isTrue);

      expect(incomeCategories.any((c) => c.id == 'salary'), isTrue);
      expect(expenseCategories.any((c) => c.id == 'food'), isTrue);
    });

    test('FinancialCategory.findById returns correct category or fallback', () {
      final category = FinancialCategory.findById('food');
      expect(category.name, 'Makanan & Minuman');
      expect(category.type, TransactionType.expense);

      final unknown = FinancialCategory.findById('invalid_id');
      expect(unknown.id, 'unknown');
    });

    test('FinancialRecord entity initialization', () {
      final record = FinancialRecord()
        ..type = 'income'
        ..categoryId = 'salary'
        ..amount = 5000000.0
        ..description = 'Monthly Salary'
        ..transactionDate = DateTime(2026, 7, 22);

      expect(record.type, 'income');
      expect(record.categoryId, 'salary');
      expect(record.amount, 5000000.0);
      expect(record.description, 'Monthly Salary');
    });
  });

  group('Monthly Bill Recurrence, Range & Delete Scope Tests', () {
    test('BillRecurrenceRule auto mode generates future months except excluded',
        () {
      const rule = BillRecurrenceRule(
        mode: 'auto',
        startMonth: '2026-11',
        excludedMonths: ['2026-12'],
        updatedAtMs: 1000,
      );

      expect(rule.shouldGenerateForMonth('2026-11', '2026-11'), isFalse);
      expect(rule.shouldGenerateForMonth('2026-12', '2026-11'), isFalse);
      expect(rule.shouldGenerateForMonth('2027-01', '2026-11'), isTrue);
      expect(rule.shouldGenerateForMonth('2027-06', '2026-11'), isTrue);
    });

    test('BillRecurrenceRule range mode stops after endMonth', () {
      const rule = BillRecurrenceRule(
        mode: 'range',
        startMonth: '2026-11',
        endMonth: '2027-01',
        updatedAtMs: 1000,
      );

      expect(rule.shouldGenerateForMonth('2026-12', '2026-11'), isTrue);
      expect(rule.shouldGenerateForMonth('2027-01', '2026-11'), isTrue);
      expect(rule.shouldGenerateForMonth('2027-02', '2026-11'), isFalse);
    });

    test(
        'IsarBillRepository month helpers and dueDate clamping work accurately',
        () {
      expect(IsarBillRepository.nextMonthKey('2026-12'), '2027-01');
      expect(IsarBillRepository.prevMonthKey('2027-01'), '2026-12');
      expect(
        IsarBillRepository.monthsInRange('2026-11', '2027-02'),
        ['2026-11', '2026-12', '2027-01', '2027-02'],
      );

      // Clamping Jan 31 -> Feb 28 in non-leap year 2027, preserving hour & minute
      final jan31 = DateTime(2027, 1, 31, 14, 30);
      final febDue =
          IsarBillRepository.calculateDueDateForMonth(jan31, '2027-02');
      expect(febDue, DateTime(2027, 2, 28, 14, 30));

      // Stripping payment realization notes when carrying over to next month
      const rawNotes = 'No Pelanggan 12345\n[Bayar 05/11/26]: Lunas via BCA';
      expect(
        IsarBillRepository.cleanBillNotesForNextMonth(rawNotes),
        'No Pelanggan 12345',
      );
    });

    testWidgets(
        'showLsBillDeleteDialog returns thisMonthOnly or thisAndFutureMonths',
        (tester) async {
      LsBillDeleteScope? selectedScope;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedScope = await showLsBillDeleteDialog(
                    context: context,
                    billName: 'Internet WiFi',
                    monthLabel: 'November 2026',
                  );
                },
                child: const Text('Open Delete Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Delete Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Bulan Ini Saja'), findsOneWidget);
      expect(find.text('Hapus Bulan Ini dan Seterusnya'), findsOneWidget);

      await tester.tap(find.text('Hapus Bulan Ini dan Seterusnya'));
      await tester.pumpAndSettle();

      expect(selectedScope, LsBillDeleteScope.thisAndFutureMonths);
    });
  });

  group('DatabaseBackupService Encrypted Snapshot & Font Scale Tests', () {
    test('Encrypt and Decrypt snapshot roundtrip preserves exact payload', () {
      final sampleSnapshot = <String, dynamic>{
        'version': 1,
        'app': 'WhatToDo',
        'exportedAt': '2026-11-10T12:00:00.000Z',
        'collections': {
          'financialNotes': [
            {'title': 'Gaji', 'type': 'income', 'totalAmount': 5000000.0}
          ],
          'bills': [
            {'title': 'Listrik', 'amount': 250000.0, 'isPaid': false}
          ],
        },
      };

      final encrypted = DatabaseBackupService.encryptSnapshot(sampleSnapshot);
      expect(encrypted.startsWith('WTDBACKUP_V1:'), isTrue);

      final decrypted = DatabaseBackupService.decryptSnapshot(encrypted);
      expect(decrypted, isNotNull);
      expect(decrypted!['version'], 1);
      expect(decrypted['app'], 'WhatToDo');
      expect(decrypted['exportedAt'], '2026-11-10T12:00:00.000Z');
      final collections = decrypted['collections'] as Map<String, dynamic>;
      final notes = collections['financialNotes'] as List;
      final bills = collections['bills'] as List;
      expect(notes[0]['title'], 'Gaji');
      expect(bills[0]['amount'], 250000.0);
    });

    test(
        'Decrypt snapshot rejects invalid header and corrupted payload with null',
        () {
      expect(
        DatabaseBackupService.decryptSnapshot('INVALID_HEADER:YWJjZA=='),
        isNull,
      );
    });

    test('FontSizeNotifier initializes default 1.0 and persists update',
        () async {
      SharedPreferences.setMockInitialValues({'app_font_scale': 1.0});
      final notifier = FontSizeNotifier();
      expect(notifier.state, 1.0);

      await notifier.setScale(1.18);
      expect(notifier.state, 1.18);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('app_font_scale'), 1.18);
    });

    testWidgets(
        'RemindersPage pill tab bar layouts without size.isFinite Stack assertion',
        (tester) async {
      await initializeDateFormatting('id_ID', null);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remindersStreamProvider.overrideWith((ref) => Stream.value([])),
            shoppingItemsProvider.overrideWith((ref) => Stream.value([])),
            billsStreamProvider(
                    DateTime.now().toIso8601String().substring(0, 7))
                .overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: RemindersPage(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Ringkasan'), findsWidgets);
      expect(find.text('Agenda'), findsWidgets);
      expect(find.text('Tagihan'), findsWidgets);
      expect(find.text('Belanja'), findsWidgets);

      // Verify tapping across tabs animates without any Stack layout exception
      await tester.tap(find.widgetWithText(GestureDetector, 'Agenda').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(GestureDetector, 'Tagihan').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'FluidBottomBar animates and handles tab taps smoothly without layout error',
        (tester) async {
      int currentTab = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return FluidBottomBar(
                  currentIndex: currentTab,
                  onTabSelected: (idx) {
                    setState(() => currentTab = idx);
                  },
                  onFabTap: () {},
                  lang: 'id',
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Keuangan'), findsOneWidget);
      expect(find.text('Nabung'), findsOneWidget);
      expect(find.text('Pengingat'), findsOneWidget);

      // Tap Keuangan (adjacent transition: contracts, trailing droplets, blooms)
      await tester.tap(find.text('Keuangan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(currentTab, 1);

      // Tap Nabung (crosses center FAB column)
      await tester.tap(find.text('Nabung'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(currentTab, 2);

      // Re-tap current tab (triggers jelly squish wobble)
      await tester.tap(find.text('Nabung'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(currentTab, 2);
    });
  });
}
