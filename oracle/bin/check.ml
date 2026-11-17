(* Reading the tokens as a program, refusing what Plainly refuses, and stopping
   at what PlainOracle can't handle yet. So far: `procedure.main`, variables of
   `Whole` and `Text`, `mut` and `change`, `+`, `&`, `be.Text` and `show_text`. *)

open Token

type value_type = Whole_type | Text_type

let type_name = function Whole_type -> "Whole" | Text_type -> "Text"

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
  | Be_text of expression
  | Format of piece list

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
  | Show_text of expression * bool
  | Declare of string * expression * limits
  | Change of string * expression * limits

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
  | Keyword
      ((Show_text_word | End_word | Procedure_word | Mut_word | Change_word), _)
  | Name _ ->
      true
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
  | Symbol '.', Word "format" -> true
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
    if inside = "new_line" then Buffer.add_char buffer '\n'
    else if String.length inside > 0 && inside.[0] = '#' then
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
                    "settings in a fill-in, like a width, aren't decided yet"))
        | _ -> calculation ()
    else if String.exists (fun c -> String.contains "+-*/&|()" c) inside then
      calculation ()
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
          ->
            Some (word, found)
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
      | Word ("divide" | "div") -> (
          english_only state token;
          match narrowing () with
          | Some ("down", found) -> narrowed found (Calculate (Divide Down)) 2
          | Some ("toward_zero", found) ->
              narrowed found (Calculate (Divide Toward_zero)) 2
          | Some ("exact", found) ->
              stop Message.Not_built_yet found
                "`.exact` isn't in PlainOracle yet, since failures aren't"
          | Some (_, found) -> not_built state found
          | None -> one Bare_divide 2)
      | Word ("remainder" | "mod") -> (
          english_only state token;
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
      | Word (("plus" | "minus" | "times") as word) -> (
          english_only state token;
          let operation, level =
            match word with
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

let rec expression state =
  let held = state.pending in
  state.pending <- [];
  let first = arithmetic state 1 in
  let result = joins state first in
  List.iter (fun (_, message) -> refuse state message) (List.rev state.pending);
  state.pending <- held;
  result

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

and primary state =
  let token = next state in
  match token.kind with
  | Text words ->
      advance state;
      plain_text token words;
      spanning token token (Text_literal words) (Some Text_type)
  | Word "new_line" ->
      (* trace: D4 *)
      english_only state token;
      advance state;
      spanning token token (Text_literal "\n") (Some Text_type)
  | Word digits when String.length digits > 0 && is_digit digits.[0] ->
      advance state;
      whole_number state token token digits
  | Name name ->
      advance state;
      let value_type = Option.map fst (find_variable state token name) in
      spanning token token (Variable name) value_type
  | Word "be" -> (
      (* trace: D6 *)
      english_only state token;
      advance state;
      ignore (expect_symbol state '.');
      let type_token = next state in
      match type_token.kind with
      | Word "Text" when is_format_next state ->
          (* trace: D11 *)
          advance state;
          ignore (expect_symbol state '.');
          ignore (expect_word state "format");
          ignore (expect_symbol state '(');
          let pieces = format_argument state in
          let closing = expect_symbol state ')' in
          spanning token closing (Format pieces) (Some Text_type)
      | Word "Text" ->
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
      let inner = expression state in
      let closing = expect_symbol state ')' in
      spanning token closing inner.shape inner.value_type
  | _ -> not_built state token

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
        match token.kind with
        | Word ("min" | "minimum") ->
            english_only state token;
            advance state;
            ignore (expect_symbol state ':');
            `Minimum (limit_number state)
        | Word ("max" | "maximum") ->
            english_only state token;
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
  | Word "Whole" ->
      english_only state token;
      advance state;
      (Whole_type, type_limits state)
  | Word "Text" ->
      english_only state token;
      advance state;
      (Text_type, no_limits)
  | _ -> not_built state token

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
        | Word (("format" | "same_line") as word)
          when not (List.mem_assoc word found) ->
            english_only state token;
            advance state;
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

let rec body state found =
  let token = next state in
  match token.kind with
  | Keyword (End_word, _) -> List.rev found
  | Keyword (Show_text_word, _) -> body state (show_text state :: found)
  | Keyword (Mut_word, table) ->
      check_table state token table;
      advance state;
      body state
        (declaration state ~shadow:false ~mutable_variable:true :: found)
  | Keyword (Shadow_word, table) ->
      check_table state token table;
      advance state;
      let mutable_variable =
        match current state with
        | Some ({ kind = Keyword (Mut_word, mut_table); _ } as mut_token) ->
            check_table state mut_token mut_table;
            advance state;
            true
        | _ -> false
      in
      body state (declaration state ~shadow:true ~mutable_variable :: found)
  | Keyword (Change_word, table) ->
      check_table state token table;
      body state (change state :: found)
  | Name _ ->
      body state
        (declaration state ~shadow:false ~mutable_variable:false :: found)
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
      declared = None;
      declared_word = "";
      refusals = [];
      variables = [];
      limits = [];
      declared_on = [];
      pending = [];
    }
  in
  match
    language_line state;
    header state;
    let statements = body state [] in
    closer state;
    statements
  with
  | statements -> (statements, List.rev state.refusals, None, state.declared)
  | exception Message.Stop message ->
      ([], List.rev state.refusals, Some message, state.declared)

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
        | Word word when line = 1 && Option.is_some (language_of_word word) -> 0
        | _ -> 1
      in
      let text = Source.line source line in
      let indent = String.sub text 0 (first.byte - 1) in
      let rest =
        String.sub text (first.byte - 1) (String.length text - first.byte + 1)
      in
      let wanted = String.make (4 * depth) ' ' in
      if indent = wanted then messages
      else
        let body, why =
          if depth > 0 then
            (* trace: D74 *)
            ( Message.Fix (wanted ^ rest),
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
