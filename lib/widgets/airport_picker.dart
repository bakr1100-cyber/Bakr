import 'package:flutter/material.dart';

import '../models/airport.dart';

class AirportPicker extends StatelessWidget {
  const AirportPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<Airport> options;
  final Airport? selected;
  final ValueChanged<Airport> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          selected?.toString() ?? '–',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final airport in options)
              ListTile(
                title: Text(airport.city),
                subtitle: Text('${airport.code} · ${airport.country}'),
                onTap: () {
                  onChanged(airport);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
