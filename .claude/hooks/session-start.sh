#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# graphify (https://github.com/Graphify-Labs/graphify) is a dev-only
# codebase-navigation tool for Claude Code, not part of the app - it's not
# tracked in git (graphify-out/ is .gitignore'd, regenerable), so each fresh
# container needs it reinstalled. Cheap and idempotent; safe to always run.
if command -v uv >/dev/null 2>&1; then
  uv tool install --upgrade graphifyy -q || true
  if command -v graphify >/dev/null 2>&1; then
    graphify install || true
  fi
fi

# ui-ux-pro-max (https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) is
# a dev-only design-knowledge skill for Claude Code (style/color/typography
# references, design-system generator) - also not part of the app, and its
# install output (.claude/skills/*) is .gitignore'd since it's ~3MB of
# regenerable vendored assets, so each fresh container needs it reinstalled.
if command -v npm >/dev/null 2>&1; then
  npm install -g ui-ux-pro-max-cli --silent || true
  if command -v uipro >/dev/null 2>&1; then
    (cd "$CLAUDE_PROJECT_DIR" && uipro init --ai claude) || true
  fi
fi
