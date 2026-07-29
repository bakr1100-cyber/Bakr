import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/trip_type.dart';
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

  test('one-way trips do not require a return date to search', () {
    final search = SearchProvider(service: FlightSearchService());
    search.setOrigin(const Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland'));
    search.setDestination(const Airport(code: 'FEZ', city: 'Fès', country: 'Marokko'));

    expect(search.tripType, TripType.oneWay);
    expect(search.canSearch, isTrue);
  });

  test('round trips require a valid return date to search', () {
    final search = SearchProvider(service: FlightSearchService());
    search.setOrigin(const Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland'));
    search.setDestination(const Airport(code: 'FEZ', city: 'Fès', country: 'Marokko'));
    search.setTripType(TripType.roundTrip);

    expect(search.canSearch, isTrue,
        reason: 'setTripType should default a valid returnDate');

    search.returnDate = search.date.subtract(const Duration(days: 1));
    expect(search.canSearch, isFalse,
        reason: 'a return date before the departure date must block search');
  });

  test('moving the departure date past the return date pulls the return date along', () {
    final search = SearchProvider(service: FlightSearchService());
    search.setTripType(TripType.roundTrip);
    final originalReturn = search.returnDate!;

    search.setDate(originalReturn.add(const Duration(days: 5)));

    expect(search.returnDate!.isBefore(search.date), isFalse);
  });

  test('switching back to one-way clears the return date', () {
    final search = SearchProvider(service: FlightSearchService());
    search.setTripType(TripType.roundTrip);
    expect(search.returnDate, isNotNull);

    search.setTripType(TripType.oneWay);
    expect(search.returnDate, isNull);
  });

  test('round-trip search() also populates returnResults', () async {
    SharedPreferences.setMockInitialValues({});
    final search = SearchProvider(service: FlightSearchService());
    search.setOrigin(const Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland'));
    search.setDestination(const Airport(code: 'FEZ', city: 'Fès', country: 'Marokko'));
    search.setTripType(TripType.roundTrip);

    await search.search();

    expect(search.results, isNotEmpty);
    expect(search.returnResults, isNotEmpty);
  });
}
