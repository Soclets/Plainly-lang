# Plainly

It's... Plain?

## Code snippet

```
procedure greet[#name: Text] returns Text:
return be.Text.format("Hello, {#name}!")
end procedure greet

procedure.main[]:
#name: Text = "Tankun"
#score: Whole = 120
show_text(greet(#name) & new_line)
show_text.format("{#name} has {#score} points.{new_line}")
end procedure.main
```

## Licences

- [`LICENSE`](LICENSE): Apache-2.0 WITH LLVM-exception, for the code. Programs you compile owe nothing.
- [`LICENSE-CC-BY-4.0`](LICENSE-CC-BY-4.0): CC BY 4.0, for this repo's writing: its Markdown files, including this README, `DECISIONS.md`, `IMPLEMENTATION.md`, `standard/` and `design/`. Credit them as `Plainly GitHub repo text: https://github.com/Soclets/Plainly-lang`, say they're under CC BY 4.0, and say whether you changed them.
