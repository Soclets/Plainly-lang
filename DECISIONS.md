# Plainly — Decisions

What was chosen, with the owner's words. Nothing in the early notes counts as decided unless it's here.

## D1: `&` joins text (2026-11-16)

`&` joins text: `"Hello, " & #name`. `+` stays for maths only, so `"5" + 3` can't be misread as joining.
`&` reads as "and", is already used for joining in Ada, Visual Basic and Excel, and Plainly has no other use for it. It
replaces `join_text(...)` from the early sketch.

Open: whether `&` turns a non-text value such as a `Whole` into text by itself. (Answered by D6: it doesn't.)

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

## D5: Only the opening brace is escaped (2026-11-16)

In `.format` text, `\{` makes a brace literal, and the closing `}` needs nothing:
`show_text.format("Type \{#name} to see your name")` prints `Type {#name} to see your name`. A `}` with no open fill-in
is just a character. That's one `\` instead of two, and no rule about the closing side, unlike Python's `{{ }}`.

Owner: "yea", to escaping only the opening brace.

## D6: `be.Type(value)` converts (2026-11-16)

Converting a value is a call narrowed by the type it becomes: `be.Text(#total)`, `be.Whole(#typed)`. The type's own name
is used, so nothing new is learnt. `.` keeps its one meaning, narrowing, and never means "do something to this value".
`&` doesn't convert by itself: `show_text("Total: " & be.Text(#total) & new_line)`. `.format`'s braces do convert,
since `{#total}` has to become text to be printed.

A conversion that can fail, such as `be.Whole("hello")`, will use the error handling Plainly takes from Cyborg or Radium,
which isn't designed yet.

Owner: "Maybe `be.Text(#total)` instead? As for why it's `.`, it's because it would have other types too", then "yea".

## D7: Braces hold values, never calls or maths (2026-11-16)

What goes in `.format`'s braces only reads: a name like `{#total}`, or a word like `{new_line}`. `{#total + 1}` and
`{greet(#name)}` are refused. A format string can never hide work, and a call that can fail or maths that can overflow
stays out where you can see it. This follows Cyborg's `fmt_print` (Cyborg D194, D210).

Open: field access, such as `{#player.score}`, once Plainly has records; width, padding and decimal places, which Cyborg
spells as words, like `{$price, places: 2}`; a version of `.format` that builds a `Text` value instead of printing,
which Cyborg's design claude advises deciding early.

Owner: "yea".

## D8: Plainly has Cyborg's labels (2026-11-16)

Plainly takes Cyborg's labels: named arguments, chosen by a function's writer, that every call must then write, as in
`first_word(#text, limit: 20)` instead of `first_word(#text, 20)`. A label is separate from the parameter's own name, so
a function can rename its insides without changing its callers. Only labelled parameters can have defaults. By
convention the first argument, the thing being worked on, stays bare. Labels can be narrowed, as in `len.max:`. Leaving
off a label with no default, or writing one that wasn't declared, is refused while building. (Cyborg D13, D113, D114)

Labels don't depend on units. Whether Plainly has Cyborg's units, checked while building (as in making Celsius correct),
isn't decided: they're very rich, and may be more than Plainly needs. Without them, Plainly skips Cyborg D144, where a
label's narrowing names a unit.

Label order: D10.

Owner: "idk if we'll have checked units. But we'll definitely have Cyborg's labels".

How a label is declared: D9.

## D9: Labels and defaults are declared on their own lines (2026-11-16)

As in Cyborg (Cyborg D114), labels and defaults are declared on separate lines at the top of the body, labels first:

    proc first_word[#text: Text, #limit: Whole] returns Text:
    labels [#limit as limit]
    defaults [#limit = 40]
    ...
    end proc first_word

    first_word(#text, limit: 20)
    first_word(#text)

The one-line form, `[#text: Text, limit #limit: Whole = 40]`, was turned down: it packs a label, a name, a type and a
default into one item, which is hard to read.

Owner: "That's bad btw" (of the one-line form), then "separate, yea".

## D10: Labels keep their order, unless `labels.any_order` (2026-11-16)

A call writes its labels in the order the function declares them. A function that doesn't mind says so by narrowing its
`labels` line, as in Cyborg (Cyborg D114):

    proc move[#player: Player, #x: Whole, #y: Whole]:
    labels.any_order [#x as across, #y as down]
    ...
    end proc move

    move(#player, across: 3, down: 1)
    move(#player, down: 1, across: 3)

`labels.in_order` is refused, since it's already the default.

Owner: "yea, but before recording, where is `labels.any_order` un synatx?", then "tea" (yea).
