Every header says what its procedure gives back, even nothing (D100, D101).

  $ plainoracle missing_returns.plainly
  refused: missing_returns.plainly:3:21, line 3 column 21
   3 | procedure.main[none]:
     |                     ^
   fix:  `returns nothing`
   why:  a header says what its procedure gives back, even when that's nothing.
  [1]

When the body returns a value, the fix names its type (D101).

  $ plainoracle missing_returns_value.plainly
  refused: missing_returns_value.plainly:7:28, line 7 column 28
   7 | procedure double[#n: Whole]:
     |                            ^
   fix:  `returns Whole`
   why:  a header says what its procedure gives back, even when that's nothing.
  [1]

A `return` with no value says `nothing` (D99, D100, D101).

  $ plainoracle bare_return.plainly
  refused: bare_return.plainly:5:9, line 5 column 9
   5 |         return;
     |         ^^^^^^
   fix:  `return nothing`
   why:  `return` is followed by what the procedure gives back.
  [1]

`return nothing` as the last line does nothing, so it's refused (D99, D101).

  $ plainoracle last_line.plainly
  refused: last_line.plainly:5:5, line 5 column 5
   5 |     return nothing;
     |     ^^^^^^^^^^^^^^
   what: `return nothing` is the last line, so it does nothing
   why:  a procedure leaves by itself at its end.
  [1]

A line after `return` in the same block never runs, so it's refused (D98, D101).

  $ plainoracle after_return.plainly
  refused: after_return.plainly:5:5, line 5 column 5
   5 |     show_text("never shown");
     |     ^^^^^^^^^^^^^^^^^^^^^^^^^
   what: this line comes after `return`, so it never runs
   why:  `return` leaves straight away, so nothing after it in the same block runs.
  [1]

A `return` matches its header (D101).

  $ plainoracle nothing_in_whole.plainly
  refused: nothing_in_whole.plainly:9:9, line 9 column 9
   9 |         return nothing;
     |         ^^^^^^^^^^^^^^
   what: `double` returns a `Whole`, not nothing
   why:  a procedure returns the type its header says.
  [1]

  $ plainoracle value_in_nothing.plainly
  refused: value_in_nothing.plainly:9:12, line 9 column 12
   9 |     return #name;
     |            ^^^^^
   what: `#name` is `Text`, but `greet` returns nothing
   why:  a procedure returns the type its header says.
  [1]

What a `returns nothing` procedure gives can't be used as a value (D101).

  $ plainoracle nothing_as_value.plainly
  refused: nothing_as_value.plainly:4:16, line 4 column 16
   4 |     #x: Text = greet("Mia");
     |                ^^^^^^^^^^^^
   what: `greet("Mia")` returns nothing, so there's no value to use
   why:  a procedure that returns nothing is called on a line of its own.
  [1]

`คืน` is `returns` and `return`, and `ไม่มีอะไร` is `nothing` (D57).

  $ plainoracle thai_runs.เพลนลี่
  2
