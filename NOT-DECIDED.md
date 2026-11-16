# Plainly — Not decided

Questions that have come up and are waiting for an answer. When one is decided, it moves to `DECISIONS.md` and leaves
this list.

## Narrowings

- **Where safety words go in the table of kinds.** D14 puts the narrowing that changes the action most first. A word
  that can do harm, like a future `unchecked`, may be the most important fact on a line, which argues for putting it
  first. Cyborg's design claude suggested action, then content, then destination, then safety. Cyborg's own standard
  ranks safety words by how much harm they can do and doesn't place them against other kinds. (Owner: "idk")
- **The rest of the table of kinds** (D14).

## Text

- Field access in braces, such as `{#player.score}`, once Plainly has records (D7).
- Width, padding and decimal places in braces; Cyborg writes them as words, like `{$price, places: 2}` (D7).
- Other named characters besides `new_line`, such as a tab (D4).
- Whether `\` before an ordinary letter is an error, and how `\"` and `\\` work in plain text (D3).

## Lists

- How far the compiler looks for a bad position while building, beyond literals and fixed sizes (D20).
- Whether there are positions counted from the end, ranges of positions, or an `offset:` form that counts from 0.
- How a list's type and a list value are written.

## Failures

Proposed, not yet agreed (D41 to D44 and D46 are decided):
- `otherwise:` with `case` arms, each ending in `instead`, `return`, `break` or `fail`, and `end otherwise`; whether a
  statement ending in `end otherwise` also takes `;`.
- `otherwise use 8080`, `otherwise ignore`, `otherwise crash`.
- Failures carrying data; `?` in `main`; cleanup for files and the terminal; how a handler family is declared; how a
  Rust `Result::Err` maps to a failure, and a Rust panic to a crash.

## Floats

- What Plainly's floats promise, now that Cyborg's stable floats are out (D18): plain IEEE 754 behaviour, with NaN and
  infinity allowed?
- `f32` or `f64` behind `Float`. `Float` means 32-bit in C, Java, C#, Swift and Kotlin, and 64-bit in Python.
- Whether Fale's `~` mark on inexact float literals, like `~0.1`, stays.

## Units

- Where unit words come from: declared by packages, or a fixed list (D45, D47).

## Used in the README, but not decided

- `procedure greet[...] returns Text:` as the header, with `:` at the end.
- `end procedure greet` as the closer.
- `procedure.main[]` with empty brackets, versus Cyborg's `[none]`.
- `proc` as the short form of `procedure`.
- Bodies not indented.
