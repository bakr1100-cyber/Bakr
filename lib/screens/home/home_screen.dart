import 'package:flutter/material.dart';

import '../alerts/price_alerts_screen.dart';
import '../assistant/ai_chat_screen.dart';
import '../companion/travel_companion_screen.dart';
import '../search/search_form_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    SearchFormScreen(),
    AiChatScreen(),
    TravelCompanionScreen(),
    PriceAlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
