import 'package:flutter/material.dart';

import '../../../core/models/travel_companion_event.dart';

const _mockEvents = [
  TravelCompanionEvent(
    phase: TravelPhase.preFlight,
    title: 'Online Check-in',
    description: 'Erinnerung: Check-in öffnet 24h vor Abflug.',
  ),
  TravelCompanionEvent(
    phase: TravelPhase.preFlight,
    title: 'Gepäckregeln',
    description: '1 Handgepäck (10kg) + 1 Aufgabegepäck (23kg) inklusive.',
  ),
  TravelCompanionEvent(
    phase: TravelPhase.atAirport,
    title: 'Boarding beginnt in 20 Minuten',
    description: 'Gate B24. Plane etwa 15 Minuten bis zum Gate ein.',
  ),
  TravelCompanionEvent(
    phase: TravelPhase.inFlight,
    title: 'Offline verfügbar',
    description:
        'Frag mich nach Sehenswürdigkeiten, Restaurants oder ONCF-Zügen '
        'in Marokko – auch ohne Internetverbindung.',
  ),
  TravelCompanionEvent(
    phase: TravelPhase.postLanding,
    title: 'Willkommen in Rabat',
    description:
        'Der nächste ONCF-Zug nach Fès fährt um 15:20 Uhr von Gleis 2 '
        '(ca. 2 Std. 50 Min.).',
  ),
];

const _phaseLabels = {
  TravelPhase.preFlight: 'Vor der Reise',
  TravelPhase.atAirport: 'Am Flughafen',
  TravelPhase.inFlight: 'Während des Fluges',
  TravelPhase.postLanding: 'Nach der Landung',
};

const _phaseIcons = {
  TravelPhase.preFlight: Icons.checklist,
  TravelPhase.atAirport: Icons.local_airport,
  TravelPhase.inFlight: Icons.airplanemode_active,
  TravelPhase.postLanding: Icons.map,
};

/// Travel companion timeline. This screen renders static mock events; a
/// real build would subscribe to Firestore/FCM for gate changes, delays,
/// and post-landing transit info as described in the product vision.
class TravelCompanionScreen extends StatelessWidget {
  const TravelCompanionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reisebegleiter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final phase in TravelPhase.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                children: [
                  Icon(_phaseIcons[phase], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _phaseLabels[phase]!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            for (final event in _mockEvents.where((e) => e.phase == phase))
              Card(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(event.description),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
