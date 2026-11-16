# Plainly — Decisions

What was chosen, with the owner's words. Nothing in the early notes counts as decided unless it's here.

## D1: `&` joins text (2026-11-16)

`&` joins text: `"Hello, " & #name`. `+` stays for maths only, so `"5" + 3` can't be misread as joining.
`&` reads as "and", is already used for joining in Ada, Visual Basic and Excel, and Plainly has no other use for it. It
replaces `join_text(...)` from the early sketch.

Open: whether `&` turns a non-text value such as a `Whole` into text by itself.

Owner: "`&` decided."

## D2: `show_text.format` fills in names, and `show_text` stays literal (2026-11-16)

Inside `show_text.format(...)`, a name in the text is replaced by its value:
`show_text.format("Score: #total / 10 points")`. The `#` that every name already starts with marks where it goes, so no
braces are needed. Plain `show_text` stays literal: `show_text("#total")` prints `#total`. Text in quotes is literal
unless the `.format` narrowing says otherwise, as in Fale's decision 7. This replaces long `&` chains, like
`"Score: " & #total & " / " & 10 & " points"`, where every value costs a pair of quotes.

Open: how to write a literal `#` inside `.format` text; where a name ends inside text (`#totalpoints`); whether
`.format` exists beyond `show_text`, for building a `Text` value.

Owner: "yup, and `show_text` stays the non format kind".

Changed by D4: names go in braces, `{#total}`.

## D3: `\` escapes, but isn't C's escape codes (2026-11-16)

A `\` makes the next character literal: `show_text.format("\#1 player: #name")` prints `#1 player: ` and then the name.
`\` only escapes. It doesn't start C-style codes, so `\n` doesn't mean a newline and `\t` doesn't mean a tab.

Open: how a newline or tab is written; whether `\` before an ordinary letter is an error; how `\"` and `\\` work in plain
(non-`.format`) text.

Owner: "`\` escapes, but it doesn't format like C".

Since D4, a bare `#` in `.format` text is literal, so `"#1 player"` needs no escape. `\{` escapes a brace instead.

## D4: `.format` fills in braces, and `new_line` is a word (2026-11-16)

Inside `show_text.format(...)`, what goes in braces is filled in: `show_text.format("Hello, {#name}{new_line}")`. A bare
`#` is literal, so `"#1 player"` prints as written, and the braces show exactly where a name ends: `{#total}points`.
This changes D2, which had no braces.

A newline is the word `new_line`, not a code like C's `\n`: `show_text("Hello, World!" & new_line)`, or `{new_line}`
inside `.format`. It's one more thing to learn, but a small one, and it says what it is.

Open: what may go in braces besides names and `new_line` (expressions such as `{#total + 1}`?); other named characters,
such as a tab.

Owner: "It should probably be this instead, then. [...] Which yes, I know, it's a thing to learn. But I think it's small".
