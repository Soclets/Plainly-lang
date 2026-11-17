`be.Text` of something that's already `Text` is refused, with the value itself as the fix (D90).

  $ plainoracle same.plainly
  refused: same.plainly:4:15, line 4 column 15
   4 |     show_text(be.Text(#name));
     |               ^^^^^^^^^^^^^^
   fix:  `#name`
   why:  `#name` is already `Text`, so there's nothing to convert.
  [1]
