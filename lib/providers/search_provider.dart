import 'package:flutter/foundation.dart';

import '../core/localization/app_localizations.dart';
import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../models/trip_type.dart';
import '../services/flight_price_source.dart';
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
  TripType tripType = TripType.oneWay;

  /// Only meaningful when [tripType] is [TripType.roundTrip]. Kept in sync
  /// with [date] so it can never end up before the departure date.
  DateTime? returnDate;

  int passengers = 1;
  double? maxBudgetEur;

  bool isLoading = false;
  List<Itinerary> results = [];

  /// Populated alongside [results] only for round trips - the return leg's
  /// own itinerary options (destination back to origin, on [returnDate]).
  List<Itinerary> returnResults = [];

  /// Whether the prices in [results] are real, sandbox, or mock data - see
  /// [FlightDataMode]. Null until the first search has run.
  FlightDataMode? get dataMode => _service.lastDataMode;

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
    if (returnDate != null && returnDate!.isBefore(date)) {
      returnDate = date;
    }
    notifyListeners();
  }

  void setReturnDate(DateTime value) {
    returnDate = value;
    notifyListeners();
  }

  void setTripType(TripType value) {
    tripType = value;
    if (value == TripType.oneWay) {
      returnDate = null;
      returnResults = [];
    } else {
      returnDate ??= date.add(const Duration(days: 7));
    }
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

  bool get canSearch =>
      origin != null &&
      destination != null &&
      (tripType == TripType.oneWay ||
          (returnDate != null && !returnDate!.isBefore(date)));

  Future<void> search({AppLanguage language = AppLanguage.de}) async {
    if (!canSearch || isLoading) return;
    isLoading = true;
    notifyListeners();

    final intent = TravelIntent(
      origin: origin,
      destination: destination,
      departureDate: date,
      passengerCount: passengers,
      maxBudgetEur: maxBudgetEur,
    );
    results = await _service.search(intent, language: language);

    if (tripType == TripType.roundTrip && returnDate != null) {
      final returnIntent = TravelIntent(
        origin: destination,
        destination: origin,
        departureDate: returnDate,
        passengerCount: passengers,
        maxBudgetEur: maxBudgetEur,
      );
      returnResults = await _service.search(returnIntent, language: language);
    } else {
      returnResults = [];
    }

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
