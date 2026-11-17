Empty brackets are refused, with `[none]` as the fix (D69).

  $ plainoracle empty_brackets
  refused: empty_brackets:2:15, line 2 column 15
   2 | procedure.main[]:
     |               ^^
   fix:  `[none]`
   why:  a procedure that takes nothing says `[none]`.
  [1]
