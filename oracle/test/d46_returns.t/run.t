A procedure returns its result with `return` (D46), and can call itself.

  $ plainoracle runs.plainly
  120
  3
  2
  1

A returned value has the header's type (D95).

  $ plainoracle wrong_type.plainly
  refused: wrong_type.plainly:9:12, line 9 column 12
   9 |     return "x";
     |            ^^^
   what: `"x"` is `Text`, but `heal` returns a `Whole`
   why:  a procedure returns the type its header says.
  [1]

Every way through a procedure with a result returns (D95).

  $ plainoracle missing_return.plainly
  refused: missing_return.plainly:11:1, line 11 column 1
  11 | end procedure sign
     | ^^^^^^^^^^^^^^^^^^
   what: `sign` can reach its end without returning a `Whole`
   why:  every way through a procedure that returns something ends in `return`.
  [1]
