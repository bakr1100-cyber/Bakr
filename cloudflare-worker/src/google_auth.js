/**
 * Mints short-lived Google OAuth2 access tokens for a service account, so
 * the scheduled price-check job (see `price_check_job.js`) can call
 * Firestore's Admin-scoped REST API (to read every user's tracked price
 * alerts and their push token, bypassing the client-facing security rules
 * that correctly restrict the app itself to `request.auth.uid == uid`) and
 * the Firebase Cloud Messaging HTTP v1 API (to actually deliver the push).
 *
 * No `google-auth-library`/`jsonwebtoken` npm dependency needed - this
 * hand-rolls the standard OAuth2 "JWT Bearer" service-account flow
 * (RFC 7523) using only WebCrypto, which Cloudflare Workers already has.
 *
 * Requires two Cloudflare secrets, from a service account JSON key
 * downloaded via Google Cloud Console -> IAM & Admin -> Service Accounts
 * -> (the account) -> Keys -> Add key -> JSON (see the deploy workflow for
 * exactly how these get set):
 *   - FIREBASE_SERVICE_ACCOUNT_EMAIL: the key's "client_email" field.
 *   - FIREBASE_SERVICE_ACCOUNT_KEY: the key's "private_key" field, PEM
 *     text including the BEGIN/END PRIVATE KEY lines (newlines can be
 *     literal or the two-character "\n" - both are normalized below).
 * That service account needs the "Cloud Datastore User" (or "Firebase
 * Admin SDK Administrator Service Agent") IAM role to read Firestore, and
 * Firebase Cloud Messaging access is implicit for any service account in
 * the same Firebase project.
 */

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SCOPES = [
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/firebase.messaging',
].join(' ');

/** Returns `null` if the two required secrets aren't configured. */
export async function getGoogleAccessToken(env) {
  const email = env.FIREBASE_SERVICE_ACCOUNT_EMAIL;
  const privateKeyPem = env.FIREBASE_SERVICE_ACCOUNT_KEY;
  if (!email || !privateKeyPem) return null;

  const assertion = await buildSignedJwt(email, privateKeyPem);
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error(`Google token exchange failed: HTTP ${response.status} ${await response.text()}`);
  }
  const data = await response.json();
  return data.access_token;
}

async function buildSignedJwt(email, privateKeyPem) {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: email,
    scope: SCOPES,
    aud: TOKEN_URL,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };

  const unsigned = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claims))}`;
  const key = await importPrivateKey(privateKeyPem);
  const signatureBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncodeBytes(new Uint8Array(signatureBytes))}`;
}

async function importPrivateKey(pem) {
  // Secrets are single-line values, so a real PEM (which needs actual
  // newlines between its base64 body lines) is normally pasted with
  // literal "\n" two-character sequences instead - normalize both forms.
  const normalized = pem.includes('\\n') ? pem.replace(/\\n/g, '\n') : pem;
  const body = normalized
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const der = base64ToBytes(body);
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function base64UrlEncode(str) {
  return base64UrlEncodeBytes(new TextEncoder().encode(str));
}

function base64UrlEncodeBytes(bytes) {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64ToBytes(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
