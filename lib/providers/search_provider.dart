import 'package:flutter/foundation.dart';

import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../services/flight_search_service.dart';

/// Drives the classic three-field-and-go search form (as opposed to the
/// conversational flow in [ChatProvider]) - departure, destination, date,
/// passengers, then straight to results in three taps.
class SearchProvider extends ChangeNotifier {
  SearchProvider({FlightSearchService? service})
      : _service = service ?? FlightSearchService();

  final FlightSearchService _service;

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

  bool get canSearch => origin != null && destination != null && date != null;

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
  }
}
