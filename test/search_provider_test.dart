import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/providers/preferences_provider.dart';
import 'package:marocfly_ai/providers/search_provider.dart';
import 'package:marocfly_ai/services/flight_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pre-fills origin/destination from saved preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesProvider();
    await preferences.update(
      (p) => p.copyWith(
        favoriteOriginAirportCode: 'DUS',
        favoriteDestinationAirportCode: 'FEZ',
      ),
    );

    final search = SearchProvider(
      service: FlightSearchService(),
      preferences: preferences,
    );

    expect(search.origin?.code, 'DUS');
    expect(search.destination?.code, 'FEZ');
  });

  test('has no pre-filled route when nothing was saved before', () {
    final preferences = PreferencesProvider();
    final search = SearchProvider(
      service: FlightSearchService(),
      preferences: preferences,
    );

    expect(search.origin, isNull);
    expect(search.destination, isNull);
  });

  test('search() saves the used route back to preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesProvider();
    await preferences.load();

    final search = SearchProvider(
      service: FlightSearchService(),
      preferences: preferences,
    );
    search.setOrigin(const Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland'));
    search.setDestination(const Airport(code: 'FEZ', city: 'Fès', country: 'Marokko'));

    await search.search();

    expect(preferences.preferences.favoriteOriginAirportCode, 'DUS');
    expect(preferences.preferences.favoriteDestinationAirportCode, 'FEZ');
  });
}
