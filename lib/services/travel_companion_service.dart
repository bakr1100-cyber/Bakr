import '../models/companion_event.dart';
import '../models/itinerary.dart';

/// Generates the "Reisebegleiter" timeline for a booked itinerary: before
/// the trip, at the airport, during the flight (offline-capable content),
/// and after landing. In production this stage would subscribe to a real
/// flight-status feed (e.g. AeroDataBox/FlightAware) for gate/boarding/delay
/// events and to ONCF's timetable for the post-landing train connection;
/// here it synthesizes a plausible timeline from the booked itinerary so
/// the companion UI has real, itinerary-specific content to show.
class TravelCompanionService {
  List<CompanionEvent> buildTimeline(Itinerary itinerary) {
    final departure = itinerary.departureTime;
    final arrival = itinerary.arrivalTime;
    final destinationCity = itinerary.legs.last.to.city;

    final events = <CompanionEvent>[
      CompanionEvent(
        id: 'checkin',
        stage: CompanionStage.beforeTrip,
        title: 'Online Check-in',
        message: 'Der Online-Check-in öffnet 24 Stunden vor deinem Flug. '
            'Ich erinnere dich rechtzeitig.',
        timestamp: departure.subtract(const Duration(hours: 24)),
      ),
      CompanionEvent(
        id: 'baggage',
        stage: CompanionStage.beforeTrip,
        title: 'Gepäckregeln',
        message: '${itinerary.legs.first.carrier ?? 'Deine Airline'} erlaubt '
            '1 Handgepäckstück (max. 10 kg) und ein Aufgabegepäckstück je nach Tarif.',
        timestamp: departure.subtract(const Duration(hours: 20)),
      ),
      CompanionEvent(
        id: 'weather',
        stage: CompanionStage.beforeTrip,
        title: 'Wetter am Ziel',
        message: 'In $destinationCity werden zur Ankunft angenehme '
            'Temperaturen erwartet. Denk an leichte Kleidung.',
        timestamp: departure.subtract(const Duration(hours: 12)),
      ),
      CompanionEvent(
        id: 'gate',
        stage: CompanionStage.atAirport,
        title: 'Gate-Information',
        message: 'Dein Gate wurde auf B24 geändert. Plane etwa 15 Minuten '
            'bis zum Gate ein.',
        timestamp: departure.subtract(const Duration(hours: 1)),
        isUrgent: true,
      ),
      CompanionEvent(
        id: 'boarding',
        stage: CompanionStage.atAirport,
        title: 'Boarding',
        message: 'Das Boarding beginnt in 20 Minuten.',
        timestamp: departure.subtract(const Duration(minutes: 40)),
        isUrgent: true,
      ),
      CompanionEvent(
        id: 'inflight',
        stage: CompanionStage.duringFlight,
        title: 'Offline-Reiseinfos',
        message: 'Frag mich unterwegs nach Sehenswürdigkeiten, Restaurants, '
            'Hotels, Mietwagen oder ONCF-Zugverbindungen in $destinationCity - '
            'ich funktioniere auch ohne Internetverbindung.',
        timestamp: departure.add(itinerary.legs.first.duration ~/ 2),
      ),
      CompanionEvent(
        id: 'landing',
        stage: CompanionStage.afterLanding,
        title: 'Willkommen in $destinationCity',
        message: itinerary.isMultimodal
            ? 'Dein Anschluss ist bereits gebucht - ich navigiere dich zum '
                'nächsten Bahnsteig/Gate.'
            : 'Der nächste ONCF-Zug und Taxis findest du direkt am Ausgang. '
                'Soll ich dir eine Verbindung weiter zu deinem Ziel suchen?',
        timestamp: arrival,
      ),
    ];

    return events;
  }
}
