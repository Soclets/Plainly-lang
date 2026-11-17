# 9. Messages

## The layout

```
refused: game.plainly:5:12, line 5 column 12
 5 |     change #lives = #lives - 1;
   |            ^^^^^^
 what: `#lives` isn't mutable
 why:  `change` only works on a variable (#) declared `mut`.
```

- **The first word is the kind** (D58):
  - `refused:` while building;
  - `check failed:` while running (D82);
  - `warning:`.
- **The place is written twice:** `file:line:column` for tools, counting the column in UTF-8 bytes, then `line N column
  M` for people, counting the column in graphemes, so the two differ in Thai (D58).
- **The source line is shown,** with `^` under exactly the part in question (D58).
- **Then the lines that are known,** in this order (D58, D82):
  - `fix:`, in place of `what:`, when there's exactly one fix (D60);
  - `what:` says what's wrong;
  - `when:` gives the values that broke the rule, for a failed check while running (D82);
  - `why:` gives the rule;
  - `because:` points back to an earlier error that caused this one.
- **No error codes,** and no "did you mean" guesses: only what's certain (D58, D60).
- **Every error is shown,** with no limit (D58).

**Not decided:** how a `warning:` is used; where `because:` goes among the other lines.

### `fix:`

A message has a `fix:` only when there's exactly one. Where there are several ways to fix it, it has a `what:` instead
(D60). An indentation fix shows the whole corrected line (D74):

```
refused: game.plainly:4:1, line 4 column 1
 4 | show_text("Hello, world!");
   | ^
 fix:  `    show_text("Hello, world!");`
 why:  a body is indented 4 spaces per level, never with a tab.
```

### `why:`

A `why:` line is a plain sentence a beginner can read, with no decision number. Where it names something the code
writes with a symbol, the symbol follows in parentheses, as in "variable (#)" (D59).

### `when:`

```
check failed: game.plainly:4:24, line 4 column 24
 4 |     change #big = #big + 1;
   |                        ^
 what: `#big + 1` is too big for a `Whole`
 when: `#big` is 9223372036854775807
 why:  a `Whole` holds whole numbers from -9223372036854775808 to 9223372036854775807.
```

Two values are joined with ", and" (D89).

## The wording

Each message's exact wording is a decision of its own: D73, D76, D80, D81, D83, D89, D90, D91, D93, D94, D95 and D101.

## Thai

A Thai file's messages are in Thai (D75), with code left as it's written and the `file:line:column` place unchanged
(D58). Their labels are (D61):

| English | Thai |
|---|---|
| `refused:` | `ไม่ผ่าน:` |
| `check failed:` | `หยุดทำงาน:` |
| `warning:` | `คำเตือน:` |
| `what:` | `ปัญหา:` |
| `why:` | `เหตุผล:` |
| `when:` | `เมื่อ:` |
| `because:` | `เพราะ:` |
| `fix:` | `วิธีแก้:` |
| `line N column M` | `บรรทัด N คอลัมน์ M` |

A variable is `ตัวแปร` in Thai messages, and a Thai `why:` says what the code has written on it, as in
`ที่เขียน `เปลี่ยนได้` ไว้`, not what was declared (D61).

**Not decided:** the Thai wording of every message's sentences.

## Against cascades

- **After an error, only that statement is skipped.** A broken declaration still creates its variable with its written
  type, so later lines don't fail because it "doesn't exist" (D58).
- **Knock-on errors are sorted out:** the first error's fix is applied in memory and the program checked again, and
  whatever disappears was caused by it, shown with a `because:` pointing back (D58).
- **After a broken block opener,** checking carries on into its body if it's clear what was meant, and stops there if it
  isn't (D62).

## Exit statuses

| Status | When |
|---|---|
| 0 | The program builds and runs to its end. |
| 1 | Anything is refused while building. |
| 2 | The file can't be read. |
| 3 | `NotBuiltYet` or `NotDesignedYet`: the implementation can't handle something yet. |
| 4 | A check failed while running. |

These hold for PlainOracle and AroundPy alike (D71, D82).

**Not decided:** the status for a failure leaving `procedure.main` (D63, D71).

## `NotBuiltYet` and `NotDesignedYet`

An implementation's own limits, not Plainly errors, use the same layout with their own name as the kind, a `what:` line,
and no `why:`. `NotBuiltYet` is for something decided but not built, and `NotDesignedYet` for something the decisions
don't cover yet. Each ends the check there, with exit status 3 (D72).

```
NotBuiltYet: game.plainly:3:5, line 3 column 5
 3 |     repeat 3 times:
   |     ^^^^^^
 what: `repeat` isn't in PlainOracle yet
```
