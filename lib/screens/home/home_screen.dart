import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../providers/home_navigation_provider.dart';
import '../alerts/price_alerts_screen.dart';
import '../assistant/ai_chat_screen.dart';
import '../companion/travel_companion_screen.dart';
import '../search/search_form_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _screens = [
    SearchFormScreen(),
    AiChatScreen(),
    TravelCompanionScreen(),
    PriceAlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<HomeNavigationProvider>();
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: navigation.tabIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.tabIndex,
        onDestinationSelected: (i) => context.read<HomeNavigationProvider>().goToTab(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.flight_takeoff_rounded),
            label: t('navSearch'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: t('navAdvisor'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            label: t('navCompanion'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_none_rounded),
            label: t('navAlerts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: t('navMore'),
          ),
        ],
      ),
    );
  }
}
