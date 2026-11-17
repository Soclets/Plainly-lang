A statement with no `;` is refused, with the one fix (D31, D58, D59, D60).

  $ plainoracle missing_semicolon
  refused: missing_semicolon:2:31, line 2 column 31
   2 |     show_text("Hello, World!")
     |                               ^
   fix:  `;`
   why:  every statement ends with `;`.
  [1]

With Thai text before the place, the column for tools counts bytes and the one for people counts graphemes (D58, D61).

  $ plainoracle thai_text
  refused: thai_text:2:36, line 2 column 22
   2 |     show_text("สวัสดี")
     |                      ^
   fix:  `;`
   why:  every statement ends with `;`.
  [1]
