# 3. Types and values

Every variable has a type, written when it's declared (D27, chapter 4).

## `Whole`

A whole number from -9223372036854775808 to 9223372036854775807. It's Rust's `i64` (D65).

```
#score: Whole = 120;
```

A calculation that goes past that range is a failed check while running, depending on the build mode (D19, D84):

| Mode | Overflow |
|---|---|
| `Working` | stops with a failed check, exit status 4 (D82) |
| `FinalSafe` | stops with a failed check, exit status 4 (D82) |
| `FinalPerf` | unchecked |

A written number too big for a `Whole` is refused while building (D81).

### Limits

A number type can carry its own limits in `[ ]`, with `minimum:` and `maximum:`, or `min:` and `max:` for short
(D88):

```
mutable #hp: Whole[min: 0, max: 100] = 100;
```

Storing a value outside the limits is refused while building where the value can be seen there, as in
`change #hp = 150;`, and is otherwise a failed check while running, with the same modes as overflow (D88). `.saturate`
sticks at the limits instead (D87, chapter 5).

**Not decided:** writing `max:` before `min:`; a minimum above the maximum.

## The number family

Beside the plain names, Plainly has Rust's number types by the same names (D65):

- **Whole numbers:** `i8`, `i16`, `i32`, `i64`, `i128`; `u8`, `u16`, `u32`, `u64`, `u128`.
- **Floats:** `f16`, `f32`, `f64`.

`Whole` is `i64` and `Float` is `f32`. There's no `isize` or `usize`, whose size changes with the machine (D65).

## `Float`

A 32-bit float, Rust's `f32` (D64). A 64-bit float is `f64` (D65).

```
#speed: Float = ~0.1;
#half: Float = 0.5;
```

A literal the type can't hold exactly is marked `~`, and `~` on one it can hold exactly is refused (D64, chapter 2).

NaN and infinity depend on the build mode (D66):

| Mode | NaN and infinity |
|---|---|
| `Working` | checked after every float operation, stopping at the exact line |
| `FinalSafe` | the CPU's float flags, read where a float leaves the procedure that made it and where a loop ends; the message names the procedure or loop |
| `FinalPerf` | plain IEEE 754, unchecked |

Plainly doesn't promise the same float bits on every machine, or correctly rounded maths (D18).

**Not decided:** what Plainly's floats do promise (D18); arithmetic on floats; converting between floats and whole
numbers.

## `Text`

Text in UTF-8 (chapter 1), written in quotes (chapter 2). Empty text is `.empty` (D68).

```
#name: Text = "Mia";
#typed: Text = .empty;
```

Text is joined with `&` (D1), and compared with `compare_Text.stored_same` or `compare_Text.looks_same`, never `==`
(D94, chapter 5).

**Not decided:** a text's length, and reaching a character in it.

## True or false

A comparison, or `and`, `or` and `not`, gives a value that's true or false, which an `if` needs (D34, D35, D36).

**Not decided:** the type's name (D40's example writes `Bool`); the words for its two values; storing one in a variable.

## Lists and arrays

A **list** grows and shrinks, and an **array** has a fixed length, known while building (D67). Each holds one type of
item, written in `< >` (D33):

```
#board: Array<Text>[length: 9] = all " ";
#row: Array<Whole>[length: 3] = [1, 2, 3];
mutable #hand: List<Text>[length.maximum: 7] = .empty;
mutable #party: List<Text>[len.min: 1, len.max: 4] = ["Mia"];
mutable #log: List<Text> = .empty;
```

- **An array** has an exact `length:`. `all` fills it with one value (D68).
- **A list** can have `length.maximum:`, `length.minimum:`, both, or neither. Going past its maximum is checked like a
  bad position (D68).
- **`.empty`** is an empty list or text, and takes its type from the left: the variable it goes into, or the other side
  of `==`. An array can't be `.empty` (D68).
- **A literal like `[1, 2, 3]`** becomes a list or an array depending on where it goes, with its count checked against
  the type (D68).
- **`[]` and `""` are refused,** with `.empty` as the fix (D68).

### Positions

An item is reached with the label `position:`, or `pos:` for short, counting from 1 (D15):

```
#first: Text = #party[position: 1];
```

A bad position the compiler can see, like `position: 0`, or position 10 of an array of 9, is refused while building in
every mode. One it can't see is checked while running, as overflow is: stopping in `Working` and `FinalSafe`, and
unchecked in `FinalPerf` (D19, D20).

**Not decided:** adding to and taking from a list; filling an array from a range or a rule (D68); how far the compiler
looks for bad positions, beyond literals and fixed lengths (D20).

## Generic types

A type's parts go in `< >`, with no spaces: `List<Whole>`, `Map<Text, Whole>`, `List<List<Whole>>` (D33).

**Not decided:** how a generic's maker declares its placeholders (D33); `Map` itself.

## Converting

A value is converted by a call narrowed with the type it becomes: `be.Text(#total)`, `be.Whole(#typed)` (D6).
`be.Text` of something that's already `Text` is refused, with the value itself as the fix (D90).

`&` doesn't convert by itself, but `.format`'s braces do, since `{#total}` has to become text to be shown (D6).

**Not decided:** how a conversion that can fail, like `be.Whole("hello")`, reports it (D6, chapter 8).

## Records

**Not decided:** records, which D51 mentions building with `[ ]`.
