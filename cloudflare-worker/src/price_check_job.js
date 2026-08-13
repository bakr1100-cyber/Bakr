/**
 * The server-side half of "real" price-drop notifications (see
 * `todo/real-outside-app-price-notifications.md` in the main repo, which
 * this closes out): runs on a Cron Trigger (see `wrangler.toml`), so it
 * fires whether or not anyone has the app open, unlike the old
 * `checkForDrops()` which only ever ran when a user manually tapped
 * refresh on the Price Alerts screen.
 *
 * For every signed-in user who has both a push token (see
 * `NotificationService`/`AccountSyncService` on the Flutter side) and at
 * least one tracked price alert: re-quotes each alert's route via Duffel,
 * and if the price dropped by a meaningful amount, sends a push
 * notification via Firebase Cloud Messaging and updates the stored alert
 * so the app shows the same drop next time it's opened.
 *
 * Needs `FIREBASE_SERVICE_ACCOUNT_EMAIL`/`FIREBASE_SERVICE_ACCOUNT_KEY`
 * (see `google_auth.js`) and `DUFFEL_API_KEY` (already required for the
 * `/air/offer_requests` route) to actually do anything - silently no-ops
 * otherwise, same fail-safe philosophy as every other optional piece of
 * this Worker.
 */

import { getGoogleAccessToken } from './google_auth.js';

const DUFFEL_BASE_URL = 'https://api.duffel.com';
const DUFFEL_VERSION = 'v2';
const FIRESTORE_BASE = 'https://firestore.googleapis.com/v1';
const MIN_MEANINGFUL_DROP_EUR = 15;
const MIN_MEANINGFUL_DROP_FRACTION = 0.05;
// How far out to search - price alerts don't store a specific travel date
// (see `PriceAlert` on the Flutter side), so this mirrors the same
// deterministic "some weeks out" convention used for the deploy-time
// Duffel smoke test.
const SEARCH_DAYS_AHEAD = 30;

export async function runPriceCheckJob(env) {
  if (!env.DUFFEL_API_KEY) {
    console.log('runPriceCheckJob: DUFFEL_API_KEY not set, skipping.');
    return;
  }
  const accessToken = await getGoogleAccessToken(env);
  if (!accessToken) {
    console.log('runPriceCheckJob: Firebase service account not configured, skipping.');
    return;
  }

  const projectId = env.FIREBASE_PROJECT_ID || 'maroc-fly-ia';
  const users = await listUsersWithAlerts(projectId, accessToken);
  console.log(`runPriceCheckJob: checking ${users.length} user(s) with tracked alerts.`);

  for (const user of users) {
    try {
      await checkUserAlerts(user, { projectId, accessToken, duffelApiKey: env.DUFFEL_API_KEY });
    } catch (error) {
      // One user's bad data / a transient Duffel error must not stop the
      // rest of the run.
      console.error(`runPriceCheckJob: failed for user ${user.uid}:`, error);
    }
  }
}

