# Plainly — Implementation rules

The rules for the code that implements Plainly. A hook prints this file into every session at startup, after compaction
and on `/clear`, so the rules survive when a session's first prompt doesn't. Only the design session edits it. Each rule
names the decision it came from, or when the owner gave it.

## Rules

1. **Commits.** `kind.folder.narrowing: sentence`, and a decision adds `(owner: "their words"; D1)`. Kinds: `decision`,
   `design`, `feature`, `fix`, `test`, `house`. Each commit ends with its session's trailer, such as
   `Co-Authored-By: design claude <noreply@anthropic.com>`. One decision per commit.
2. **The owner's words are exact, or `too long`.** In a commit and in `DECISIONS.md`, a quote is the owner's whole
   message, exactly as written, typos included. If it won't fit, write too long, with no quotation marks. Never trim a
   quote, fix its typos, or use `[...]`. Notes outside the quotes, like what a "yea" answered, are fine. Decide before
   writing the line, never by picking the relevant part: in a commit subject, quote only a short message copied whole,
   like "yea", and write too long for anything longer. (Owner, 2026-11-16)
