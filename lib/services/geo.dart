import 'dart:math';

import '../models/airport.dart';

/// Great-circle distance between two airports, in kilometers.
double distanceKm(Airport a, Airport b) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRad(b.lat - a.lat);
  final dLon = _toRad(b.lon - a.lon);
  final lat1 = _toRad(a.lat);
  final lat2 = _toRad(b.lat);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
  return earthRadiusKm * 2 * atan2(sqrt(h), sqrt(1 - h));
}

double _toRad(double deg) => deg * pi / 180;

/// Airports from [pool] within [radiusKm] of [airport], nearest first,
/// excluding [airport] itself - e.g. Casablanca is ~90 km from Rabat, so
/// it shows up as a nearby alternative when searching to/from Rabat.
List<Airport> nearbyAirports(Airport airport, List<Airport> pool, {required double radiusKm}) {
  final withDistance = pool
      .where((a) => a.code != airport.code)
      .map((a) => (airport: a, distance: distanceKm(airport, a)))
      .where((e) => e.distance <= radiusKm)
      .toList()
    ..sort((a, b) => a.distance.compareTo(b.distance));
  return [for (final e in withDistance) e.airport];
}

/// Rough taxi/shuttle transfer time between two nearby airports/cities.
/// There's no ground-transport API wired into this build, so this is a
/// synthetic estimate (~70 km/h average incl. traffic, plus a fixed
/// 20-minute buffer) - illustrative, not a real fare/schedule, same as the
/// other synthetic train/bus legs in [FlightSearchService].
Duration groundTransferDuration(double km) =>
    Duration(minutes: (km / 70 * 60).round() + 20);

/// Synthetic taxi/shuttle price for a ground transfer of [km] kilometers.
double groundTransferPriceEur(double km) => (km * 0.18).clamp(8, 60);
