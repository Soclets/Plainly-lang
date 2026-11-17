Empty brackets are refused, with `[none]` as the fix (D69).

  $ plainoracle empty_brackets
  refused: empty_brackets:1:15, line 1 column 15
   1 | procedure.main[]:
     |               ^^
   fix:  `[none]`
   why:  a procedure that takes nothing says `[none]`.
  [1]
