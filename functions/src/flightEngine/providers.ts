import { FlightOption, SearchQuery, TransportLeg } from "../shared/types";

/**
 * Abstraction over a real flight-data API (e.g. Duffel, Kiwi Tequila,
 * Amadeus Self-Service). Swap `MockFlightProvider` for a concrete
 * implementation once an API key is available (see docs/INTEGRATIONS.md).
 */
export interface FlightProvider {
  searchDirect(query: SearchQuery): Promise<FlightOption[]>;
  searchAlternateAirports(query: SearchQuery): Promise<FlightOption[]>;
  searchStopovers(query: SearchQuery): Promise<FlightOption[]>;
}

/**
 * Abstraction over ground-transport schedules (Deutsche Bahn, SNCF, ONCF,
 * FlixBus). ONCF in particular has no known public API today, so this will
 * likely start as a maintained static/semi-static timetable dataset rather
 * than a live API call.
 */
export interface GroundTransportProvider {
  searchLegs(from: string, to: string, notBefore: string): Promise<TransportLeg[]>;
}

const ALTERNATE_DESTINATION_AIRPORTS: Record<string, string> = {
  "Fès": "Rabat",
  "Fes": "Rabat",
};

export class MockFlightProvider implements FlightProvider {
  async searchDirect(query: SearchQuery): Promise<FlightOption[]> {
    const departure = query.departureDate;
    return [
      {
        id: "direct-1",
        strategy: "direct",
        legs: [
          leg("flight", "Direct Air", query.origin, query.destination, departure, addHours(departure, 3.5)),
        ],
        totalPrice: 320,
        currency: "EUR",
        explanation: `Der Direktflug von ${query.origin} nach ${query.destination} ist am bequemsten, aber nicht die günstigste Option.`,
      },
    ];
  }

  async searchAlternateAirports(query: SearchQuery): Promise<FlightOption[]> {
    const altAirport = ALTERNATE_DESTINATION_AIRPORTS[query.destination];
    if (!altAirport) return [];
    const departure = query.departureDate;
    return [
      {
        id: "alt-airport-1",
        strategy: "alternateAirport",
        legs: [
          leg("flight", "Air Arabia", query.origin, altAirport, departure, addHours(departure, 3.2)),
          leg("train", "ONCF", altAirport, query.destination, addHours(departure, 4), addHours(departure, 6.8)),
        ],
        totalPrice: 190,
        currency: "EUR",
        savingsVsCheapestDirect: 130,
        explanation: `Von ${altAirport} nach ${query.destination} fährt ein Zug. Dadurch sparst du 130 €.`,
      },
    ];
  }

  async searchStopovers(query: SearchQuery): Promise<FlightOption[]> {
    const departure = query.departureDate;
    return [
      {
        id: "stopover-1",
        strategy: "stopover",
        legs: [
          leg("flight", "Ryanair", query.origin, "Madrid", departure, addHours(departure, 2)),
          leg("flight", "Air Arabia", "Madrid", query.destination, addHours(departure, 4), addHours(departure, 6.25)),
        ],
        totalPrice: 180,
        currency: "EUR",
        savingsVsCheapestDirect: 140,
        explanation: "Mit einem Zwischenstopp in Madrid sparst du 140 €.",
      },
    ];
  }
}

export class MockGroundTransportProvider implements GroundTransportProvider {
  async searchLegs(from: string, to: string, notBefore: string): Promise<TransportLeg[]> {
    return [leg("train", "ONCF", from, to, notBefore, addHours(notBefore, 2.8))];
  }
}

function leg(
  mode: TransportLeg["mode"],
  carrier: string,
  from: string,
  to: string,
  departure: string,
  arrival: string,
): TransportLeg {
  return { mode, carrier, from, to, departure, arrival };
}

function addHours(iso: string, hours: number): string {
  const date = new Date(iso);
  date.setMinutes(date.getMinutes() + hours * 60);
  return date.toISOString();
}
