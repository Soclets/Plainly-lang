A header missing its `:` is clear, so checking carries on into the body, and every error is shown (D58, D62).

  $ plainoracle broken
  refused: broken:1:21, line 1 column 21
   1 | procedure.main[none]
     |                     ^
   fix:  `:`
   why:  a block's opening line ends with `:`.
  
  refused: broken:2:21, line 2 column 21
   2 |     show_text("one")
     |                     ^
   fix:  `;`
   why:  every statement ends with `;`.
  [1]
