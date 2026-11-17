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
`opam install --switch=./oracle dune uuseg ocamlformat`, from the repository root.

## Slices

| Slice | State |
|---|---|
| 1. Hello world, English and Thai, the error format, `;`, `[none]`, indentation | Done, 2026-11-17 |
| 2. Variables, `Whole` and `Text`, `mut`, `change`, `+`, `&`, `be.Text` | Done, 2026-11-17 |
| 3. `show_text.format`, braces, `\{`, `new_line`, `be.Text.format`, `.same_line` | Done, 2026-11-17 |
| 4. `if`, `else if`, `else`, comparisons, `and`/`or`/`not`, D50 | Next |
| 5 to 9 | Not started |

## Slice 1

Runs: `procedure.main[none]:` with `show_text("…");` statements and `end procedure.main`, in English or Thai keywords
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

Stops, tested: `Whole` in a Thai file, since its Thai word isn't decided. `เปลี่ยนได้` is Thai `mutable` (D57). Declaring a name again needs `shadow`, which may change its type, and `shadow mutable` works too; a redeclaration
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
- A line's role for indentation comes from its first token: `procedure` and `end` lines are at level 0, everything else
  at level 1. That's only enough for slice 1, which has one block.

## Wording

All wording so far is approved: D73, D76, D80, D81, D82, D83, D89, D90 and D91.

## Questions slice 2 raised

1. ~~How a failed check is reported while running~~: decided as D82, and built.
2. ~~Which goes first when `+` and `&` are mixed~~: decided as D83 (follow maths, brackets where maths doesn't say),
   and built.
3. ~~`-`, `*` and division~~: decided as D84 to D89, and built.
4. ~~`be.Text` of something that's already `Text`~~: refused, as D90, and built.
5. ~~Declaring the same name twice~~: `shadow` in front, as D91, and built.
6. The Thai words for `change`, `shadow`, `be`, `Whole` and `Text` (`mutable` is `เปลี่ยนได้`).
7. Other ways of writing numbers, like `1_000`.

## Questions slice 3 raised

8. `{}`, and words other than `new_line` in braces.
9. Settings in braces, like a width or decimal places (D7 left them open).
10. `.format` of text that isn't written in quotes, like a variable holding a template.
