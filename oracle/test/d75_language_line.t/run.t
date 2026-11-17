A file that says `English` and uses a Thai keyword is refused, with the English word as the fix (D57, D75).

  $ plainoracle mixed
  refused: mixed:3:5, line 3 column 5
   3 |     แสดงข้อความ("สวัสดี");
     |     ^^^^^^^^^^
   fix:  `show_text`
   why:  this file says `English`, so its keywords are English.
  [1]

A file must start with its language (D75).

  $ plainoracle no_language
  refused: no_language:1:1, line 1 column 1
   1 | procedure.main[none]:
     | ^
   what: the file doesn't say its language
   why:  a file starts with its language: `English` or `ไทย`.
  [1]

A Thai file's messages are in Thai, and only their labels are decided so far (D61, D75).

  $ plainoracle thai_refusal
  NotDesignedYet: thai_refusal:3:60, line 3 column 23
   3 |     แสดงข้อความ("สวัสดี")
     |                       ^
   what: the Thai wording of this message isn't decided yet
  [3]
