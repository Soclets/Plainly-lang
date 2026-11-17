# 8. Failures

A failure is something a procedure can give back instead of its result, like a file that isn't there. It's part of the
procedure's header, and every call that can fail must handle it.

## Declaring failures

A procedure lists its failures in its header, after `or fails` (D46, D100):

```
procedure load_level[#name: Text] returns Level or fails [not_found, broken]:
procedure save_game[#state: Text] returns nothing or fails [disk_full]:
```

A standard-library procedure lists a failure only when a normal program would want to handle it (D44). So `show_text`
can't fail: if the text can't go anywhere, the program ends by itself (D44).

**Not decided:** how a procedure gives back a failure of its own: D50 and D55 call it `fail`, but its form isn't
written down; what a failure can carry besides its name.

## Handling is required

A call that can fail must be handled, with `?`, an `otherwise` form or a handler family. A call with none is refused
while building, so a library procedure gaining a new failure gives every caller a build error, not a crash while
playing (D43).

## `?`

`?` passes a failure up to the caller, and the procedure must list that failure itself (D42):

```
#count: Whole = parse_whole(#typed)?;
save_text(#line, file: "save.txt")?;
```

## One-line `otherwise`

```
#port: Whole = read_port() otherwise use 8080;
save_text(#line, file: "save.txt") otherwise ignore;
load_level(#name) otherwise crash;
```

- **`otherwise use`** carries on with a value (D56).
- **`otherwise ignore`** ignores the failure on purpose (D56).
- **`otherwise crash`** stops the program on purpose (D56).

Each is a phrase a search can find, so every ignored failure and every deliberate crash in a game can be found. Every way
of handling a failure except `?` starts with `otherwise` (D56).

## The `otherwise:` block

```
#best: Whole = load_best_score() otherwise:
    case not_found:
        show_text("No high score yet.");
        instead 0;
    case unreadable:
        instead 0;
end otherwise
```

- **One `case` per failure,** and the cases must cover every failure still possible at that call (D55).
- **Each case ends in one of four ways:** `instead` a value, carrying on with it; `return`; `break`; or `fail`, passing
  a failure up. A case that could fall off its end is refused (D55).
- **`end otherwise`** closes the block and stands alone (D31, D55).

`.exact` division's failure is `has_remainder` (D85):

```
#each: Whole = #coins divide.exact #players otherwise:
    case has_remainder:
        show_text("The coins don't split evenly.");
        instead 0;
end otherwise
```

**Not decided:** how a `case`'s body is indented against `case` itself.

## Handler families

A handler family is a named, reusable set of `case` arms, used at a call so the same handling isn't copied to every
call (D41):

```
#title: Text = first_word(#heading) otherwise word_failed.use_placeholder;
#name: Text = first_word(#typed) otherwise word_failed.*give_up;
```

A handler that can `return` or `break` out of the caller is marked `*` on its name, where it's used. Leaving the mark
off a handler that can jump is refused, and so is putting it on one that can't, so a jump never hides behind a name
(D41).

**Not decided:** how a handler family is declared (D41).

## Failures in `procedure.main`

`procedure.main` can list failures and use `?` like any procedure. A failure that leaves it goes to the runtime, which
stops the program with a message and a failure exit status (D63).

```
procedure.main[none] returns nothing or fails [not_found]:
    #level: Text = load_text(file: "level1.txt")?;
    show_text(#level);
end procedure.main
```

**Not decided:** how that message looks (D63).

## Failures and failed checks

A failure is different from a failed check. Overflow, dividing by zero, a bad position and a value outside a type's
limits aren't failures the program handles; they're failed checks that depend on the build mode (D19, D20, D84, D85,
D88, chapter 9).

**Not decided:** what a Rust procedure does when it fails (D40); how a conversion that can fail, like `be.Whole`,
reports it (D6).
