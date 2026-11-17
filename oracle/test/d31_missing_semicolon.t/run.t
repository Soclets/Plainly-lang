A statement with no `;` is refused, with the one fix (D31, D58, D59, D60).

  $ plainoracle missing_semicolon.plainly
  refused: missing_semicolon.plainly:3:31, line 3 column 31
   3 |     show_text("Hello, World!")
     |                               ^
   fix:  `;`
   why:  every statement ends with `;`.
  [1]

With Thai text before the place, the column for tools counts bytes and the one for people counts graphemes (D58, D61).

  $ plainoracle thai_text.plainly
  refused: thai_text.plainly:3:36, line 3 column 22
   3 |     show_text("สวัสดี")
     |                      ^
   fix:  `;`
   why:  every statement ends with `;`.
  [1]
