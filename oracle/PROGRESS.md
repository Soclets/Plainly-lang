# PlainOracle progress

Read this, `git log`, and the test results after every compaction, before doing anything else. The prompt is
`design/plainoracle-prompt.md`.

## How to build and test

PlainOracle has its own opam switch in `oracle/_opam` (ignored by git), on the system OCaml 5.5, with `dune`, `uuseg`
and `ocamlformat`. From `oracle/`:

```
opam exec --switch=. -- dune build
opam exec --switch=. -- dune test
opam exec --switch=. -- dune fmt
```

To recreate the switch: `opam switch create ./oracle ocaml-system --no-install`, then
`opam install --switch=./oracle dune uuseg uunf ocamlformat`, from the repository root.

## Slices

| Slice | State |
|---|---|
| 1. Hello world, English and Thai, the error format, `;`, `[none]`, indentation | Done, 2026-11-17 |
| 2. Variables, `Whole` and `Text`, `mut`, `change`, `+`, `&`, `be.Text` | Done, 2026-11-17 |
| 3. `show_text.format`, braces, `\{`, `new_line`, `be.Text.format`, `.same_line` | Done, 2026-11-17 |
| 4. `if`, `else if`, `else`, comparisons, `and`/`or`/`not`, D50 | Done, 2026-11-17, except D50 |
| 5. Procedures with parameters, results, labels, defaults, the pipe | Done, 2026-11-17 |
| 6 to 9 | Not started |

## Slice 1

Runs: `procedure.main[none]:` (now `procedure.main[none] returns nothing:`, D100) with `show_text("…");` statements and `end procedure.main`, in English or Thai keywords
(`proc` works too), printing each text with a newline.

Refused, with D58's layout, tested:
- a missing `;` (D31), with the byte and grapheme columns differing for Thai text;
- a header missing its `:`, recovering and checking the body (D62), with every error shown (D58);
- `[]` with `fix: [none]` (D69);
- indentation other than 4 spaces per level, tabs included, and an indented closer (D70).

Also refused, tested: a file with no language line, a keyword from the other table than the file's language (D75),
and an extension that doesn't match the language line (`.plainly` for English, `.เพลนลี่` for Thai), or any other
extension (D79, D80).

Stops, tested: a variable (`NotBuiltYet`), and any refusal in a Thai file (`NotDesignedYet`, until Thai sentences are
decided).

Traced decisions: D3, D12, D31, D44, D57, D58, D60, D61, D62, D63, D69, D70, D74, D75, D77, D79, D80. The wording of
D75's refusals is D76.

Not built yet: D58's knock-on sorting (apply the first fix, check again, add `because:`). Nothing in slice 1 can cause a
knock-on error, so there's nothing to test it with yet. It's needed from slice 2, when a broken declaration can cause
later errors.

## Slice 2

Runs: declarations with written types, `#name: Text = "Mia";` and `mut #score: Whole = 10;` (`mutable` too), `change`,
`+` on `Whole`, `&` on `Text`, `be.Text` of a `Whole`, brackets for grouping, and `show_text` of any `Text` expression.

Refused, tested: `change` on a variable that isn't `mut`; a value of the wrong type; `+` on text, with `fix: &`; a number
joined with `&` or passed to `show_text`, with `fix: be.Text(…)`; a variable used before its declaration; a number too
big for a `Whole`. A refused declaration still creates its variable with its written type (D58), tested.

A failed check, tested: overflow stops with `check failed:`, a `when:` line naming the variables' values, and exit
status 4 (D82). With two variables, the `when:` line joins them with ", and", which isn't tested or reviewed yet.

Refused, tested: `+` and `&` mixed without brackets (D83). The mixed expression's type becomes unknown, so nothing
after it is refused because of it.

Runs, tested: a whole Thai program with `เปลี่ยนได้`, `เปลี่ยน`, `จำนวนเต็ม`, `ข้อความ` and `เป็น` (D57). `Whole` in a Thai
file is the other table's word, so it's refused, which shows as `NotDesignedYet` until Thai sentences are worded. Declaring a name again needs `shadow`, which may change its type, and `shadow mutable` works too; a redeclaration
without it is refused (D91), tested. Numbers written with anything but digits are `NotDesignedYet`. `be.Text`
of `Text` is refused, with the value as the fix (D90), tested.

Traced decisions added: D1, D6, D19, D27, D28, D51, D71, D82, D83.

## Slice 3

Runs: `show_text.format` and `be.Text.format`, with `{#name}` filled in (numbers converted) and `{new_line}`; `\{` and
`\"` inside `.format`; a lone `}` as a character; plain `show_text` staying literal; `.same_line`, alone or as
`.format.same_line`; `new_line` as a word joined with `&`.

