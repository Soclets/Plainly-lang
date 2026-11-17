Labels (D8), declared on their own lines with defaults (D9), kept in order unless `labels.any_order` (D10), on
procedures declared after `procedure.main` (D96).

  $ plainoracle runs.plainly
  110
  115
  10: 3, 1
  10: 4, 2

A labelled argument written bare gets its label as the fix (D95).

  $ plainoracle bare_label.plainly
  refused: bare_label.plainly:5:28, line 5 column 28
   5 |     change #hp = heal(#hp, 300);
     |                            ^^^
   fix:  `by: 300`
   why:  `heal` labels this argument, so every call writes the label.
  [1]

A label the procedure doesn't declare is refused (D8, D95).

  $ plainoracle unknown_label.plainly
  refused: unknown_label.plainly:5:28, line 5 column 28
   5 |     change #hp = heal(#hp, with: 300);
     |                            ^^^^^
   what: `heal` has no label `with:`
   why:  a call writes only the labels its procedure declares.
  [1]

A label with no default can't be left off (D8, D95).

  $ plainoracle missing_label.plainly
  refused: missing_label.plainly:5:18, line 5 column 18
   5 |     change #hp = heal(#hp);
     |                  ^^^^^^^^^
   what: `heal` needs `by:`
   why:  only a label with a default can be left off.
  [1]

Labels are written in the order they're declared (D10, D95).

  $ plainoracle label_order.plainly
  refused: label_order.plainly:5:18, line 5 column 18
   5 |     change #hp = heal(#hp, times: 2, by: 300);
     |                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   fix:  `heal(#hp, by: 300, times: 2)`
   why:  labels are written in the order the procedure declares them, unless it says `labels.any_order`.
  [1]

`labels.in_order` is refused, since it's the default (D10, D95).

  $ plainoracle in_order.plainly
  refused: in_order.plainly:9:5, line 9 column 5
   9 |     labels.in_order [#amount as by];
     |     ^^^^^^^^^^^^^^^
   fix:  `labels`
   why:  keeping the order is already what `labels` does.
  [1]

A call gives each parameter once (D95).

  $ plainoracle too_many.plainly
  refused: too_many.plainly:5:18, line 5 column 18
   5 |     change #hp = heal(#hp, 7, by: 300);
     |                  ^^^^^^^^^^^^^^^^^^^^^
   what: `heal` takes 2 values, but this call gives 3
   why:  a call gives each of a procedure's parameters once.
  [1]

Procedures in Thai (D57).

  $ plainoracle thai.เพลนลี่
  สวัสดี มีอา
