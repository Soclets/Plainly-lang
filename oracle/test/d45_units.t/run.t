A number for a parameter with a unit says the unit, and a variable doesn't (D45, D47, D48).

  $ plainoracle runs.plainly
  1 at 300, 2
  2 at 7, 3

A written number without its unit is refused (D45, D95).

  $ plainoracle missing_unit.plainly
  refused: missing_unit.plainly:4:21, line 4 column 21
   4 |     draw(1, across: 300, down: 2 pixels);
     |                     ^^^
   fix:  `300 pixels`
   why:  `across:` is in pixels, so a number written here says so.
  [1]

So is one with another unit (D45, D95).

  $ plainoracle wrong_unit.plainly
  refused: wrong_unit.plainly:4:21, line 4 column 21
   4 |     draw(1, across: 300 seconds, down: 2 pixels);
     |                     ^^^^^^^^^^^
   fix:  `300 pixels`
   why:  `across:` is in pixels, so a number written here says so.
  [1]