Refused, tested: `.same_line.format`, with `fix: show_text.format.same_line` (D14); a calculation in braces (D7); a `{`
with no `}`; an undeclared variable in braces.

Stops, tested: `\` before a letter, and `\` in text outside `.format` (D3); fields in braces (D7). Also built: settings
in braces like a width, `{}` and other words in braces, and `.format` of text not written in quotes, all
`NotDesignedYet`.

Traced decisions added: D2, D3, D4, D5, D7, D11, D12, D13, D14.

## Arithmetic (slice 2, continued)

Runs: `-`, `x`, maths order with `( )` (D83, D84); `divide.down`, `divide.toward_zero`, `remainder.down`,
`remainder.toward_zero`, and `div` and `mod` (D85); negatives like `-7` and `-#a` (D86); `plus.saturate`,
`minus.saturate` and `times.saturate` sticking at a type's written limits, `Whole[min: 0, max: 100]` with `minimum` and
`maximum` too (D87, D88).

Refused, tested: a bare `divide` on whole numbers; a written number outside a variable's limits; `&` mixed with `x`
(D83, D89). A `+` on text sitting next to `&` gets only the mixing refusal, not both.

Failed checks, tested: dividing by zero; overflow on `-`; storing outside the limits, above and below (D82, D85, D88,
D89). Built but not tested yet: overflow on `x`, negating the lowest `Whole`, and `remainder` by zero.

