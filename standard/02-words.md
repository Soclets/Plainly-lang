# 2. Words

A program is made of keywords, names, text, numbers and symbols. Spaces separate keywords and names (D57).

## Keywords

Plainly has one grammar and two word tables, English and Thai. A file's language line picks one (chapter 1), and every
keyword gets a word in both (D57).

| English | Thai | Decided in |
|---|---|---|
| `procedure` | `กระบวนการ` | D57 |
| `end` | `สิ้นสุด` | D57 |
| `.main` | `.หลัก` | D57, D63 |
| `none` | `ไม่มี` | D57, D69 |
| `returns`, `return` | `คืน` | D46, D57, D100 |
| `nothing` | `ไม่มีอะไร` | D57, D100 |
| `show_text` | `แสดงข้อความ` | D57 |
| `.same_line` | `.บรรทัดเดิม` | D12, D57 |
| `.format` | `.แทนค่า` | D2, D57 |
| `new_line` | `บรรทัดใหม่` | D4, D57 |
| `if` | `ถ้า` | D35, D57 |
| `else` | `ไม่งั้น` | D35, D57 |
| `mutable` | `เปลี่ยนได้` | D28, D57 |
| `change` | `เปลี่ยน` | D27, D57 |
| `shadow` | `บัง` | D57, D91 |
| `be` | `เป็น` | D6, D57 |
| `Whole` | `จำนวนเต็ม` | D57 |
| `Text` | `ข้อความ` | D57 |
| `divide` | `หาร` | D57, D84 |
| `remainder` | `หาเศษ` | D57, D85 |
| `.down` | `.ปัดลง` | D57, D85 |
| `.toward_zero` | `.ตัดเศษ` | D57, D85 |
| `.exact` | `.ลงตัว` | D57, D85 |
| `plus`, `minus`, `times` | `บวก`, `ลบ`, `คูณ` | D57, D87 |
| `.saturate` | `.ไม่เกิน` | D57, D87 |
| `minimum`, `maximum` | `ต่ำสุด`, `สูงสุด` | D57, D88 |

In Thai, `คืน` is both `returns` in a header and `return` in a body, since Thai verbs don't change form; where it
stands shows which (D57).

**Not decided:** the Thai words for every other keyword, including `and`, `or`, `not`, `at_least`, `at_most`,
`compare_Text` and its methods, `labels`, `defaults`, `units`, `as`, `in`, the loop words, `range`, the failure words,
and the number family.

### Short forms

Some English keywords have a short form, each a word of its own. The long form is the main one, and examples use it.

| Long | Short | Decided in |
|---|---|---|
| `procedure` | `proc` | D28 |
| `mutable` | `mut` | D28 |
| `english` | `eng` | D77 |
| `divide` | `div` | D84 |
| `remainder` | `mod` | D85 |
| `position:` | `pos:` | D15 |
| `length` | `len` | D68 |
| `minimum`, `maximum` | `min`, `max` | D68 |

The Thai words decided so far have no short forms (D57).

### Narrowings

A keyword or a name can be narrowed with `.` and a word, which makes it more specific: `procedure.main`,
`show_text.same_line`, `divide.down`, `labels.any_order` (D10, D12, D63, D85). When there are several, the one that
changes the action most comes first, and any other order is refused (D14):

```
show_text.format.same_line("Score: {#score}");
```

**Not decided:** Plainly's table of narrowing kinds, which would place each new narrowing in that order without judging
it again (D14).

## Names

- **A variable's name starts with `#`**: `#score`, `#player_health` (D27).
- **A procedure's name is a plain word**: `greet`, `first_word` (D9).
- **English names join words with `_`**: `#player_health`, `show_text`.
- **Thai names are written joined,** as normal Thai is, with no `_`: `#คะแนน`, `แสดงข้อความ` (D57).
- **A label** is a word chosen by the procedure's writer, written with `:` in a call, as in `heal(#hp, by: 300)` (D8).

A package's names are used bare. When two packages share a name, the bare name is refused, and the package goes in
front with `::`, as in `crossterm::draw(...)`. That's one level only, never a path (D39).

**Not decided:** which characters a name may hold; whether a name can match a keyword.

## Text

Text is written in double quotes: `"Hello, world!"`.

- **`\` makes the next character literal,** and nothing more. It doesn't start C's codes, so `\n` isn't a newline and
  `\t` isn't a tab (D3).
- **A new line is the word `new_line`**, joined with `&` or filled in as `{new_line}` (D4).
- **Empty text, `""`, is refused,** with `.empty` as the fix, so empty text is written `.empty` (D68).

Inside `.format` text, `{#name}` is filled in, and `\{` writes a brace (D2, D4, D5): chapter 5.

**Not decided:** `\` before a letter; `\"` and `\\` outside `.format` text; text that runs past the end of its line; how
a tab is written.

## Numbers

- **A whole number is written in digits:** `120`.
- **A `-` right before a number or a name negates it:** `-7`, `-#speed`. Subtracting has a space on each side,
  `#a - #b`, so the spacing tells them apart (D86).
- **A float is written with a point:** `0.5`. One that a float can't hold exactly is marked `~`, as in `~0.1`, and `~`
  on one it can hold exactly, like `~0.5`, is refused, so `~` always means "this was rounded" (D64).
- **A unit word can follow a number:** `300 pixels`, `2 seconds` (D45), where a procedure's parameter has a unit
  (chapter 7).

**Not decided:** other ways of writing numbers, like `1_000`, hexadecimal or exponents; subtracting with a missing
space, as in `#a -#b` (D86).

## Symbols

| Symbol | Meaning | Decided in |
|---|---|---|
| `( )` | runs something, a call, or groups maths | D51 |
| `[ ]` | holds values, and runs nothing: parameters, positions, lists, ranges, `labels` and the like | D51 |
| `< >` | fills in a type, as in `List<Whole>`, with no spaces | D33, D51 |
| `&` | joins text | D1 |
| `+`, `-` | add and subtract numbers | D84 |
| `x` | multiplies, as a word | D84 |
| `==`, `!=`, `<`, `>` | compare; `<` and `>` need a space on each side | D33, D34 |
| `\|>` | the pipe | D30 |
| `~` | marks a rounded float literal | D64 |
| `?` | passes a failure up | D42 |
| `::` | names a package | D39 |
| `#` | starts a variable's name | D27 |
| `.` | narrows | D14 |
| `:` | ends an opening line, follows a label in a call, or comes between a name and its type | D8, D27, D31 |
| `;` | ends a statement | D31 |
| `,` | separates items | D10 |

A lone `=` gives a variable its value, and is refused in a comparison, with `==` as the fix (D27, D34).
