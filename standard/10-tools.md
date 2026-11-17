# 10. Tools

## `apy`

Plainly's compiler is AroundPy, AroundPython in full and APy for short, and its command is `apy` (D23, D79):

```
apy run game.plainly --mode=Working
apy build game.plainly --mode=FinalSafe
apy check game.plainly
apy convert game.plainly --language=ไทย
```

- **`run`** builds to a temporary file and runs it (D16, D79).
- **`build`** makes the binary to ship (D79).
- **`check`** shows the refusals without building (D79).
- **`convert`** rewrites a file into the other keyword table, language line included (D57, D79).
- **`--mode=`** takes a build mode. `run` and `build` need one, since there's no default (D19, D79).
- **`--language=`**, or `--lang=` for short, takes a language line's word, as in `--language=ไทย` or `--lang=eng` (D79).

The commands are fully Thai too, so nothing needs the English keyboard layout (D79):

| English | Thai |
|---|---|
| `apy` | `เอพาย` |
| `run` | `รัน` |
| `build` | `สร้าง` |
| `check` | `ตรวจ` |
| `convert` | `แปลง` |
| `--mode=` | `--โหมด=` |
| `--language=` | `--ภาษา=` |

**Not decided:** the Thai names of the build modes (D79).

## Build modes

Every build names its mode, and there's no default (D19):

| Mode | Compiling | Checks the compiler can't prove away |
|---|---|---|
| `Working` | the fastest compile, with no optimizations | kept |
| `FinalSafe` | optimized | kept |
| `FinalPerf` | optimized | dropped |

The checks are overflow, division by zero, bad positions, values outside a type's limits, and NaN and infinity in floats
(D19, D20, D66, D84, D85, D88). `FinalSafe` checks NaN and infinity more cheaply than `Working`, at the end of a
procedure or loop (D66, chapter 3). `FinalPerf` is for code already tested in `Working` or `FinalSafe` (D19).

The Final modes add Plainly's own optimizations before Cranelift's (D21). The modes differ only in optimizations, never
in how code is translated (D22).

**Not decided:** which optimizations (D21).

## How a program is compiled

AroundPy is written in Rust and compiles a whole program ahead of time to one native binary through Cranelift, with no
bytecode and no JIT (D16):

```
source → syntax tree → typed tree → Plainly IR → Cranelift IR → native
```

The typed tree has names resolved and types attached, and is where refusals happen. Plainly IR is Plainly's one IR of
its own, a control-flow graph where each check, allocation, label and default is written out (D22).

Cranelift builds for x86-64, ARM64 and RISC-V (D16).

## PlainGC

Plainly's memory is managed by PlainGC, which follows Go's collector (D38):

- it marks while the program runs, so pauses usually stay well under a millisecond;
- it never moves objects;
- it needs only a write barrier;
- it has no generations, and short-lived values are kept off the heap by escape analysis (D21);
- it groups objects by size;
- it finds references through Cranelift's stack maps (D16).

**Not decided:** how closely it follows Go's pacer (D38).

## PlainOracle

PlainOracle is the slow, obviously correct reference that AroundPy's output is checked against. It's written in OCaml,
so the compiler can't copy it and share its bugs, and it holds every `Whole` in 64 bits (D17). It prints exactly the
same messages and exit statuses as AroundPy (D58, D71), and stops with `NotBuiltYet` or `NotDesignedYet` where it can't
go yet (D72).

## Packages and the standard library

Plainly's standard library targets the terminal: printing, reading keys, drawing characters and colours. A GUI, if it
ever comes, is a separate package (D49).

The standard library has two random sources with names that can't be mixed up: a fast seeded one for games, and an
unpredictable one from the operating system for secrets (D25).

A package's names are used bare, and `package::` settles a clash (D39, chapter 2). Its Rust code is a static library
with symbols named after the package and procedure, so two packages can't collide (D40).

**Not decided:** the standard library's procedures and their names; the random sources' names and how a seed is given
(D25); the package manifest (D39).
