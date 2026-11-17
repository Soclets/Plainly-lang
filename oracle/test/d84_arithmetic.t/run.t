`-`, `x`, maths order and `( )` (D83, D84); division and remainders that name their rounding (D85); negatives (D86);
`.saturate` sticking at a type's written limits (D87, D88).

  $ plainoracle runs.plainly
  5
  15
  21
  3
  -4
  -3
  1
  -1
  -7
  14
  0
  100
  9

A bare `divide` on whole numbers is refused (D85, D89).

  $ plainoracle bare_divide.plainly
  refused: bare_divide.plainly:3:23, line 3 column 23
   3 |     show_text(be.Text(7 divide 2));
     |                       ^^^^^^^^^^
   what: `7 divide 2` doesn't say how to round
   why:  whole numbers divide with `.down`, `.toward_zero` or `.exact`.
  [1]

Dividing by zero is a failed check (D85, D89).

  $ plainoracle by_zero.plainly
  check failed: by_zero.plainly:5:26, line 5 column 26
   5 |     show_text(be.Text(#a divide.down #b));
     |                          ^^^^^^^^^^^
   what: `#a divide.down #b` divides by zero
   when: `#b` is 0
   why:  nothing can be divided by zero.
  [4]

Overflow on `-` works like on `+` (D84, D89).

  $ plainoracle too_small.plainly
  check failed: too_small.plainly:5:26, line 5 column 26
   5 |     show_text(be.Text(#a - #b));
     |                          ^
   what: `#a - #b` is too small for a `Whole`
   when: `#a` is -9223372036854775808, and `#b` is 1
   why:  a `Whole` holds whole numbers from -9223372036854775808 to 9223372036854775807.
  [4]

A value outside the written limits is refused where it can be seen (D88, D89),

  $ plainoracle above_max.plainly
  refused: above_max.plainly:3:40, line 3 column 40
   3 |     mut #hp: Whole[min: 0, max: 100] = 150;
     |                                        ^^^
   what: `150` is above `#hp`'s maximum of 100
   why:  a number stays within the limits written for its type.
  [1]

and is a failed check while running otherwise.

  $ plainoracle runtime_max.plainly
  check failed: runtime_max.plainly:4:18, line 4 column 18
   4 |     change #hp = #hp + 60;
     |                  ^^^^^^^^
   what: `#hp + 60` is above `#hp`'s maximum of 100
   when: `#hp` is 50
   why:  a number stays within the limits written for its type.
  [4]

  $ plainoracle runtime_min.plainly
  check failed: runtime_min.plainly:4:18, line 4 column 18
   4 |     change #hp = #hp - 60;
     |                  ^^^^^^^^
   what: `#hp - 60` is below `#hp`'s minimum of 0
   when: `#hp` is 50
   why:  a number stays within the limits written for its type.
  [4]

Mixing `&` with arithmetic needs `( )` (D83).

  $ plainoracle mixed_times.plainly
  refused: mixed_times.plainly:4:24, line 4 column 24
   4 |     show_text("n" & #a x 2);
     |                        ^
   what: `x` and `&` are mixed without `( )`
   why:  maths doesn't say which goes first, so `( )` shows it.
  [1]
