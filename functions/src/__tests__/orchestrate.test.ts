import { orchestrate } from "../orchestrator/orchestrate";
import { MockFlightProvider } from "../flightEngine/providers";
import { MockLlmClient } from "../shared/llmClient";

describe("orchestrate", () => {
  const flightProvider = new MockFlightProvider();
  const llmClient = new MockLlmClient();

  it("asks a clarifying question when origin/destination are unknown", async () => {
    const result = await orchestrate(llmClient, flightProvider, "hello there");
    expect(result.needsClarification).toBe(true);
    expect(result.options).toHaveLength(0);
  });

  it("returns ranked options once origin and destination are recognized", async () => {
    const result = await orchestrate(
      llmClient,
      flightProvider,
      "Bghit arkhass vol mn Düsseldorf l Fès.",
    );
    expect(result.needsClarification).toBe(false);
    expect(result.options.length).toBeGreaterThan(0);
    expect(result.message).toContain("Optionen");
  });
});
