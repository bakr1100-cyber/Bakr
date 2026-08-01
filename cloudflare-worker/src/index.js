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
 *  - POST /ai/chat - conversational replies via Cloudflare Workers AI (a
 *    free, open-source LLM running directly on Cloudflare's own
 *    infrastructure - the [ai] binding in wrangler.toml needs no separate
 *    API key/signup, it just uses this Worker's Cloudflare account).
 */

const DUFFEL_BASE_URL = 'https://api.duffel.com';
const DUFFEL_VERSION = 'v2';

// A capable-but-cheap instruction-tuned open model, to make good use of
// Workers AI's free daily quota (10,000 "neurons"/day as of this writing).
const CHAT_MODEL = '@cf/meta/llama-3.1-8b-instruct';

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
  if (!env.AI) {
    return jsonResponse({ error: 'ai_not_configured' }, 500);
  }

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

function jsonResponse(data, status) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}
