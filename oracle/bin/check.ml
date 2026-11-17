(* Reading the tokens as a program, refusing what Plainly refuses, and stopping
   at what PlainOracle can't handle yet. So far: procedures with parameters,
   labels, defaults, units and results, variables of `Whole` and `Text`, `mut`
   and `change`, arithmetic, `&`, `be.Text`, `show_text`, `if`, and the pipe. *)

open Token

(* [Nothing_type] is what a procedure with no result gives, which only a
   statement of its own can use. *)
type value_type = Whole_type | Text_type | Bool_type | Nothing_type

let type_name = function
  | Whole_type -> "Whole"
  | Text_type -> "Text"
  | Bool_type -> "true or false"
  | Nothing_type -> "nothing"

(* An expression, with the place it covers and its type. Its type is [None]
   when the expression was refused, so nothing after it is refused because of
   it. *)
type expression = {
  shape : shape;
  line : int;
  byte : int;
  length : int;
  value_type : value_type option;
  (* The operator at the top of an unbracketed calculation, with its place, so
     that mixing it with `&` can be refused (D83). *)
  top_operator : (string * Token.t) option;
}

and shape =
  | Whole_literal of Int64.t
  | Text_literal of string
  | Variable of string
  | Arithmetic of operation * expression * expression * Token.t
  | Negate of expression * Token.t
  | Join of expression * expression
  (* trace: D34 *)
  | Compare_values of string * expression * expression
  (* trace: D36 *)
  (* trace: D37 *)
  | Logic of string * bool * expression * expression
  | Not of expression
  (* trace: D94 *)
  | Compare_text of bool * expression * expression
  | Be_text of expression
  | Format of piece list
  (* trace: D8 *)
  (* A call, with each argument's parameter position, in the order they're
     worked out, and defaults last. *)
  | Call of string * (int * expression) list
  (* trace: D30 *)
  (* `show_text` as a pipe's last step. *)
  | Shown of expression * bool

(* A piece of `.format` text: words as they are, or a fill-in. *)
and piece = Words of string | Fill of expression

(* trace: D84 *)
(* trace: D85 *)
(* trace: D87 *)
and operation =
  | Plus
  | Minus
  | Times
  | Divide of rounding
  | Remainder of rounding
  | Saturate of operation

and rounding = Down | Toward_zero

(* A number type's written limits (D88). *)
type limits = { minimum : Int64.t option; maximum : Int64.t option }

let no_limits = { minimum = None; maximum = None }

type statement =
  | If of (expression * statement list) list * statement list option
  | Show_text of expression * bool
  | Declare of string * expression * limits
  | Change of string * expression * limits
  | Expression_statement of expression
  | Return of expression option

(* trace: D8 *)
(* trace: D9 *)
(* trace: D47 *)
(* A parameter, with what a call writes for it: its label, its default and its
   unit. *)
type parameter = {
  parameter_name : string;
  parameter_type : value_type;
  parameter_limits : limits;
  label : string option;
  default : expression option;
  unit_word : string option;
}

(* trace: D46 *)
type signature = {
  procedure_name : string;
  parameters : parameter list;
  result : value_type option;
  any_order : bool;
}

(* An argument as written in a call. *)
type argument = {
  argument_label : (Token.t * Token.t) option;
  argument_value : expression;
  unit_token : Token.t option;
}

type state = {
  source : Source.t;
  tokens : Token.t array;
  lexer_stop : Message.t option;
  mutable position : int;
  mutable declared : table option;
  mutable declared_word : string;
  mutable refusals : Message.t list;
  mutable variables : (string * (value_type * bool)) list;
  mutable limits : (string * limits) list;
  mutable declared_on : (string * int) list;
  (* Refusals of `+` on text, held until it's known whether that `+` sits next
     to `&`, which is refused instead (D83). *)
  mutable pending : (Token.t * Message.t) list;
  (* Comparisons and true or false values are only read inside an `if`'s
     condition, since storing them isn't decided. *)
  mutable in_condition : bool;
  (* The indentation level each line's statement should have (D70). *)
  mutable depths : (int * int) list;
  (* trace: D96 *)
  (* Every procedure in the file, found before checking any body, so a call can
     come before its procedure. [None] is one whose header couldn't be read. *)
  mutable signatures : (string * signature option) list;
  mutable parameter_names : string list;
  (* The procedure being checked, [None] for `procedure.main`. *)
  mutable current_procedure : signature option;
  (* The token the current statement starts at. *)
  mutable statement_start : int;
  mutable defined : string list;
  mutable main_seen : bool;
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
             "a file that ends inside a procedure isn't in PlainOracle yet";
         why = None;
       })

let next state =
  match current state with Some token -> token | None -> end_of_file state

let refuse state message =
  if not (List.mem message state.refusals) then
    state.refusals <- message :: state.refusals

(* trace: D75 *)
(* A keyword from the other table than the file's language line is refused,
   with its word in the file's table as the fix. *)
let check_table state (token : Token.t) table =
  match (state.declared, token.kind) with
  | Some declared, Keyword (keyword, _) when declared <> table -> (
      match spelling keyword declared with
      | Some word ->
          refuse state
            {
              Message.kind = Message.Refused;
              line = token.line;
              byte = token.byte;
              length = token.length;
              body = Message.Fix word;
              why =
                Some
                  (Printf.sprintf "this file says `%s`, so its keywords are %s."
                     state.declared_word
                     (match declared with
                     | English -> "English"
                     | Thai -> "Thai"));
            }
      | None ->
          (* trace: D57 *)
          stop Message.Not_designed_yet token
            (Printf.sprintf "the Thai word for `%s` isn't decided yet"
               (text_of state token)))
  | _ -> ()

(* A word with no Thai form yet, like a type name, can't be used in a Thai
   file. *)
let english_only state (token : Token.t) =
  match state.declared with
  | Some Thai ->
      stop Message.Not_designed_yet token
        (Printf.sprintf "the Thai word for `%s` isn't decided yet"
           (text_of state token))
  | _ -> ()

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

let record_depth_line state line depth =
  if not (List.mem_assoc line state.depths) then
    state.depths <- (line, depth) :: state.depths

(* trace: D75 *)
(* A file's first line is its language, alone on the line. *)
let language_line state =
  let missing () =
    refuse state
      {
        Message.kind = Message.Refused;
        line = 1;
        byte = 1;
        length = 0;
        body = Message.What "the file doesn't say its language";
        why = Some "a file starts with its language: `english` or `ไทย`.";
      }
  in
  match current state with
  | Some ({ kind = Word word; line = 1; _ } as token) -> (
      match language_of_word word with
      | Some table -> (
          state.declared <- Some table;
          state.declared_word <- word;
          record_depth_line state token.line 0;
          (* trace: D79 *)
          (* trace: D80 *)
          (* The extension must match the language line. When it doesn't, the
             file's language is in doubt, so its keywords aren't checked
             against either table, and its messages stay in English. *)
          let extension = Filename.extension state.source.file in
          (match (table, extension) with
          | English, ".plainly" | Thai, ".เพลนลี่" -> ()
          | _ ->
              refuse state
                {
                  Message.kind = Message.Refused;
                  line = token.line;
                  byte = token.byte;
                  length = token.length;
                  body =
                    Message.What
                      (match extension with
                      | ".plainly" | ".เพลนลี่" ->
                          Printf.sprintf
                            "this file says `%s`, but its name ends in `%s`"
                            word extension
                      | _ ->
                          "this file's name doesn't end in `.plainly` or \
                           `.เพลนลี่`");
                  why =
                    Some
                      "a file's name ends in `.plainly` for English and \
                       `.เพลนลี่` for Thai.";
                };
              state.declared <- None);
          advance state;
          match current state with
          | Some next when next.line = token.line -> not_built state next
          | _ -> ())
      | None -> missing ())
  | _ -> missing ()

(* Words that can continue an expression on the next line. *)
let continuing_words =
  [
    "x";
    "and";
    "or";
    "not";
    "at_least";
    "at_most";
    "divide";
    "div";
    "remainder";
    "mod";
    "plus";
    "minus";
    "times";
    "หาร";
    "หาเศษ";
    "บวก";
    "ลบ";
    "คูณ";
  ]

let starts_a_statement (token : Token.t) =
  match token.kind with
  | Keyword
      ( ( Show_text_word | End_word | Procedure_word | Mut_word | Change_word
        | Shadow_word | If_word ),
        _ )
  | Name _ | Text _ ->
      true
  | Word word -> not (List.mem word continuing_words)
  | _ -> false

let previous state = state.tokens.(state.position - 1)

(* trace: D31 *)
(* A statement ends at its `;`, so a missing `;` is certain only when the next
   line starts something that can't continue this one. *)
let finish state =
  let last = previous state in
  match current state with
  | Some { kind = Symbol ';'; _ } -> advance state
  | Some token when token.line > last.line && starts_a_statement token ->
      refuse_missing state last ";" "every statement ends with `;`."
  | None -> refuse_missing state last ";" "every statement ends with `;`."
  | Some token -> not_built state token

let refuse_at state (expression : expression) body why =
  refuse state
    {
      Message.kind = Message.Refused;
      line = expression.line;
      byte = expression.byte;
      length = expression.length;
      body;
      why = Some why;
    }

let text_of_expression state (expression : expression) =
  String.sub
    (Source.line state.source expression.line)
    (expression.byte - 1) expression.length

let spanning (first : Token.t) (last : Token.t) shape value_type =
  {
    shape;
    line = first.line;
    byte = first.byte;
    length = last.byte + last.length - first.byte;
    value_type;
    top_operator = None;
  }

let joined (left : expression) (right : expression) shape value_type =
  {
    shape;
    line = left.line;
    byte = left.byte;
    length = right.byte + right.length - left.byte;
    value_type;
    top_operator = None;
  }

(* From an expression to a token on the same line. *)
let from_to (left : expression) (last : Token.t) shape value_type =
  {
    shape;
    line = left.line;
    byte = left.byte;
    length = last.byte + last.length - left.byte;
    value_type;
    top_operator = None;
  }

let token_of_expression (expression : expression) =
  {
    Token.kind = Word "";
    line = expression.line;
    byte = expression.byte;
    length = expression.length;
  }

let is_digit character = character >= '0' && character <= '9'

(* trace: D27 *)
let find_variable state (token : Token.t) name =
  match List.assoc_opt name state.variables with
  | Some found -> Some found
  | None ->
      refuse state
        {
          Message.kind = Message.Refused;
          line = token.line;
          byte = token.byte;
          length = token.length;
          body =
            Message.What
              (Printf.sprintf "`%s` isn't declared before this line" name);
          why =
            Some "a variable (#) is declared, with its type, before it's used.";
        };
      None

(* trace: D3 *)
(* Text outside `.format` is literal, and what `\` means there isn't decided. *)
let plain_text (token : Token.t) words =
  match String.index_opt words '\\' with
  | Some index ->
      raise
        (Message.Stop
           {
             Message.kind = Message.Not_designed_yet;
             line = token.line;
             byte = token.byte + 1 + index;
             length = 1;
             body =
               Message.What "`\\` in text outside `.format` isn't decided yet";
             why = None;
           })
  | None -> ()

let expect_word state word =
  let token = next state in
  match token.kind with
  | Word found when found = word ->
      english_only state token;
      advance state;
      token
  | _ -> not_built state token

let is_format_next state =
  state.position + 2 < Array.length state.tokens
  &&
  match
    ( state.tokens.(state.position + 1).kind,
      state.tokens.(state.position + 2).kind )
  with
  | Symbol '.', Keyword (Format_word, _) -> true
  | _ -> false

let is_letter_or_digit = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' -> true
  | _ -> false

let is_name_byte = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | other -> Char.code other >= 0x80

(* trace: D2 *)
(* trace: D4 *)
(* trace: D5 *)
(* trace: D7 *)
(* `.format` text: `{#name}` and `{new_line}` are filled in, `\` keeps the next
   character, so `\{` is a brace, and a lone `}` is just a character. *)
let format_text state (token : Token.t) text =
  let size = String.length text in
  let at index length kind words =
    {
      Message.kind;
      line = token.line;
      byte = token.byte + 1 + index;
      length;
      body = Message.What words;
      why = None;
    }
  in
  let pieces = ref [] in
  let buffer = Buffer.create 16 in
  let flush () =
    if Buffer.length buffer > 0 then (
      pieces := Words (Buffer.contents buffer) :: !pieces;
      Buffer.clear buffer)
  in
  let rec go index =
    if index < size then
      match text.[index] with
      | '\\' when index + 1 < size ->
          let next_character = text.[index + 1] in
          if is_letter_or_digit next_character then
            raise
              (Message.Stop
                 (at index 1 Message.Not_designed_yet
                    "`\\` before a letter isn't decided yet"));
          Buffer.add_char buffer next_character;
          go (index + 2)
      | '{' -> (
          match String.index_from_opt text (index + 1) '}' with
          | None ->
              refuse state
                {
                  (at index 1 Message.Refused "this `{` has no `}`") with
                  why = Some "a fill-in starts with `{` and ends with `}`.";
                }
          | Some closing ->
              let inside = String.sub text (index + 1) (closing - index - 1) in
              fill index inside closing;
              go (closing + 1))
      | character ->
          Buffer.add_char buffer character;
          go (index + 1)
  and fill index inside closing =
    let calculation () =
      refuse state
        {
          (at index
             (closing - index + 1)
             Message.Refused
             (Printf.sprintf "`{%s}` holds a calculation, not a value" inside))
          with
          why = Some "a fill-in only reads a value, so it can never hide work.";
        }
    in
    match keyword_of_word inside with
    | Some (New_line_word, table) ->
        (* trace: D4 *)
        check_table state
          {
            Token.kind = Keyword (New_line_word, table);
            line = token.line;
            byte = token.byte + 2 + index;
            length = String.length inside;
          }
          table;
        Buffer.add_char buffer '\n'
    | _ ->
        if String.length inside > 0 && inside.[0] = '#' then
          let size = String.length inside in
          let rec name_end position =
            if position < size && is_name_byte inside.[position] then
              name_end (position + 1)
            else position
          in
          let finish = name_end 1 in
          if finish = size then (
            flush ();
            let name_token =
              {
                Token.kind = Name inside;
                line = token.line;
                byte = token.byte + 2 + index;
                length = size;
              }
            in
            let value_type =
              Option.map fst (find_variable state name_token inside)
            in
            pieces :=
              Fill (spanning name_token name_token (Variable inside) value_type)
              :: !pieces)
          else
            match inside.[finish] with
            | '.' ->
                raise
                  (Message.Stop
                     (at
                        (index + 1 + finish)
                        1 Message.Not_designed_yet
                        "fields in a fill-in aren't decided yet"))
            | ',' ->
                raise
                  (Message.Stop
                     (at
                        (index + 1 + finish)
                        1 Message.Not_designed_yet
                        "settings in a fill-in, like a width, aren't decided \
                         yet"))
            | _ -> calculation ()
        else if String.exists (fun c -> String.contains "+-*/&|()" c) inside
        then calculation ()
        else
          raise
            (Message.Stop
               (at index
                  (closing - index + 1)
                  Message.Not_designed_yet
                  (Printf.sprintf "`{%s}` isn't decided yet" inside)))
  in
  go 0;
  flush ();
  List.rev !pieces

(* The argument of `.format` is text written in quotes. *)
let format_argument state =
  let token = next state in
  match token.kind with
  | Text words ->
      advance state;
      format_text state token words
  | _ ->
      stop Message.Not_designed_yet token
        "`.format` of text that isn't written in quotes isn't decided yet"

(* An operator found where one can be: its text as written, the place it
   covers, and how tightly it binds (D83): 2 for `x`, `divide` and `remainder`,
   1 for `+` and `-`, 0 for `&`. *)
type operator = {
  text : string;
  place : Token.t;
  level : int;
  doing : doing;
  token_count : int;
}

and doing = Calculate of operation | Bare_divide | Join_text

let spaced state (token : Token.t) =
  let text = Source.line state.source token.line in
  let before = token.byte - 2 and after = token.byte - 1 + token.length in
  before >= 0
  && (text.[before] = ' ' || text.[before] = '\t')
  && after < String.length text
  && (text.[after] = ' ' || text.[after] = '\t')

let token_at state index =
  if index < Array.length state.tokens then Some state.tokens.(index) else None

(* trace: D57 *)
(* The arithmetic words in both tables, each with what it means. The first
   word for a meaning in a table is the one a fix suggests. *)
let arithmetic_words =
  [
    ("divide", "divide", English);
    ("div", "divide", English);
    ("หาร", "divide", Thai);
    ("remainder", "remainder", English);
    ("mod", "remainder", English);
    ("หาเศษ", "remainder", Thai);
    ("plus", "plus", English);
    ("บวก", "plus", Thai);
    ("minus", "minus", English);
    ("ลบ", "minus", Thai);
    ("times", "times", English);
    ("คูณ", "times", Thai);
    ("down", "down", English);
    ("ปัดลง", "down", Thai);
    ("toward_zero", "toward_zero", English);
    ("ตัดเศษ", "toward_zero", Thai);
    ("exact", "exact", English);
    ("ลงตัว", "exact", Thai);
    ("saturate", "saturate", English);
    ("ไม่เกิน", "saturate", Thai);
    ("minimum", "minimum", English);
    ("min", "minimum", English);
    ("ต่ำสุด", "minimum", Thai);
    ("maximum", "maximum", English);
    ("max", "maximum", English);
    ("สูงสุด", "maximum", Thai);
  ]

(* What an arithmetic word means, refusing one from the other table than the
   file's language, with its word in the file's table as the fix (D75). *)
let meaning_of state (token : Token.t) word =
  match List.find_opt (fun (found, _, _) -> found = word) arithmetic_words with
  | None -> None
  | Some (_, meaning, table) ->
      (match state.declared with
      | Some declared when declared <> table ->
          let fix =
            match
              List.find_opt
                (fun (_, other, other_table) ->
                  other = meaning && other_table = declared)
                arithmetic_words
            with
            | Some (spelling, _, _) -> spelling
            | None -> meaning
          in
          refuse state
            {
              Message.kind = Message.Refused;
              line = token.line;
              byte = token.byte;
              length = token.length;
              body = Message.Fix fix;
              why =
                Some
                  (Printf.sprintf "this file says `%s`, so its keywords are %s."
                     state.declared_word
                     (match declared with
                     | English -> "English"
                     | Thai -> "Thai"));
            }
      | _ -> ());
      Some meaning

(* Looks at the operator at the current position without moving past it. *)
let peek_operator state =
  match current state with
  | None -> None
  | Some token -> (
      let one doing level =
        Some
          {
            text = text_of state token;
            place = token;
            level;
            doing;
            token_count = 1;
          }
      in
      let narrowed (narrowing : Token.t) doing level =
        Some
          {
            text =
              String.sub
                (Source.line state.source token.line)
                (token.byte - 1)
                (narrowing.byte + narrowing.length - token.byte);
            place =
              {
                token with
                length = narrowing.byte + narrowing.length - token.byte;
              };
            level;
            doing;
            token_count = 3;
          }
      in
      let narrowing () =
        match
          ( token_at state (state.position + 1),
            token_at state (state.position + 2) )
        with
        | Some { kind = Symbol '.'; _ }, Some ({ kind = Word word; _ } as found)
          -> (
            match meaning_of state found word with
            | Some meaning -> Some (meaning, found)
            | None -> Some (word, found))
        | _ -> None
      in
      match token.kind with
      | Symbol '+' -> one (Calculate Plus) 1
      | Symbol '-' ->
          (* trace: D86 *)
          if spaced state token then one (Calculate Minus) 1
          else
            stop Message.Not_designed_yet token
              "a `-` without a space on each side, between two values, isn't \
               decided yet"
      | Symbol '&' -> one Join_text 0
      | Word "x" -> one (Calculate Times) 2
      | Word word -> (
          match meaning_of state token word with
          | Some "divide" -> (
              match narrowing () with
              | Some ("down", found) ->
                  narrowed found (Calculate (Divide Down)) 2
              | Some ("toward_zero", found) ->
                  narrowed found (Calculate (Divide Toward_zero)) 2
              | Some ("exact", found) ->
                  stop Message.Not_built_yet found
                    "`.exact` isn't in PlainOracle yet, since failures aren't"
              | Some (_, found) -> not_built state found
              | None -> one Bare_divide 2)
          | Some "remainder" -> (
              match narrowing () with
              | Some ("down", found) ->
                  narrowed found (Calculate (Remainder Down)) 2
              | Some ("toward_zero", found) ->
                  narrowed found (Calculate (Remainder Toward_zero)) 2
              | Some (_, found) -> not_built state found
              | None ->
                  stop Message.Not_built_yet token
                    "a `remainder` that doesn't say how to round isn't in \
                     PlainOracle yet")
          | Some (("plus" | "minus" | "times") as meaning) -> (
              let operation, level =
                match meaning with
                | "plus" -> (Plus, 1)
                | "minus" -> (Minus, 1)
                | _ -> (Times, 2)
              in
              match narrowing () with
              | Some ("saturate", found) ->
                  narrowed found (Calculate (Saturate operation)) level
              | Some (_, found) -> not_built state found
              | None ->
                  stop Message.Not_designed_yet token
                    (Printf.sprintf "a bare `%s` isn't decided yet" word))
          | _ -> None)
      | _ -> None)

let take_operator state operator =
  state.position <- state.position + operator.token_count

let refuse_mixed state (text, (place : Token.t)) =
  (* trace: D83 *)
  state.pending <-
    List.filter (fun ((held : Token.t), _) -> held <> place) state.pending;
  refuse state
    {
      Message.kind = Message.Refused;
      line = place.line;
      byte = place.byte;
      length = place.length;
      body =
        Message.What
          (Printf.sprintf "`%s` and `&` are mixed without `( )`" text);
      why = Some "maths doesn't say which goes first, so `( )` shows it.";
    }

let check_holds state name variable_type (value : expression) =
  match value.value_type with
  | Some found when found <> variable_type ->
      refuse_at state value
        (Message.What
           (Printf.sprintf "`%s` is `%s`, but `%s` is a `%s`"
              (text_of_expression state value)
              (type_name found) name (type_name variable_type)))
        "a variable (#) holds only the type written for it."
  | _ -> ()

(* trace: D88 *)
(* A written number outside the limits is refused, since it can be seen while
   building. Anything else is checked while running. *)
let check_limits state name limits (value : expression) =
  match value.shape with
  | Whole_literal number -> (
      let refuse_limit words =
        refuse_at state value (Message.What words)
          "a number stays within the limits written for its type."
      in
      let text = text_of_expression state value in
      match limits with
      | { maximum = Some high; _ } when number > high ->
          refuse_limit
            (Printf.sprintf "`%s` is above `%s`'s maximum of %Ld" text name high)
      | { minimum = Some low; _ } when number < low ->
          refuse_limit
            (Printf.sprintf "`%s` is below `%s`'s minimum of %Ld" text name low)
      | _ -> ())
  | _ -> ()

let rec expression state =
  let start = state.position in
  let held = state.pending in
  state.pending <- [];
  let first = arithmetic state 1 in
  let result = joins state first in
  List.iter (fun (_, message) -> refuse state message) (List.rev state.pending);
  state.pending <- held;
  pipe state start result

(* trace: D1 *)
(* trace: D6 *)
(* trace: D83 *)
(* `&` joins text. Maths says nothing about `&` against `+`, `-`, `x` or
   `divide`, so an unbracketed calculation next to `&` is refused, and the
   result's type becomes unknown, so nothing after is refused because of it. *)
and joins state left =
  match peek_operator state with
  | Some ({ doing = Join_text; _ } as operator) ->
      take_operator state operator;
      let right = arithmetic state 1 in
      let mixed =
        match (left.top_operator, right.top_operator) with
        | Some top, _ | None, Some top ->
            refuse_mixed state top;
            true
        | None, None -> false
      in
      if mixed then joins state (joined left right (Join (left, right)) None)
      else
        let check_side side =
          match side.value_type with
          | Some Bool_type ->
              stop Message.Not_designed_yet operator.place
                "true or false values joined with `&` aren't decided yet"
          | Some Whole_type ->
              refuse_at state side
                (Message.Fix
                   (Printf.sprintf "be.Text(%s)"
                      (text_of_expression state side)))
                "`&` joins text, and doesn't turn a number into text by itself."
          | _ -> ()
        in
        check_side left;
        check_side right;
        let value_type =
          match (left.value_type, right.value_type) with
          | None, _ | _, None -> None
          | _ -> Some Text_type
        in
        joins state (joined left right (Join (left, right)) value_type)
  | _ -> left

(* Maths order: operators that bind tighter are gathered first, and ones of the
   same level go left to right. *)
and arithmetic state minimum_level =
  let left = negation state in
  climb state left minimum_level

and climb state left minimum_level =
  match peek_operator state with
  | Some ({ doing = Calculate _ | Bare_divide; level; _ } as operator)
    when level >= minimum_level ->
      take_operator state operator;
      let right = arithmetic state (level + 1) in
      climb state (calculate state operator left right) minimum_level
  | _ -> left

and calculate state operator left right =
  let whole shape =
    {
      (joined left right shape (Some Whole_type)) with
      top_operator = Some (operator.text, operator.place);
    }
  in
  (match (left.value_type, right.value_type) with
  | Some Bool_type, _ | _, Some Bool_type ->
      stop Message.Not_designed_yet operator.place
        "true or false values in calculations aren't decided yet"
  | _ -> ());
  match (operator.doing, left.value_type, right.value_type) with
  | Calculate operation, Some Whole_type, Some Whole_type ->
      whole (Arithmetic (operation, left, right, operator.place))
  | Bare_divide, Some Whole_type, Some Whole_type ->
      (* trace: D85 *)
      let whole_text =
        String.sub
          (Source.line state.source left.line)
          (left.byte - 1)
          (right.byte + right.length - left.byte)
      in
      refuse state
        {
          Message.kind = Message.Refused;
          line = left.line;
          byte = left.byte;
          length = right.byte + right.length - left.byte;
          body =
            Message.What
              (Printf.sprintf "`%s` doesn't say how to round" whole_text);
          why =
            Some
              "whole numbers divide with `.down`, `.toward_zero` or `.exact`.";
        };
      whole (Arithmetic (Divide Down, left, right, operator.place))
  | Calculate Plus, Some Text_type, Some Text_type ->
      state.pending <-
        ( operator.place,
          {
            Message.kind = Message.Refused;
            line = operator.place.line;
            byte = operator.place.byte;
            length = operator.place.length;
            body = Message.Fix "&";
            why = Some "`+` is only for numbers, and `&` joins text.";
          } )
        :: state.pending;
      {
        (joined left right (Join (left, right)) (Some Text_type)) with
        top_operator = Some (operator.text, operator.place);
      }
  | Calculate Plus, Some _, Some _ ->
      refuse state
        {
          Message.kind = Message.Refused;
          line = operator.place.line;
          byte = operator.place.byte;
          length = operator.place.length;
          body = Message.What "`+` can't add `Text`";
          why = Some "`+` is only for numbers, and `&` joins text.";
        };
      joined left right (Arithmetic (Plus, left, right, operator.place)) None
  | _, Some _, Some _ ->
      stop Message.Not_built_yet operator.place
        (Printf.sprintf "`%s` on `Text` isn't in PlainOracle yet" operator.text)
  | Calculate operation, _, _ ->
      joined left right
        (Arithmetic (operation, left, right, operator.place))
        None
  | _ ->
      joined left right
        (Arithmetic (Divide Down, left, right, operator.place))
        None

(* trace: D86 *)
(* A `-` right before a number or a name negates it. *)
and negation state =
  match current state with
  | Some ({ kind = Symbol '-'; _ } as minus) -> (
      let next_token = token_at state (state.position + 1) in
      match next_token with
      | Some ({ kind = Word digits; _ } as number)
        when number.line = minus.line
             && number.byte = minus.byte + 1
             && String.length digits > 0
             && is_digit digits.[0] ->
          advance state;
          advance state;
          whole_number state minus number ("-" ^ digits)
      | Some ({ kind = Name _; _ } as name)
        when name.line = minus.line && name.byte = minus.byte + 1 ->
          advance state;
          let inner = primary state in
          {
            (spanning minus name (Negate (inner, minus)) inner.value_type) with
            length = inner.byte + inner.length - minus.byte;
          }
      | _ ->
          stop Message.Not_designed_yet minus
            "a `-` that isn't right before a number or a name isn't decided yet"
      )
  | _ -> primary state

and whole_number state (first : Token.t) (last : Token.t) text =
  if
    not
      (String.for_all is_digit
         (String.sub text
            (if text.[0] = '-' then 1 else 0)
            (String.length text - if text.[0] = '-' then 1 else 0)))
  then
    stop Message.Not_designed_yet first
      "this way of writing a number isn't decided yet"
  else
    match Int64.of_string_opt text with
    | Some value -> spanning first last (Whole_literal value) (Some Whole_type)
    | None ->
        refuse state
          {
            Message.kind = Message.Refused;
            line = first.line;
            byte = first.byte;
            length = last.byte + last.length - first.byte;
            body =
              Message.What (Printf.sprintf "`%s` doesn't fit in a `Whole`" text);
            why =
              Some
                "a `Whole` holds whole numbers from -9223372036854775808 to \
                 9223372036854775807.";
          };
        spanning first last (Whole_literal 0L) (Some Whole_type)

(* trace: D36 *)
(* trace: D92 *)
(* A condition: `not` first, then `and`, then `or`, with comparisons tighter
   than all three. *)
and condition state = or_level state

and logic_word state word =
  match current state with
  | Some ({ kind = Word found; _ } as token) when found = word ->
      english_only state token;
      let both =
        match
          ( token_at state (state.position + 1),
            token_at state (state.position + 2) )
        with
        | ( Some { kind = Symbol '.'; _ },
            Some ({ kind = Word "both"; _ } as narrowing) ) ->
            english_only state narrowing;
            true
        | _ -> false
      in
      state.position <- (state.position + if both then 3 else 1);
      Some both
  | _ -> None

and or_level state =
  let rec more left =
    match logic_word state "or" with
    | Some both ->
        let right = and_level state in
        require_condition state left;
        require_condition state right;
        more
          (joined left right (Logic ("or", both, left, right)) (Some Bool_type))
    | None -> left
  in
  more (and_level state)

and and_level state =
  let rec more left =
    match logic_word state "and" with
    | Some both ->
        let right = not_level state in
        require_condition state left;
        require_condition state right;
        more
          (joined left right
             (Logic ("and", both, left, right))
             (Some Bool_type))
    | None -> left
  in
  more (not_level state)

and not_level state =
  match current state with
  | Some ({ kind = Word "not"; _ } as token) ->
      english_only state token;
      advance state;
      let inner = not_level state in
      require_condition state inner;
      {
        (spanning token token (Not inner) (Some Bool_type)) with
        length = inner.byte + inner.length - token.byte;
      }
  | _ -> comparison state

(* trace: D34 *)
(* trace: D93 *)
(* trace: D94 *)
and comparison state =
  let left = expression state in
  let operator =
    match current state with
    | Some ({ kind = Compare text; _ } as token) ->
        if (text = "<" || text = ">") && not (spaced state token) then
          stop Message.Not_built_yet token
            (Printf.sprintf
               "`%s` without a space on each side isn't in PlainOracle yet" text);
        Some (text, token)
    | Some ({ kind = Word (("at_least" | "at_most") as word); _ } as token) ->
        english_only state token;
        Some (word, token)
    | Some ({ kind = Symbol '='; _ } as token) ->
        refuse state
          {
            Message.kind = Message.Refused;
            line = token.line;
            byte = token.byte;
            length = token.length;
            body = Message.Fix "==";
            why = Some "`=` gives a variable its value, and `==` compares.";
          };
        Some ("==", token)
    | _ -> None
  in
  match operator with
  | None -> left
  | Some (text, token) -> (
      advance state;
      let right = expression state in
      (match current state with
      | Some
          ({ kind = Compare _ | Word ("at_least" | "at_most"); _ } as next_token)
        ->
          stop Message.Not_designed_yet next_token
            "a chain of comparisons isn't decided yet"
      | _ -> ());
      let compared =
        joined left right (Compare_values (text, left, right)) (Some Bool_type)
      in
      match (left.value_type, right.value_type) with
      | Some Whole_type, Some Whole_type -> compared
      | Some Text_type, Some Text_type ->
          if text = "==" || text = "!=" then
            refuse state
              {
                Message.kind = Message.Refused;
                line = token.line;
                byte = token.byte;
                length = token.length;
                body =
                  Message.What
                    (Printf.sprintf "`%s` doesn't compare `Text`" text);
                why =
                  Some
                    "text is compared with `compare_Text.stored_same` or \
                     `compare_Text.looks_same`.";
              }
          else
            stop Message.Not_designed_yet token
              (Printf.sprintf "`%s` between two `Text`s isn't decided yet" text);
          compared
      | Some Bool_type, _ | _, Some Bool_type ->
          stop Message.Not_designed_yet token
            "comparing true or false values isn't decided yet"
      | Some found_left, Some found_right ->
          refuse_at state compared
            (Message.What
               (Printf.sprintf
                  "`%s` is `%s` and `%s` is `%s`, so they can't be compared"
                  (text_of_expression state left)
                  (type_name found_left)
                  (text_of_expression state right)
                  (type_name found_right)))
            "only values of the same type can be compared.";
          compared
      | _ -> { compared with value_type = None })

(* trace: D93 *)
and require_condition state (value : expression) =
  match value.value_type with
  | Some (Whole_type | Text_type) ->
      refuse_at state value
        (Message.What
           (Printf.sprintf "`%s` isn't a comparison"
              (text_of_expression state value)))
        "an `if` needs something true or false, like `#score > 0`."
  | _ -> ()

and primary state =
  let token = next state in
  match token.kind with
  | Text words ->
      advance state;
      plain_text token words;
      spanning token token (Text_literal words) (Some Text_type)
  | Keyword (New_line_word, table) ->
      (* trace: D4 *)
      check_table state token table;
      advance state;
      spanning token token (Text_literal "\n") (Some Text_type)
  | Word digits when String.length digits > 0 && is_digit digits.[0] ->
      advance state;
      whole_number state token token digits
  | Name name ->
      advance state;
      let value_type = Option.map fst (find_variable state token name) in
      spanning token token (Variable name) value_type
  | Keyword (Be_word, table) -> (
      (* trace: D6 *)
      check_table state token table;
      advance state;
      ignore (expect_symbol state '.');
      let type_token = next state in
      match type_token.kind with
      | Keyword (Text_word, table) when is_format_next state ->
          (* trace: D11 *)
          check_table state type_token table;
          advance state;
          ignore (expect_symbol state '.');
          ignore (expect_keyword state Format_word);
          ignore (expect_symbol state '(');
          let pieces = format_argument state in
          let closing = expect_symbol state ')' in
          spanning token closing (Format pieces) (Some Text_type)
      | Keyword (Text_word, table) ->
          check_table state type_token table;
          advance state;
          ignore (expect_symbol state '(');
          let inner = expression state in
          let closing = expect_symbol state ')' in
          let value_type =
            match inner.value_type with
            | None -> None
            | Some _ -> Some Text_type
          in
          let converted = spanning token closing (Be_text inner) value_type in
          (* trace: D90 *)
          (* Converting text to text does nothing, so it's refused, with the
             value itself as the fix. *)
          (match inner.value_type with
          | Some Text_type ->
              let inner_text = text_of_expression state inner in
              refuse_at state converted (Message.Fix inner_text)
                (Printf.sprintf
                   "`%s` is already `Text`, so there's nothing to convert."
                   inner_text)
          | _ -> ());
          converted
      | _ -> not_built state type_token)
  | Symbol '(' ->
      (* trace: D51 *)
      advance state;
      let inner =
        if state.in_condition then condition state else expression state
      in
      let closing = expect_symbol state ')' in
      spanning token closing inner.shape inner.value_type
  | Word "compare_Text" -> (
      (* trace: D94 *)
      english_only state token;
      if not state.in_condition then
        stop Message.Not_designed_yet token
          "true or false values outside an `if` aren't decided yet";
      advance state;
      ignore (expect_symbol state '.');
      let method_token = next state in
      match method_token.kind with
      | Word (("stored_same" | "looks_same") as method_word) ->
          english_only state method_token;
          advance state;
          ignore (expect_symbol state '(');
          let first = expression state in
          ignore (expect_symbol state ',');
          let second = expression state in
          let closing = expect_symbol state ')' in
          List.iter
            (fun (argument : expression) ->
              match argument.value_type with
              | Some Text_type | None -> ()
              | Some _ ->
                  stop Message.Not_built_yet method_token
                    "`compare_Text` of something that isn't `Text` isn't in \
                     PlainOracle yet")
            [ first; second ];
          spanning token closing
            (Compare_text (method_word = "looks_same", first, second))
            (Some Bool_type)
      | _ -> not_built state method_token)
  | Word name when next_is_symbol state '(' -> (
      let start = state.position in
      match List.assoc_opt name state.signatures with
      | None -> not_built state token
      | Some found ->
          advance state;
          let written, closing = arguments state token in
          let shape, value_type =
            match found with
            | Some signature ->
                check_call state signature token closing None written
            | None -> (Call (name, []), None)
          in
          let result = spanning token closing shape value_type in
          allow_nothing state start result;
          result)
  | Keyword (Procedure_word, table) when next_is_symbol state '.' ->
      check_table state token table;
      advance state;
      main_call state token
  | _ -> not_built state token

and next_is_symbol state symbol =
  match token_at state (state.position + 1) with
  | Some { kind = Symbol found; _ } -> found = symbol
  | _ -> false

(* trace: D63 *)
(* trace: D95 *)
and main_call state (token : Token.t) =
  ignore (expect_symbol state '.');
  let main_token = expect_keyword state Main_word in
  let closing =
    match current state with
    | Some { kind = Symbol '('; _ } -> snd (arguments state main_token)
    | _ -> main_token
  in
  let called = spanning token closing (Call ("", [])) None in
  refuse_at state called (Message.What "`procedure.main` can't be called")
    "`procedure.main` runs once, when the program starts.";
  called

(* What a procedure with no result gives can only be a statement of its own:
   the whole statement, with nothing after it. *)
and allow_nothing state start (result : expression) =
  if result.value_type = Some Nothing_type then
    let ends =
      match current state with
      | None -> true
      | Some { kind = Symbol ';'; _ } -> true
      | Some token -> token.line > (previous state).line
    in
    if not (start = state.statement_start && ends) then
      stop Message.Not_designed_yet
        (token_of_expression result)
        (Printf.sprintf
           "`%s` gives nothing, and using that as a value isn't decided yet"
           (text_of_expression state result))

(* trace: D8 *)
(* A call's arguments, from `(` to `)`: each a value, with a label before it
   and a unit word after it where written. *)
and arguments state (before : Token.t) =
  ignore (expect_symbol state '(');
  let result =
    match current state with
    | Some ({ kind = Symbol ')'; _ } as closing) ->
        advance state;
        ([], closing)
    | _ ->
        let rec items found =
          let argument_label =
            match (current state, token_at state (state.position + 1)) with
            | ( Some ({ kind = Word _; _ } as label),
                Some ({ kind = Symbol ':'; _ } as colon) ) ->
                advance state;
                advance state;
                Some (label, colon)
            | _ -> None
          in
          let argument_value = expression state in
          let unit_token =
            match current state with
            | Some ({ kind = Word _; _ } as unit_word)
              when unit_word.line = (previous state).line ->
                advance state;
                Some unit_word
            | _ -> None
          in
          let argument = { argument_label; argument_value; unit_token } in
          match current state with
          | Some { kind = Symbol ','; _ } ->
              advance state;
              items (argument :: found)
          | _ ->
              let closing = expect_symbol state ')' in
              (List.rev (argument :: found), closing)
        in
        items []
  in
  let closing = snd result in
  if closing.line <> before.line then
    stop Message.Not_built_yet closing
      "a call written over several lines isn't in PlainOracle yet";
  result

(* trace: D8 *)
(* trace: D10 *)
(* trace: D45 *)
(* trace: D95 *)
(* Matches a call's arguments to its procedure's parameters, refusing what
   doesn't fit. [piped] is a pipe's value, which goes first. *)
and check_call state signature (name_token : Token.t) (last : Token.t) piped
    written =
  let name = signature.procedure_name in
  let call_place =
    { name_token with length = last.byte + last.length - name_token.byte }
  in
  let refuse_place (place : Token.t) body why =
    refuse state
      {
        Message.kind = Message.Refused;
        line = place.line;
        byte = place.byte;
        length = place.length;
        body;
        why = Some why;
      }
  in
  let value_place argument =
    let value = token_of_expression argument.argument_value in
    match argument.unit_token with
    | Some unit_word ->
        { value with length = unit_word.byte + unit_word.length - value.byte }
    | None -> value
  in
  let value_text argument = text_of state (value_place argument) in
  let indexed = List.mapi (fun index parameter -> (index, parameter)) in
  let parameters = indexed signature.parameters in
  (* A value without a label after a labelled one. *)
  ignore
    (List.fold_left
       (fun seen_label argument ->
         match argument.argument_label with
         | Some _ -> true
         | None ->
             if seen_label then
               stop Message.Not_designed_yet (value_place argument)
                 "a value without a label after a labelled one isn't decided \
                  yet";
             false)
       false written);
  let bare = List.filter (fun a -> a.argument_label = None) written in
  let labelled = List.filter (fun a -> a.argument_label <> None) written in
  (* Each match: the parameter's position, the written argument (none for a
     piped value), and the value. *)
  let matched = ref [] in
  let given index = List.exists (fun (found, _, _) -> found = index) !matched in
  let unlabelled =
    ref (List.filter (fun (_, parameter) -> parameter.label = None) parameters)
  in
  let take argument value =
    match !unlabelled with
    | (index, _) :: rest ->
        matched := (index, argument, value) :: !matched;
        unlabelled := rest;
        true
    | [] -> false
  in
  (match piped with
  | Some value ->
      if not (take None value) then
        stop Message.Not_designed_yet name_token
          (Printf.sprintf
             "piping into `%s`, which has no parameter without a label, isn't \
              decided yet"
             name)
  | None -> ());
  let extras =
    List.filter
      (fun argument -> not (take (Some argument) argument.argument_value))
      bare
  in
  if !unlabelled <> [] then
    stop Message.Not_designed_yet call_place
      (Printf.sprintf
         "a call to `%s` that leaves out a value without a label isn't decided \
          yet"
         name);
  let unknown = ref false in
  List.iter
    (fun argument ->
      match argument.argument_label with
      | Some (label_token, colon) -> (
          let word = text_of state label_token in
          match
            List.find_opt
              (fun (_, parameter) -> parameter.label = Some word)
              parameters
          with
          | Some (index, _) ->
              if given index then
                stop Message.Not_designed_yet label_token
                  (Printf.sprintf "writing `%s:` twice isn't decided yet" word);
              matched :=
                (index, Some argument, argument.argument_value) :: !matched
          | None ->
              unknown := true;
              refuse_place
                {
                  label_token with
                  length = colon.byte + colon.length - label_token.byte;
                }
                (Message.What
                   (Printf.sprintf "`%s` has no label `%s:`" name word))
                "a call writes only the labels its procedure declares.")
      | None -> ())
    labelled;
  (* Bare values where labels are expected get them, in order. *)
  let open_labels =
    List.filter
      (fun (index, parameter) -> parameter.label <> None && not (given index))
      parameters
  in
  let rec pair extras open_labels =
    match (extras, open_labels) with
    | [], _ -> false
    | argument :: rest, (index, parameter) :: more ->
        refuse_place (value_place argument)
          (Message.Fix
             (Printf.sprintf "%s: %s"
                (Option.value parameter.label ~default:"")
                (value_text argument)))
          (Printf.sprintf
             "`%s` labels this argument, so every call writes the label." name);
        matched := (index, Some argument, argument.argument_value) :: !matched;
        pair rest more
    | _ :: _, [] -> true
  in
  let too_many = pair extras open_labels in
  if too_many then begin
    let takes = List.length signature.parameters in
    refuse_place call_place
      (Message.What
         (Printf.sprintf "`%s` takes %d %s, but this call gives %d" name takes
            (if takes = 1 then "value" else "values")
            (List.length written + if piped = None then 0 else 1)))
      "a call gives each of a procedure's parameters once."
  end;
  (if not (!unknown || extras <> []) then
     match
       List.find_opt
         (fun (index, parameter) ->
           parameter.label <> None && parameter.default = None
           && not (given index))
         parameters
     with
     | Some (_, parameter) ->
         refuse_place call_place
           (Message.What
              (Printf.sprintf "`%s` needs `%s:`" name
                 (Option.value parameter.label ~default:"")))
           "only a label with a default can be left off."
     | None ->
         (* trace: D10 *)
         let written_order =
           List.filter_map
             (fun argument ->
               List.find_map
                 (fun (index, found, _) ->
                   match found with
                   | Some found when found == argument -> Some (index, argument)
                   | _ -> None)
                 !matched)
             labelled
         in
         let sorted =
           List.sort (fun (a, _) (b, _) -> compare a b) written_order
         in
         if (not signature.any_order) && written_order <> sorted then
           let labelled_text (index, argument) =
             Printf.sprintf "%s: %s"
               (Option.value (List.nth signature.parameters index).label
                  ~default:"")
               (value_text argument)
           in
           refuse_place call_place
             (Message.Fix
                (Printf.sprintf "%s(%s)" name
                   (String.concat ", "
                      (List.map value_text bare @ List.map labelled_text sorted))))
             "labels are written in the order the procedure declares them, \
              unless it says `labels.any_order`.");
  List.iter
    (fun (index, argument, value) ->
      let parameter = List.nth signature.parameters index in
      check_holds state parameter.parameter_name parameter.parameter_type value;
      check_limits state parameter.parameter_name parameter.parameter_limits
        value;
      match argument with
      | Some argument -> check_unit state parameter argument value_place
      | None -> ())
    (List.rev !matched);
  let defaults =
    List.filter_map
      (fun (index, parameter) ->
        if given index then None
        else Option.map (fun value -> (index, value)) parameter.default)
      parameters
  in
  let arguments =
    List.map (fun (index, _, value) -> (index, value)) (List.rev !matched)
    @ defaults
  in
  ( Call (name, arguments),
    match signature.result with
    | Some result -> Some result
    | None -> Some Nothing_type )

(* trace: D45 *)
(* trace: D95 *)
(* Only a written number's unit word is compared. A variable passes with no
   unit word. *)
and check_unit state parameter argument value_place =
  let literal =
    match argument.argument_value.shape with
    | Whole_literal _ -> true
    | _ -> false
  in
  let refuse_unit unit_word =
    let place = value_place argument in
    refuse state
      {
        Message.kind = Message.Refused;
        line = place.line;
        byte = place.byte;
        length = place.length;
        body =
          Message.Fix
            (Printf.sprintf "%s %s"
               (text_of_expression state argument.argument_value)
               unit_word);
        why =
          Some
            (Printf.sprintf "`%s:` is in %s, so a number written here says so."
               (Option.value parameter.label ~default:"")
               unit_word);
      }
  in
  match (parameter.unit_word, argument.unit_token) with
  | Some unit_word, None -> if literal then refuse_unit unit_word
  | Some unit_word, Some written ->
      if not literal then
        stop Message.Not_designed_yet written
          "a unit word after something that isn't a written number isn't \
           decided yet"
      else if text_of state written <> unit_word then refuse_unit unit_word
  | None, Some written ->
      stop Message.Not_designed_yet written
        "a unit word for a parameter with no unit isn't decided yet"
  | None, None -> ()

(* trace: D29 *)
(* trace: D30 *)
(* trace: D97 *)
(* `|>` passes the value on its left as the next step's bare first argument.
   It's read after maths and `&`, so it takes all of its left side. *)
and pipe state start (left : expression) =
  match current state with
  | Some ({ kind = Pipe; _ } as bar) ->
      (match left.value_type with
      | Some Bool_type ->
          stop Message.Not_designed_yet bar
            "piping a true or false value isn't decided yet"
      | _ -> ());
      advance state;
      let step = next state in
      if step.line <> left.line then
        stop Message.Not_built_yet step
          "a pipe written over several lines isn't in PlainOracle yet";
      let result = pipe_step state left step in
      allow_nothing state start result;
      pipe state start result
  | _ -> left

and pipe_step state (left : expression) (step : Token.t) =
  match step.kind with
  | Keyword (Be_word, table) -> (
      check_table state step table;
      advance state;
      ignore (expect_symbol state '.');
      let type_token = next state in
      match type_token.kind with
      | Keyword (Text_word, table) ->
          check_table state type_token table;
          advance state;
          (match current state with
          | Some ({ kind = Symbol ('.' | '('); _ } as more) ->
              stop Message.Not_designed_yet more
                "`be.Text` with more after it in a pipe isn't decided yet"
          | _ -> ());
          let converted =
            from_to left type_token (Be_text left)
              (Option.map (fun _ -> Text_type) left.value_type)
          in
          (* trace: D90 *)
          (match left.value_type with
          | Some Text_type ->
              let inner_text = text_of_expression state left in
              refuse_at state converted (Message.Fix inner_text)
                (Printf.sprintf
                   "`%s` is already `Text`, so there's nothing to convert."
                   inner_text)
          | _ -> ());
          converted
      | _ -> not_built state type_token)
  | Keyword (Show_text_word, table) ->
      check_table state step table;
      advance state;
      let same_line =
        match current state with
        | Some { kind = Symbol '.'; _ } -> (
            advance state;
            let narrowing = next state in
            match narrowing.kind with
            | Keyword (Same_line_word, table) ->
                check_table state narrowing table;
                advance state;
                true
            | Keyword (Format_word, _) ->
                stop Message.Not_designed_yet narrowing
                  "`show_text.format` in a pipe isn't decided yet"
            | _ -> not_built state narrowing)
        | _ -> false
      in
      (match left.value_type with
      | Some Whole_type ->
          stop Message.Not_designed_yet step
            "piping a number into `show_text` isn't decided yet"
      | _ -> ());
      from_to left (previous state)
        (Shown (left, same_line))
        (Some Nothing_type)
  | Word name -> (
      match List.assoc_opt name state.signatures with
      | None -> not_built state step
      | Some found ->
          advance state;
          let written, last =
            match current state with
            | Some { kind = Symbol '('; _ } ->
                (match token_at state (state.position + 1) with
                | Some { kind = Symbol ')'; _ } ->
                    stop Message.Not_designed_yet step
                      "empty `( )` on a pipe step isn't decided yet"
                | _ -> ());
                arguments state step
            | _ -> ([], step)
          in
          List.iter
            (fun argument ->
              if argument.argument_label = None then
                stop Message.Not_designed_yet
                  (token_of_expression argument.argument_value)
                  "a value without a label in a pipe step isn't decided yet")
            written;
          let shape, value_type =
            match found with
            | Some signature ->
                check_call state signature step last (Some left) written
            | None -> (Call (name, []), None)
          in
          from_to left last shape value_type)
  | _ -> not_built state step

(* trace: D88 *)
(* A signed whole number written in a type's limits. *)
let limit_number state =
  let token = next state in
  match token.kind with
  | Symbol '-' -> (
      advance state;
      let number = next state in
      match number.kind with
      | Word digits when number.byte = token.byte + 1 -> (
          advance state;
          match Int64.of_string_opt ("-" ^ digits) with
          | Some value -> value
          | None -> not_built state number)
      | _ -> not_built state number)
  | Word digits -> (
      advance state;
      match Int64.of_string_opt digits with
      | Some value -> value
      | None -> not_built state token)
  | _ -> not_built state token

(* trace: D88 *)
(* `Whole[min: 0, max: 100]`, with `minimum` and `maximum` as the long forms
   (D68). *)
let type_limits state =
  match current state with
  | Some { kind = Symbol '['; _ } ->
      advance state;
      let label () =
        let token = next state in
        let meaning =
          match token.kind with
          | Word word -> meaning_of state token word
          | _ -> None
        in
        match meaning with
        | Some "minimum" ->
            advance state;
            ignore (expect_symbol state ':');
            `Minimum (limit_number state)
        | Some "maximum" ->
            advance state;
            ignore (expect_symbol state ':');
            `Maximum (limit_number state, token)
        | _ -> not_built state token
      in
      let first = label () in
      let second =
        match current state with
        | Some { kind = Symbol ','; _ } ->
            advance state;
            Some (label ())
        | _ -> None
      in
      ignore (expect_symbol state ']');
      let limits =
        match (first, second) with
        | `Minimum low, None -> { minimum = Some low; maximum = None }
        | `Maximum (high, _), None -> { minimum = None; maximum = Some high }
        | `Minimum low, Some (`Maximum (high, _)) ->
            { minimum = Some low; maximum = Some high }
        | `Maximum (_, token), Some _ ->
            stop Message.Not_designed_yet token
              "writing `max:` before `min:` isn't decided yet"
        | `Minimum _, Some (`Minimum _) -> not_built state (previous state)
      in
      (match limits with
      | { minimum = Some low; maximum = Some high } when low > high ->
          stop Message.Not_built_yet (previous state)
            "limits with the minimum above the maximum aren't in PlainOracle \
             yet"
      | _ -> ());
      limits
  | _ -> no_limits

let type_of state =
  let token = next state in
  match token.kind with
  | Keyword (Whole_word, table) ->
      check_table state token table;
      advance state;
      (Whole_type, type_limits state)
  | Keyword (Text_word, table) ->
      check_table state token table;
      advance state;
      (Text_type, no_limits)
  | _ -> not_built state token

(* trace: D27 *)
(* trace: D28 *)
(* trace: D58 *)
(* A declaration creates its variable with its written type even when its
   value is refused, so later lines aren't refused because of it. *)
let declaration state ~shadow ~mutable_variable =
  let name_token = next state in
  let name =
    match name_token.kind with
    | Name name ->
        advance state;
        name
    | _ -> not_built state name_token
  in
  (* trace: D91 *)
  (* A name is declared once, unless `shadow` declares it again. A refused
     redeclaration still replaces the variable, so later lines aren't refused
     because of it (D58). *)
  (match (List.assoc_opt name state.declared_on, shadow) with
  | Some line, false ->
      refuse state
        {
          Message.kind = Message.Refused;
          line = name_token.line;
          byte = name_token.byte;
          length = name_token.length;
          body =
            Message.What
              (Printf.sprintf "`%s` is already declared on line %d" name line);
          why =
            Some
              "a variable (#) is declared once, unless `shadow` declares it \
               again.";
        }
  | Some _, true when List.mem name state.parameter_names ->
      stop Message.Not_designed_yet name_token
        (Printf.sprintf "`shadow` on the parameter `%s` isn't decided yet" name)
  | None, true ->
      stop Message.Not_designed_yet name_token
        (Printf.sprintf
           "`shadow` on `%s`, which isn't declared yet, isn't decided yet" name)
  | _ -> ());
  state.declared_on <- (name, name_token.line) :: state.declared_on;
  ignore (expect_symbol state ':');
  let variable_type, limits = type_of state in
  ignore (expect_symbol state '=');
  let value = expression state in
  check_holds state name variable_type value;
  check_limits state name limits value;
  state.variables <-
    (name, (variable_type, mutable_variable)) :: state.variables;
  state.limits <- (name, limits) :: state.limits;
  finish state;
  Declare (name, value, limits)

let change state =
  ignore (expect_keyword state Change_word);
  let name_token = next state in
  let name =
    match name_token.kind with
    | Name name ->
        advance state;
        name
    | _ -> not_built state name_token
  in
  let found = find_variable state name_token name in
  (match found with
  | Some _ when List.mem name state.parameter_names ->
      (* trace: D32 *)
      (* trace: D95 *)
      refuse state
        {
          Message.kind = Message.Refused;
          line = name_token.line;
          byte = name_token.byte;
          length = name_token.length;
          body =
            Message.What
              (Printf.sprintf "`%s` is a parameter, so it can't be changed" name);
          why =
            Some
              "a procedure only reads its parameters, and gives a new value \
               back instead.";
        }
  | Some (_, false) ->
      refuse state
        {
          Message.kind = Message.Refused;
          line = name_token.line;
          byte = name_token.byte;
          length = name_token.length;
          body = Message.What (Printf.sprintf "`%s` isn't mutable" name);
          why = Some "`change` only works on a variable (#) declared `mut`.";
        }
  | _ -> ());
  ignore (expect_symbol state '=');
  let value = expression state in
  let limits =
    Option.value (List.assoc_opt name state.limits) ~default:no_limits
  in
  (match found with
  | Some (variable_type, _) ->
      check_holds state name variable_type value;
      check_limits state name limits value
  | None -> ());
  finish state;
  Change (name, value, limits)

(* trace: D12 *)
(* trace: D13 *)
(* trace: D14 *)
(* trace: D44 *)
let show_text state =
  let show_token = expect_keyword state Show_text_word in
  let rec narrowings found =
    match current state with
    | Some { kind = Symbol '.'; _ } -> (
        advance state;
        let token = next state in
        match token.kind with
        | Keyword (((Format_word | Same_line_word) as keyword), table)
          when not
                 (List.mem_assoc
                    (if keyword = Format_word then "format" else "same_line")
                    found) ->
            check_table state token table;
            advance state;
            let word =
              if keyword = Format_word then "format" else "same_line"
            in
            narrowings ((word, token) :: found)
        | _ -> not_built state token)
    | _ -> List.rev found
  in
  let found = narrowings [] in
  let words = List.map fst found in
  (if words = [ "same_line"; "format" ] then
     let last = snd (List.nth found 1) in
     refuse state
       {
         Message.kind = Message.Refused;
         line = show_token.line;
         byte = show_token.byte;
         length = last.byte + last.length - show_token.byte;
         body = Message.Fix "show_text.format.same_line";
         why =
           Some
             "`.format` changes what's shown, so it comes before `.same_line`.";
       });
  ignore (expect_symbol state '(');
  let value =
    if List.mem "format" words then
      let first = next state in
      let pieces = format_argument state in
      spanning first (previous state) (Format pieces) (Some Text_type)
    else expression state
  in
  ignore (expect_symbol state ')');
  (match value.value_type with
  | Some Whole_type ->
      refuse_at state value
        (Message.Fix
           (Printf.sprintf "be.Text(%s)" (text_of_expression state value)))
        "`show_text` shows text, and doesn't turn a number into text by itself."
  | _ -> ());
  finish state;
  Show_text (value, List.mem "same_line" words)

let record_depth state (token : Token.t) depth =
  if not (List.mem_assoc token.line state.depths) then
    state.depths <- (token.line, depth) :: state.depths

(* trace: D35 *)
(* trace: D62 *)
(* A block's opening line ends with `:`; a missing one is clear, so checking
   carries on. *)
let colon state =
  let last = previous state in
  match current state with
  | Some { kind = Symbol ':'; _ } -> advance state
  | Some token when token.line = last.line -> not_built state token
  | _ -> refuse_missing state last ":" "a block's opening line ends with `:`."

let condition_of state =
  state.in_condition <- true;
  let value = condition state in
  state.in_condition <- false;
  require_condition state value;
  value

(* The last token on the same line as the token at [index]. *)
let line_last_token state index =
  let line = state.tokens.(index).line in
  let rec go found =
    match token_at state (found + 1) with
    | Some token when token.line = line -> go (found + 1)
    | _ -> state.tokens.(found)
  in
  go index

(* trace: D50 *)
(* Whether every way through these statements leaves. *)
let rec leaves statements =
  List.exists
    (function
      | Return _ -> true
      | If (branches, Some otherwise) ->
          List.for_all (fun (_, body) -> leaves body) branches
          && leaves otherwise
      | _ -> false)
    statements

(* trace: D50 *)
(* trace: D95 *)
(* After an `if` that always leaves, the rest goes in its `else:`. *)
let after_leaving state (token : Token.t) previous_statement =
  match previous_statement with
  | Some (Return _) ->
      stop Message.Not_designed_yet token
        "a line after `return` in the same block isn't decided yet"
  | Some (If (branches, otherwise)) ->
      let branches_leave =
        List.for_all (fun (_, body) -> leaves body) branches
      in
      let some_leave =
        List.exists (fun (_, body) -> leaves body) branches
        || Option.fold ~none:false ~some:leaves otherwise
      in
      if some_leave then
        if otherwise = None && branches_leave then
          let last = line_last_token state state.position in
          refuse state
            {
              Message.kind = Message.Refused;
              line = token.line;
              byte = token.byte;
              length = last.byte + last.length - token.byte;
              body =
                Message.What "this line comes after an `if` that always leaves";
              why =
                Some
                  "after an `if` that always leaves, the rest goes in its \
                   `else:`.";
            }
        else if branches_leave then
          stop Message.Not_designed_yet token
            "a line after an `if` whose every way leaves isn't decided yet"
        else
          stop Message.Not_designed_yet token
            "a line after an `if` where only some ways leave isn't decided yet"
  | _ -> ()

(* trace: D46 *)
(* trace: D95 *)
let return_statement state (token : Token.t) =
  english_only state token;
  advance state;
  let value =
    match current state with
    | Some { kind = Symbol ';'; _ } -> None
    | Some next_token when next_token.line > token.line -> None
    | _ -> Some (expression state)
  in
  (match (state.current_procedure, value) with
  | None, Some value ->
      stop Message.Not_designed_yet
        (token_of_expression value)
        "a `return` with a value in `procedure.main` isn't decided yet"
  | Some { result = None; _ }, Some value ->
      stop Message.Not_designed_yet
        (token_of_expression value)
        "a `return` with a value in a procedure that returns nothing isn't \
         decided yet"
  | Some { result = Some result; _ }, None ->
      stop Message.Not_designed_yet token
        (Printf.sprintf
           "a `return` without a value in a procedure that returns a `%s` \
            isn't decided yet"
           (type_name result))
  | Some { result = Some result; procedure_name; _ }, Some value -> (
      match value.value_type with
      | Some found when found <> result ->
          refuse_at state value
            (Message.What
               (Printf.sprintf "`%s` is `%s`, but `%s` returns a `%s`"
                  (text_of_expression state value)
                  (type_name found) procedure_name (type_name result)))
            "a procedure returns the type its header says."
      | _ -> ())
  | _, None -> ());
  finish state;
  Return value

(* trace: D26 *)
(* trace: D95 *)
(* A statement that's a call, or a pipe ending in one or in `show_text`. A
   result it gives is refused, since nothing uses it. *)
let expression_statement state =
  let value = expression state in
  (match (value.value_type, value.shape) with
  | (None | Some Nothing_type), _ -> ()
  | Some found, Call _ ->
      refuse_at state value
        (Message.What
           (Printf.sprintf "`%s` gives a `%s`, and it isn't used"
              (text_of_expression state value)
              (type_name found)))
        "a result that's thrown away is usually a bug, so it's refused."
  | Some _, _ ->
      stop Message.Not_designed_yet
        (token_of_expression value)
        "a line that only works out a value isn't decided yet");
  finish state;
  Expression_statement value

(* Statements until an `end` or `else`, each recorded at its indentation level
   (D70). *)
let rec statements state depth found =
  let token = next state in
  match token.kind with
  | Keyword ((End_word | Else_word), _) -> List.rev found
  | _ ->
      record_depth state token depth;
      after_leaving state token
        (match found with [] -> None | last :: _ -> Some last);
      state.statement_start <- state.position;
      let statement =
        match token.kind with
        | Keyword (Show_text_word, _) -> show_text state
        | Keyword (Mut_word, table) ->
            check_table state token table;
            advance state;
            declaration state ~shadow:false ~mutable_variable:true
        | Keyword (Shadow_word, table) ->
            check_table state token table;
            advance state;
            let mutable_variable =
              match current state with
              | Some ({ kind = Keyword (Mut_word, mut_table); _ } as mut_token)
                ->
                  check_table state mut_token mut_table;
                  advance state;
                  true
              | _ -> false
            in
            declaration state ~shadow:true ~mutable_variable
        | Keyword (Change_word, table) ->
            check_table state token table;
            change state
        | Keyword (If_word, table) ->
            check_table state token table;
            advance state;
            if_statement state token depth
        | Name _ when next_is_symbol state ':' ->
            declaration state ~shadow:false ~mutable_variable:false
        | Word "return" -> return_statement state token
        | Name _ | Word _ | Text _ | Symbol '(' | Keyword (Be_word, _) ->
            expression_statement state
        | Keyword (Procedure_word, _) when next_is_symbol state '.' ->
            expression_statement state
        | _ -> not_built state token
      in
      statements state depth (statement :: found)

(* trace: D35 *)
and if_statement state (if_token : Token.t) depth =
  let branch () =
    let value = condition_of state in
    colon state;
    let body = statements state (depth + 1) [] in
    (value, body)
  in
  let rec more branches =
    let token = next state in
    match token.kind with
    | Keyword (Else_word, table) -> (
        check_table state token table;
        record_depth state token depth;
        advance state;
        match current state with
        | Some ({ kind = Keyword (If_word, if_table); _ } as else_if) ->
            check_table state else_if if_table;
            advance state;
            more (branch () :: branches)
        | _ ->
            colon state;
            let otherwise = statements state (depth + 1) [] in
            close (List.rev branches) (Some otherwise))
    | _ -> close (List.rev branches) None
  and close branches otherwise =
    let end_token = next state in
    (match end_token.kind with
    | Keyword (End_word, _) -> ()
    | _ -> not_built state end_token);
    match token_at state (state.position + 1) with
    | Some ({ kind = Keyword (If_word, table); _ } as if_word) ->
        check_table state end_token table;
        check_table state if_word table;
        record_depth state end_token depth;
        advance state;
        advance state;
        If (branches, otherwise)
    | Some { kind = Keyword (Procedure_word, _); _ } ->
        (* trace: D93 *)
        (* A missing `end if`, found where the procedure closes. The procedure's
           closer is left for the procedure. *)
        let last = line_last_token state state.position in
        refuse state
          {
            Message.kind = Message.Refused;
            line = end_token.line;
            byte = end_token.byte;
            length = last.byte + last.length - end_token.byte;
            body =
              Message.What
                (Printf.sprintf
                   "`%s` closes the procedure while the `if` on line %d is \
                    still open"
                   (String.sub
                      (Source.line state.source end_token.line)
                      (end_token.byte - 1)
                      (last.byte + last.length - end_token.byte))
                   if_token.line);
            why = Some "each block closes with its own `end`, inside out.";
          };
        If (branches, otherwise)
    | Some token -> not_built state token
    | None -> end_of_file state
  in
  more [ branch () ]

(* trace: D62 *)
(* A header missing only its `:` is clear, so checking carries on. *)
let header_colon state (closing : Token.t) =
  match current state with
  | Some { kind = Symbol ':'; _ } -> advance state
  | Some token when token.line = closing.line -> not_built state token
  | _ ->
      refuse_missing state closing ":" "a block's opening line ends with `:`."

(* trace: D69 *)
(* A header's parameters, `[none]` or a list of names and types. Returns the
   closing `]`. *)
let parameters_of state ~main =
  let opening = expect_symbol state '[' in
  let token = next state in
  match token.kind with
  | Symbol ']' ->
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
      (token, [])
  | Keyword (None_word, table) ->
      check_table state token table;
      advance state;
      (expect_symbol state ']', [])
  | Name _ when main ->
      stop Message.Not_designed_yet token
        "parameters on `procedure.main` aren't decided yet"
  | Name _ ->
      let rec items found =
        let name_token = next state in
        let name =
          match name_token.kind with
          | Name name ->
              advance state;
              name
          | _ -> not_built state name_token
        in
        if List.exists (fun parameter -> parameter.parameter_name = name) found
        then
          stop Message.Not_designed_yet name_token
            (Printf.sprintf "two parameters named `%s` aren't decided yet" name);
        ignore (expect_symbol state ':');
        let parameter_type, parameter_limits = type_of state in
        let parameter =
          {
            parameter_name = name;
            parameter_type;
            parameter_limits;
            label = None;
            default = None;
            unit_word = None;
          }
        in
        match current state with
        | Some { kind = Symbol ','; _ } ->
            advance state;
            items (parameter :: found)
        | _ -> (expect_symbol state ']', List.rev (parameter :: found))
      in
      items []
  | _ -> not_built state token

(* trace: D46 *)
(* A named procedure's header after `procedure`: its name, parameters and
   result. *)
let named_header state =
  let name_token = next state in
  let name =
    match name_token.kind with
    | Word name ->
        advance state;
        name
    | _ -> not_built state name_token
  in
  let closing, parameters = parameters_of state ~main:false in
  let closing, result =
    match current state with
    | Some ({ kind = Word "returns"; _ } as returns) ->
        english_only state returns;
        advance state;
        let type_token = next state in
        let result, limits = type_of state in
        if limits <> no_limits then
          stop Message.Not_designed_yet type_token
            "limits on a procedure's result aren't decided yet";
        (previous state, Some result)
    | _ -> (closing, None)
  in
  header_colon state closing;
  (name_token, name, parameters, result)

let enter_procedure state parameters line =
  state.variables <-
    List.map
      (fun parameter ->
        (parameter.parameter_name, (parameter.parameter_type, false)))
      parameters;
  state.limits <-
    List.map
      (fun parameter -> (parameter.parameter_name, parameter.parameter_limits))
      parameters;
  state.declared_on <-
    List.map (fun parameter -> (parameter.parameter_name, line)) parameters;
  state.parameter_names <-
    List.map (fun parameter -> parameter.parameter_name) parameters

(* trace: D9 *)
(* trace: D10 *)
(* trace: D47 *)
(* The `labels`, `defaults` and `units` lines at the top of a body, in that
   order. *)
let procedure_top state parameters =
  let stage = ref 0 in
  let any_order = ref false in
  let parameters = ref parameters in
  let parameter_named () =
    let name_token = next state in
    match name_token.kind with
    | Name name -> (
        advance state;
        match
          List.find_opt
            (fun parameter -> parameter.parameter_name = name)
            !parameters
        with
        | Some parameter -> (name_token, parameter)
        | None ->
            stop Message.Not_designed_yet name_token
              (Printf.sprintf
                 "`%s` here, which isn't a parameter, isn't decided yet" name))
    | _ -> not_built state name_token
  in
  let update changed =
    parameters :=
      List.map
        (fun parameter ->
          if parameter.parameter_name = changed.parameter_name then changed
          else parameter)
        !parameters
  in
  let items each =
    ignore (expect_symbol state '[');
    let rec go () =
      each ();
      match current state with
      | Some { kind = Symbol ','; _ } ->
          advance state;
          go ()
      | _ -> ()
    in
    go ();
    ignore (expect_symbol state ']');
    finish state
  in
  let word_after () =
    let token = next state in
    match token.kind with
    | Word word ->
        advance state;
        (token, word)
    | _ -> not_built state token
  in
  let rec lines () =
    match current state with
    | Some
        ({ kind = Word (("labels" | "defaults" | "units") as word); _ } as token)
      ->
        english_only state token;
        record_depth state token 1;
        let order =
          match word with "labels" -> 1 | "defaults" -> 2 | _ -> 3
        in
        if order <= !stage then
          stop Message.Not_designed_yet token
            "this order of `labels`, `defaults` and `units` lines isn't \
             decided yet";
        stage := order;
        advance state;
        (match word with
        | "labels" ->
            (match current state with
            | Some { kind = Symbol '.'; _ } -> (
                advance state;
                let narrowing = next state in
                match narrowing.kind with
                | Word "any_order" ->
                    english_only state narrowing;
                    advance state;
                    any_order := true
                | Word "in_order" ->
                    english_only state narrowing;
                    advance state;
                    (* trace: D95 *)
                    refuse state
                      {
                        Message.kind = Message.Refused;
                        line = token.line;
                        byte = token.byte;
                        length = narrowing.byte + narrowing.length - token.byte;
                        body = Message.Fix "labels";
                        why =
                          Some
                            "keeping the order is already what `labels` does.";
                      }
                | _ -> not_built state narrowing)
            | _ -> ());
            items (fun () ->
                let name_token, parameter = parameter_named () in
                if parameter.label <> None then
                  stop Message.Not_designed_yet name_token
                    "a second label for one parameter isn't decided yet";
                ignore (expect_word state "as");
                let label_token, label = word_after () in
                if
                  List.exists
                    (fun other -> other.label = Some label)
                    !parameters
                then
                  stop Message.Not_designed_yet label_token
                    (Printf.sprintf
                       "two parameters labelled `%s` aren't decided yet" label);
                update { parameter with label = Some label })
        | "defaults" ->
            items (fun () ->
                let name_token, parameter = parameter_named () in
                if parameter.label = None then
                  stop Message.Not_designed_yet name_token
                    (Printf.sprintf
                       "a default for `%s`, which has no label, isn't decided \
                        yet"
                       parameter.parameter_name);
                if parameter.default <> None then
                  stop Message.Not_designed_yet name_token
                    "a second default for one parameter isn't decided yet";
                ignore (expect_symbol state '=');
                let value = expression state in
                (match value.shape with
                | Whole_literal _ | Text_literal _ -> ()
                | _ ->
                    stop Message.Not_designed_yet
                      (token_of_expression value)
                      "a default that isn't a written value isn't decided yet");
                check_holds state parameter.parameter_name
                  parameter.parameter_type value;
                check_limits state parameter.parameter_name
                  parameter.parameter_limits value;
                update { parameter with default = Some value })
        | _ ->
            items (fun () ->
                let name_token, parameter = parameter_named () in
                if parameter.label = None then
                  stop Message.Not_designed_yet name_token
                    (Printf.sprintf
                       "a unit for `%s`, which has no label, isn't decided yet"
                       parameter.parameter_name);
                if parameter.parameter_type <> Whole_type then
                  stop Message.Not_designed_yet name_token
                    "a unit on a parameter that isn't a `Whole` isn't decided \
                     yet";
                (* trace: D48 *)
                (* The unit's word is whatever this line writes. *)
                ignore (expect_word state "in");
                let _, unit_word = word_after () in
                update { parameter with unit_word = Some unit_word }));
        lines ()
    | _ -> ()
  in
  lines ();
  (!parameters, !any_order)

(* A named procedure's header and the lines at the top of its body. *)
let signature_of state =
  let procedure_token = expect_keyword state Procedure_word in
  let name_token, name, parameters, result = named_header state in
  enter_procedure state parameters procedure_token.line;
  let parameters, any_order = procedure_top state parameters in
  (name_token, { procedure_name = name; parameters; result; any_order })

(* trace: D96 *)
(* Reads every named procedure's header before any body is checked, so a call
   can come before its procedure. Messages are left for the real reading. *)
let collect_signatures state =
  Array.iteri
    (fun index (token : Token.t) ->
      let first_on_line =
        index = 0 || state.tokens.(index - 1).line < token.line
      in
      match (token.kind, token_at state (index + 1)) with
      | Keyword (Procedure_word, _), Some { kind = Word name; _ }
        when first_on_line && not (List.mem_assoc name state.signatures) ->
          let scratch = { state with position = index } in
          let found =
            match signature_of scratch with
            | _, signature -> Some signature
            | exception Message.Stop _ -> None
          in
          state.signatures <- (name, found) :: state.signatures
      | _ -> ())
    state.tokens

let closer state signature body =
  let end_token = expect_keyword state End_word in
  record_depth state end_token 0;
  ignore (expect_keyword state Procedure_word);
  let last =
    match signature with
    | None ->
        ignore (expect_symbol state '.');
        expect_keyword state Main_word
    | Some signature ->
        let token = next state in
        (match token.kind with
        | Word word when word = signature.procedure_name -> advance state
        | Word _ | Symbol '.' ->
            stop Message.Not_designed_yet token
              (Printf.sprintf "closing `%s` with another name isn't decided yet"
                 signature.procedure_name)
        | _ -> not_built state token);
        token
  in
  (match signature with
  | Some { result = Some result; procedure_name; _ } when not (leaves body) ->
      (* trace: D95 *)
      refuse state
        {
          Message.kind = Message.Refused;
          line = end_token.line;
          byte = end_token.byte;
          length = last.byte + last.length - end_token.byte;
          body =
            Message.What
              (Printf.sprintf "`%s` can reach its end without returning a `%s`"
                 procedure_name (type_name result));
          why =
            Some
              "every way through a procedure that returns something ends in \
               `return`.";
        }
  | _ -> ());
  match current state with
  | Some token when token.line = last.line -> not_built state token
  | _ -> ()

type procedure =
  | Main_procedure of statement list
  | Named_procedure of string * parameter list * statement list

(* trace: D63 *)
let procedure state =
  let procedure_token = next state in
  record_depth state procedure_token 0;
  if next_is_symbol state '.' then begin
    if state.main_seen then
      stop Message.Not_designed_yet procedure_token
        "a second `procedure.main` isn't decided yet";
    state.main_seen <- true;
    ignore (expect_keyword state Procedure_word);
    ignore (expect_symbol state '.');
    ignore (expect_keyword state Main_word);
    let closing, _ = parameters_of state ~main:true in
    header_colon state closing;
    enter_procedure state [] procedure_token.line;
    state.current_procedure <- None;
    let body = statements state 1 [] in
    closer state None body;
    Main_procedure body
  end
  else
    let name_token, signature = signature_of state in
    if List.mem signature.procedure_name state.defined then
      stop Message.Not_designed_yet name_token
        (Printf.sprintf "two procedures named `%s` aren't decided yet"
           signature.procedure_name);
    state.defined <- signature.procedure_name :: state.defined;
    state.current_procedure <- Some signature;
    let body = statements state 1 [] in
    closer state (Some signature) body;
    Named_procedure (signature.procedure_name, signature.parameters, body)

let program source tokens lexer_stop =
  let state =
    {
      source;
      tokens = Array.of_list tokens;
      lexer_stop;
      position = 0;
      declared = None;
      declared_word = "";
      refusals = [];
      variables = [];
      limits = [];
      declared_on = [];
      pending = [];
      in_condition = false;
      depths = [];
      signatures = [];
      parameter_names = [];
      current_procedure = None;
      statement_start = 0;
      defined = [];
      main_seen = false;
    }
  in
  let result =
    match
      language_line state;
      collect_signatures state;
      let rec procedures main named =
        match current state with
        | None -> (
            match main with
            | Some body -> (body, List.rev named)
            | None ->
                stop Message.Not_designed_yet state.tokens.(0)
                  "a file without `procedure.main` isn't decided yet")
        | Some { kind = Keyword (Procedure_word, _); _ } -> (
            match procedure state with
            | Main_procedure body -> procedures (Some body) named
            | Named_procedure (name, parameters, body) ->
                procedures main ((name, parameters, body) :: named))
        | Some token -> not_built state token
      in
      procedures None []
    with
    | found -> (found, List.rev state.refusals, None, state.declared)
    | exception Message.Stop message ->
        (([], []), List.rev state.refusals, Some message, state.declared)
  in
  (result, state.depths)

(* trace: D70 *)
(* Every line is indented 4 spaces per level, at the level its statement was
   found at: a procedure's header and closer at none, its body one level in,
   and a block's body one level further. *)
let indentation (source : Source.t) tokens depths =
  let firsts = Hashtbl.create 16 in
  List.iter
    (fun (token : Token.t) ->
      if not (Hashtbl.mem firsts token.line) then
        Hashtbl.add firsts token.line token)
    tokens;
  Hashtbl.fold
    (fun line (first : Token.t) messages ->
      match List.assoc_opt line depths with
      | None -> messages
      | Some depth -> (
          let text = Source.line source line in
          let indent = String.sub text 0 (first.byte - 1) in
          let rest =
            String.sub text (first.byte - 1)
              (String.length text - first.byte + 1)
          in
          let wanted = String.make (4 * depth) ' ' in
          let message body why =
            {
              Message.kind = Message.Refused;
              line;
              byte = 1;
              length = String.length indent;
              body;
              why = Some why;
            }
            :: messages
          in
          if indent = wanted then messages
          else if depth > 0 then
            (* trace: D74 *)
            message
              (Message.Fix (wanted ^ rest))
              "a body is indented 4 spaces per level, never with a tab."
          else
            match first.kind with
            | Keyword (End_word, _) ->
                message
                  (Message.What
                     "a block's closer lines up with its opening line")
                  "only a body is indented, 4 spaces per level."
            | Keyword (Procedure_word, _) ->
                message
                  (Message.What "a procedure's opening line has no indentation")
                  "only a body is indented, 4 spaces per level."
            | _ -> messages))
    firsts []
