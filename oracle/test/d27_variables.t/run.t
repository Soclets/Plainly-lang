Variables with written types, `mut` and `change`, `+` for numbers, `&` for text, and `be.Text` (D1, D6, D27, D28).

  $ plainoracle runs.plainly
  Hello, Mia
  Score: 15

`mutable` is the long form of `mut` (D28).

  $ plainoracle mutable_long.plainly
  4

`change` needs `mut` (D27, D59).

  $ plainoracle not_mut.plainly
  refused: not_mut.plainly:4:12, line 4 column 12
   4 |     change #score = 11;
     |            ^^^^^^
   what: `#score` isn't mutable
   why:  `change` only works on a variable (#) declared `mut`.
  [1]

A variable holds only its written type.

  $ plainoracle wrong_type.plainly
  refused: wrong_type.plainly:3:21, line 3 column 21
   3 |     #score: Whole = "ten";
     |                     ^^^^^
   what: `"ten"` is `Text`, but `#score` is a `Whole`
   why:  a variable (#) holds only the type written for it.
  [1]

`+` is only for numbers (D1).

  $ plainoracle plus_text.plainly
  refused: plus_text.plainly:3:19, line 3 column 19
   3 |     show_text("a" + "b");
     |                   ^
   fix:  `&`
   why:  `+` is only for numbers, and `&` joins text.
  [1]

`&` doesn't turn a number into text by itself (D6).

  $ plainoracle join_whole.plainly
  refused: join_whole.plainly:4:27, line 4 column 27
   4 |     show_text("Score: " & #score);
     |                           ^^^^^^
   fix:  `be.Text(#score)`
   why:  `&` joins text, and doesn't turn a number into text by itself.
  [1]

Neither does `show_text` (D6).

  $ plainoracle show_whole.plainly
  refused: show_whole.plainly:4:15, line 4 column 15
   4 |     show_text(#score);
     |               ^^^^^^
   fix:  `be.Text(#score)`
   why:  `show_text` shows text, and doesn't turn a number into text by itself.
  [1]

A variable is declared before it's used, and there's no guess at what was meant.

  $ plainoracle undeclared.plainly
  refused: undeclared.plainly:3:15, line 3 column 15
   3 |     show_text(#nmae);
     |               ^^^^^
   what: `#nmae` isn't declared before this line
   why:  a variable (#) is declared, with its type, before it's used.
  [1]

A broken declaration still creates its variable with its written type, so later lines don't fail because of it (D58).

  $ plainoracle kept_variable.plainly
  refused: kept_variable.plainly:3:21, line 3 column 21
   3 |     #score: Whole = "ten";
     |                     ^^^^^
   what: `"ten"` is `Text`, but `#score` is a `Whole`
   why:  a variable (#) holds only the type written for it.
  [1]

A number that doesn't fit in a `Whole` is refused.

  $ plainoracle too_big.plainly
  refused: too_big.plainly:3:17, line 3 column 17
   3 |     #n: Whole = 9223372036854775808;
     |                 ^^^^^^^^^^^^^^^^^^^
   what: `9223372036854775808` doesn't fit in a `Whole`
   why:  a `Whole` holds whole numbers from -9223372036854775808 to 9223372036854775807.
  [1]

Overflow is a check that stops the program in `Working` (D19), reported with the values that broke it and exit status 4
(D82).

  $ plainoracle overflow.plainly
  check failed: overflow.plainly:4:24, line 4 column 24
   4 |     change #big = #big + 1;
     |                        ^
   what: `#big + 1` is too big for a `Whole`
   when: `#big` is 9223372036854775807
   why:  a `Whole` holds whole numbers from -9223372036854775808 to 9223372036854775807.
  [4]

Mixing `+` and `&` needs brackets, since maths doesn't say which goes first (D83). Within brackets, either is fine.

  $ plainoracle mixed.plainly
  refused: mixed.plainly:4:25, line 4 column 25
   4 |     show_text("x" & "y" + "z");
     |                         ^
   what: `+` and `&` are mixed without `( )`
   why:  maths doesn't say which goes first, so `( )` shows it.
  [1]

The Thai word for `mut` isn't decided yet (D57).

  $ plainoracle thai_mut.เพลนลี่
  NotDesignedYet: thai_mut.เพลนลี่:3:5, line 3 column 5
   3 |     mut #score: Whole = 10;
     |     ^^^
   what: the Thai word for `mut` isn't decided yet
  [3]
