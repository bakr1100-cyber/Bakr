import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/flight_option.dart';
import '../../../core/models/search_query.dart';
import '../../../core/providers.dart';

sealed class FlightSearchState {
  const FlightSearchState();
}

class FlightSearchIdle extends FlightSearchState {
  const FlightSearchIdle();
}

class FlightSearchLoading extends FlightSearchState {
  const FlightSearchLoading();
}

class FlightSearchLoaded extends FlightSearchState {
  const FlightSearchLoaded(this.query, this.results);
  final SearchQuery query;
  final List<FlightOption> results;
}

class FlightSearchError extends FlightSearchState {
  const FlightSearchError(this.message);
  final String message;
}

class FlightSearchController extends Notifier<FlightSearchState> {
  @override
  FlightSearchState build() => const FlightSearchIdle();

  Future<void> search(SearchQuery query) async {
    state = const FlightSearchLoading();
    try {
      final provider = ref.read(flightProviderProvider);
      final results = await provider.search(query);
      await ref.read(offlineCacheProvider).saveLastSearch(query, results);
      state = FlightSearchLoaded(query, results);
    } catch (e) {
      state = FlightSearchError(e.toString());
    }
  }
}

final flightSearchControllerProvider =
    NotifierProvider<FlightSearchController, FlightSearchState>(
  FlightSearchController.new,
);
