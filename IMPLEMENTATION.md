# Plainly — Implementation rules

The rules for the code that implements Plainly. A hook prints this file into every session at startup, after compaction
and on `/clear`, so the rules survive when a session's first prompt doesn't. Only the design session edits it. Each rule
names the decision it came from, or when the owner gave it.

## Rules

1. **Commits.** `kind.folder.narrowing: sentence`, and a decision adds `(owner: "their words"; D1)`. Kinds: `decision`,
   `design`, `feature`, `fix`, `test`, `house`. Each commit ends with its session's trailer, such as
   `Co-Authored-By: design claude <noreply@anthropic.com>`. One decision per commit.
2. **The owner's words are exact, or a marker that says why not.** In a commit and in `DECISIONS.md`, a quote is the
   owner's whole message, exactly as written, typos included. Never trim a quote, fix its typos, or use `[...]`. Notes
   outside the quotes, like what a "yea" answered, are fine. Decide before writing the line, never by picking the
   relevant part. When a message can't be quoted, write the marker for the real reason, with no quotation marks:
   - **too long**: more than 300 characters in `DECISIONS.md`, or more than fits the line in a commit subject;
   - **has code**: a code block, or in a commit subject any code formatting (backticks).
   (Owner, 2026-11-16 and 2026-11-17)
3. **Stop at 8:30 PM.** Every session stops at 20:30 and suggests the owner stops too, since going past bedtime has made
   the owner abandon languages. A `UserPromptSubmit` hook prints the time with every message, and a reminder from 20:30
   until 05:00. (Owner, 2026-11-17)
4. **Prompting.** Before prompting a subagent or a new session, a session downloads the current prompting guide for that
   AI as Markdown and reads the file itself, in full, and again after every compaction. Never through a fetch tool's
   summary, which can drop parts. Messaging another session isn't prompting, and is written like one colleague talking
   to another. (Owner, 2026-11-17, from Cyborg's rule 11)
5. **Style and checks.** Comments say why, not what.
   - **Rust** (AroundPy, the runtime, PlainGC): `rustfmt` and `clippy`. `unwrap`, `expect` and `panic` are denied on
     any path a real program takes, so a bad program never crashes AroundPy; if AroundPy itself fails, it says so and how
     to report it. `unsafe` is forbidden except in the runtime and PlainGC, which can't be written without it, and there
     each `unsafe` block has a comment saying why it's safe.
   - **OCaml** (PlainOracle): `ocamlformat`, and compiler warnings are errors.
   (Owner, 2026-11-17, from Cyborg's rules 6 and 7)
6. **Fixing stale documents.** The design session may correct a document that contradicts the decisions, such as
   NOT-DECIDED.md, a prompt, the README, or a note under an old entry, but only when the proof is firsthand in its
   current context: the owner's own message, or a file it read since the last compaction. A compaction summary doesn't
   count, so after a compaction it reads the files again before correcting anything. Each correction says in its commit
   what was stale and which decision shows it. It never overrules the owner's recorded words: an entry in DECISIONS.md
   changes only through a new decision. (Owner, 2026-11-17)
7. **Push after committing.** Every commit goes to `main` as it's made, without asking, so nothing piles up locally.
   (Owner, 2026-11-17, from `design/plainoracle-prompt.md`)
8. **Talk in chat.** One question at a time, asked in the message itself, with no popups or pre-made answer buttons:
   no question dialogs, and no question or buttons in the app's next-step box. (Owner, 2026-11-16 and 2026-11-17, from
   Cyborg's CLAUDE.md)
9. **The standard follows the decisions.** A decision that changes a rule updates `standard/` in the same commit, and
   anything it leaves open is marked **Not decided** there (`standard/README.md`). (Owner, 2026-11-17)

## Tracing

Code that carries out a decision says so with a comment, in PlainOracle and AroundPy alike:

```rust
// trace: D27
```

```ocaml
(* trace: D27 *)
```

A check fails on a tag that names no decision, and lists the decisions nothing traces yet.

## Naming

The code uses Plainly's own words, so the code, the decisions and the error messages all say the same thing.

- **Full words.** `expression`, not `expr`.
- **One name per concept.**
- **Plainly's words over textbook words.** `narrowing`, `label`, `failure`, `handler`.
- **Each language's own casing**, which `clippy` and `ocamlformat` enforce.
- **Tests are named after their decision.**
