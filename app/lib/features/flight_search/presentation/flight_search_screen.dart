import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/search_query.dart';
import '../application/flight_search_controller.dart';
import 'flight_results_screen.dart';

/// Step 1 of the "max 3 clicks to flight search" flow: origin,
/// destination, date, passenger count. Click 2 is "Suchen", click 3 is
/// tapping a result on [FlightResultsScreen].
class FlightSearchScreen extends ConsumerStatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  ConsumerState<FlightSearchScreen> createState() =>
      _FlightSearchScreenState();
}

class _FlightSearchScreenState extends ConsumerState<FlightSearchScreen> {
  final _originController = TextEditingController(text: 'Düsseldorf');
  final _destinationController = TextEditingController(text: 'Fès');
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  int _passengers = 1;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search() async {
    final query = SearchQuery(
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      departureDate: _date,
      passengers: _passengers,
    );
    await ref.read(flightSearchControllerProvider.notifier).search(query);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FlightResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MarocFly AI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Der günstigste und intelligenteste Weg nach Marokko.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Abflugort',
                prefixIcon: Icon(Icons.flight_takeoff),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Ziel',
                prefixIcon: Icon(Icons.flight_land),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Datum: ${_date.day}.${_date.month}.${_date.year}'),
              onTap: _pickDate,
            ),
            Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 12),
                const Text('Personen'),
                const Spacer(),
                IconButton(
                  onPressed: _passengers > 1
                      ? () => setState(() => _passengers--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_passengers'),
                IconButton(
                  onPressed: () => setState(() => _passengers++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _search,
              child: const Text('Flug suchen'),
            ),
          ],
        ),
      ),
    );
  }
}
