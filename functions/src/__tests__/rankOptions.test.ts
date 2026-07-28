import { searchAndRankOptions } from "../flightEngine/rankOptions";
import { MockFlightProvider } from "../flightEngine/providers";
import { SearchQuery } from "../shared/types";

describe("searchAndRankOptions", () => {
  const baseQuery: SearchQuery = {
    origin: "Düsseldorf",
    destination: "Fès",
    departureDate: "2026-08-04T09:00:00.000Z",
    passengers: 1,
  };

  it("ranks options cheapest first", async () => {
    const options = await searchAndRankOptions(new MockFlightProvider(), baseQuery);

    expect(options.length).toBeGreaterThan(1);
    const prices = options.map((o) => o.totalPrice);
    expect(prices).toEqual([...prices].sort((a, b) => a - b));
  });

  it("includes the cheaper alternate-airport route for Fès", async () => {
    const options = await searchAndRankOptions(new MockFlightProvider(), baseQuery);
    const alt = options.find((o) => o.strategy === "alternateAirport");
    expect(alt).toBeDefined();
    expect(alt!.totalPrice).toBeLessThan(320);
  });

  it("filters out options above maxBudget", async () => {
    const options = await searchAndRankOptions(new MockFlightProvider(), {
      ...baseQuery,
      maxBudget: 185,
    });
    expect(options.every((o) => o.totalPrice <= 185)).toBe(true);
    expect(options.some((o) => o.strategy === "direct")).toBe(false);
  });
});
