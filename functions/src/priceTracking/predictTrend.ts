import { PricePoint } from "../shared/types";

export type PriceRecommendation =
  | { action: "bookNow"; reason: string }
  | { action: "wait"; reason: string }
  | { action: "unknown"; reason: string };

/**
 * Heuristic price-trend recommendation from historical snapshots for a
 * route. A real implementation would replace this with a trained model;
 * this linear-trend heuristic is enough to make the "book now / wait"
 * feature demoable end-to-end.
 */
export function predictTrend(history: PricePoint[]): PriceRecommendation {
  if (history.length < 2) {
    return { action: "unknown", reason: "Nicht genug Preisdaten vorhanden." };
  }

  const sorted = [...history].sort(
    (a, b) => new Date(a.observedAt).getTime() - new Date(b.observedAt).getTime(),
  );
  const first = sorted[0];
  const last = sorted[sorted.length - 1];
  const change = last.price - first.price;
  const changeRatio = change / first.price;

  if (changeRatio <= -0.05) {
    return { action: "bookNow", reason: "Der Preis ist zuletzt gefallen und könnte wieder steigen." };
  }
  if (changeRatio >= 0.05) {
    return { action: "wait", reason: "Der Preis ist zuletzt gestiegen; es lohnt sich abzuwarten." };
  }
  return { action: "unknown", reason: "Der Preis ist stabil." };
}
