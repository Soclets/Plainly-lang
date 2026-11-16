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

- What happens at a position past the end, or at position 0 (D15).
- Whether there are positions counted from the end, ranges of positions, or an `offset:` form that counts from 0.
- How a list's type and a list value are written.

## Units

- Whether Plainly has Cyborg's units, checked while building (D8).

## Used in the README, but not decided

- `procedure greet[...] returns Text:` as the header, with `:` at the end.
- `end procedure greet` as the closer.
- `procedure.main[]` with empty brackets, versus Cyborg's `[none]`.
- `proc` as the short form of `procedure`.
- Bodies not indented.
