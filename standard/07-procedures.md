# 7. Procedures

```
procedure heal[#health: Whole, #amount: Whole, #count: Whole] returns Whole:
    labels [#amount as by, #count as times];
    defaults [#count = 1];
    return #health + #amount x #count;
end procedure heal
```

## The header

A header says what a procedure takes and what it gives back (D46):

- **`procedure`**, or `proc` for short (D28), and the procedure's name.
- **Its parameters in `[ ]`**, each a name and a type, separated by commas. A procedure that takes nothing writes
  `[none]`, and an empty `[]` is refused, with `[none]` as the fix (D69).
- **`returns` and what it gives back**: a type, or `nothing`. A header with no `returns` is refused (D100, D101).
- **Its failures**, after `or fails`, as in `returns Level or fails [not_found, broken]`, or
  `returns nothing or fails [disk_full]` (D46, D100, chapter 8).
- **`:`** at the end (D31).

```
procedure greet[#name: Text] returns nothing:
procedure tick[none] returns nothing:
procedure load_level[#name: Text] returns Level or fails [not_found, broken]:
```

`returns nothing` is written even though nothing comes back. A procedure can do something, like showing text, and still
give nothing back, and the header says so (D100).

A procedure ends with `end procedure` and its name (D9, D35).

## Labels, defaults and units

The lines at the top of a body say how a procedure is called, in this order: `labels`, then `defaults`, then `units`
(D9, D47).

```
external.rust procedure draw_image[#image: Image, #x: Whole, #y: Whole] returns nothing:
    labels [#x as across, #y as down];
    units [#x in pixels, #y in pixels];
end procedure draw_image
```

- **A label** is a word every call writes before that argument. It's separate from the parameter's name, so the inside
  can be renamed without changing the callers (D8). By convention, the first argument, the thing being worked on, has no
  label (D8).
- **Labels keep their order** in a call, unless the line says `labels.any_order` (D10). `labels.in_order` is refused,
  since it's already what `labels` does (D10, D95).
- **A default** is a value used when a call leaves the label off. Only a labelled parameter can have one (D8, D9).
- **A unit** is a word a call writes behind a number, as in `300 pixels`. Whatever word the `units` line writes is the
  word callers use, and two packages can use the same unit word without clashing (D45, D47, D48).

## Calling

```
change #hp = heal(#hp, by: 30, times: 2);
change #hp = heal(#hp, by: 5);
draw_image(#whale, across: 300 pixels, down: 200 pixels);
play_turn();
```

- **Every label is written,** except one with a default. Leaving off a label with no default, or writing one that isn't
  declared, is refused (D8).
- **A labelled argument written bare** is refused, with the label as the fix (D95).
- **A call gives each parameter once.** Too many arguments is refused (D95).
- **A wrong-typed argument** is refused, as a variable given the wrong type is (D81, D95).
- **Units:** a written number for a parameter with a unit must say that unit. A missing or different unit word is
  refused, with the right one as the fix. A variable passes with no unit word, and nothing else is checked: there are no
  unit types and no conversions (D45, D95).
- **A call can come before its procedure** in the file (D96).
- **A procedure taking nothing** is called with `()`, as in `play_turn()` (D53).
- **In a pipe**, the piped value is the bare first argument (D30, chapter 5).

### Results

- **A result can't be thrown away.** A call to a procedure that returns something, with nothing using what it gives,
  is refused (D26).
- **What a `returns nothing` procedure gives can't be used as a value.** Such a call stands on a line of its own (D101).

**Not decided:** throwing a result away on purpose (D26); a call that leaves out a value without a label; narrowed
labels like `len.max:` in a call (D8).

## Parameters

A procedure only reads its parameters. `change` on one is refused, and a procedure that changes a list gives the new one
back for the caller to store (D32, chapter 4).

## `return`

`return` is followed by what the procedure gives back: a value of the header's type, or `nothing` (D100).

```
procedure sign[#n: Whole] returns Whole:
    if #n < 0:
        return -1;
    else:
        return 1;
    end if
end procedure sign

procedure greet[#name: Text] returns nothing:
    if compare_Text.stored_same(#name, .empty):
        return nothing;
    else:
        show_text.format("Hi, {#name}!");
    end if
end procedure greet
```

- **A procedure that returns something** returns on every way through it; one that can reach its end without returning
  is refused (D95).
- **A returned value has the header's type,** and `return nothing` is only for a `returns nothing` procedure (D95,
  D101).
- **A bare `return;`** is refused, with `return nothing` as the fix (D99, D100).
- **`return nothing` as a procedure's last line** does nothing, so it's refused (D99, D100).
- **A line after `return`** in the same block is refused (D98).

## `procedure.main`

```
english

procedure.main[none] returns nothing:
    show_text("Hello, world!");
end procedure.main
```

`.main` narrows `procedure` by one fact: it runs once, when the program starts, so a call to it is refused (D63, D95).
Everything else about procedures applies to it, including `returns nothing`, `fails` in its header, and `?` (D63,
D100). A failure that leaves `procedure.main` stops the program with a message and a failure exit status (D63).

**Not decided:** parameters on `procedure.main`; how the message for a failure leaving it looks (D63).

## Procedures written in Rust

`external.rust`, or `extern.rust` for short, in front of `procedure` says its body is written in Rust (D40):

```
external.rust procedure save_text[#text: Text, #file: Text] returns Bool:
    labels [#file as file];
end procedure save_text
```

Its body holds only `labels` and `defaults`, never code, and the closer doesn't repeat `external.rust`. Callers can't
tell it apart from any other procedure (D40).

On the Rust side, a helper crate, `plainly`, writes the wrapper. `Whole` is `i64`; a `Text` argument is a borrowed
`plainly::Text<'_>`, valid only during the call; and a returned `Text` is built in PlainGC's heap. Rust code never keeps
a Plainly object after the call returns (D38, D40).

**Not decided:** what a Rust procedure does when it fails; how floats and true or false values cross over (D40).
