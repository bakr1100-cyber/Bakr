import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/flight_search_controller.dart';
import 'widgets/flight_option_card.dart';

class FlightResultsScreen extends ConsumerWidget {
  const FlightResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flightSearchControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ergebnisse')),
      body: switch (state) {
        FlightSearchIdle() || FlightSearchLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        FlightSearchError(:final message) => Center(
            child: Text('Fehler: $message'),
          ),
        FlightSearchLoaded(:final results) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return FlightOptionCard(option: results[index]);
            },
          ),
      },
    );
  }
}
