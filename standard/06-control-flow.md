# 6. Control flow

## `if`

```
if #hp at_least 1:
    show_text("Still alive!");
else if #hp == 0:
    show_text("Just barely gone.");
else:
    show_text("Game over.");
end if
```

The condition has no parentheses and no `then`, and the opening line ends with `:`. `else if` and `else:` are optional,
and `end if` closes the whole `if` (D35). The condition must be true or false, so a plain value like `if #score:` is
refused (D93). Each body is indented one more level (D70).

## After an `if` that leaves

When an `if` has no `else` and every one of its ways leaves, by `return`, `break` or `fail`, the code that runs
otherwise goes in an `else:`, not after `end if`. A line after such an `if` is refused (D50):

```
procedure greet[#name: Text] returns nothing:
    if compare_Text.same_bytes(#name, .empty):
        return nothing;
    else:
        show_text.format("Hi, {#name}!");
    end if
end procedure greet
```

With `else`, the two paths read as alternatives, and both shapes compile to the same test and jump (D50).

A line after `return` in the same block can never run, so it's refused too (D98).

**Not decided:** a line after an `if` where only some ways leave, or where every way leaves, `else` included.

## Ranges

A range holds numbers and runs nothing, so it uses `[ ]` (D51, D52):

```
range[from: 1, to: 5]
range[from: 1, before: #count]
range[from: 10, to: 1, step_by: -1]
```

- `to:` includes the end, and `before:` stops just before it.
- `step_by:` steps, or counts down.
- `from:` is required, and the order is fixed.
- A range that can never reach its end, like `range[from: 1, to: 5, step_by: -1]`, is refused while building.

## Loops

```
repeat 3 times:
    show_text("Get ready...");
end repeat

for each #word in #words:
    show_text(#word);
end for

for each #n in range[from: 1, to: 5]:
    show_text.format("Level {#n}");
end for

while #lives at_least 1:
    play_turn();
end while

forever:
    if #score at_least 50:
        break;
    else:
        change #score = #score + 5;
    end if
end forever
```

- **`repeat … times`** repeats with no counter (D53).
- **`for each … in`** goes through a list or a range. Its variable has no written type, since it comes from what's
  looped over (D53).
- **`while`** runs while its condition holds (D53).
- **`forever`** has no end unless something leaves it, so one word finds every endless loop (D53).
- **`break;`** leaves the innermost loop. An `if` that breaks has the rest of the pass in its `else:` (D50, D53).
- **There's no `continue`.** Ending a pass early is an `if` around the rest (D53).

### Named loops

`named` at the end of a loop's opening line names it, the closer repeats the name, and `break` with the name leaves
that loop and every loop inside it (D54):

```
for each #row in #grid named rows:
    for each #cell in #row:
        if compare_Text.same_bytes(#cell, "X"):
            break rows;
        else:
            show_text.same_line(#cell);
        end if
    end for
end for rows
```

Any loop can be named, as in `forever named game:` closed by `end forever game` (D54).

A variable declared in a loop's body ends where the body ends, on every pass (D102, chapter 4).

**Not decided:** whether a `for each` loop's variable can be changed; changing a list while looping over it.
