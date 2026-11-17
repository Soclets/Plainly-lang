(* Splitting a program's text into tokens. Lexing stops at the first thing
   PlainOracle can't handle, and returns what it had found before it, with the
   message that stopped it. *)

open Token

let is_word_byte = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | other -> Char.code other >= 0x80

let stop kind line byte length words =
  raise
    (Message.Stop
       {
         Message.kind;
         line;
         byte;
         length;
         body = Message.What words;
         why = None;
       })

(* The length in bytes of the UTF-8 character starting at [index]. *)
let character_length text index =
  Uchar.utf_decode_length (String.get_utf_8_uchar text index)

let tokens (source : Source.t) =
  let found = ref [] in
  let lex_line index text =
    let line = index + 1 in
    let size = String.length text in
    let add kind start length =
      found := { kind; line; byte = start + 1; length } :: !found
    in
    let rec word_end index =
      if index < size && is_word_byte text.[index] then word_end (index + 1)
      else index
    in
    let rec go index =
      if index < size then
        match text.[index] with
        | ' ' | '\t' | '\r' -> go (index + 1)
        | ('.' | '[' | ']' | '(' | ')' | ':' | ';' | '=' | '+' | '&') as symbol
          ->
            add (Symbol symbol) index 1;
            go (index + 1)
        | '"' -> go (text_literal index)
        | '#' ->
            let finish = word_end (index + 1) in
            add
              (Name (String.sub text index (finish - index)))
              index (finish - index);
            go finish
        | character when is_word_byte character ->
            let finish = word_end index in
            let word = String.sub text index (finish - index) in
            (match keyword_of_word word with
            | Some (keyword, table) ->
                add (Keyword (keyword, table)) index (finish - index)
            | None -> add (Word word) index (finish - index));
            go finish
        | _ ->
            let length = character_length text index in
            stop Message.Not_built_yet line (index + 1) length
              (Printf.sprintf "`%s` isn't in PlainOracle yet"
                 (String.sub text index length))
    and text_literal start =
      let rec scan index =
        if index >= size then
          (* trace: D3 *)
          stop Message.Not_designed_yet line (start + 1) (size - start)
            "text that runs past the end of its line isn't decided yet"
        else
          match text.[index] with
          | '"' ->
              add
                (Text (String.sub text (start + 1) (index - start - 1)))
                start
                (index - start + 1);
              index + 1
          | '\\' ->
              (* trace: D3 *)
              (* A backslash keeps the next character, even a quote. Whether
                 that's allowed here depends on where the text is, so the
                 checker decides. *)
              scan (index + 2)
          | _ -> scan (index + 1)
      in
      scan (start + 1)
    in
    go 0
  in
  match Array.iteri lex_line source.lines with
  | () -> (List.rev !found, None)
  | exception Message.Stop message -> (List.rev !found, Some message)
