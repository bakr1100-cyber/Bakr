import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/airport.dart';
import '../../providers/search_provider.dart';
import '../../widgets/airport_picker.dart';
import '../../widgets/big_button.dart';
import '../../widgets/passenger_counter.dart';
import 'search_results_screen.dart';

/// The three-tap fast path: pick origin, pick destination, tap search.
/// Date defaults to next week and passengers defaults to 1 so a user who
/// wants the golden path can be searching in exactly three taps.
class SearchFormScreen extends StatelessWidget {
  const SearchFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('MarocFly AI')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Nicht den günstigsten Flug -\nden intelligentesten Weg nach Marokko.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          AirportPicker(
            label: 'Von',
            options: europeanAirports,
            selected: search.origin,
            onChanged: search.setOrigin,
          ),
          const SizedBox(height: 16),
          AirportPicker(
            label: 'Nach',
            options: moroccanAirports,
            selected: search.destination,
            onChanged: search.setDestination,
          ),
          const SizedBox(height: 16),
          _DateField(
            date: search.date,
            onChanged: search.setDate,
          ),
          const SizedBox(height: 16),
          PassengerCounter(
            count: search.passengers,
            onChanged: search.setPassengers,
          ),
          const SizedBox(height: 32),
          BigButton(
            label: 'Flüge suchen',
            icon: Icons.search_rounded,
            onPressed: search.canSearch
                ? () async {
                    await search.search();
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchResultsScreen(),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Datum'),
        child: Text(
          DateFormat.yMMMMd().format(date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
