import '../models/flight_option.dart';
import '../models/search_query.dart';

/// Abstraction over local persistence for offline mode (last search
/// results, static travel info). A real implementation should use Drift
/// (SQLite) so cached data survives app restarts; this in-memory
/// implementation is a placeholder that keeps the interface stable.
abstract class OfflineCache {
  Future<void> saveLastSearch(SearchQuery query, List<FlightOption> results);
  Future<(SearchQuery, List<FlightOption>)?> lastSearch();
}

class InMemoryOfflineCache implements OfflineCache {
  (SearchQuery, List<FlightOption>)? _lastSearch;

  @override
  Future<void> saveLastSearch(
    SearchQuery query,
    List<FlightOption> results,
  ) async {
    _lastSearch = (query, results);
  }

  @override
  Future<(SearchQuery, List<FlightOption>)?> lastSearch() async {
    return _lastSearch;
  }
}
