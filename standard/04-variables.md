# 4. Variables

## Declaring

A variable is declared with its name, its type and its first value (D27):

```
#name: Text = "Mia";
#score: Whole = 120;
```

A variable is declared before it's used, and using one before its declaration is refused (D81). Procedures are
different: they can be called from anywhere in their file (D96).

**Not decided:** declaring a variable without a first value; whether a variable declared inside a block, like an `if`'s
body, can be used after the block ends.

## `mutable` and `change`

A variable that can be changed is declared `mutable`, or `mut` for short (D28). It gets a new value with `change` in
front (D27):

```
mutable #player_health: Whole = 100;
change #player_health = heal(#player_health, by: 300);
```

`change` on a variable that isn't `mutable` is refused (D27). Since creating says a type and changing says `change`,
the two can't be mixed up, and a reader sees every place a value changes.

**Not decided:** shorthand for changing a variable by an amount, like adding 1.

## `shadow`

A name already declared in the procedure can be declared again only with `shadow` in front, which may change its type
(D91):

```
#input: Text = "42";
shadow #input: Whole = be.Whole(#input);
shadow mutable #input: Whole = 0;
```

`shadow` comes before `mutable`. Declaring a name again without `shadow` is refused, with no `fix:`, since adding
`shadow` and using `change` are both possible (D60, D91).

**Not decided:** `shadow` on a name that wasn't declared before (D91); `shadow` on a parameter.

## `copy` and `share`

Assigning a list or a record to a name says whether it gets its own copy or shares the original, and there's no
default (D32):

```
mutable #b: List<Whole> = copy #a;
mutable #c: List<Whole> = share #a;
```

Changing `#b` leaves `#a` alone. Changing `#c` changes `#a`, and the word `share` on that line says so. Plain values
like a `Whole` need no word, since copying and sharing them look the same (D32).

**Not decided:** how AroundPy keeps `copy` cheap (D32).

## Parameters

A procedure's parameters are variables it can only read, so `change` on one is refused, and arguments need no `copy` or
`share` (D32). A procedure that changes a list returns the new one, and the caller stores it:

```
change #party = add_member(#party, name: "Tankun");
```

Parameters are declared in a procedure's header (chapter 7).
