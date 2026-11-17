`procedure.main` can't be called (D63, D95).

  $ plainoracle main_call.plainly
  refused: main_call.plainly:5:5, line 5 column 5
   5 |     procedure.main();
     |     ^^^^^^^^^^^^^^^^
   what: `procedure.main` can't be called
   why:  `procedure.main` runs once, when the program starts.
  [1]
