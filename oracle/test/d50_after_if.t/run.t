After an `if` that always leaves, the rest goes in its `else:` (D50).

  $ plainoracle runs.plainly
  Hi, Mia!

Code after such an `if` is refused (D50, D95).

  $ plainoracle after_if.plainly
  refused: after_if.plainly:11:5, line 11 column 5
  11 |     show_text.format("Hi, {#name}!");
     |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   what: this line comes after an `if` that always leaves
   why:  after an `if` that always leaves, the rest goes in its `else:`.
  [1]
