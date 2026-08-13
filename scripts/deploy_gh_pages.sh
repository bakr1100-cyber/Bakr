#!/usr/bin/env bash
# Builds the Flutter web app and publishes it to the gh-pages branch.
#
# This repo is served as a GitHub *project* page
# (https://<user>.github.io/Bakr/), not a root/user page - so the build
# MUST be given --base-href /Bakr/, or every asset request resolves
# against the site root instead of /Bakr/ and 404s, which renders as a
# blank white page. `flutter build web` alone defaults to "/" and looks
# fine locally (served from root) while silently breaking on GitHub
# Pages - this happened for real once, hence this script existing at
# all instead of just documenting the flag.
set -euo pipefail

cd "$(dirname "$0")/.."

# Wires the deployed app to the real flight-price proxy (see app.dart's
# `_duffelProxyUrl`/`_resolvePriceSource`) - without this define the app
# always fell back to MockFlightPriceSource's synthetic prices, even on
# builds made after the Cloudflare Worker + DUFFEL_API_KEY secret were set
# up, because nothing ever actually told the compiled app the proxy's URL.
# Safe to pass unconditionally: if the Worker has no DUFFEL_API_KEY secret
# configured yet, it responds with an error and DuffelFlightPriceSource
# catches that and falls back to the mock data exactly as before.
DUFFEL_PROXY_URL="${DUFFEL_PROXY_URL:-https://marocfly-duffel-proxy.bakr1100.workers.dev}"

# Wires real push notifications (see NotificationService/AccountSyncService)
# - the "Web Push certificate" key pair from Firebase console: Project
# settings -> Cloud Messaging -> Web configuration. Left empty until set as
# a local env var before running this script (there's no safe placeholder
# default the way there is for DUFFEL_PROXY_URL above, since this one is
# project-specific and secret-ish); without it, getToken() simply fails and
# push notifications stay unavailable, same graceful degradation as every
# other optional integration here.
FIREBASE_VAPID_KEY="${FIREBASE_VAPID_KEY:-}"

flutter build web --release --base-href /Bakr/ \
  --dart-define=DUFFEL_PROXY_URL="$DUFFEL_PROXY_URL" \
  --dart-define=FIREBASE_VAPID_KEY="$FIREBASE_VAPID_KEY"

worktree_dir=$(mktemp -d)
git fetch origin gh-pages
git worktree add "$worktree_dir" gh-pages

find "$worktree_dir" -mindepth 1 -maxdepth 1 -not -name '.git' -exec rm -rf {} +
cp -r build/web/. "$worktree_dir"/
touch "$worktree_dir"/.nojekyll

pushd "$worktree_dir" >/dev/null
git add -A
if git diff --cached --quiet; then
  echo "Nothing changed - build output is identical to what's already deployed."
else
  git commit -m "Deploy: ${1:-update web build}"
  git push origin gh-pages
fi
popd >/dev/null

git worktree remove "$worktree_dir" --force
