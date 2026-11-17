# 5. Expressions

## Order

From tightest to loosest (D83, D84, D86, D92, D97):

1. `-` negating, as in `-7` or `-#speed`
2. `x`, `divide` and `remainder`
3. `+` and `-`
4. `&`, which needs `( )` wherever it meets 2 or 3
5. comparisons: `==`, `!=`, `<`, `>`, `at_least`, `at_most`
6. `not`
7. `and`
8. `or`

Where maths has an order, Plainly follows it. Where maths doesn't say, as when `+` or `x` meets `&`, `( )` is
required, and a mix without it is refused (D83, D89). So `#a + #b & "!"` is refused, and `(#a + #b) & "!"` isn't, though
`&` still needs text on both sides (D6):

```
#line: Text = be.Text(#a + #b) & "!";
```

`( )` groups anything (D51). The pipe, `|>`, takes everything on its left after maths and `&` (D97).

**Not decided:** where the pipe sits against comparisons and logic.

## Arithmetic

`+` adds, `-` subtracts, and `x` multiplies, the sign taught at school. There's no `*` (D84):

```
#total: Whole = #price x #count;
#left: Whole = #lives - 1;
```

Going past a type's range is a failed check that depends on the build mode, the same for every operator (D84, chapter
3).

A `-` with no space after it negates; subtracting has a space on each side (D86).

### Dividing

Whole-number division says how it rounds (D85):

```
#each: Whole = 7 divide.down 2;
#each: Whole = 7 divide.toward_zero 2;
#each: Whole = 8 divide.exact 2;
```

- `.down` rounds down: -7 divided by 2 is -4.
- `.toward_zero` cuts the fraction off: -7 divided by 2 is -3, as in C and Java.
- `.exact` doesn't accept a remainder. A remainder is a failure the program handles, `has_remainder` (chapter 8).
- A bare `divide` on whole numbers is refused, and the message names the three roundings. Floats get a plain `divide`.
- `div` is the short form of `divide` (D84).

Dividing by zero is a failed check, depending on the build mode: it stops with exit status 4 in `Working` and
`FinalSafe`, and isn't checked in `FinalPerf` (D85).

The remainder matches its division, with `mod` as its short form (D85):

```
#left: Whole = 7 remainder.down 2;
#left: Whole = 7 remainder.toward_zero 2;
```

-7 `remainder.down` 2 is 1, and -7 `remainder.toward_zero` 2 is -1.

### Sticking at a limit

`plus.saturate`, `minus.saturate` and `times.saturate` stick at the limit instead of failing a check, the same in every
build mode (D87). The limit is the type's range, or the limits written on the variable it goes into (D88):

```
mutable #hp: Whole[min: 0, max: 100] = 100;
change #hp = #hp minus.saturate 30;
```

**Not decided:** a `.wrap` form; whether a bare `plus`, `minus` or `times` is refused (D87).

## Joining text

`&` joins text: `"Hello, " & #name` (D1). It doesn't turn a number into text by itself, so a number is converted with
`be.Text` first (D6):

```
show_text("Score: " & be.Text(#score) & new_line & "Well done!");
```

`+` on text is refused, with `&` as the fix (D1, D81).

## Filling in text

`.format` fills in what's in braces (D2, D4):

```
show_text.format("{#name} has {#score} points.");
#line: Text = be.Text.format("Level {#level}");
```

- **`show_text.format`** shows the text, and **`be.Text.format`** gives it back as `Text` (D11).
- **Braces hold a variable's name or `new_line`, and nothing else.** `{#total + 1}` and `{greet(#name)}` are refused, so
  a format can never hide work (D7).
- **A number in braces becomes text** by itself (D6).
- **A bare `#` is just a character,** as in `"#1 player"` (D4).
- **`\{` writes a brace,** and a `}` with no open fill-in is just a character (D5).

**Not decided:** a record's field in braces, like `{#player.score}`; settings like a width or decimal places (D7);
`{}`, and other words in braces; `.format` of text that isn't written in quotes.

## Showing text

`show_text` shows text and ends the line, and `show_text.same_line` doesn't end it (D12). Both forms of a filled-in
prompt work (D13), and the other order of narrowings is refused (D14):

```
show_text("Hello, world!");
show_text.same_line("Your move: ");
show_text.format.same_line("Lives: {#lives}, your move: ");
```

`show_text` can't fail (D44). It shows text only, and a number given to it is refused, with `be.Text(…)` as the fix
(D81).

## Comparing

```
#lives == 0
#guess != #answer
#score > #best
#hp at_least 1
#hp at_most 100
```

- `==`, `!=`, `<` and `>`, with a space on each side of `<` and `>`; `at_least` and `at_most` instead of `>=` and `<=`
  (D33, D34).
- **A lone `=` is refused,** with `==` as the fix, since `=` only gives a variable its value (D34).
- **Values of different types can't be compared** (D93).
- **`==` and `!=` don't compare `Text`.** Text is compared with a procedure that names how (D94):

  ```
  if compare_Text.looks_same(#guess, #answer):
  if not compare_Text.stored_same(#guess, #answer):
  ```

  `.stored_same` compares byte for byte. `.looks_same` compares after Unicode normalization (NFC), so differently typed
  versions of the same visible text match. Case matters in both.

**Not decided:** a chain like `1 < #x < 10`; `<` and `>` between two `Text`s; comparing true or false values.

## Logic

`and`, `or` and `not` combine conditions, in that order: `not` first, then `and`, then `or` (D36, D92):

```
if #hp at_least 1 and #lives > 0 or #cheat == 1:
```

reads as `(#hp at_least 1 and #lives > 0) or #cheat == 1`.

`and` and `or` stop early: the right side runs only when it can change the answer. `and.both` and `or.both` work out
both sides every time (D37).

## The pipe

`|>` passes the value on its left as the next step's bare first argument (D29, D30):

```
#typed |> be.Whole |> heal(by: 300) |> be.Text |> show_text;
```

- **A step with nothing else to pass is written bare,** `|> be.Whole`, with no `()` (D30).
- **A step with labels keeps its parentheses,** `|> heal(by: 300)` (D30).
- **The pipe takes everything on its left**, after maths and `&`, so `#a + 1 |> be.Text` pipes `#a + 1` (D97).
- **A long pipe can run over several lines,** since a statement ends at its `;` (D31).
