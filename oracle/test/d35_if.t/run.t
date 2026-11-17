`if`, `else if`, `else` and `end if` (D35); comparisons (D34); `not`, then `and`, then `or` (D36, D92), with
`and.both` evaluating both sides (D37); `compare_Text.stored_same` and `.looks_same` (D94).

  $ plainoracle runs.plainly
  alive
  five
  and first
  not strong
  same
  looks same
  stored differently

A lone `=` in a condition is refused, with `==` as the fix (D34, D93).

  $ plainoracle lone_equals.plainly
  refused: lone_equals.plainly:4:12, line 4 column 12
   4 |     if #hp = 5:
     |            ^
   fix:  `==`
   why:  `=` gives a variable its value, and `==` compares.
  [1]

`==` doesn't compare `Text` (D94).

  $ plainoracle text_equals.plainly
  refused: text_equals.plainly:4:14, line 4 column 14
   4 |     if #name == "Mia":
     |              ^^
   what: `==` doesn't compare `Text`
   why:  text is compared with `compare_Text.stored_same` or `compare_Text.looks_same`.
  [1]

Different types can't be compared (D93).

  $ plainoracle mixed_types.plainly
  refused: mixed_types.plainly:4:8, line 4 column 8
   4 |     if #hp == "full":
     |        ^^^^^^^^^^^^^
   what: `#hp` is `Whole` and `"full"` is `Text`, so they can't be compared
   why:  only values of the same type can be compared.
  [1]

An `if` needs a comparison (D93).

  $ plainoracle not_comparison.plainly
  refused: not_comparison.plainly:4:8, line 4 column 8
   4 |     if #hp:
     |        ^^^
   what: `#hp` isn't a comparison
   why:  an `if` needs something true or false, like `#score > 0`.
  [1]

A missing `end if` is refused where the procedure closes (D93).

  $ plainoracle missing_end_if.plainly
  refused: missing_end_if.plainly:6:1, line 6 column 1
   6 | end procedure.main
     | ^^^^^^^^^^^^^^^^^^
   what: `end procedure.main` closes the procedure while the `if` on line 4 is still open
   why:  each block closes with its own `end`, inside out.
  [1]

An `if`'s body is indented one more level (D70).

  $ plainoracle nested_indent.plainly
  refused: nested_indent.plainly:5:1, line 5 column 1
   5 |     show_text("x");
     | ^^^^
   fix:  `        show_text("x");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

`ถ้า` and `ไม่งั้น` are Thai `if` and `else` (D57).

  $ plainoracle thai.เพลนลี่
  ผ่าน

Whether a variable declared inside an `if` lasts after `end if` isn't decided, so using it there stops.

  $ plainoracle block_variable.plainly
  NotDesignedYet: block_variable.plainly:7:15, line 7 column 15
   7 |     show_text(#message);
     |               ^^^^^^^^
   what: using `#message` after the block it was declared in isn't decided yet
  [3]
