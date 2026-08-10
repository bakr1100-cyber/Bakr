/**
 * Shared proxy Worker for MarocFly AI.
 *
 * The Flutter web build is a public static site - any secret embedded in it
 * (an API key baked in via --dart-define, for example) ships in plain text
 * inside main.dart.js for anyone to read via "view source". This Worker is
 * the fix: it holds real secrets server-side (as Cloudflare secrets, never
 * committed to git, never shipped to the browser) and the Flutter app calls
 * THIS endpoint instead of the third-party APIs directly.
 *
 * Two routes:
 *  - POST /air/offer_requests - Duffel flight search (mirrors Duffel's own
 *    "create an offer request" shape so the Dart-side DuffelFlightApi
 *    client barely changes).
 *  - POST /ai/chat - conversational replies. Uses Mistral's API
 *    (https://api.mistral.ai) when MISTRAL_API_KEY is configured as a
 *    Cloudflare secret - noticeably better at open-ended phrasing and
 *    Darija than the small Workers AI model below, which is why this was
 *    added, but it needs its own account/API key and is not necessarily
 *    free long-term. Falls back to Cloudflare Workers AI (a free,
 *    open-source LLM running directly on Cloudflare's own infrastructure -
 *    the [ai] binding in wrangler.toml needs no separate API key/signup)
 *    whenever MISTRAL_API_KEY isn't set, or the Mistral call itself fails -
 *    the chat should degrade, never go fully silent.
 */

const DUFFEL_BASE_URL = 'https://api.duffel.com';
const DUFFEL_VERSION = 'v2';

const MISTRAL_CHAT_URL = 'https://api.mistral.ai/v1/chat/completions';
// "Small" tier: a reasonable quality/latency/cost balance for a
// conversational travel assistant. Mistral renames/retires model IDs over
// time same as Cloudflare does - if requests start failing, check
// https://docs.mistral.ai/getting-started/models/ for the current name.
const MISTRAL_CHAT_MODEL = 'mistral-small-latest';

// Picked for speed, not raw quality: a live smoke test showed the 70B
// fp8-fast flagship taking far longer per reply than this app's own
// client-side timeout (12s, see llm_chat_service.dart) tolerates - a
// smarter model that regularly times out just means every reply silently
// falls back to the German template anyway, which is strictly worse than
// a quicker, slightly less eloquent one that actually replies. This 3B
// model is Cloudflare's small/fast tier, still genuinely conversational
// for a travel-chat use case. Cloudflare periodically deprecates model
// IDs (the plain llama-3.1-8b-instruct was retired 2026-05-30, even
// though it stayed listed in the docs) - if /ai/chat starts failing with
// "This model was deprecated", check the *actually callable* catalog by
// hitting the endpoint directly, not just the docs page.
const CHAT_MODEL = '@cf/meta/llama-3.2-3b-instruct';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);

    if (url.pathname === '/air/offer_requests' && request.method === 'POST') {
      return handleFlightSearch(request, env, url);
    }

    if (url.pathname === '/ai/chat' && request.method === 'POST') {
      return handleAiChat(request, env);
    }

    return jsonResponse({ error: 'not_found' }, 404);
  },
};

async function handleFlightSearch(request, env, url) {
  if (!env.DUFFEL_API_KEY) {
    return jsonResponse({ error: 'proxy_not_configured' }, 500);
  }

  let body;
  try {
    body = await request.text();
  } catch (error) {
    return jsonResponse({ error: 'invalid_request_body' }, 400);
  }

  const duffelUrl = `${DUFFEL_BASE_URL}/air/offer_requests${url.search}`;
  const duffelResponse = await fetch(duffelUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.DUFFEL_API_KEY}`,
      'Duffel-Version': DUFFEL_VERSION,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body,
  });

  const responseBody = await duffelResponse.text();
  return new Response(responseBody, {
    status: duffelResponse.status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}

async function handleAiChat(request, env) {
  let body;
  try {
    body = await request.json();
  } catch (error) {
    return jsonResponse({ error: 'invalid_request_body' }, 400);
  }

  const messages = Array.isArray(body?.messages) ? body.messages : null;
  const validRoles = new Set(['system', 'user', 'assistant']);
  const isValid =
    messages &&
    messages.length > 0 &&
    messages.every(
      (m) => m && validRoles.has(m.role) && typeof m.content === 'string' && m.content.length > 0,
    );
  if (!isValid) {
    return jsonResponse({ error: 'messages_required' }, 400);
  }
  // Set by AiAssistantService's intent-extraction call so Mistral can be
  // asked to guarantee valid JSON output (response_format) - Workers AI
  // has no equivalent, so this is a no-op on that fallback path.
  const jsonMode = body?.json_mode === true;

  if (env.MISTRAL_API_KEY) {
    try {
      const reply = await callMistral(messages, env.MISTRAL_API_KEY, jsonMode);
      return jsonResponse({ reply }, 200);
    } catch (error) {
      // Don't fail the request over a Mistral-side issue (quota, outage,
      // bad key) when a free fallback is available - fall through to
      // Workers AI below instead. Logged server-side only: unlike the
      // Workers AI path, an API key is involved here, so the error detail
      // is not safe to hand back to the client.
      console.error('Mistral call failed, falling back to Workers AI:', error);
    }
  }

  if (!env.AI) {
    return jsonResponse({ error: 'ai_not_configured' }, 500);
  }

  try {
    const result = await env.AI.run(CHAT_MODEL, {
      messages,
      max_tokens: 400,
      temperature: 0.6,
    });
    return jsonResponse({ reply: result?.response ?? '' }, 200);
  } catch (error) {
    // The underlying message (e.g. "this account needs to enable Workers
    // AI", a model-availability error, etc.) is genuinely useful for
    // diagnosing a broken deploy and carries no secret - unlike the Duffel
    // route, there is no API key involved in this call at all.
    return jsonResponse({ error: 'ai_request_failed', detail: String(error?.message ?? error) }, 502);
  }
}

async function callMistral(messages, apiKey, jsonMode) {
  const response = await fetch(MISTRAL_CHAT_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: MISTRAL_CHAT_MODEL,
      messages,
      max_tokens: 400,
      temperature: 0.6,
      ...(jsonMode ? { response_format: { type: 'json_object' } } : {}),
    }),
  });
  if (!response.ok) {
    throw new Error(`Mistral request failed: HTTP ${response.status} ${await response.text()}`);
  }
  const data = await response.json();
  return data?.choices?.[0]?.message?.content ?? '';
}

function jsonResponse(data, status) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}
