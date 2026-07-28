import { predictTrend } from "../priceTracking/predictTrend";
import { PricePoint } from "../shared/types";

function point(daysAgo: number, price: number): PricePoint {
  const observedAt = new Date(Date.now() - daysAgo * 86_400_000).toISOString();
  return { route: "DUS-FEZ", observedAt, price, currency: "EUR" };
}

describe("predictTrend", () => {
  it("recommends booking now when the price recently dropped", () => {
    const result = predictTrend([point(5, 200), point(0, 180)]);
    expect(result.action).toBe("bookNow");
  });

  it("recommends waiting when the price recently rose", () => {
    const result = predictTrend([point(5, 180), point(0, 210)]);
    expect(result.action).toBe("wait");
  });

  it("returns unknown with fewer than 2 data points", () => {
    const result = predictTrend([point(0, 180)]);
    expect(result.action).toBe("unknown");
  });
});
