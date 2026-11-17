(* The program's text, split into lines, with the two kinds of column D58 needs. *)

type t = { file : string; lines : string array }

let read file =
  let text = In_channel.with_open_bin file In_channel.input_all in
  let pieces = String.split_on_char '\n' text in
  (* A final newline leaves an empty last piece, which isn't a line. *)
  let pieces =
    match List.rev pieces with "" :: rest -> List.rev rest | _ -> pieces
  in
  { file; lines = Array.of_list pieces }

let line source number =
  if number >= 1 && number <= Array.length source.lines then
    source.lines.(number - 1)
  else ""

(* trace: D58 *)
(* The column for people counts grapheme clusters, which differ from bytes in
   Thai, where vowels and tone marks join the letter they sit on. *)
let graphemes text =
  Uuseg_string.fold_utf_8 `Grapheme_cluster (fun count _ -> count + 1) 0 text
