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
          ? const Center(child: CircularProgressIndicator())
          : search.results.isEmpty
              ? const Center(child: Text('Keine Verbindungen gefunden.'))
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
