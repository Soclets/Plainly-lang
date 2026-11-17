`shadow` declares a name again, and may change its type; `shadow mutable` makes the new one changeable (D91).

  $ plainoracle runs.plainly
  ten
  4

Declaring a name again without `shadow` is refused, with no fix, since `change` might be what was meant (D91).

  $ plainoracle twice.plainly
  refused: twice.plainly:4:5, line 4 column 5
   4 |     #score: Whole = 20;
     |     ^^^^^^
   what: `#score` is already declared on line 3
   why:  a variable (#) is declared once, unless `shadow` declares it again.
  [1]

`shadow` on a name that isn't declared yet isn't decided (D91).

  $ plainoracle shadow_new.plainly
  NotDesignedYet: shadow_new.plainly:3:12, line 3 column 12
   3 |     shadow #score: Whole = 10;
     |            ^^^^^^
   what: `shadow` on `#score`, which isn't declared yet, isn't decided yet
  [3]