Stops: `divide.exact` (`NotBuiltYet`, since failures aren't built); a `-` without a space on each side between two
values, a bare `plus`, and `max:` written before `min:` (`NotDesignedYet`).

Traced decisions added: D84, D85, D86, D87, D88, D89.

## Slice 4

Runs: `if`, `else if`, `else` and `end if`, nested, with each block's body indented one more level, which is now
checked from the level each line's statement was found at (D35, D70); `==`, `!=`, `<`, `>`, `at_least` and `at_most`
on whole numbers (D34); `not`, then `and`, then `or` (D92), short-circuiting, with `and.both` and `or.both` (D36, D37);
`compare_Text.stored_same` and `compare_Text.looks_same`, normalizing with `uunf` (D94); `ถ้า` and `ไม่งั้น` in Thai.

Refused, tested: a lone `=` in a condition, with `fix: ==`; `==` between two `Text`s; comparing different types; an
`if` given a plain value; a missing `end if`; a block's body at the wrong level (D93, D94).

Stops: using or declaring again a variable declared inside an `if`, after its `end if`, since block scope isn't
decided (found by Mult's Claude, 2026-11-17: before, the checker let it through and the oracle crashed with OCaml's
`Not_found`); chains of comparisons, ordering text with `<`, comparing true or false values, and true or false values outside
an `if` (`NotDesignedYet`); `<` or `>` without spaces (`NotBuiltYet`).

D50 is built in slice 5, with `return`. The Thai words for `and`, `or`, `not`, `at_least`,
`at_most`, `compare_Text` and its methods aren't decided, so those stop in Thai files.

Traced decisions added: D34, D35, D36, D37, D92, D93, D94.

The opam switch now also has `uunf`.

## Slice 5

Runs: procedures with parameters and a result, `procedure name[#a: Whole, #b: Text] returns Whole:`, closed by
`end procedure name`, in any order in the file (D96), calling each other and themselves; `return` with or without a
value; `labels`, `labels.any_order` and `defaults` lines (D8 to D10); `units` lines, with a written number's unit word
compared (D45, D47, D48); a parameter's limits checked when it's given a value, while building for a written number and
while running otherwise (D88); the pipe, `|>`, with bare steps, steps with labels, `be.Text` and `show_text` as steps,
taking all of a calculation or joined text on its left (D29, D30, D97); a procedure with no result called as a statement; procedures in Thai files, as long as they use no word
whose Thai isn't decided.

Refused, tested, with D95's wording: a labelled argument written bare; an undeclared label; a missing label with no
default; labels out of order; `labels.in_order`; too many arguments; an unused result, also at the end of a pipe (D26);
`change` on a parameter (D32); a returned value of the wrong type; a procedure with a result that can reach its end
without `return`; a call to `procedure.main` (D63); a written number without its unit or with another one; a line after
an `if` with no `else` whose every branch leaves (D50). A wrong-typed argument uses D81's wording, untested.

Stops (`NotDesignedYet`), each a refusal whose wording or rule isn't decided: leaving out a value without a label;
`shadow` on a parameter; a line after an `if` where only some ways leave, or where every way leaves through an `else`
too; a bare `return;` in a procedure that returns a value; a result on `procedure.main`; `|>` into `show_text` from a number, `show_text.format` and `be.Text.format` as steps, `( )` on
a step, and an unlabelled value in a step; a label, default or unit for something that isn't a parameter, a default or
unit on a parameter without a label, a unit on a parameter that isn't `Whole`, and a unit word on anything but a written
number; `labels`, `defaults` and `units` lines out of order; a default that isn't a written value; limits on a result;
two procedures with one name, a second `procedure.main`, a file without one, and a closer with another name; a line that
only works out a value.

Stops (`NotBuiltYet`): a call to a name that isn't a procedure in the file, since it may be the standard library; calls
and pipes written over several lines; `fails` in a header (slice 8).

Not built yet: `external.rust procedure` (D40), `package::` (D39), and the Thai words for `labels`, `defaults`, `units`,
`as` and `in`, which aren't decided, so they stop in Thai files.

Traced decisions added: D8, D9, D10, D26, D29, D30, D32, D45, D46, D47, D48, D50, D95, D96, D97.

## Returns and `return nothing` (slice 5, continued)

Runs: every header says what it gives back, `returns Whole` or `returns nothing`, `procedure.main` included, and a
procedure that returns nothing leaves early with `return nothing;` (D100); `คืน` for both `returns` and `return`, and
`ไม่มีอะไร` for `nothing`, in Thai files (D57). Every test program now has `returns nothing` on its headers.

Refused, tested, with D101's wording: a header with no `returns`, with the fix naming the type of the body's first
returned value or `nothing`; a bare `return;`; `return nothing` as a procedure's last line; a line after `return` in the
same block (D98); `return nothing` in a procedure that returns a value; a value returned from a procedure that returns
nothing, `procedure.main` included; using what a `returns nothing` procedure gives as a value, whose type then becomes
unknown so nothing after is refused because of it.

Traced decisions added: D98, D99, D100, D101.

## Waiting for the owner

These are choices slice 1 had to make so that anything could run. They're provisional until the owner answers:
1. ~~Exit statuses~~: decided as D71.
2. ~~The layout of `NotBuiltYet` and `NotDesignedYet`~~: decided as D72.
3. ~~New wording~~: decided as D73.
4. ~~The indentation fix~~: decided as D74, and built.
5. ~~Which language a message is in~~: decided as D75 and D77 (a required first line, `english`, `eng` or `ไทย`), and built. A Thai
   file's first refusal stops with `NotDesignedYet`, since only the Thai labels are decided (D61), not the sentences.
6. ~~The file extension and command line~~: decided as D78 and D79. PlainOracle stays `plainoracle <file>`, since
   it's the oracle, not `apy`.

## Assumptions to know about

- The caret line counts one screen column per grapheme. That's right for English and Thai, but not for wide characters
  like Chinese, which take two.
- A procedure's arguments are worked out in the order they're written, and defaults after them.

## Wording

All wording so far is approved: D73, D76, D80, D81, D82, D83, D89, D90, D91, D93, D94 and D95.

## Questions slice 2 raised

1. ~~How a failed check is reported while running~~: decided as D82, and built.
2. ~~Which goes first when `+` and `&` are mixed~~: decided as D83 (follow maths, brackets where maths doesn't say),
   and built.
3. ~~`-`, `*` and division~~: decided as D84 to D89, and built.
4. ~~`be.Text` of something that's already `Text`~~: refused, as D90, and built.
5. ~~Declaring the same name twice~~: `shadow` in front, as D91, and built.
6. ~~Thai words for what's built~~: every built keyword has a Thai word now, all built and tested, including the
   arithmetic words (`หาร`, `หาเศษ`, `.ปัดลง`, `.ตัดเศษ`, `.ลงตัว`, `บวก`, `ลบ`, `คูณ`, `.ไม่เกิน`, `ต่ำสุด`, `สูงสุด`). Decided: `mutable` `เปลี่ยนได้`, `change` `เปลี่ยน`, `shadow` `บัง`, `be` `เป็น`, `Whole`
   `จำนวนเต็ม`, `Text` `ข้อความ`.
7. Other ways of writing numbers, like `1_000`.

## Questions slice 3 raised

8. `{}`, and words other than `new_line` in braces.
9. Settings in braces, like a width or decimal places (D7 left them open).
10. `.format` of text that isn't written in quotes, like a variable holding a template.

## Questions slice 5 raised

11. The wording for the slice 5 stops listed above, most of all a call leaving out a value without a label. (Using what
    a procedure that returns nothing gives, and a `return` that doesn't match its header, are D101.)
12. `shadow` on a parameter.
13. ~~Code after `return` in the same block~~: refused, as D98. Still open: code after an `if` where only some ways
    leave.
14. ~~Whether `|>` comes after `+` and `&`~~: decided as D97, and built.
15. Thai words for `labels`, `defaults`, `units`, `as` and `in`. (`returns` and `return` are `คืน`, and `nothing` is
    `ไม่มีอะไร`.)
16. Block scope: whether a variable declared inside a block lasts after the block ends.
