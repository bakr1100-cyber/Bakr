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
 * Two HTTP routes, plus a scheduled job:
 *  - POST /air/offer_requests - Duffel flight search (mirrors Duffel's own
 *    "create an offer request" shape so the Dart-side DuffelFlightApi
 *    client barely changes).
 *  - POST /ai/chat - conversational replies, tried in this order:
 *    1. Mistral's API (https://api.mistral.ai) if MISTRAL_API_KEY is set.
 *    2. Cloudflare Workers AI (free, open-source, runs directly on this
 *       Worker's own Cloudflare account via the [ai] binding in
 *       wrangler.toml - no separate signup) - the guaranteed-always-on
 *       last resort.
 *    Step 1 needs its own account/API key and is not necessarily free
 *    long-term, but is noticeably better at open-ended phrasing and
 *    Darija than the small Workers AI model. It's skipped entirely (not
 *    configured) or falls through to step 2 (configured but the call
 *    itself failed - quota, outage, bad key) - the chat should degrade,
 *    never go fully silent.
 *
 *    (A third tier, Qwen/Alibaba Cloud, was tried and removed - the
 *    signup required identity/payment verification that wasn't worth the
 *    hassle for a hobby project. Mistral + Workers AI is plenty.)
 *  - `scheduled` (see `wrangler.toml`'s `[triggers]`) - runs
 *    `price_check_job.js`, which re-checks every tracked price alert for
 *    every user with a push token and sends a real push notification
 *    (Firebase Cloud Messaging) on a meaningful drop, whether or not
 *    anyone has the app open. Needs `FIREBASE_SERVICE_ACCOUNT_EMAIL`/
 *    `FIREBASE_SERVICE_ACCOUNT_KEY` (see `google_auth.js`) in addition to
 *    `DUFFEL_API_KEY` - silently skipped if either is missing.
 */

import { runPriceCheckJob } from './price_check_job.js';
import { synthesizeSpeech } from './tts_providers.js';

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

// Whisper (speech-to-text) and MeloTTS (text-to-speech), both via the same
// no-signup Workers AI [ai] binding that already powers the Workers-AI
// tier of /ai/chat above - see todo/voice-stt-tts-whisper-migration.md in
// the main repo for why: Safari's on-device Web Speech API (used by
// VoiceService today) was the suspected/reported cause of poor Darija
// transcription and unnatural-sounding speech.
const STT_MODEL = '@cf/openai/whisper';
// MeloTTS's documented `lang` values are a short fixed list (EN/ES/FR/
// ZH/JP/KR) - there is no Arabic/Darija option. Requests for those
// languages are still sent through (best-effort, likely mispronounced)
// rather than rejected outright, so VoiceService's fallback to the native
// TTS engine - which at least tries - only kicks in on an actual error,
// not preemptively.
const TTS_MODEL = '@cf/myshell-ai/melotts';

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

    if (url.pathname === '/ai/stt' && request.method === 'POST') {
      return handleSpeechToText(request, env);
    }

    if (url.pathname === '/ai/tts' && request.method === 'POST') {
      return handleTextToSpeech(request, env);
    }

    return jsonResponse({ error: 'not_found' }, 404);
  },

  // Fired on the schedule in `wrangler.toml`'s `[triggers]` - the
  // server-side half of real, "even when the app is closed" price-drop
  // notifications. `ctx.waitUntil` keeps the Worker alive until the run
  // (which makes several sequential Duffel/Firestore/FCM calls) actually
  // finishes, not just until this function returns.
  async scheduled(event, env, ctx) {
    ctx.waitUntil(runPriceCheckJob(env));
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
      // Don't fail the request over a provider-side issue (quota, outage,
      // bad key) when another option is available - fall through to the
      // next step instead. Logged server-side only: unlike the Workers AI
      // path, an API key is involved here, so the error detail is not
      // safe to hand back to the client.
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

async function handleSpeechToText(request, env) {
  if (!env.AI) {
    return jsonResponse({ error: 'ai_not_configured' }, 500);
  }

  let audioBytes;
  try {
    audioBytes = new Uint8Array(await request.arrayBuffer());
  } catch (error) {
    return jsonResponse({ error: 'invalid_request_body' }, 400);
  }
  if (audioBytes.length === 0) {
    return jsonResponse({ error: 'empty_audio' }, 400);
  }

  try {
    const result = await env.AI.run(STT_MODEL, { audio: Array.from(audioBytes) });
    const text = (result?.text ?? '').trim();
    return jsonResponse({ text }, 200);
  } catch (error) {
    return jsonResponse(
      { error: 'stt_request_failed', detail: String(error?.message ?? error) },
      502,
    );
  }
}

async function handleTextToSpeech(request, env) {
  if (!env.AI) {
    return jsonResponse({ error: 'ai_not_configured' }, 500);
  }

  let body;
  try {
    body = await request.json();
  } catch (error) {
    return jsonResponse({ error: 'invalid_request_body' }, 400);
  }
  const text = typeof body?.text === 'string' ? body.text.trim() : '';
  if (!text) {
    return jsonResponse({ error: 'text_required' }, 400);
  }
  // See TTS_MODEL's doc comment above - unsupported languages are sent
  // through anyway rather than rejected.
  const lang = typeof body?.lang === 'string' && body.lang ? body.lang : 'en';
  const female = body?.female !== false;

  try {
    // Which service actually answers depends purely on which secrets are
    // configured - see tts_providers.js. `provider` is echoed back so the
    // deploy smoke test can report which one is live.
    const result = await synthesizeSpeech(text, lang, env, { female });
    return jsonResponse(
      { audio: result.audioBase64, mimeType: result.mimeType, provider: result.provider },
      200,
    );
  } catch (error) {
    return jsonResponse(
      { error: 'tts_request_failed', detail: String(error?.message ?? error) },
      502,
    );
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
