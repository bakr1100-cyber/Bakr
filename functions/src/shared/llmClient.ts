import { FlightOption, SearchQuery } from "./types";

export interface IntentResult {
  /** A fully-specified query, ready to hand to the flight engine. */
  query?: SearchQuery;
  /** Set when the LLM needs more information; never guess silently. */
  clarifyingQuestion?: string;
}

/**
 * Abstraction over the LLM used for intent extraction and natural-language
 * explanations (Claude via the Anthropic API, using tool-use). See
 * docs/INTEGRATIONS.md for what's needed to wire up a real provider.
 */
export interface LlmClient {
  extractIntent(userText: string, knownFields: Partial<SearchQuery>): Promise<IntentResult>;
  explainResults(options: FlightOption[], userText: string): Promise<string>;
}

/**
 * Deterministic mock so the orchestrator can be exercised end-to-end
 * without an Anthropic API key. Recognizes a handful of Darija/French/
 * German/English keywords from the product brief; a real implementation
 * replaces this with a Claude tool-use call.
 */
export class MockLlmClient implements LlmClient {
  async extractIntent(
    userText: string,
    knownFields: Partial<SearchQuery>,
  ): Promise<IntentResult> {
    const origin = knownFields.origin ?? extractCity(userText, ORIGIN_HINTS);
    const destination = knownFields.destination ?? extractCity(userText, DESTINATION_HINTS);

    if (!origin || !destination) {
      return {
        clarifyingQuestion:
          "Ich bin mir nicht ganz sicher. Von wo nach wo möchtest du reisen?",
      };
    }

    return {
      query: {
        origin,
        destination,
        departureDate: knownFields.departureDate ?? new Date().toISOString(),
        passengers: knownFields.passengers ?? 1,
        maxBudget: knownFields.maxBudget,
      },
    };
  }

  async explainResults(options: FlightOption[], _userText: string): Promise<string> {
    if (options.length === 0) {
      return "Ich habe leider keine passenden Optionen gefunden.";
    }
    const cheapest = options[0];
    return `Ich habe ${options.length} Optionen gefunden. Die günstigste kostet ${cheapest.totalPrice} ${cheapest.currency}: ${cheapest.explanation}`;
  }
}

const ORIGIN_HINTS = ["düsseldorf", "köln", "frankfurt", "dortmund", "brüssel", "amsterdam"];
const DESTINATION_HINTS = ["fès", "fes", "rabat", "casablanca", "tanger", "nador", "oujda", "marrakesch"];

function extractCity(text: string, hints: string[]): string | undefined {
  const lower = text.toLowerCase();
  const match = hints.find((hint) => lower.includes(hint));
  return match ? capitalize(match) : undefined;
}

function capitalize(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}
