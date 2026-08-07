# To-dos

One file per deferred item - things the user flagged as "das ist ein to do"
during a session, to fix later rather than immediately.

Convention (see `CLAUDE.md` at the repo root for the full standing
instruction): whenever the user marks something as a to-do, add a new file
here named `<short-slug>.md` with a one-line summary, the relevant context,
and file/line references if applicable. At the end of a session, remind the
user what's still open in this folder. Delete the file once it's done (or
move it into the commit message / PR description that fixes it).
