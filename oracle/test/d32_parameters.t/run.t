A procedure can't change its parameters (D32, D95).

  $ plainoracle change_parameter.plainly
  refused: change_parameter.plainly:9:12, line 9 column 12
   9 |     change #health = #health + #amount;
     |            ^^^^^^^
   what: `#health` is a parameter, so it can't be changed
   why:  a procedure only reads its parameters, and gives a new value back instead.
  [1]
