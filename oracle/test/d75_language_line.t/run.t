A file that says `english` and uses a Thai keyword is refused, with the English word as the fix (D57, D75).

  $ plainoracle mixed.plainly
  refused: mixed.plainly:3:5, line 3 column 5
   3 |     แสดงข้อความ("สวัสดี");
     |     ^^^^^^^^^^
   fix:  `show_text`
   why:  this file says `english`, so its keywords are English.
  [1]

A file must start with its language (D75, D77).

  $ plainoracle no_language.plainly
  refused: no_language.plainly:1:1, line 1 column 1
   1 | procedure.main[none]:
     | ^
   what: the file doesn't say its language
   why:  a file starts with its language: `english` or `ไทย`.
  [1]

A Thai file's messages are in Thai, and only their labels are decided so far (D61, D75).

  $ plainoracle thai_refusal.เพลนลี่
  NotDesignedYet: thai_refusal.เพลนลี่:3:60, line 3 column 23
   3 |     แสดงข้อความ("สวัสดี")
     |                       ^
   what: the Thai wording of this message isn't decided yet
  [3]

`eng` is the short form of `english`, and a refusal quotes the word the file wrote (D77).

  $ plainoracle eng_mixed.plainly
  refused: eng_mixed.plainly:3:5, line 3 column 5
   3 |     แสดงข้อความ("Hi");
     |     ^^^^^^^^^^
   fix:  `show_text`
   why:  this file says `eng`, so its keywords are English.
  [1]

A file's extension must match its language line (D79, D80).

  $ plainoracle mismatch.plainly
  refused: mismatch.plainly:1:1, line 1 column 1
   1 | ไทย
     | ^^^
   what: this file says `ไทย`, but its name ends in `.plainly`
   why:  a file's name ends in `.plainly` for English and `.เพลนลี่` for Thai.
  [1]

Any other extension is refused too.

  $ plainoracle other.txt
  refused: other.txt:1:1, line 1 column 1
   1 | english
     | ^^^^^^^
   what: this file's name doesn't end in `.plainly` or `.เพลนลี่`
   why:  a file's name ends in `.plainly` for English and `.เพลนลี่` for Thai.
  [1]
