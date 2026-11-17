(* Reading the tokens as a program, refusing what Plainly refuses, and stopping
   at what PlainOracle can't handle yet. Slice 1: `procedure.main` with
   `show_text` statements. *)

open Token

type statement = Show_text of string

type state = {
  source : Source.t;
  tokens : Token.t array;
  lexer_stop : Message.t option;
  mutable position : int;
  mutable table : table option;
  mutable refusals : Message.t list;
}

let stop kind (token : Token.t) words =
  raise
    (Message.Stop
       {
         Message.kind;
         line = token.line;
         byte = token.byte;
         length = token.length;
         body = Message.What words;
         why = None;
       })

let text_of state (token : Token.t) =
  String.sub (Source.line state.source token.line) (token.byte - 1) token.length

let not_built state token =
  stop Message.Not_built_yet token
    (Printf.sprintf "`%s` isn't in PlainOracle yet" (text_of state token))

(* The token at the current position. Past the last token, it's the message
   that stopped lexing, if any, and otherwise the end of the file. *)
let current state =
  if state.position < Array.length state.tokens then
    Some state.tokens.(state.position)
  else
    match state.lexer_stop with
    | Some message -> raise (Message.Stop message)
    | None -> None

let advance state = state.position <- state.position + 1

let end_of_file state =
  let last = max 1 (Array.length state.source.lines) in
  raise
    (Message.Stop
       {
         Message.kind = Message.Not_built_yet;
         line = last;
         byte = String.length (Source.line state.source last) + 1;
         length = 0;
         body =
           Message.What
             "a file that ends before `end procedure.main` isn't in \
              PlainOracle yet";
         why = None;
       })

let next state =
  match current state with Some token -> token | None -> end_of_file state

let refuse state message = state.refusals <- message :: state.refusals

(* trace: D57 *)
let check_table state token table =
  match state.table with
  | None -> state.table <- Some table
  | Some first when first = table -> ()
  | Some _ ->
      stop Message.Not_designed_yet token
        "mixing English and Thai keywords in one file isn't decided yet"

let expect_keyword state keyword =
  let token = next state in
  match token.kind with
  | Keyword (found, table) when found = keyword ->
      check_table state token table;
      advance state;
      token
  | _ -> not_built state token

let expect_symbol state symbol =
  let token = next state in
  match token.kind with
  | Symbol found when found = symbol ->
      advance state;
      token
  | _ -> not_built state token

(* A missing piece is refused at the place right after [after], with the one
   fix. *)
let refuse_missing state (after : Token.t) code why =
  refuse state
    {
      Message.kind = Message.Refused;
      line = after.line;
      byte = after.byte + after.length;
      length = 0;
      body = Message.Fix code;
      why = Some why;
    }

(* trace: D63 *)
let header state =
  ignore (expect_keyword state Procedure_word);
  ignore (expect_symbol state '.');
  ignore (expect_keyword state Main_word);
  let opening = expect_symbol state '[' in
  let closing =
    let token = next state in
    match token.kind with
    | Symbol ']' ->
        (* trace: D69 *)
        refuse state
          {
            Message.kind = Message.Refused;
            line = opening.line;
            byte = opening.byte;
            length = token.byte + token.length - opening.byte;
            body = Message.Fix "[none]";
            why = Some "a procedure that takes nothing says `[none]`.";
          };
        advance state;
        token
    | Keyword (None_word, table) ->
        check_table state token table;
        advance state;
        expect_symbol state ']'
    | _ ->
        stop Message.Not_designed_yet token
          "parameters on `procedure.main` aren't decided yet"
  in
  (* trace: D62 *)
  (* A header missing only its `:` is clear, so checking carries on. *)
  match current state with
  | Some { kind = Symbol ':'; _ } -> advance state
  | Some token when token.line = closing.line -> not_built state token
  | _ ->
      refuse_missing state closing ":" "a block's opening line ends with `:`."

let starts_a_statement (token : Token.t) =
  match token.kind with
  | Keyword ((Show_text_word | End_word | Procedure_word), _) | Name _ -> true
  | _ -> false

(* trace: D12 *)
(* trace: D44 *)
let show_text state =
  ignore (expect_keyword state Show_text_word);
  (let token = next state in
   match token.kind with
   | Symbol '(' -> advance state
   | Symbol '.' ->
       stop Message.Not_built_yet token
         "narrowings of `show_text`, like `.format`, aren't in PlainOracle yet"
   | _ -> not_built state token);
  let words =
    let token = next state in
    match token.kind with
    | Text words ->
        advance state;
        words
    | _ -> not_built state token
  in
  let closing = expect_symbol state ')' in
  (* trace: D31 *)
  (* A statement ends at its `;`, so a missing `;` is certain only when the next
     line starts something that can't continue this one. *)
  (match current state with
  | Some { kind = Symbol ';'; _ } -> advance state
  | Some token when token.line > closing.line && starts_a_statement token ->
      refuse_missing state closing ";" "every statement ends with `;`."
  | None -> refuse_missing state closing ";" "every statement ends with `;`."
  | Some token -> not_built state token);
  Show_text words

let rec body state found =
  let token = next state in
  match token.kind with
  | Keyword (End_word, _) -> List.rev found
  | Keyword (Show_text_word, _) -> body state (show_text state :: found)
  | Name _ ->
      stop Message.Not_built_yet token "variables (#) aren't in PlainOracle yet"
  | _ -> not_built state token

let closer state =
  ignore (expect_keyword state End_word);
  ignore (expect_keyword state Procedure_word);
  ignore (expect_symbol state '.');
  ignore (expect_keyword state Main_word);
  match current state with None -> () | Some token -> not_built state token

let program source tokens lexer_stop =
  let state =
    {
      source;
      tokens = Array.of_list tokens;
      lexer_stop;
      position = 0;
      table = None;
      refusals = [];
    }
  in
  match
    header state;
    let statements = body state [] in
    closer state;
    statements
  with
  | statements -> (statements, List.rev state.refusals, None)
  | exception Message.Stop message -> ([], List.rev state.refusals, Some message)

(* trace: D70 *)
(* Every line is indented 4 spaces per level: a procedure's header and closer
   at no indentation, and its body one level in. *)
let indentation (source : Source.t) tokens =
  let firsts = Hashtbl.create 16 in
  List.iter
    (fun (token : Token.t) ->
      if not (Hashtbl.mem firsts token.line) then
        Hashtbl.add firsts token.line token)
    tokens;
  Hashtbl.fold
    (fun line (first : Token.t) messages ->
      let depth =
        match first.kind with
        | Keyword ((Procedure_word | End_word), _) -> 0
        | _ -> 1
      in
      let indent = String.sub (Source.line source line) 0 (first.byte - 1) in
      let wanted = String.make (4 * depth) ' ' in
      if indent = wanted then messages
      else
        let body, why =
          if depth > 0 then
            ( Message.Fix wanted,
              "a body is indented 4 spaces per level, never with a tab." )
          else
            ( Message.What
                (match first.kind with
                | Keyword (End_word, _) ->
                    "a block's closer lines up with its opening line"
                | _ -> "a procedure's opening line has no indentation"),
              "only a body is indented, 4 spaces per level." )
        in
        {
          Message.kind = Message.Refused;
          line;
          byte = 1;
          length = String.length indent;
          body;
          why = Some why;
        }
        :: messages)
    firsts []
