import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";

import { MockFlightProvider } from "./flightEngine/providers";
import { searchAndRankOptions } from "./flightEngine/rankOptions";
import { shouldNotify } from "./notifications/priceAlertRule";
import { orchestrate } from "./orchestrator/orchestrate";
import { MockLlmClient } from "./shared/llmClient";
import { SearchQuery } from "./shared/types";

// Swap these for real implementations once provider credentials exist —
// see docs/INTEGRATIONS.md. Everything downstream depends only on the
// FlightProvider/LlmClient interfaces, so this is the only place to change.
const flightProvider = new MockFlightProvider();
const llmClient = new MockLlmClient();

/**
 * Receives free-text (typed or transcribed voice) input from the app,
 * extracts intent via the LLM, runs the flight engine, and returns a
 * natural-language explanation plus ranked options.
 */
export const aiOrchestrator = onCall(async (request) => {
  const { text, knownFields } = request.data as {
    text: string;
    knownFields?: Partial<SearchQuery>;
  };
  return orchestrate(llmClient, flightProvider, text, knownFields ?? {});
});

/**
 * Structured search entry point for the plain (non-chat) search form —
 * bypasses intent extraction since the app already collected origin,
 * destination, date, and passenger count directly.
 */
export const searchFlights = onCall(async (request) => {
  const query = request.data as SearchQuery;
  return searchAndRankOptions(flightProvider, query);
});

/**
 * Periodic price snapshot for watched routes. Currently a no-op stub —
 * wiring this to Firestore (read watched routes, write PricePoint docs)
 * is follow-up work once a real FlightProvider exists.
 */
export const snapshotPrices = onSchedule("every 6 hours", async () => {
  logger.info("snapshotPrices: no watched routes configured yet (stub).");
});

/**
 * Fires when a `priceAlerts/{alertId}` document's `currentPrice` is
 * updated (by `snapshotPrices` once it's wired to Firestore) and sends an
 * FCM push if the alert's threshold is met.
 */
export const notifyOnPriceDrop = onDocumentUpdated(
  "priceAlerts/{alertId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;

    if (shouldNotify({ maxPrice: after.maxPrice }, after.currentPrice)) {
      logger.info(
        `Price alert triggered for ${event.params.alertId}: ` +
          `${after.currentPrice} <= ${after.maxPrice} (stub — FCM send not yet wired up).`,
      );
      // TODO: admin.messaging().send({ ... }) once FCM tokens are stored per user.
    }
  },
);
