(* Error messages, in the layout D58 to D62 give. *)

type kind = Refused | Not_built_yet | Not_designed_yet

(* trace: D60 *)
(* A message shows a fix only when there's exactly one, and the fix replaces
   [what:]. *)
type body = Fix of string | What of string

(* [byte] and [length] mark the part in question, in bytes. A length of 0 marks
   the place where something is missing. *)
type t = {
  kind : kind;
  line : int;
  byte : int;
  length : int;
  body : body;
  why : string option;
}

exception Stop of t

let stops message = match message.kind with Refused -> false | _ -> true

let kind_word = function
  | Refused -> "refused"
  | Not_built_yet -> "NotBuiltYet"
  | Not_designed_yet -> "NotDesignedYet"

(* trace: D58 *)
let render (source : Source.t) message =
  let text = Source.line source message.line in
  let before = String.sub text 0 (message.byte - 1) in
  let part = String.sub text (message.byte - 1) message.length in
  let number = string_of_int message.line in
  let width = max 2 (String.length number) in
  let gutter label = String.make (width - String.length label) ' ' ^ label in
  let buffer = Buffer.create 256 in
  let add format = Printf.bprintf buffer format in
  add "%s: %s:%d:%d, line %d column %d\n" (kind_word message.kind) source.file
    message.line message.byte message.line
    (Source.graphemes before + 1);
  add "%s | %s\n" (gutter number) text;
  add "%s | %s%s\n" (gutter "")
    (String.make (Source.graphemes before) ' ')
    (String.make (max 1 (Source.graphemes part)) '^');
  (match message.body with
  | Fix code -> add " fix:  `%s`\n" code
  | What words -> add " what: %s\n" words);
  (match message.why with Some words -> add " why:  %s\n" words | None -> ());
  Buffer.contents buffer
