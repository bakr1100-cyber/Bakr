import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/search_provider.dart';
import '../../widgets/itinerary_card.dart';
import 'itinerary_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${search.origin?.city} → ${search.destination?.city}'),
      ),
      body: search.isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ich suche die besten Verbindungen für dich...'),
                ],
              ),
            )
          : search.results.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Für diese Route habe ich noch keine Verbindung gefunden. '
                      'Probier ein anderes Datum oder Ziel.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: search.results.length,
                  itemBuilder: (context, index) {
                    final itinerary = search.results[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ItineraryCard(
                        itinerary: itinerary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ItineraryDetailScreen(itinerary: itinerary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