async function listUsersWithAlerts(projectId, accessToken) {
  const results = [];
  let pageToken;
  do {
    const url = new URL(`${FIRESTORE_BASE}/projects/${projectId}/databases/(default)/documents/users`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const response = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
    if (!response.ok) {
      throw new Error(`Firestore list failed: HTTP ${response.status} ${await response.text()}`);
    }
    const data = await response.json();
    for (const doc of data.documents ?? []) {
      const fields = doc.fields ?? {};
      const pushToken = fields.pushToken?.stringValue;
      const alerts = fields.priceAlerts?.arrayValue?.values ?? [];
      if (!pushToken || alerts.length === 0) continue;
      results.push({
        uid: doc.name.split('/').pop(),
        documentName: doc.name,
        pushToken,
        alerts: alerts.map(decodeAlert).filter(Boolean),
      });
    }
    pageToken = data.nextPageToken;
  } while (pageToken);
  return results;
}

function decodeAlert(value) {
  const fields = value.mapValue?.fields;
  if (!fields) return null;
  const id = fields.id?.stringValue;
  const originCode = fields.originCode?.stringValue;
  const destinationCode = fields.destinationCode?.stringValue;
  const watchedPriceEur = Number(fields.watchedPriceEur?.doubleValue ?? fields.watchedPriceEur?.integerValue);
  if (!id || !originCode || !destinationCode || Number.isNaN(watchedPriceEur)) return null;
  return { id, originCode, destinationCode, watchedPriceEur };
}

async function checkUserAlerts(user, { projectId, accessToken, duffelApiKey }) {
  let anyUpdated = false;
  const updatedAlerts = [];

  for (const alert of user.alerts) {
    const currentPriceEur = await quoteCheapestPrice(alert.originCode, alert.destinationCode, duffelApiKey);
    if (currentPriceEur == null) {
      updatedAlerts.push(alert);
      continue;
    }

    const drop = alert.watchedPriceEur - currentPriceEur;
    const bar = Math.max(MIN_MEANINGFUL_DROP_EUR, alert.watchedPriceEur * MIN_MEANINGFUL_DROP_FRACTION);
    if (drop >= bar) {
      anyUpdated = true;
      await sendPriceDropNotification({
        projectId,
        accessToken,
        pushToken: user.pushToken,
        originCode: alert.originCode,
        destinationCode: alert.destinationCode,
        drop,
        currentPriceEur,
      });
    }
    updatedAlerts.push({ ...alert, currentPriceEur });
  }

  if (anyUpdated) {
    await writeUpdatedAlerts({ projectId, accessToken, documentName: user.documentName, alerts: updatedAlerts });
  }
}

async function quoteCheapestPrice(originIata, destinationIata, apiKey) {
  const departureDate = new Date();
  departureDate.setUTCDate(departureDate.getUTCDate() + SEARCH_DAYS_AHEAD);
  const dateOnly = departureDate.toISOString().slice(0, 10);

  const response = await fetch(`${DUFFEL_BASE_URL}/air/offer_requests?return_offers=true`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Duffel-Version': DUFFEL_VERSION,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      data: {
        slices: [{ origin: originIata, destination: destinationIata, departure_date: dateOnly }],
        passengers: [{ type: 'adult' }],
        cabin_class: 'economy',
      },
    }),
  });
  if (!response.ok) {
    console.error(`quoteCheapestPrice(${originIata}->${destinationIata}): HTTP ${response.status}`);
    return null;
  }
  const data = await response.json();
  const offers = data?.data?.offers ?? [];
  if (offers.length === 0) return null;
  const cheapest = offers.reduce((min, o) => Math.min(min, Number(o.total_amount)), Infinity);
  return Number.isFinite(cheapest) ? cheapest : null;
}

async function sendPriceDropNotification({ projectId, accessToken, pushToken, originCode, destinationCode, drop, currentPriceEur }) {
  const title = `Preisalarm: ${originCode} → ${destinationCode}`;
  const body = `Dein Flug ist jetzt ${Math.round(drop)} € günstiger (${Math.round(currentPriceEur)} €).`;

  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: pushToken,
        notification: { title, body },
        webpush: { fcm_options: { link: '/' } },
      },
    }),
  });
  if (!response.ok) {
    // A single invalid/expired token (uninstalled app, revoked
    // permission, ...) must not abort the whole job.
    console.error(`sendPriceDropNotification: HTTP ${response.status} ${await response.text()}`);
  }
}

async function writeUpdatedAlerts({ projectId, accessToken, documentName, alerts }) {
  const url = new URL(`${FIRESTORE_BASE}/${documentName}`);
  url.searchParams.set('updateMask.fieldPaths', 'priceAlerts');

  const arrayValue = {
    arrayValue: {
      values: alerts.map((a) => ({
        mapValue: {
          fields: {
            id: { stringValue: a.id },
            originCode: { stringValue: a.originCode },
            destinationCode: { stringValue: a.destinationCode },
            watchedPriceEur: { doubleValue: a.watchedPriceEur },
            ...(a.currentPriceEur != null ? { currentPriceEur: { doubleValue: a.currentPriceEur } } : {}),
          },
        },
      })),
    },
  };

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: { priceAlerts: arrayValue } }),
  });
  if (!response.ok) {
    throw new Error(`Firestore alert update failed: HTTP ${response.status} ${await response.text()}`);
  }
}
