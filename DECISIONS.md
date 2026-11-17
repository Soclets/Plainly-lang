# Plainly — Decisions

What was chosen, with the owner's words. Nothing in the early notes counts as decided unless it's here.

## D1: `&` joins text (2026-11-16)

`&` joins text: `"Hello, " & #name`. `+` stays for maths only, so `"5" + 3` can't be misread as joining.
`&` reads as "and", is already used for joining in Ada, Visual Basic and Excel, and Plainly has no other use for it. It
replaces `join_text(...)` from the early sketch.

Open: whether `&` turns a non-text value such as a `Whole` into text by itself. (Answered by D6: it doesn't.)

Owner: too long.

## D2: `show_text.format` fills in names, and `show_text` stays literal (2026-11-16)

Inside `show_text.format(...)`, a name in the text is replaced by its value:
`show_text.format("Score: #total / 10 points")`. The `#` that every name already starts with marks where it goes, so no
braces are needed. Plain `show_text` stays literal: `show_text("#total")` prints `#total`. Text in quotes is literal
unless the `.format` narrowing says otherwise, as in Fale's decision 7. This replaces long `&` chains, like
`"Score: " & #total & " / " & 10 & " points"`, where every value costs a pair of quotes.

Open: how to write a literal `#` inside `.format` text; where a name ends inside text (`#totalpoints`); whether
`.format` exists beyond `show_text`, for building a `Text` value.

Owner: "yup, and `show_text` stays the non format kind".

Changed by D4: names go in braces, `{#total}`.

## D3: `\` escapes, but isn't C's escape codes (2026-11-16)

A `\` makes the next character literal: `show_text.format("\#1 player: #name")` prints `#1 player: ` and then the name.
`\` only escapes. It doesn't start C-style codes, so `\n` doesn't mean a newline and `\t` doesn't mean a tab.

Open: how a newline or tab is written; whether `\` before an ordinary letter is an error; how `\"` and `\\` work in plain
(non-`.format`) text.

Owner: too long.

Since D4, a bare `#` in `.format` text is literal, so `"#1 player"` needs no escape. `\{` escapes a brace instead.

## D4: `.format` fills in braces, and `new_line` is a word (2026-11-16)

Inside `show_text.format(...)`, what goes in braces is filled in: `show_text.format("Hello, {#name}{new_line}")`. A bare
`#` is literal, so `"#1 player"` prints as written, and the braces show exactly where a name ends: `{#total}points`.
This changes D2, which had no braces.

A newline is the word `new_line`, not a code like C's `\n`: `show_text("Hello, World!" & new_line)`, or `{new_line}`
inside `.format`. It's one more thing to learn, but a small one, and it says what it is.

Open: what may go in braces besides names and `new_line` (expressions such as `{#total + 1}`?); other named characters,
such as a tab.

Owner: too long.

Changed by D12: `show_text` ends the line by itself, so `new_line` is for line breaks inside text.

## D5: Only the opening brace is escaped (2026-11-16)

In `.format` text, `\{` makes a brace literal, and the closing `}` needs nothing:
`show_text.format("Type \{#name} to see your name")` prints `Type {#name} to see your name`. A `}` with no open fill-in
is just a character. That's one `\` instead of two, and no rule about the closing side, unlike Python's `{{ }}`.

Owner: "yea", to escaping only the opening brace.

## D6: `be.Type(value)` converts (2026-11-16)

Converting a value is a call narrowed by the type it becomes: `be.Text(#total)`, `be.Whole(#typed)`. The type's own name
is used, so nothing new is learnt. `.` keeps its one meaning, narrowing, and never means "do something to this value".
`&` doesn't convert by itself: `show_text("Total: " & be.Text(#total) & new_line)`. `.format`'s braces do convert,
since `{#total}` has to become text to be printed.

A conversion that can fail, such as `be.Whole("hello")`, will use the error handling Plainly takes from Cyborg or Radium,
which isn't designed yet.

Owner: "Maybe `be.Text(#total)` instead? As for why it's `.`, it's because it would have other types too", then "yea".

## D7: Braces hold values, never calls or maths (2026-11-16)

What goes in `.format`'s braces only reads: a name like `{#total}`, or a word like `{new_line}`. `{#total + 1}` and
`{greet(#name)}` are refused. A format string can never hide work, and a call that can fail or maths that can overflow
stays out where you can see it. This follows Cyborg's `fmt_print` (Cyborg D194, D210).

Open: field access, such as `{#player.score}`, once Plainly has records; width, padding and decimal places, which Cyborg
spells as words, like `{$price, places: 2}`; a version of `.format` that builds a `Text` value instead of printing,
which Cyborg's design claude advises deciding early (D11).

Owner: too long.

## D8: Plainly has Cyborg's labels (2026-11-16)

Plainly takes Cyborg's labels: named arguments, chosen by a function's writer, that every call must then write, as in
`first_word(#text, limit: 20)` instead of `first_word(#text, 20)`. A label is separate from the parameter's own name, so
a function can rename its insides without changing its callers. Only labelled parameters can have defaults. By
convention the first argument, the thing being worked on, stays bare. Labels can be narrowed, as in `len.max:`. Leaving
off a label with no default, or writing one that wasn't declared, is refused while building. (Cyborg D13, D113, D114)

Labels don't depend on units. Whether Plainly has Cyborg's units, checked while building (as in making Celsius correct),
isn't decided: they're very rich, and may be more than Plainly needs. Without them, Plainly skips Cyborg D144, where a
label's narrowing names a unit.

Label order: D10.

Owner: too long.

How a label is declared: D9.

## D9: Labels and defaults are declared on their own lines (2026-11-16)

As in Cyborg (Cyborg D114), labels and defaults are declared on separate lines at the top of the body, labels first:

    proc first_word[#text: Text, #limit: Whole] returns Text:
    labels [#limit as limit]
    defaults [#limit = 40]
    ...
    end proc first_word

    first_word(#text, limit: 20)
    first_word(#text)

The one-line form, `[#text: Text, limit #limit: Whole = 40]`, was turned down: it packs a label, a name, a type and a
default into one item, which is hard to read.

Owner: "Fucking profound. That's bad btw" (of the one-line form), then "separate, yea".

## D10: Labels keep their order, unless `labels.any_order` (2026-11-16)

A call writes its labels in the order the function declares them. A function that doesn't mind says so by narrowing its
`labels` line, as in Cyborg (Cyborg D114):

    proc move[#player: Player, #x: Whole, #y: Whole]:
    labels.any_order [#x as across, #y as down]
    ...
    end proc move

    move(#player, across: 3, down: 1)
    move(#player, down: 1, across: 3)

`labels.in_order` is refused, since it's already the default.

Owner: "yea, but before recording, where is `labels.any_order` un synatx?", then "tea" (yea).

## D11: `be.Text.format` builds text without printing it (2026-11-16)

`be.Text.format("...")` fills in braces the way `show_text.format` does, and gives back a `Text` value instead of
printing. It's `be.Text` (make Text, D6) narrowed by `.format` (fill in the braces, D2, D4), so it's made of words already
learnt. Since the result is ordinary `Text`, it works anywhere text goes, and no procedure has to support formatting
itself:

    #line: Text = be.Text.format("{#name}: {#score}")
    #banner: Text = "== " & be.Text.format("Level {#score}") & " =="
    save_text(be.Text.format("{#name},{#score}"), file: "save.txt")
    return be.Text.format("Hello, {#name}!")

`show_text.format(...)` stays, as a shortcut for `show_text(be.Text.format(...))`, since it's the most common line in a
CLI game. Owner, asked whether to keep it: "yes".

Owner: "Probably, how would it look?", "Wait, how do you make that work elsewhere? Like, not just in conversion", then
"Ahhh. yea".

## D12: `show_text` ends the line by itself, and `.same_line` doesn't (2026-11-16)

`show_text` and `show_text.format` add a newline at the end, as Python's `print`, Java's `println` and Go's `Println` do.
Most prints want one, and a beginner who forgets `& new_line` gets everything on one line with no idea why:

    show_text(greet(#name))
    show_text.format("{#name} has {#score} points.")

`show_text.same_line` doesn't add one, for prompts and for drawing the screen: `show_text.same_line("Your move: ")`. It
names what you get rather than what you don't, so it isn't `no_new_line`.

`new_line` stays, for line breaks inside text: `be.Text.format("Line one{new_line}Line two")`. This changes D4's
examples, not the word.

How `.same_line` and `.format` combine: D13.

Owner: "Hm, honest opinion? I don't like `new_line` that much. How about we do auto newline, and make `no_newline`?",
then "`same_line`".

## D13: Both ways of printing a filled-in prompt work (2026-11-16)

To fill in braces and stay on the line, either form works:

    show_text.format.same_line("Lives: {#lives}, your move: ")
    show_text.same_line(be.Text.format("Lives: {#lives}, your move: "))

The second works without any special rule, since `be.Text.format` gives back ordinary `Text` (D11). The first works
because `show_text` is an ordinary procedure from `std`'s writer, not syntax, so its narrowings are whatever `std` offers,
and `std` offers both together.

The other order, `show_text.same_line.format`, is refused: D14.

Owner: "Wait, shouldn't you be able to do it both ways? And `show_text` depends on `std`'s writer anyways".

## D14: Narrowings go strongest first (2026-11-16)

When one name has two or more narrowings, their order is fixed: the one that changes the action most sits next to the
name. The wrong order is refused, with the right spelling as the fix. `.format` changes what's printed, and
`.same_line` only where the output ends, so it's `show_text.format.same_line(...)`, and `show_text.same_line.format(...)`
is refused with `fix: show_text.format.same_line`.

One spelling per thing means a search finds every use, and nobody wonders whether two orders mean different things. The
reader also learns the most important fact first. This is the same rule as CyborgPL's (owner: "yeah, strongest first")
and Cyborg's (Cyborg D223). Labels, like a format's settings, aren't narrowings, and their order is set by D10.

Open: Plainly's table of narrowing kinds, so each new narrowing gets its place without judging it again. Cyborg's
design claude suggested action, then content, then destination, then safety, and advises writing it early. That order
isn't in Cyborg's standard, whose table has one row so far (a borrow: how it can be used, then how long), and whose rule
ranks safety words by how much harm they can do.

Owner: "yup".

## D15: Items are reached by `position:`, counting from 1 (2026-11-16)

An item in a list is reached with the label `position:`, or its short form `pos:`: `#xs[position: 1]`,
`#xs[pos: 1]`. Position 1 is the first item, as "first position" means in plain English. The label says what the number
is, so it can't be mistaken for an offset from 0, which Cyborg writes as `offset.items:`. `pos` is to `position` what
`proc` is to `procedure`. Square brackets after a name hold which item, and after `procedure greet` they hold
parameters, and the label keeps the two apart.

Owner: too long, then "yea", to position 1 being the first item.

## D16: Plainly compiles ahead of time to native code, through Cranelift (2026-11-16)

The compiler is written in Rust and compiles a whole program ahead of time to a native binary through Cranelift. There's
no bytecode and no JIT. This replaces the early plan of bytecode run by a Cranelift JIT, with some parts optionally
precompiled. It's simpler: there's no bytecode format to design and version, no runtime compiler, and none of that plan's
questions (tiered or not, who picks the precompiled parts, what happens when precompiled code and bytecode disagree).
The player gets one native file, with no warm-up.

Cranelift compiles fast, so a `run` command can compile to a temporary file and run it, as `go run` does. The cost is a
build per target, which Cranelift covers for x86-64, ARM64 and RISC-V, and less optimization than LLVM, which CLI games
don't need. PlainGC finds references through the stack maps Cranelift records.

Owner: "Before I answer that. I was thinking of switching to full AOT native via Cranelift, it's simpler", then "yup. Now,
should PlainOracle be made in OCaml?".

## D17: PlainOracle is written in OCaml (2026-11-16)

PlainOracle, the slow, obviously correct reference that the compiler's output is checked against, is written in OCaml,
while the compiler stays in Rust (D16). Two languages mean the compiler can't copy the oracle, even by accident, and
agree with its bugs. OCaml's garbage collector gives the oracle memory handling much like PlainGC's for free, and its
data types and pattern matching suit a readable interpreter. The cost is a second toolchain, opam and dune, next to
Cargo.

`Whole` is 64-bit, and OCaml's `int` is 63-bit, so the oracle uses `Int64` for every `Whole`, never `int`, or its overflow
results would be wrong in ways that look right. OCaml strings are bytes, so `Text` needs a Unicode library.

Owner: "yup. Now, should PlainOracle be made in OCaml?", then "Yea", to its independence being worth a second toolchain.

## D18: Plainly doesn't have Cyborg's stable floats (2026-11-16)

Plainly doesn't take Cyborg's `f64.stable` machinery: no guarantee of the same bits on every machine, no rule against NaN
and infinity with a check on every result, no correctly rounded maths library such as CORE-MATH, and no fixed order for
adding up vector lanes. CLI games don't need any of it, and it's a lot of work in the compiler and the standard library.

Open: what Plainly's floats do promise.

Owner: "We wouldn't add those, broooo".

## D19: Three build modes, and no default (2026-11-16)

| Mode | Cranelift | Checks the compiler can't prove away, like a bad position or overflow |
|---|---|---|
| `Working` | `opt_level` none, the fastest compile | kept |
| `FinalSafe` | `opt_level` speed | kept, so a bad position stops the program with an error |
| `FinalPerf` | `opt_level` speed | dropped |

There's no default mode: every build names one, so every build says what it promises. This follows Cyborg's rule for
bare names: where no default is obvious, there's no bare name.

In `FinalPerf`, a dropped check means a bad position reads past the end of the list, with whatever happens next. That's
the point of the mode: test in `Working` or `FinalSafe` first.

Owner: too long, then "It's FinalPerf, bro. Test your shit".

## D20: A bad position the compiler can see is refused while building (2026-11-16)

A position the compiler can tell is wrong before the program runs is refused while building, in every mode, `FinalPerf`
included: `#xs[position: 0]`, or position 10 of a list whose size is fixed at 5. Positions it can't check while
building follow D19: an error while running in `Working` and `FinalSafe`, and no check in `FinalPerf`.

Open: how far the compiler looks, beyond literals and fixed sizes, such as a loop counter whose range it knows.

Owner: "yea".

## D21: The Final modes add Plainly's own optimizations (2026-11-16)

Cranelift optimizes little, so `FinalSafe` and `FinalPerf` also run optimizations in Plainly's own compiler, before the
code reaches Cranelift. `Working` doesn't, so it keeps the fastest compile (D19).

Open: which optimizations. Candidates are what Cranelift lacks or can't see: inlining small procedures; removing checks
the compiler can prove, from known values and ranges, as Cyborg does (Cyborg D312), which also makes `FinalSafe` cheaper;
keeping values that never leave a procedure out of PlainGC's heap; and anything that needs Plainly's types. They work on
Plainly IR (D22).

Owner: "Btw, the Final modes would have better optimization from our frontend. Since Cranelift doesn't do much shit".

## D22: One IR of Plainly's own, Swift-style (2026-11-16)

    source → syntax tree → typed tree → Plainly IR → Cranelift IR → native

The typed tree is the checker's output, with names resolved and types attached, and it's where refusals like D20's
happen. Plainly IR is the one IR of Plainly's own: a control-flow graph where what was hidden is written out, such as
each position check, each PlainGC allocation, and labels and defaults filled in. D21's optimizations run on it. Cranelift
IR is Cranelift's own.

`Working` takes the same path and skips the optimizations, so the modes differ only in optimizations, never in how code
is translated, and a translation bug shows in every mode, where the oracle catches it.

This is Swift's shape (AST, then SIL, then LLVM IR): a backend does the low-level work, so the language needs one layer
of its own for its checks and optimizations. Go has two of its own (an IR tree and SSA) because it writes its own
backend. From Go: inlining and escape analysis work well close to the tree, so Plainly IR needn't be very low-level. One
IR is also enough to add LLVM later, if it's ever wanted.

Owner: "How many IRs?", "How many does Go and Swift have?", then "yea".

## D23: The compiler is AroundPy (2026-11-16)

Plainly's compiler is called AroundPy, so Plainly has "AroundPy performance", in the spirit of Cyborg's `OKAY\n`.
Its full name is AroundPython, and its short form is APy, the way `proc` is short for `procedure`. It
undersells on purpose: a native binary compiled through Cranelift with static types should run far faster than CPython
on compute-heavy code.

Owner: "What should the compiler's name be? AroundPy? So, we could say \"AroundPy performance\"", then "That's the
fucking point?". On the names: "Its shorten is APy, so APy (AroundPython)?", then "yea".

Open: whether the command is `apy` or `plainly`. APY is also a finance term (annual percentage yield), which crowds search
results.

## D24: PlainGC is ZGC-style (2026-11-16)

Replaced by D38: PlainGC is Go-style.

PlainGC follows ZGC's design: it marks and moves objects on its own threads while the program runs, so pauses stay well
under a frame, which matters for games beyond the terminal. It's precise, finding references through Cranelift's stack
maps (D16).

What it brings with it:
- **Load barriers.** Every read of a reference checks whether the object has moved, so AroundPy emits a barrier into every
  reference load it hands to Cranelift. They cost a little speed all the time, not just while collecting.
- **Coloured pointers.** PlainGC keeps its own bits inside pointers, which depends on each OS and CPU's address layout.
- **Objects move.** Rust code in the standard library never holds a raw pointer to a Plainly object across a point where
  PlainGC can run. It holds a handle, or pins the object.
- **A runtime with threads from the start.**

Go's collector (running alongside the program, but never moving objects) and a simple stop-the-world mark-and-sweep were
considered. Go's gets most of ZGC's short pauses with far less work, and doesn't move objects. ZGC was chosen anyway,
because it's fun, and it compacts memory.

The design copies ZGC, so where ZGC has an answer, that's PlainGC's answer, and the question isn't asked again. So
PlainGC is generational, as ZGC has been since JDK 21 and by default since JDK 23, which also means store barriers and
remembered sets alongside the load barriers. Its pointer colouring follows ZGC's on each target. Rust code reaching
Plainly objects follows what the JVM does for native code: JNI-style handles, and critical regions where an object
mustn't move.

Open: only where Plainly differs from the JVM, such as Cranelift's stack maps in place of HotSpot's.

Owner: "Ah, ZGC, right? Seems nice", "It's cool, though. And for games (maybe not fucking CLI, though), pauses are
shit", then "But it's fun, thoughhhh". On open questions: "No, like. The design copies ZGC, so you don't have to ask
generational".

## D25: Two kinds of random, with names that can't be mixed up (2026-11-16)

Plainly's standard library has two random sources:
- **Game random:** a fast pseudo-random generator, such as PCG or xoshiro, started from a seed. The same seed gives the
  same sequence, so a daily puzzle can be seeded by the date, and a bug that depends on a roll can be replayed until
  it's fixed.
- **Secret random:** unpredictable randomness from the operating system, as `openssl rand` gives, for anything that must
  be unguessable.

Their names make the difference obvious, since using a game random for a secret is a classic security bug.

Open: the names, and how a seed is given.

Owner: "Randomeness? Like `openssl rand`?", then "yea", to both kinds with clearly different names.

## D26: A returned value can't be ignored (2026-11-16)

Calling a procedure that returns a value and doing nothing with the result is refused. In

    heal(#player_health, by: 300)

`heal` returns the new health, and nothing stores it, so the health never changes. That bug looks like working code, and
it showed up in the first procedure multifinity wrote in Plainly.

Open: how to discard a result on purpose, when that's really meant.

Owner: "yea. Also, it's `change` in front to change", to refusing it.

## D27: `change` in front changes a variable (2026-11-16)

A variable that already exists gets a new value with `change` in front:

    mut #player_health: Whole = 100
    change #player_health = heal(#player_health, by: 300)

A new variable is a type and `=` (`#total: Whole = 0`), and changing one says `change`, so creating and changing can't be
mixed up, and a reader sees every place a value changes.

`change` on a variable not declared `mut` (or `mutable`) is refused (owner: "yea, no shit").

The spellings are D28.

Owner: "yea. Also, it's `change` in front to change".

## D28: `mutable`, or `mut` for short (2026-11-16)

A variable that can be changed is declared `mutable`, or `mut` for short, the way `proc` is short for `procedure`:

    mutable #player_health: Whole = 100
    mut #player_health: Whole = 100

`mutable` is Fale's word. `mut` is what Rust and Cyborg readers already know.

Owner: "It's `mut` and `mutatable`, right? Or what is it", then "rec".

## D29: Plainly has a pipe (2026-11-16)

A value can be passed along a chain of calls, read left to right in the order they run, instead of nested from the
inside out:

    show_text(be.Text(heal(be.Whole(#typed), by: 300)))

becomes one chain where each step's result is the next call's bare first argument, as in Elixir. That matches the labels
convention (D8), where the first argument, the thing being worked on, stays bare, and the labelled ones stay written out.

The spelling isn't `|>`, which isn't meant to be read, or `then`, which reads wrongly before a procedure's name and which
an `if` may want.

The spelling is D30.

Owner: "I think it should, but `|>` isn't meant to be read, while `then` is, and then `then` breaks the grammar".

## D30: The pipe is `|>` (2026-11-16)

    #typed |> be.Whole |> heal(by: 300) |> be.Text |> show_text

No word read right: `then` breaks the grammar before a procedure's name, and `into` and `through` were offered. An arrow,
`=>` or `->`, already says what something is (in maths, `⇒` is "implies"), not where it goes, and in other languages it
means an inline function, a `match` arm or a return type. `|>` means one thing only, and it's learnt once, like `&`
(D1). Where no plain word reads right, a symbol that means one thing is the next best choice.

A step with no other arguments is written bare, `|> be.Whole`, not `|> be.Whole()`: empty parentheses on every step of
a long chain are just noise. A step with labels keeps its parentheses, `|> heal(by: 300)`. (Owner: "`()` looks like it's
a stroke when you don't nest for a lot".)

Owner: "Just the symbol? Maybe we use `=>` arrow instead? Let's see", "Man, for some reason it looks like not the same
thing doing. Idk why", "Let me see slider (the original symbol)", then "`|>` it is".

## D31: Every statement in a body ends with `;` (2026-11-16)

    procedure.main[]:
    mutable #player_health: Whole = 100;
    change #player_health = #player_health |> heal(by: 300) |> heal;
    #player_health |> be.Text |> show_text;
    "Tankun" |> greet |> show_text;
    end procedure.main

Without an end mark, lines after a `change` read as if the `change` did all of them. With `;`, each statement visibly
stops, and a long pipe can run over several lines, since a statement ends only at its `;`:

    change #player_health = #player_health
    |> heal(by: 300)
    |> heal;

`labels [...];` and `defaults [...];` end with `;` too, as in Cyborg. A header ends with `:`, and a closer such as
`end procedure.main` stands alone, with no `;`. Examples in entries before this one are written without `;`.

Owner: too long, then "yea".

## D32: `copy` or `share` on assignment, and parameters can't be changed (2026-11-16)

Assigning a list or a record to a name says whether it gets its own or shares the original:

    mutable #b: List = copy #a;
    mutable #c: List = share #a;

Changing `#b` leaves `#a` alone. Changing `#c` changes `#a`, and the word `share` on that line says so. There's no
default, so it's never hidden, which is what bites Python beginners. Plain values like `Whole` need no word, since
copying and sharing them look the same.

Arguments need no word, because a procedure can't change its parameters. It can only read them, so passing the original
looks exactly like passing a copy, and costs nothing. A procedure that changes a list returns the new one, and the caller
stores it, which D26 makes sure of:

    change #party = add_member(#party, name: "Tankun");

Requiring a word on every argument, as in `heal(share #party)`, was turned down: that's ownership with friendlier
names, like Cyborg's `Lend` and `Give`.

Open: how AroundPy keeps `copy` cheap without reference counts (escape analysis, D21, or lists that share unchanged
parts); the list syntax itself.

Owner: "Tell me, two words, `share` & `copy`. Hard to learn?", "Bro's talking number 2 like we're adding ownership",
then "yes".

## D33: Generic types use `<>`, and `<` and `>` as operators need spaces (2026-11-16)

A generic type's parts go in angle brackets: `List<Whole>`, `Map<Text, Whole>`, `List<List<Whole>>`. They're written
with no spaces. `<` and `>` used as operators always have a space on each side, as in `#a < #b`, so the two can never be
mixed up. That's also why `>>` at the end of `List<List<Whole>>` is two closers, not an operator, the problem that gave
Rust its `::<>` and older C++ its `> >`.

The word form, `List of Whole` and `Map of Text to Whole`, was turned down: it reads oddly with two parts, and nesting
needs a grouping rule.

Open: how a generic's maker declares its placeholders (Cyborg writes `?u`). `<` and `>` are operators: D34.

Owner: "Map of Text to Whole sounds weird. And I mean `<>`  works everywhere, even when we use `<` and `>` as operator.
Just require space".

## D34: Comparison is `==`, `!=`, `<`, `>`, `at_least` and `at_most` (2026-11-16)

    #lives == 0
    #guess != #answer
    #score > #best
    #hp at_least 1
    #hp at_most 100

A symbol where it's read at a glance, a word where it isn't. `==` and `!=` are understood without reading them in your
head, and are in almost every language. `<` and `>` are school maths. `<=` and `>=` are where beginners trip (which way
round, whether the number counts, `<=` or `=<`), so they're `at_least` and `at_most`. `<` and `>` have a space on each
side (D33).

A lone `=` in a condition, the classic `if #a = 1` typo, is refused with `fix: ==`. `=` only appears in declarations and
in `change` (D27), so it can never be a comparison.

Owner: "`<` & `>`, `at_most`, `at_least`, `!=`, `==`? What about that? As for why `!=` and `==`, it's because when you
get it, you get it without even reading in mind.", then "yea".

## D35: `if`, `else if`, `else` and `end if` (2026-11-16)

    if #hp at_least 1:
    show_text("Still alive!");
    else if #hp == 0:
    show_text("Just barely gone.");
    else:
    show_text("Game over.");
    end if

The condition has no parentheses and no `then`: a header ends with `:`, as `procedure greet[...]:` does. `end if`
closes it, like `end procedure greet`. Statements inside end with `;`, and the headers and closer don't (D31). A lone `=`
in the condition is refused (D34).

`else`, not `otherwise`, which Cyborg uses for the arm that handles a failure. Plainly's error handling will come from
Cyborg or Radium (D6), so `otherwise` stays free for that.

Combining conditions: D36.

Owner: "`otherwise`? That's error handling", then "yes".

## D36: Conditions combine with `and`, `or` and `not` (2026-11-16)

    if #hp at_least 1 and not #paused:

Words, not C's `&&`, `||` and `!`.

Whether they stop early: D37.

Owner: too long.

## D37: `and` and `or` stop early, and `and.both` and `or.both` don't (2026-11-16)

`and` and `or` short-circuit: the right side runs only when it can change the answer. That keeps the everyday guard safe,
since the right side doesn't run when `#i` is past the end:

    if #i at_most #count and #xs[position: #i] == 0:

`and.both` and `or.both` evaluate both sides every time, for the rare right side with an effect that must happen. The
plain word is the safe one, the reverse of Ada, whose plain `and` evaluates both sides, so its users learn to write
`and then` everywhere.

Owner: too long, then "Huh? How does Ada's problem even apply?", then "have".

## D38: PlainGC is Go-style, from the start (2026-11-16)

This replaces D24's ZGC-style design. PlainGC follows Go's collector:
- **It marks while the program runs**, so pauses usually stay well under a millisecond, close to ZGC's.
- **It never moves objects.** Rust code in the standard library holds plain pointers: no handles, no pinning.
- **Only a write barrier**, a check when a reference is stored. Reads are plain loads, so AroundPy emits no load
  barriers.
- **No coloured pointers and no generations**, so no remembered sets.
- **Objects are grouped by size** (size classes, as in Go and TCMalloc), which keeps fragmentation down without
  compacting.

It's precise, finding references through Cranelift's stack maps (D16). Without generations, short-lived garbage is kept
off the heap by escape analysis (D21), as Go does.

What was weighed: for offline CLI games a simple stop-the-world mark-and-sweep fits best, since their heaps are tiny.
Go-style fits best if Plainly grows past the terminal, and ZGC-style fits the goal least: its strengths are huge heaps
and short pauses at any size, and it forces handles and load barriers into AroundPy and the whole standard library. A
simple collector and Go's make the same promise that objects never move, so either could grow into the other. Go-style
was chosen from the start. It's roughly 5,000 to 12,000 lines, against 10,000 to 25,000 for ZGC-style.

Open: how closely to follow Go's pacer, which decides when a collection starts.

Owner: "What if we move to Go-style GC?", "What would fit our goal most?", then "Go-style from the start".

## D39: Names have no paths, and `package::` settles a clash (2026-11-16)

A package's names are used bare: `show_text`, `be.Text`, `draw`. There are no paths like Cyborg's
`std::io::fmt_print`. When two packages both have a name, the bare name is refused, with a fix listing each package's
spelling. The package's name goes in front with `::`:

    crossterm::draw(...);

That's one level only: a package's name, never a path inside it.

Open: whether files import anything, or the manifest's list of packages is enough, as in Jernal; limbs, which Cyborg's
design claude advises leaving out until Plainly needs to extend its compiler. A procedure with its body in Rust: D40.

Owner: "I don't agree with paths, though. As for no limbs, that means Plainly has to be able to print by itself?", then
"you say `name::` in front".

## D40: `external.rust procedure` declares a procedure whose body is in Rust (2026-11-16)

    external.rust procedure save_text[#text: Text, #file: Text] returns Bool:
    labels [#file as file];
    end procedure save_text

    extern.rust proc show_text[#text: Text]:
    end proc show_text

`external` says the body is somewhere else, and `.rust` says where, which leaves room for `external.c` later. `extern`
is its short form, as `proc` is for `procedure`. It's a modifier in front, like `mutable` or a `pub`, so the closer
doesn't repeat it. The body holds only `labels` and `defaults` (D9), never code. Callers can't tell it apart from any
other procedure, and AroundPy only reads its signature and emits a call.

The Rust side uses a helper crate, `plainly`, whose attribute writes the `extern "C"` wrapper:

    #[plainly::procedure]
    fn save_text(text: plainly::Text<'_>, file: plainly::Text<'_>) -> bool { ... }

`Whole` is `i64`, a `Text` argument is a borrowed `plainly::Text<'_>`, valid only during the call, and a returned
`Text` is built in PlainGC's heap with `plainly::Text::new(...)`. Rust code never keeps a Plainly object after the call
returns: PlainGC never moves objects (D38), but it can't see Rust's variables, so the object could be freed. The `'_`
lifetime makes Rust's own compiler refuse that. Each package's Rust code is a static library, with symbols named after
the package and procedure, like `plainly_std_save_text`, so two packages can't collide (D39).

Open: what a Rust procedure does when it fails, which waits on error handling (D6); the mappings for floats and the
true/false type, which aren't designed yet.

Claude proposed the Rust side and `procedure.rust`. Owner: "Design that Rust shit", "What about `external.rust
procedure`? `extern` alias", then "What do you think? `extern.rust` is kinda like `pub`? So, it's like a generic thingy.
So, maybe it doesn't need to reapt?"

## D41: Handler families, and `.*` on a handler that can jump (2026-11-16)

Plainly has handler families: named, reusable sets of `case` arms for failures, used at a call so the same handling
isn't copied to every call, as in Cyborg (`fam.handler`) and Radium:

    #title: Text = first_word(#heading) otherwise word_failed.use_placeholder;
    #name: Text = first_word(#typed) otherwise word_failed.*give_up;

A handler that can `return` or `break` out of the caller is marked `*`, on its own name after the family's dot, where
it's used and not where it's declared, as in Cyborg (standard 8.8). Leaving the mark off a handler that can jump is
refused, and so is putting it on one that can't. Without it, a jump hides behind a name, and the lines after the call
can silently never run.

Open: how a handler family is declared; the rest of error handling, of which this is one part.

Owner: "Where's handler families?", "First of all why did you drop handler families?", "Why no `*` mark?", too long,
"Bro, that's the wrong place for it", then "yea".

## D42: `?` passes a failure up (2026-11-16)

    #count: Whole = parse_whole(#typed)?;
    save_text(#line, file: "save.txt")?;

`?` hands a failure to the caller, and the procedure must list that failure itself, as in Cyborg (Cyborg D44). Like `|>`
(D30) and `&` (D1), it's a symbol that means one thing only, learnt once, and it's the most common way of handling a
failure, so being short matters. It replaces the proposed `otherwise fail`.

Owner: "Wait a minute, `show_text(\"HW\") otherwise what` for passing up", "I think `?` is looking very beutiful", then
"yea".

## D43: Handling a failure is required (2026-11-16)

A call that can fail must be handled, with `?` (D42), an `otherwise` form, or a handler family (D41). One with none is
refused while building, as in Cyborg (Cyborg D434) and Radium. If a library procedure gains a new failure, every caller
that doesn't handle it gets a build error, not a surprise crash while playing. It's the same idea as D26: an unhandled
failure hides a bug, just as an ignored result does.

Owner: "yea".

## D44: `show_text` can't fail (2026-11-16)

`show_text` never needs `?` or `otherwise`. If the text can't go anywhere, the game ends by itself, and the game's code
never handles it. That only happens when the terminal closed, or when the output was sent into a file or another program
that stopped taking it. A handler couldn't tell anyone, since telling means printing, which is what failed. Rust's
`println!`, Python's `print`, Go's `fmt.Println` and C's `printf` all end up the same way in practice.

How the runtime ends the game is AroundPy's detail: quietly when whatever was reading the output quit, and with a line on
stderr and a failure exit status for a real error, such as a full disk when the output goes to a file.

The general rule for the standard library: a procedure lists a failure only when a normal program would want to handle
it.

Owner: "yea".

## D45: Units go behind the number, and only literals are compared (2026-11-16)

A number can say its unit behind it, as in Cyborg:

    draw_image(#whale, across: 300 pixels, down: 200 pixels);
    wait(for: 2 seconds);

A parameter declares its unit, and the compiler compares only the unit words on literals: `300 pixels` where the
parameter is in pixels is fine, and `300 seconds` or a bare `300` there is refused. A variable, as in `across: #x`,
passes with no unit word and no check. There are no unit types, no conversions and no maths on units. That's Cyborg's
checked units (D8 left them undecided), which are heavy, and Plainly skips them.

Where unit words come from: D48. How a parameter declares its unit: D47.

Owner: "i would like to add units there, just not checked ones (those are heavy)", "Uh, bro, Shouldn't it be behind?",
then "yea, but not that syntax".

## D46: Failures go in the header, as `or fails [...]` (2026-11-16)

    procedure load_level[#name: Text] returns Level or fails [not_found, broken]:
    ...
    end procedure load_level

A failure is something a procedure can give back instead of its result, so it sits next to `returns`, as in Cyborg
(Cyborg D209). `or fails` reads as what happens: it gives back a `Level`, or it fails. Without the `or`,
`returns Level fails [...]` runs together. A comma, or `fails` on its own header line, were also offered.

So the header says what a procedure takes and gives (parameters with their types, the result, and its failures), and
the top of the body says how to call it (labels and defaults, D9). This replaces the proposed `fails` lines in the
body, from Radium.

A procedure with no result writes just `fails [...]`, with no `or` (owner: "just `fails [disk_full]`"):

    procedure save_game[#state: Text] fails [disk_full]:

How a parameter declares its unit: D47, in the body, not the header.

Owner: "Also, wait. You have to be shitting me if you put failure in body, but units in header", "I feel like failure
should go in h?", "Ah, that reads weird. There's nothing separating fails", then "yup".

## D47: Units are declared in the body, after labels and defaults (2026-11-16)

    external.rust procedure draw_image[#image: Image, #x: Whole, #y: Whole]:
    labels [#x as across, #y as down];
    units [#x in pixels, #y in pixels];
    end procedure draw_image

    draw_image(#whale, across: 300 pixels, down: 200 pixels);

To a caller, a unit works like a label: it's a word written at the call, and the compiler checks the word, not the
value (D45). So it sits with the labels. That refines D46's split: the header holds the types, the result and the
failures, what a procedure takes and gives, and the top of the body holds labels, defaults and units, the words written
when calling it, in that order.

Owner: "What abt in body instead?", then "yea".

## D48: A procedure's `units` line is where its unit words come from (2026-11-16)

There's no separate list of unit words. Whatever word a procedure writes in its `units` line (D47) is the word its
callers must write: `units [#x in pixels];` makes `pixels` the word for `#x`. A unit word isn't a name a package exports,
just part of one procedure's calling rules, like a label, so two packages that both use `pixels` never clash, and D39's
`package::` isn't needed for units. Nothing makes packages agree on spelling, so one may write `pixel` and another
`pixels`, a fair trade for unchecked units.

Owner: "declared by packages", "Just let them declare in there? Like in the fn", then "yea".

## D49: CLI first, and a GUI only as a package later, if ever (2026-11-16)

Plainly's standard library targets the terminal: printing, reading keys, drawing characters and colours, through
`crossterm`. Its examples and README show terminal games. A GUI, if it ever comes, is a separate package wrapping a
library like raylib behind `external.rust` (D40), with labels and units (D45 to D48) for its calls. The language itself
doesn't change either way.

Owner: "CLI first, GUI as a package later if ever. And btw, I'm Tankun, lol".

## D50: After an `if` that always leaves, the rest goes in `else:` (2026-11-16)

When an `if` block always leaves, by `return`, `break` or `fail`, the code that runs otherwise goes in that `if`'s
`else:`, not after `end if`. Code after `end if` there is refused, with a fix moving it into `else:`:

    procedure greet[#name: Text]:
    if #name == "":
    return;
    else:
    show_text.format("Hi, {#name}!");
    end if
    end procedure greet

A guard clause, an `if` that leaves with plain code after it, looks like it would do two things. With `else`, the two
paths read as alternatives. Both shapes compile to the same test and jump, so it costs nothing at run time. This is
Cyborg's D430. Several conditions stay flat as one `else if` chain (D35).

Owner: "follow Radium on that one, don't rec yet, though. I think Cyborg has something with `if`s in functions, ask it",
then "yea".

## D51: `( )` runs, `[ ]` holds, `< >` fills in a type (2026-11-16)

- `( )` runs something: a call, as in `greet(#name)`. It also groups maths, as in `(#a + #b) * 2`.
- `[ ]` describes or holds values, and runs nothing: a declaration's parameters (`procedure greet[#name: Text]`),
  positions (`#xs[position: 1]`), list values, building a record, ranges (D52), and the `labels`, `defaults`, `units`
  and `fails` lists.
- `< >` fills in a type: `List<Whole>` (D33).

A reader can tell at a glance whether something happens: `[ ]` just holds values, and `( )` runs code, which may fail.
Making a value that really runs code, like allocating or something that can fail, uses `( )`. This is Cyborg's D23,
from Radium. Plainly already followed it before writing it down.

Owner: "Right... You don't know the signature bracket rule, ask Cyborg", then "yea".

## D52: Ranges are `range[from: 1, to: 5]` (2026-11-16)

    range[from: 1, to: 5]
    range[from: 1, before: #count]
    range[from: 10, to: 1, step_by: -1]

A range holds its numbers and runs nothing, so it uses `[ ]` (D51). `to:` includes the end and `before:` stops just
before it, so there's no off-by-one guessing. `step_by:` steps or counts down. `from:` is required and the order is
fixed, and a range that can never reach its end, like `from: 1, to: 5, step_by: -1`, is refused while building. This is
Cyborg's D128 range, from Radium. `1 to 5` was turned down, since `for each #n in 1 to 5` reads oddly.

Owner: "`for each #n in 1 to 5:` reads weird", "Cyborg actually uses `[]` there. And... Hm... We might want Cyborg's",
then "yea".

## D53: Loops (2026-11-16)

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

- `repeat … times` repeats with no counter.
- `for each … in` goes through a list or a range (D52). The loop variable writes no type: it comes from what's looped
  over, since `#word: Text in #words:` repeats what `List<Text>` already says, with two colons in one header.
- `while` runs while its condition holds, and `forever` has no end unless you `break` or `return`, so one word finds every
  endless loop.
- `break;` leaves the innermost loop. An `if` that breaks has the rest of the pass in its `else:` (D50).
- There's no `continue`. Ending one pass early is an `if` around the rest. This follows Radium's D77, where every word
  for it was misread in cold tests: `continue` as carrying on, `skip` as skipping the whole loop, and `next`,
  `skip_rest` and `skip_this` too.

Named loops: D54.

Owner: "rec loops".

## D54: A loop can be `named`, and `break` can name it (2026-11-16)

    for each #row in #grid named rows:
    for each #cell in #row:
    if #cell == "X":
    break rows;
    else:
    show_text.same_line(#cell);
    end if
    end for
    end for rows

`named` goes at the end of a loop's header, and the closer repeats the name: `end for rows`. `break rows;` leaves that
loop and every loop inside it. Any loop can be named, as in `forever named game:` closed by `end forever game`. Cyborg
puts the name right after the loop word, which in Plainly would be `for each rows #row`, and a label in front,
`rows: for each …`, was also offered.

Owner: "We should have named loops", then "named".

## D55: The `otherwise:` block, with one `case` per failure (2026-11-16)

    #best: Whole = load_best_score() otherwise:
    case not_found:
    show_text("No high score yet.");
    instead 0;
    case unreadable:
    instead 0;
    end otherwise

The arms must cover every failure still possible at that call. An arm can run any statements, and must end in one of
four ways: `instead` a value, carrying on with it; `return`; `break`; or `fail`, passing a failure up. An arm that could
fall off its end is refused. `end otherwise` closes the block and stands alone, with no `;`, like every closer (D31).
`otherwise` is kept for this, which is why `if` uses `else` (D35). This is Cyborg's `otherwise:` (Cyborg D45, D139) and
Radium's (Radium D78).

Owner: "yea".

## D56: `otherwise use`, `otherwise ignore` and `otherwise crash` (2026-11-16)

    #port: Whole = read_port() otherwise use 8080;
    save_text(#line, file: "save.txt") otherwise ignore;
    load_level(#name) otherwise crash;

One-line ways to handle a failure: `otherwise use` carries on with a value, `otherwise ignore` ignores the failure on
purpose, and `otherwise crash` stops the program on purpose. Each is a searchable phrase, so every ignored failure and
every deliberate crash in a game can be found. They're Cyborg's `?? 8080`, `?? void` and `?? crash` in plain words.
Every way of handling a failure except `?` (D42) starts with `otherwise`.

Owner: too long.

## D57: Plainly supports Thai: one grammar, two word tables (2026-11-16)

Plainly's keywords come in English and Thai. It's one language with two word tables, not two languages: the grammar is
the same, and since keywords are a fixed list, `apy` can rewrite any file from one table to the other without losing
anything, so Thai code and English code are always the same program. Many Thai kids can't read English, and for them
`procedure` and `otherwise` aren't plain words, so this is "plain words where we can" for them. Scratch does the same
with its blocks.

From now on, every keyword gets both an English and a Thai word. The first:

| English | Thai |
|---|---|
| `procedure` | `กระบวนการ` |
| `end` | `สิ้นสุด` |
| `.main` | `.หลัก` |
| `show_text` | `แสดงข้อความ` |
| `if` | `ถ้า` |
| `else` | `ไม่งั้น` |

Thai names are written joined, as normal Thai is, with no `_`: `แสดงข้อความ`, not `แสดง_ข้อความ`. Spaces separate
keywords and names, the way spaces separate phrases in a Thai sentence, so a space always means a new name or keyword.
`end` is `สิ้นสุด` ("end, conclude"), so `สิ้นสุด ถ้า` reads as "end of the if". It's one word, so it needs no `_`,
and it's the word Thai school flowcharts and pseudocode use for an end, next to `เริ่มต้น` for a start.

What was turned down on the way:
- `ขั้นตอน` for `procedure`: it means one step, not a whole procedure.
- A bare `จบ` for `end`: it reads like "The End", finishing everything, not closing one block.
- `จบ_ส่วน` for `end`, with `_` always between the words of a Thai name: predictable, but code full of `_` looks
  unlike Thai, and `จบส่วน` written joined reads wrong.
- Writing each name as everyday Thai with `_` only where it reads wrong: not predictable.
- `_` wherever the English name has one: it clashed with `end`.
- `ปิด` ("close") for `end`: `ปิด ถ้า` reads as "close, if…", the start of a condition.
- `มิฉะนั้น` and `ไม่อย่างนั้น` for `else`: too formal, and too long. `ไม่งั้น` is the casual "or else", and one word.

Owner, on the way: too long, then "Fuck, Thai sentence, mb", "Let me see a Thai senetcne", "So, what if we follow that
for names?", "yea, rec it", "`ปิด ถ้า` reads like close if, rather than end of section if. So, we could bring the old
word bacl", "Look at normal Thai, what do they use?", then "yea, rec it".

Open:
- the rest of the Thai keyword table;
- Thai names for the standard library's procedures, types and labels;
- error messages in Thai;
- requiring a space between keywords, since Thai doesn't put spaces between words;
- measuring text by the columns it takes on screen, not by characters, since `ที่` is three characters in one column.

Owner: too long, "Whatever, but `ขั้นตอน` means step in Thai, not a entire procedure", too long, then "We support Thai,
yeah".

## D58: Error messages start from Cyborg's format, with its anti-cascade rules (2026-11-17)

    refused: game.plain_code:12:1, line 12 column 1
    12 | change #lives = #lives - 1;
       | ^^^^^^^^^^^^^^^^^^^^^^^^^^^
     what: `#lives` isn't mutable
     why:  `change` needs a variable declared `mut` (D27)

The starting point is Cyborg's format (Cyborg D16, from Radium):
- The first word is the kind: `refused:`, `check failed:` (while running) or `warning:`.
- The place is written twice: `file:line:col` for tools, then `line N column M` for people.
- `^` marks exactly the part in question.
- `what:` says what's wrong, `why:` gives the rule, `when:` the values that break it, and `because:` earlier steps, each
  only when known.
- A `fix:` line replaces `what:` when there's a fix.
- No error codes, and no "did you mean" guesses: only what's certain. PlainOracle and AroundPy print identical text.
- Every error is shown, with no limit.

Against cascades, as in Cyborg:
- After an error, only that statement is skipped. A broken declaration still creates its variable with its written type,
  so later lines don't fail because it "doesn't exist" (Cyborg D215). That works because Plainly always writes types.
- To sort knock-on errors from independent ones, the first error's single fix is applied in memory and the program
  checked again. Whatever disappears was caused by it, and is shown with a `because:` pointing back (Cyborg D207).

Open, to be changed one at a time: Thai labels (D57) with code untranslated and the `file:line:col` place
unchanged, and columns counted in graphemes; what happens after a broken block opener or header, which Cyborg never
decided.

Owner: "yea".

## D59: `why:` is a plain sentence, and names the symbol a word stands for (2026-11-17)

    why:  `change` only works on a variable (#) declared `mut`.

A `why:` line is a plain sentence a beginner can read, with no decision number, since `(D27)` means nothing to them.
Where it names something the code writes with a symbol, the symbol follows in parentheses, as in "variable (#)", so the
message ties the word to what's on the page. Writing "a `#` variable" was turned down: it sounds like a special kind of
variable, rather than how Plainly writes every variable.

Owner: too long, then "That kinda sounds like hastag variable is a special thing, rather than our language calls
variables as hashtags, or used as hashtags".

## D60: At most one `fix:`, as in Cyborg (2026-11-17)

An error message shows a `fix:` only when there's exactly one, as in Cyborg. Several fixes, as Fale shows, were turned
down: every extra suggestion is more that can be wrong, and a wrong error message is worse than a bug in the garbage
collector. Messages say only what's certain.

Owner: "I think that's more surface to get wrong, and err msgs? It's not really the same as a GC bug to me", then "Wrong
err msgs are more annoying to me than having a bug in the GC".

## D61: Thai error messages start with `ไม่ผ่าน:` (2026-11-17)

In Thai, `refused:` is `ไม่ผ่าน:` ("didn't pass"), the word Thai students hear for a failed check. `ปฏิเสธ:` was turned
down as too formal, closer to "rejected". A Thai `why:` line says what the code has written on it, not what was
declared, as in `ที่เขียน `เปลี่ยนได้` ไว้` ("that has `mut` written on it"), since `ที่ประกาศ` ("which was declared")
is textbook language.

Thai messages call a variable `ตัวแปร`, the word Thai maths and programming textbooks use ("a symbol that varies"),
as in "ตัวแปร x" (owner: "yea").

`what:` is `ปัญหา:` ("problem"), which says what the line is. `อะไร:` ("what") was turned down: as a label it reads
like a bare question (owner: "I'm back. I think problem in Thai").

`why:` is `เหตุผล:` ("reason"), naming what the line is, like `ปัญหา:`. `ทำไม:` ("why") reads like a bare question,
and `เพราะ:` ("because") would clash with the `because:` label (owner: "yea, เหตุผล").

`fix:` is `วิธีแก้:` ("how to fix"), naming what the line is. `แก้:` ("fix") was offered (owner: "วิธีแก้").

`because:` is `เพราะ:` ("because"), which is free since `why:` became `เหตุผล:`. `สาเหตุ:` ("cause") was offered
(owner: "เพราะ:").

`when:` is `เมื่อ:` ("when"). `กรณี:` ("in the case") was turned down, since it's the draft Thai word for the `case`
keyword (owner: "เมื่อ:").

`check failed:` is `หยุดทำงาน:` ("stopped running"), which says what happened to the program and reads differently from
`ไม่ผ่าน:` while building. `ตรวจไม่ผ่าน:` ("check didn't pass") was turned down as too close to `ไม่ผ่าน:` (owner:
"หยุดทำงาน:").

`warning:` is `คำเตือน:` ("warning"), the word Thai apps and signs use. `ระวัง:` ("careful") was offered (owner:
"คำเตือน:").

All of D58's labels now have Thai:

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

Owner: "`ไม่ผ่าน:` and `ที่เขียน` is good, but idk if `ตัวแปร` means variable. I mean, I don't know the Thai word for
that".
