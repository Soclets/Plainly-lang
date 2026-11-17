A body is indented 4 spaces, and anything else is refused (D70).

  $ plainoracle two_spaces
  refused: two_spaces:2:1, line 2 column 1
   2 |   show_text("Hello, World!");
     | ^^
   fix:  `    show_text("Hello, World!");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

A tab is refused too.

  $ plainoracle tab
  refused: tab:2:1, line 2 column 1
   2 | 	show_text("Hello, World!");
     | ^
   fix:  `    show_text("Hello, World!");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

So is a body with no indentation.

  $ plainoracle not_indented
  refused: not_indented:2:1, line 2 column 1
   2 | show_text("Hello, World!");
     | ^
   fix:  `    show_text("Hello, World!");`
   why:  a body is indented 4 spaces per level, never with a tab.
  [1]

A closer lines up with its opening line.

  $ plainoracle indented_closer
  refused: indented_closer:3:1, line 3 column 1
   3 |     end procedure.main
     | ^^^^
   what: a block's closer lines up with its opening line
   why:  only a body is indented, 4 spaces per level.
  [1]
