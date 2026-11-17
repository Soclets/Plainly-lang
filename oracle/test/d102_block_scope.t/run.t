A variable declared inside a block ends with the block (D102). A `shadow` inside it ends too, a name can be declared
again after the block, and an outer `mutable` changed inside keeps its new value.

  $ plainoracle runs.plainly
  7
  again
  5
  outer

Using a block's variable after the block is refused (D81, D102).

  $ plainoracle used_after.plainly
  refused: used_after.plainly:7:15, line 7 column 15
   7 |     show_text(#message);
     |               ^^^^^^^^
   what: `#message` isn't declared before this line
   why:  a variable (#) is declared, with its type, before it's used.
  [1]
