import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: navigation.tabIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.tabIndex,
        onDestinationSelected: (i) => context.read<HomeNavigationProvider>().goToTab(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_rounded),
            label: 'Suche',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Berater',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Begleiter',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            label: 'Alarme',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Mehr',
          ),
        ],
      ),
    );
  }
}
