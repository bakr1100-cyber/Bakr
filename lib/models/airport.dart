/// A single airport or, for train legs, a station acting as a virtual
/// "airport" endpoint (e.g. Rabat Agdal for the Rabat->Fès ONCF connection).
class Airport {
  const Airport({
    required this.code,
    required this.city,
    required this.country,
    this.isTrainStation = false,
    this.lat = 0,
    this.lon = 0,
  });

  final String code;
  final String city;
  final String country;
  final bool isTrainStation;

  /// Approximate real-world coordinates, used by `services/geo.dart` to
  /// find genuinely nearby alternative airports (e.g. Casablanca is ~90 km
  /// from Rabat) instead of guessing from country/list order.
  final double lat;
  final double lon;

  @override
  String toString() => '$city ($code)';

  @override
  bool operator ==(Object other) => other is Airport && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Departure airports relevant to the European Moroccan diaspora, grouped by
/// the metro area the user actually lives in.
const europeanAirports = <Airport>[
  Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland', lat: 51.2895, lon: 6.7668),
  Airport(code: 'CGN', city: 'Köln/Bonn', country: 'Deutschland', lat: 50.8659, lon: 7.1427),
  Airport(code: 'FRA', city: 'Frankfurt', country: 'Deutschland', lat: 50.0379, lon: 8.5622),
  Airport(code: 'DTM', city: 'Dortmund', country: 'Deutschland', lat: 51.5183, lon: 7.6122),
  Airport(code: 'EIN', city: 'Eindhoven', country: 'Niederlande', lat: 51.4501, lon: 5.3745),
  Airport(code: 'AMS', city: 'Amsterdam', country: 'Niederlande', lat: 52.3105, lon: 4.7683),
  Airport(code: 'BRU', city: 'Brüssel', country: 'Belgien', lat: 50.9014, lon: 4.4844),
  Airport(code: 'CDG', city: 'Paris', country: 'Frankreich', lat: 49.0097, lon: 2.5479),
  Airport(code: 'MAD', city: 'Madrid', country: 'Spanien', lat: 40.4983, lon: -3.5676),
  Airport(code: 'BCN', city: 'Barcelona', country: 'Spanien', lat: 41.2974, lon: 2.0833),
  // Málaga: on the mock engine's Gibraltar-strait "stopover" candidates -
  // it sits close to the great-circle path from most German/Benelux
  // airports down to Morocco, so it's often the lowest-detour via city.
  Airport(code: 'AGP', city: 'Málaga', country: 'Spanien', lat: 36.6749, lon: -4.4991),
  Airport(code: 'LIS', city: 'Lissabon', country: 'Portugal', lat: 38.7813, lon: -9.1359),
  Airport(code: 'MXP', city: 'Mailand', country: 'Italien', lat: 45.6306, lon: 8.7281),
];

/// Moroccan destination airports, including the ones the smart engine
/// proposes as alternatives when the requested city is expensive.
const moroccanAirports = <Airport>[
  Airport(code: 'CMN', city: 'Casablanca', country: 'Marokko', lat: 33.3675, lon: -7.5900),
  Airport(code: 'RBA', city: 'Rabat', country: 'Marokko', lat: 34.0515, lon: -6.7515),
  Airport(code: 'FEZ', city: 'Fès', country: 'Marokko', lat: 33.9273, lon: -4.9778),
  Airport(code: 'TNG', city: 'Tanger', country: 'Marokko', lat: 35.7269, lon: -5.9168),
  Airport(code: 'NDR', city: 'Nador', country: 'Marokko', lat: 34.9888, lon: -3.0289),
  Airport(code: 'OUD', city: 'Oujda', country: 'Marokko', lat: 34.7867, lon: -1.9236),
  Airport(code: 'RAK', city: 'Marrakesch', country: 'Marokko', lat: 31.6069, lon: -8.0363),
];

Airport? findAirportByCity(String query) {
  final q = query.trim().toLowerCase();
  for (final airport in [...europeanAirports, ...moroccanAirports]) {
    if (airport.city.toLowerCase() == q ||
        airport.code.toLowerCase() == q ||
        airport.city.toLowerCase().contains(q)) {
      return airport;
    }
  }
  return null;
}

Airport? findAirportByCode(String? code) {
  if (code == null) return null;
  for (final airport in [...europeanAirports, ...moroccanAirports]) {
    if (airport.code == code) return airport;
  }
  return null;
}
