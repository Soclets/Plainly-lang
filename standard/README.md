# The Plainly standard

What Plainly is today, by topic. `DECISIONS.md` records how each rule was decided, in the order it happened; this
standard says what the rules are now.

## Rules

1. **`DECISIONS.md` is the source of truth.** The standard only restates what's decided, and every rule names its
   decision, as in "(D100)". Where they disagree, the decision wins and the standard is wrong.
2. **Undecided means "Not decided".** Anything the decisions leave open is marked **Not decided** where it would go,
   never filled in by the standard.
3. **They change together.** A decision that changes a rule changes the standard in the same commit.
4. **Examples use the long forms,** `procedure` and `mutable` rather than `proc` and `mut`, and are indented as Plainly
   requires (D70).

## Chapters

1. [Files](01-files.md): the language line, extensions, procedures in a file, lines, `;` and indentation
2. [Words](02-words.md): keywords in both tables, names, text, numbers and symbols
3. [Types and values](03-types.md): `Whole` and its limits, the number family, `Float`, `Text`, lists and arrays
4. [Variables](04-variables.md): declaring, `mutable`, `change`, `shadow`, `copy` and `share`
5. Expressions: maths order, operators, division and rounding, `&`, `.format`, comparisons, logic and the pipe
6. Control flow: `if`, loops and ranges, and what comes after an `if` that leaves
7. Procedures: headers, `returns`, labels, defaults, units, calls, `return` and `procedure.main`
8. Failures: `fails`, `?`, `otherwise` and handlers
9. Messages: the error layout, the kinds of message, and exit statuses
10. Tools: the `apy` commands, build modes, and PlainOracle
