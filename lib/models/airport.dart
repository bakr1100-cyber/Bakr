/// A single airport or, for train legs, a station acting as a virtual
/// "airport" endpoint (e.g. Rabat Agdal for the Rabat->Fès ONCF connection).
class Airport {
  const Airport({
    required this.code,
    required this.city,
    required this.country,
    this.isTrainStation = false,
  });

  final String code;
  final String city;
  final String country;
  final bool isTrainStation;

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
  Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland'),
  Airport(code: 'CGN', city: 'Köln/Bonn', country: 'Deutschland'),
  Airport(code: 'FRA', city: 'Frankfurt', country: 'Deutschland'),
  Airport(code: 'DTM', city: 'Dortmund', country: 'Deutschland'),
  Airport(code: 'EIN', city: 'Eindhoven', country: 'Niederlande'),
  Airport(code: 'AMS', city: 'Amsterdam', country: 'Niederlande'),
  Airport(code: 'BRU', city: 'Brüssel', country: 'Belgien'),
  Airport(code: 'CDG', city: 'Paris', country: 'Frankreich'),
  Airport(code: 'MAD', city: 'Madrid', country: 'Spanien'),
  Airport(code: 'BCN', city: 'Barcelona', country: 'Spanien'),
  Airport(code: 'LIS', city: 'Lissabon', country: 'Portugal'),
  Airport(code: 'MXP', city: 'Mailand', country: 'Italien'),
];

/// Moroccan destination airports, including the ones the smart engine
/// proposes as alternatives when the requested city is expensive.
const moroccanAirports = <Airport>[
  Airport(code: 'CMN', city: 'Casablanca', country: 'Marokko'),
  Airport(code: 'RBA', city: 'Rabat', country: 'Marokko'),
  Airport(code: 'FEZ', city: 'Fès', country: 'Marokko'),
  Airport(code: 'TNG', city: 'Tanger', country: 'Marokko'),
  Airport(code: 'NDR', city: 'Nador', country: 'Marokko'),
  Airport(code: 'OUD', city: 'Oujda', country: 'Marokko'),
  Airport(code: 'RAK', city: 'Marrakesch', country: 'Marokko'),
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
