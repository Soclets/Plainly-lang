A procedure with no result is called as a statement of its own.

  $ plainoracle runs.plainly
  Hi, Mia!

A result that isn't used is refused (D26, D95).

  $ plainoracle ignored.plainly
  refused: ignored.plainly:5:5, line 5 column 5
   5 |     heal(#hp, by: 300);
     |     ^^^^^^^^^^^^^^^^^^
   what: `heal(#hp, by: 300)` gives a `Whole`, and it isn't used
   why:  a result that's thrown away is usually a bug, so it's refused.
  [1]

The same at the end of a pipe (D26, D30).

  $ plainoracle ignored_pipe.plainly
  refused: ignored_pipe.plainly:5:5, line 5 column 5
   5 |     #hp |> heal(by: 300);
     |     ^^^^^^^^^^^^^^^^^^^^
   what: `#hp |> heal(by: 300)` gives a `Whole`, and it isn't used
   why:  a result that's thrown away is usually a bug, so it's refused.
  [1]
