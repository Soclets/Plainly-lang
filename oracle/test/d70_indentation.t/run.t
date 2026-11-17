A body is indented 4 spaces, and anything else is refused, with the whole corrected line as the fix (D70, D74).

  $ plainoracle two_spaces.plainly
  refused: two_spaces.plainly:3:1, line 3 column 1
   3 |   show_text("Hello, World!");
     | ^^
   fix:  `    show_text("Hello, World!");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

A tab is refused too.

  $ plainoracle tab.plainly
  refused: tab.plainly:3:1, line 3 column 1
   3 | 	show_text("Hello, World!");
     | ^
   fix:  `    show_text("Hello, World!");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

So is a body with no indentation.

  $ plainoracle not_indented.plainly
  refused: not_indented.plainly:3:1, line 3 column 1
   3 | show_text("Hello, World!");
     | ^
   fix:  `    show_text("Hello, World!");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

A closer lines up with its opening line.

  $ plainoracle indented_closer.plainly
  refused: indented_closer.plainly:4:1, line 4 column 1
   4 |     end procedure.main
     | ^^^^
   what: a block's closer lines up with its opening line
   why:  only a body is indented, 4 spaces per level.
  [1]
