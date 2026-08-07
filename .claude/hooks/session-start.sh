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
