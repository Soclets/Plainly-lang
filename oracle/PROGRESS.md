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
| 2. Variables, `Whole` and `Text`, `mut`, `change`, `+`, `&`, `be.Text` | Next |
| 3 to 9 | Not started |

## Slice 1

Runs: `procedure.main[none]:` with `show_text("…");` statements and `end procedure.main`, in English or Thai keywords
(`proc` works too), printing each text with a newline.

Refused, with D58's layout, tested:
- a missing `;` (D31), with the byte and grapheme columns differing for Thai text;
- a header missing its `:`, recovering and checking the body (D62), with every error shown (D58);
- `[]` with `fix: [none]` (D69);
- indentation other than 4 spaces per level, tabs included, and an indented closer (D70).

Stops, tested: a variable (`NotBuiltYet`), and English and Thai keywords mixed in one file (`NotDesignedYet`).

Traced decisions: D3, D12, D31, D44, D57, D58, D60, D62, D63, D69, D70.

Not built yet: D58's knock-on sorting (apply the first fix, check again, add `because:`). Nothing in slice 1 can cause a
knock-on error, so there's nothing to test it with yet. It's needed from slice 2, when a broken declaration can cause
later errors.

## Waiting for the owner

These are choices slice 1 had to make so that anything could run. They're provisional until the owner answers:
1. ~~Exit statuses~~: decided as D71.
2. ~~The layout of `NotBuiltYet` and `NotDesignedYet`~~: decided as D72.
3. **New wording,** written in D59's style and needing the owner's eye:
   - `why:  every statement ends with `;`.`
   - `why:  a block's opening line ends with `:`.`
   - `why:  a procedure that takes nothing says `[none]`.`
   - `why:  a body is indented 4 spaces per level, never with a tab.`
   - `what: a block's closer lines up with its opening line`, with `why:  only a body is indented, 4 spaces per level.`
   - `what: a procedure's opening line has no indentation` (built, not tested yet).
4. **The indentation fix** marks the indentation itself and shows four spaces as code, `` `    ` ``. When a line has no
   indentation, the `^` sits under its first letter, which can read as "replace this letter".
5. **Which language a message is in** when the file uses Thai keywords. Slice 1 writes every message in English.
6. **The file extension and command line.** `plainoracle <file>`, any file name.

## Assumptions to know about

- The caret line counts one screen column per grapheme. That's right for English and Thai, but not for wide characters
  like Chinese, which take two.
- A line's role for indentation comes from its first token: `procedure` and `end` lines are at level 0, everything else
  at level 1. That's only enough for slice 1, which has one block.
