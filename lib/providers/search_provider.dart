import 'package:flutter/foundation.dart';

import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../services/flight_search_service.dart';
import 'preferences_provider.dart';

/// Drives the classic three-field-and-go search form (as opposed to the
/// conversational flow in [ChatProvider]) - departure, destination, date,
/// passengers, then straight to results in three taps.
///
/// Pre-fills origin/destination from [PreferencesProvider] (if a favorite
/// route is already known) and saves the route used on every search back
/// to preferences, so a returning user's fields are already filled in and
/// the golden path shrinks toward the promised three taps: open the app,
/// review the pre-filled route, tap search.
class SearchProvider extends ChangeNotifier {
  SearchProvider({FlightSearchService? service, PreferencesProvider? preferences})
      : _service = service ?? FlightSearchService(),
        _preferences = preferences {
    final saved = preferences?.preferences;
    origin = findAirportByCode(saved?.favoriteOriginAirportCode);
    destination = findAirportByCode(saved?.favoriteDestinationAirportCode);
    passengers = saved?.travelsWithFamily == true ? 4 : 1;
  }

  final FlightSearchService _service;
  final PreferencesProvider? _preferences;

  Airport? origin;
  Airport? destination;
  DateTime date = DateTime.now().add(const Duration(days: 7));
  int passengers = 1;
  double? maxBudgetEur;

  bool isLoading = false;
  List<Itinerary> results = [];

  void setOrigin(Airport airport) {
    origin = airport;
    notifyListeners();
  }

  void setDestination(Airport airport) {
    destination = airport;
    notifyListeners();
  }

  void setDate(DateTime value) {
    date = value;
    notifyListeners();
  }

  void setPassengers(int value) {
    passengers = value;
    notifyListeners();
  }

  void setMaxBudget(double? value) {
    maxBudgetEur = value;
    notifyListeners();
  }

  bool get canSearch => origin != null && destination != null;

  Future<void> search() async {
    if (!canSearch) return;
    isLoading = true;
    notifyListeners();

    final intent = TravelIntent(
      origin: origin,
      destination: destination,
      departureDate: date,
      passengerCount: passengers,
      maxBudgetEur: maxBudgetEur,
    );
    results = await _service.search(intent);

    isLoading = false;
    notifyListeners();

    await _preferences?.update(
      (p) => p.copyWith(
        favoriteOriginAirportCode: origin!.code,
        favoriteDestinationAirportCode: destination!.code,
        travelsWithFamily: passengers >= 4,
      ),
    );
  }
}
