export interface PriceAlertRule {
  maxPrice: number;
}

/** Pure trigger rule: kept separate from the FCM send call so it's unit-testable. */
export function shouldNotify(rule: PriceAlertRule, currentPrice: number): boolean {
  return currentPrice <= rule.maxPrice;
}
