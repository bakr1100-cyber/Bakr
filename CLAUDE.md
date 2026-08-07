# Working with the user on this project

The user (Bakr) cannot code, test, or debug directly - they only have an
iPad and view the deployed web app in Safari. They report problems via
German (often voice-dictated, sometimes garbled) or French text, screenshots,
or screen-recorded videos. Diagnose from what they send, not from asking them
to reproduce technical steps.

## To-dos

Whenever the user marks something as a to-do ("das ist ein to do",
"erinnere mich später", "notier das", etc.) instead of asking for it to be
fixed immediately: add a new file to the `todo/` folder (see
`todo/README.md` for the convention) instead of fixing it right away.

At the end of a session - or whenever it's a natural point to wrap up -
remind the user what's still open in `todo/` (a short list of file names /
one-line summaries is enough, no need to paste full file contents).

Once a to-do is actually fixed, delete its file from `todo/` as part of that
fix's commit.

## Deploying

Always use `scripts/deploy_gh_pages.sh` to publish to GitHub Pages - it
builds with the correct `--base-href /Bakr/`, which a plain `flutter build
web` does not set and which silently breaks the deployed site (blank white
page). Always end replies to the user with the deployed link:
https://bakr1100-cyber.github.io/Bakr/

## graphify

`graphify` (see the `graphify` skill) is installed purely as a
codebase-navigation aid for Claude Code - it is not part of the app and
nothing about it is user-facing. `graphify-out/` is gitignored and rebuilt
per-session via `.claude/hooks/session-start.sh`.
