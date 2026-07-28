import { FlightProvider } from "../flightEngine/providers";
import { searchAndRankOptions } from "../flightEngine/rankOptions";
import { LlmClient } from "../shared/llmClient";
import { FlightOption, SearchQuery } from "../shared/types";

export interface OrchestrateResult {
  message: string;
  options: FlightOption[];
  needsClarification: boolean;
}

/**
 * The `aiOrchestrator` core logic, kept free of `firebase-functions` types
 * so it can run in unit tests without the Functions runtime. The onCall
 * wrapper in `index.ts` is a thin adapter around this.
 */
export async function orchestrate(
  llmClient: LlmClient,
  flightProvider: FlightProvider,
  userText: string,
  knownFields: Partial<SearchQuery> = {},
): Promise<OrchestrateResult> {
  const intent = await llmClient.extractIntent(userText, knownFields);

  if (!intent.query) {
    return {
      message: intent.clarifyingQuestion ?? "Kannst du das genauer beschreiben?",
      options: [],
      needsClarification: true,
    };
  }

  const options = await searchAndRankOptions(flightProvider, intent.query);
  const message = await llmClient.explainResults(options, userText);

  return { message, options, needsClarification: false };
}
