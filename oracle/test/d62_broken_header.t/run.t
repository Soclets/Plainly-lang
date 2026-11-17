A header missing its `:` is clear, so checking carries on into the body, and every error is shown (D58, D62).

  $ plainoracle broken.plainly
  refused: broken.plainly:2:37, line 2 column 37
   2 | procedure.main[none] returns nothing
     |                                     ^
   fix:  `:`
   why:  a block's opening line ends with `:`.
  
  refused: broken.plainly:3:21, line 3 column 21
   3 |     show_text("one")
     |                     ^
   fix:  `;`
   why:  every statement ends with `;`.
  [1]
