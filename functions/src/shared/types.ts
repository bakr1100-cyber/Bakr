export type TransportMode = "flight" | "train" | "bus" | "taxi";

export interface TransportLeg {
  mode: TransportMode;
  carrier: string;
  from: string;
  to: string;
  departure: string; // ISO 8601
  arrival: string; // ISO 8601
}

export type RouteStrategy =
  | "direct"
  | "alternateAirport"
  | "stopover"
  | "multimodal";

export interface FlightOption {
  id: string;
  strategy: RouteStrategy;
  legs: TransportLeg[];
  totalPrice: number;
  currency: string;
  explanation: string;
  savingsVsCheapestDirect?: number;
}

export interface SearchQuery {
  origin: string;
  destination: string;
  departureDate: string; // ISO 8601 date
  passengers: number;
  maxBudget?: number;
}

export interface PricePoint {
  route: string; // `${origin}-${destination}`
  observedAt: string; // ISO 8601
  price: number;
  currency: string;
}
