`.format` fills in braces with values, converting numbers (D2, D4, D6, D11). Plain `show_text` stays literal (D2).
`\{` escapes an opening brace and a lone `}` is literal (D5). `.same_line` doesn't end the line (D12), and both
narrowings stack strongest first (D13, D14). `new_line` is a word (D4).

  $ plainoracle runs.plainly
  Mia has 120 points.
  Line one
  Line two
  Not filled: {#name}
  Type {#name} for your name, and a lone } stays.
  Your move: Mia? done
  Mia: 120
  a
  b

The other order is refused, with the right spelling as the fix (D14).

  $ plainoracle order.plainly
  refused: order.plainly:4:5, line 4 column 5
   4 |     show_text.same_line.format("{#name}");
     |     ^^^^^^^^^^^^^^^^^^^^^^^^^^
   fix:  `show_text.format.same_line`
   why:  `.format` changes what's shown, so it comes before `.same_line`.
  [1]

A fill-in holds a value, never a calculation (D7).

  $ plainoracle calculation.plainly
  refused: calculation.plainly:4:23, line 4 column 23
   4 |     show_text.format("{#n + 1}");
     |                       ^^^^^^^^
   what: `{#n + 1}` holds a calculation, not a value
   why:  a fill-in only reads a value, so it can never hide work.
  [1]

A `{` with no `}` is refused.

  $ plainoracle unclosed.plainly
  refused: unclosed.plainly:4:26, line 4 column 26
   4 |     show_text.format("Hi {#name");
     |                          ^
   what: this `{` has no `}`
   why:  a fill-in starts with `{` and ends with `}`.
  [1]

A fill-in's variable is declared first, like anywhere else.

  $ plainoracle undeclared.plainly
  refused: undeclared.plainly:3:24, line 3 column 24
   3 |     show_text.format("{#nmae}");
     |                        ^^^^^
   what: `#nmae` isn't declared before this line
   why:  a variable (#) is declared, with its type, before it's used.
  [1]

`\` before a letter isn't decided (D3).

  $ plainoracle letter_escape.plainly
  NotDesignedYet: letter_escape.plainly:3:23, line 3 column 23
   3 |     show_text.format("\n");
     |                       ^
   what: `\` before a letter isn't decided yet
  [3]

Neither is `\` in text outside `.format` (D3).

  $ plainoracle plain_escape.plainly
  NotDesignedYet: plain_escape.plainly:3:17, line 3 column 17
   3 |     show_text("a\"b");
     |                 ^
   what: `\` in text outside `.format` isn't decided yet
  [3]

Nor fields in a fill-in (D7).

  $ plainoracle field.plainly
  NotDesignedYet: field.plainly:4:29, line 4 column 29
   4 |     show_text.format("{#name.size}");
     |                             ^
   what: fields in a fill-in aren't decided yet
  [3]

`บรรทัดใหม่` is Thai `new_line` (D57).

  $ plainoracle thai_new_line.เพลนลี่
  ก
  ข
