# 1. Files

```
english

procedure.main[none] returns nothing:
    #name: Text = "Tankun";
    greet(#name);
end procedure.main

procedure greet[#name: Text] returns nothing:
    show_text.format("Hi, {#name}!");
end procedure greet
```

## The language line

A file's first line is its language, and it's required (D75):

- `english`, or `eng` for short (D77);
- `ไทย`.

The language line decides two things (D75):

- **The keyword table** the file uses (D57). A keyword from the other table is refused, with the word from the file's
  own table as the fix.
- **The language of the file's messages.**

`apy convert` rewrites a file into the other table, language line included, and the program stays the same (D57, D79).

## The file's name

A file's name ends in `.plainly` for English and `.เพลนลี่` for Thai, as in `game.plainly` and `เกม.เพลนลี่` (D78,
D79). The extension must match the language line, and a file whose extension doesn't match, or is neither, is refused
(D79). That message is in English, since the file's language is in doubt (D80).

## Procedures in a file

A file holds procedures (chapter 7). Exactly one is `procedure.main`, where the program starts; it runs once, and
nothing else calls it (D63).

Procedures can be written in any order. A call can come before the procedure it calls, so a file can start with
`procedure.main` and read from the top down (D96).

**Not decided:** what happens with a second `procedure.main`, or none; whether anything but procedures can be written
outside a procedure; whether files import anything, or a package manifest is enough (D39).

## Lines and statements

- **A statement ends with `;`** (D31). That includes `labels [...];`, `defaults [...];` and `units [...];` lines (D31,
  D47).
- **A statement can run over several lines,** since it ends only at its `;`, which suits a long pipe (D31):

  ```
  change #player_health = #player_health
  |> heal(by: 300)
  |> heal;
  ```

- **A block's opening line ends with `:`**, like a procedure's header or an `if` (D31, D35).
- **A block's closer stands alone,** with no `;`, like `end procedure.main` or `end if` (D31).

**Not decided:** how a statement's later lines are indented; comments; blank lines, which every example uses between
procedures; more than one statement on a line.

## Indentation

A block's body is indented one level inside its opening line and its closer, and a block inside a body one level
further (D70):

```
procedure.main[none] returns nothing:
    #lives: Whole = 3;
    if #lives > 0:
        show_text("Still alive");
    end if
end procedure.main
```

- **One level is 4 spaces** (D70).
- **A tab in indentation is refused** (D70).
- **Wrong indentation is refused while building,** so every Plainly program looks the same (D70).
- **Indentation never decides where a block ends.** Every block ends with its own `end …` (D35, D70).

## Text encoding

A message's column counts UTF-8 bytes for tools and graphemes for people (D58), so a file's text is UTF-8.

**Not decided:** a byte order mark at the start; Windows line endings.
