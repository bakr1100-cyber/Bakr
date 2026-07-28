/**
 * Duffel proxy for MarocFly AI.
 *
 * The Flutter web build is a public static site - any secret embedded in it
 * (an API key baked in via --dart-define, for example) ships in plain text
 * inside main.dart.js for anyone to read via "view source". This Worker is
 * the fix: it holds the real Duffel API key server-side (as a Cloudflare
 * secret, never committed to git, never shipped to the browser) and the
 * Flutter app calls THIS endpoint instead of Duffel directly.
 *
 * It deliberately mirrors Duffel's own "create an offer request" shape
 * (POST /air/offer_requests) so the Dart-side DuffelFlightApi client barely
 * changes - just point its base URL here and drop the Authorization header
 * (this Worker adds the real one itself).
 */

const DUFFEL_BASE_URL = 'https://api.duffel.com';
const DUFFEL_VERSION = 'v2';

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
    if (url.pathname !== '/air/offer_requests' || request.method !== 'POST') {
      return jsonResponse({ error: 'not_found' }, 404);
    }

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
  },
};

function jsonResponse(data, status) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}
