import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/companion_event.dart';
import '../../models/itinerary.dart';
import '../../services/travel_companion_service.dart';

class TravelCompanionScreen extends StatelessWidget {
  const TravelCompanionScreen({super.key, this.itinerary});

  final Itinerary? itinerary;

  static final _service = TravelCompanionService();

  String _stageTitle(CompanionStage stage) => switch (stage) {
        CompanionStage.beforeTrip => 'Vor der Reise',
        CompanionStage.atAirport => 'Am Flughafen',
        CompanionStage.duringFlight => 'Während des Fluges',
        CompanionStage.afterLanding => 'Nach der Landung',
      };

  @override
  Widget build(BuildContext context) {
    if (itinerary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reisebegleiter')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sobald du eine Reise buchst, begleite ich dich von der '
              'Anreise bis zur Ankunft - Check-in, Gate-Änderungen, '
              'Boarding, und Tipps für dein Ziel.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final events = _service.buildTimeline(itinerary!);
    final grouped = <CompanionStage, List<CompanionEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.stage, () => []).add(event);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reisebegleiter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final stage in CompanionStage.values)
            if (grouped[stage]?.isNotEmpty ?? false) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _stageTitle(stage),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final event in grouped[stage]!)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      event.isUrgent
                          ? Icons.notifications_active_rounded
                          : Icons.info_outline_rounded,
                      color: event.isUrgent
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    title: Text(event.title),
                    subtitle: Text(event.message),
                    trailing: Text(DateFormat.Hm().format(event.timestamp)),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}
