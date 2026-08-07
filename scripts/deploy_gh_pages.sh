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

flutter build web --release --base-href /Bakr/

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
