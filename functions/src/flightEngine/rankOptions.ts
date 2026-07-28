import { FlightOption, SearchQuery } from "../shared/types";
import { FlightProvider } from "./providers";

/**
 * The Smart Flight Engine: fetches direct flights, alternate-airport
 * routes, and stopover routes, then ranks everything by total price. This
 * is where a future multimodal (flight+train+bus) combiner and a
 * `GroundTransportProvider` would plug in alongside `FlightProvider`.
 */
export async function searchAndRankOptions(
  provider: FlightProvider,
  query: SearchQuery,
): Promise<FlightOption[]> {
  const [direct, alternate, stopover] = await Promise.all([
    provider.searchDirect(query),
    provider.searchAlternateAirports(query),
    provider.searchStopovers(query),
  ]);

  const all = [...direct, ...alternate, ...stopover];
  const withinBudget =
    query.maxBudget === undefined
      ? all
      : all.filter((option) => option.totalPrice <= query.maxBudget!);

  return withinBudget.sort((a, b) => a.totalPrice - b.totalPrice);
}
