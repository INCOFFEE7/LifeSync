import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/presentation/pages/beebee/beebee_dashboard_page.dart';
import 'package:lifesync_app/presentation/pages/beebee/beebee_calendar_page.dart';
import 'package:lifesync_app/presentation/pages/beebee/fasting_history_page.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:lifesync_app/core/utils/translations.dart';

class BeebeeMainPage extends ConsumerStatefulWidget {
  const BeebeeMainPage({super.key});

  @override
  ConsumerState<BeebeeMainPage> createState() => _BeebeeMainPageState();
}

class _BeebeeMainPageState extends ConsumerState<BeebeeMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BeebeeDashboardPage(),
    const BeebeeCalendarPage(),
    const FastingHistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: AppTranslations.get(lang, 'dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: AppTranslations.get(lang, 'kalender'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: AppTranslations.get(lang, 'riwayat'),
          ),
        ],
      ),
    );
  }
}
