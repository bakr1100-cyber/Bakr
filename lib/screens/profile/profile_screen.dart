import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/preferences_provider.dart';

/// Shows what the app has learned about the user - favorite airports,
/// airlines, budget, family vs. solo travel - per the "Persönliche
/// Empfehlungen" feature. Currently populated only from what the user sets
/// explicitly in Settings/search; a production build should also derive
/// this from booking history.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>().preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Deine Reisevorlieben')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(
            icon: Icons.flight_takeoff_rounded,
            label: 'Lieblingsflughafen (Abflug)',
            value: prefs.favoriteOriginAirportCode ?? 'Noch nicht bekannt',
          ),
          _InfoTile(
            icon: Icons.flight_land_rounded,
            label: 'Lieblingsziel',
            value: prefs.favoriteDestinationAirportCode ?? 'Noch nicht bekannt',
          ),
          _InfoTile(
            icon: Icons.airlines_rounded,
            label: 'Lieblingsairlines',
            value: prefs.favoriteAirlines.isEmpty
                ? 'Noch nicht bekannt'
                : prefs.favoriteAirlines.join(', '),
          ),
          _InfoTile(
            icon: Icons.payments_outlined,
            label: 'Übliches Budget',
            value: prefs.usualMaxBudgetEur != null
                ? '${prefs.usualMaxBudgetEur!.toStringAsFixed(0)} €'
                : 'Noch nicht bekannt',
          ),
          _InfoTile(
            icon: Icons.family_restroom_rounded,
            label: 'Reisestil',
            value: prefs.travelsWithFamily ? 'Mit Familie' : 'Alleinreisend',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
