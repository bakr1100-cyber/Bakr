import 'package:flutter/material.dart';

class PassengerCounter extends StatelessWidget {
  const PassengerCounter({
    super.key,
    required this.count,
    required this.onChanged,
  });

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Personen'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: count > 1 ? () => onChanged(count - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$count', style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            onPressed: count < 9 ? () => onChanged(count + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
