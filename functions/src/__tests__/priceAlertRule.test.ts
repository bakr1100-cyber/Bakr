import { shouldNotify } from "../notifications/priceAlertRule";

describe("shouldNotify", () => {
  it("triggers when the current price is at or below the max price", () => {
    expect(shouldNotify({ maxPrice: 200 }, 200)).toBe(true);
    expect(shouldNotify({ maxPrice: 200 }, 150)).toBe(true);
  });

  it("does not trigger when the current price is above the max price", () => {
    expect(shouldNotify({ maxPrice: 200 }, 250)).toBe(false);
  });
});
