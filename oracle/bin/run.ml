(* Running a checked program, one statement after another. PlainOracle's
   answers are `Working`'s answers: every check is made (D19, D66). *)

type value =
  | Whole_value of Int64.t
  | Text_value of string
  | Bool_value of bool
  (* What a procedure with no result gives. *)
  | Nothing_value

(* trace: D46 *)
(* A `return` leaves its procedure with its value. *)
exception Returned of value

(* Each named procedure's parameters, with their limits, and body. *)
let procedures :
    (string, (string * Check.limits) list * Check.statement list) Hashtbl.t =
  Hashtbl.create 16

let text_of (source : Source.t) (part : Check.expression) =
  String.sub (Source.line source part.line) (part.byte - 1) part.length

(* The variables an expression reads, each once, in the order they're written,
   for a `when:` line (D82, D89). *)
let rec variables_in (expression : Check.expression) =
  match expression.shape with
  | Check.Variable name -> [ name ]
  | Check.Arithmetic (_, left, right, _)
  | Check.Join (left, right)
  | Check.Compare_values (_, left, right)
  | Check.Logic (_, _, left, right)
  | Check.Compare_text (_, left, right) ->
      let left_names = variables_in left in
      left_names
      @ List.filter
          (fun name -> not (List.mem name left_names))
          (variables_in right)
  | Check.Negate (inner, _)
  | Check.Be_text inner
  | Check.Not inner
  | Check.Shown (inner, _) ->
      variables_in inner
  | Check.Call (_, arguments) ->
      List.fold_left
        (fun names (_, argument) ->
          names
          @ List.filter
              (fun name -> not (List.mem name names))
              (variables_in argument))
        [] arguments
  | Check.Format pieces ->
      List.concat_map
        (function
          | Check.Fill inner -> variables_in inner | Check.Words _ -> [])
        pieces
  | Check.Whole_literal _ | Check.Text_literal _ -> []

let describe variables names =
  List.filter_map
    (fun name ->
      match Hashtbl.find_opt variables name with
      | Some (Whole_value number) ->
          Some (Printf.sprintf "`%s` is %Ld" name number)
      | _ -> None)
    names
  |> String.concat ", and "

(* trace: D82 *)
let check_failed (place : Token.t) what values why =
  raise
    (Message.Stop
       {
         Message.kind = Message.Check_failed;
         line = place.line;
         byte = place.byte;
         length = place.length;
         body =
           (if values = "" then Message.What what
            else Message.What_when (what, values));
         why = Some why;
       })

let whole_range =
  "a `Whole` holds whole numbers from -9223372036854775808 to \
   9223372036854775807."

(* The exact result, or which way it went past a `Whole`'s range. *)
let exact operation first second =
  let open Int64 in
  match (operation : Check.operation) with
  | Check.Plus ->
      let sum = add first second in
      if first >= 0L && second >= 0L && sum < 0L then Error `Too_big
      else if first < 0L && second < 0L && sum >= 0L then Error `Too_small
      else Ok sum
  | Check.Minus ->
      let difference = sub first second in
      if first >= 0L && second < 0L && difference < 0L then Error `Too_big
      else if first < 0L && second > 0L && difference >= 0L then
        Error `Too_small
      else Ok difference
  | Check.Times ->
      let product = mul first second in
      let overflowed =
        (first <> 0L && div product first <> second)
        || (first = -1L && second = min_int)
        || (second = -1L && first = min_int)
      in
      if overflowed then
        if first < 0L = (second < 0L) then Error `Too_big else Error `Too_small
      else Ok product
  | Check.Divide rounding ->
      if second = -1L && first = min_int then Error `Too_big
      else
        let quotient = div first second in
        let remainder = rem first second in
        if
          rounding = Check.Down && remainder <> 0L && first < 0L <> (second < 0L)
        then Ok (sub quotient 1L)
        else Ok quotient
  | Check.Remainder rounding ->
      if second = -1L then Ok 0L
      else
        let remainder = rem first second in
        if
          rounding = Check.Down && remainder <> 0L
          && remainder < 0L <> (second < 0L)
        then Ok (add remainder second)
        else Ok remainder
  | Check.Saturate _ -> invalid_arg "Run.exact: saturate is handled apart"

let rec evaluate source variables (expression : Check.expression) =
  match expression.shape with
  | Check.Whole_literal number -> Whole_value number
  | Check.Text_literal words -> Text_value words
  | Check.Variable name -> Hashtbl.find variables name
  | Check.Negate (inner, minus) -> (
      match evaluate source variables inner with
      | Whole_value number when number = Int64.min_int ->
          (* trace: D86 *)
          check_failed minus
            (Printf.sprintf "`%s` is too big for a `Whole`"
               (text_of source expression))
            (describe variables (variables_in inner))
            whole_range
      | Whole_value number -> Whole_value (Int64.neg number)
      | Text_value _ | Bool_value _ | Nothing_value ->
          invalid_arg "Run.evaluate: `-` on a non-number passed the checker")
  | Check.Arithmetic (Check.Saturate operation, left, right, _) ->
      saturate source variables Check.no_limits operation left right
  | Check.Arithmetic (operation, left, right, place) -> (
      match
        (evaluate source variables left, evaluate source variables right)
      with
      | Whole_value first, Whole_value second -> (
          (match operation with
          | (Check.Divide _ | Check.Remainder _) when second = 0L ->
              (* trace: D85 *)
              let values =
                match right.shape with
                | Check.Variable name -> describe variables [ name ]
                | _ -> ""
              in
              check_failed place
                (Printf.sprintf "`%s` divides by zero"
                   (text_of source expression))
                values "nothing can be divided by zero."
          | _ -> ());
          match exact operation first second with
          | Ok number -> Whole_value number
          | Error direction ->
              (* trace: D84 *)
              let operands =
                List.filter_map
                  (fun (part : Check.expression) ->
                    match part.shape with
                    | Check.Variable name -> Some name
                    | _ -> None)
                  [ left; right ]
              in
              check_failed place
                (Printf.sprintf "`%s` is too %s for a `Whole`"
                   (text_of source expression)
                   (match direction with
                   | `Too_big -> "big"
                   | `Too_small -> "small"))
                (describe variables operands)
                whole_range)
      | _ -> invalid_arg "Run.evaluate: arithmetic on text passed the checker")
  | Check.Join (left, right) -> (
      match
        (evaluate source variables left, evaluate source variables right)
      with
      | Text_value first, Text_value second -> Text_value (first ^ second)
      | _ -> invalid_arg "Run.evaluate: `&` on a number passed the checker")
  (* trace: D6 *)
  | Check.Be_text inner -> (
      match evaluate source variables inner with
      | Whole_value number -> Text_value (Int64.to_string number)
      | Text_value words -> Text_value words
      | Bool_value _ | Nothing_value ->
          invalid_arg "Run.evaluate: be.Text of a condition passed the checker")
  (* trace: D34 *)
  | Check.Compare_values (operator, left, right) -> (
      match
        (evaluate source variables left, evaluate source variables right)
      with
      | Whole_value first, Whole_value second ->
          Bool_value
            (match operator with
            | "==" -> first = second
            | "!=" -> first <> second
            | "<" -> first < second
            | ">" -> first > second
            | "at_least" -> first >= second
            | _ -> first <= second)
      | _ ->
          invalid_arg
            "Run.evaluate: a comparison of non-numbers passed the checker")
  (* trace: D37 *)
  (* `and` and `or` stop early; `.both` evaluates both sides every time. *)
  | Check.Logic (word, both, left, right) -> (
      let truth part =
        match evaluate source variables part with
        | Bool_value value -> value
        | _ ->
            invalid_arg
              "Run.evaluate: logic on a non-condition passed the checker"
      in
      let first = truth left in
      match (word, both) with
      | "and", false -> Bool_value (first && truth right)
      | "or", false -> Bool_value (first || truth right)
      | "and", true ->
          let second = truth right in
          Bool_value (first && second)
      | _ ->
          let second = truth right in
          Bool_value (first || second))
  | Check.Not inner -> (
      match evaluate source variables inner with
      | Bool_value value -> Bool_value (not value)
      | _ ->
          invalid_arg
            "Run.evaluate: `not` on a non-condition passed the checker")
  (* trace: D94 *)
  | Check.Compare_text (looks_same, left, right) -> (
      match
        (evaluate source variables left, evaluate source variables right)
      with
      | Text_value first, Text_value second ->
          if looks_same then
            Bool_value
              (String.equal
                 (Uunf_string.normalize_utf_8 `NFC first)
                 (Uunf_string.normalize_utf_8 `NFC second))
          else Bool_value (String.equal first second)
      | _ ->
          invalid_arg
            "Run.evaluate: compare_Text of non-text passed the checker")
  (* trace: D2 *)
  | Check.Format pieces ->
      Text_value
        (String.concat ""
           (List.map
              (function
                | Check.Words words -> words
                | Check.Fill inner -> (
                    match evaluate source variables inner with
                    | Whole_value number -> Int64.to_string number
                    | Text_value words -> words
                    | Bool_value _ | Nothing_value ->
                        invalid_arg
                          "Run.evaluate: a condition in braces passed the \
                           checker"))
              pieces))
  (* trace: D8 *)
  (* Each argument is worked out in the caller's variables and stored in the
     procedure's own, checking its limits as any variable's (D88). *)
  | Check.Call (name, arguments) -> (
      let parameters, body = Hashtbl.find procedures name in
      let scope = Hashtbl.create 16 in
      List.iter
        (fun (index, argument) ->
          let parameter, limits = List.nth parameters index in
          store source variables scope parameter limits argument)
        arguments;
      match run_statements source scope body with
      | () -> Nothing_value
      | exception Returned value -> value)
  (* trace: D30 *)
  | Check.Shown (inner, same_line) ->
      show (evaluate source variables inner) same_line;
      Nothing_value

and show value same_line =
  match value with
  | Text_value words ->
      print_string words;
      (* trace: D12 *)
      if not same_line then print_char '\n'
  | _ -> invalid_arg "Run: show_text of a non-text passed the checker"

(* trace: D87 *)
(* trace: D88 *)
(* The result sticks at the limits of the type it goes into, or a `Whole`'s
   own range when it has none. *)
and saturate source variables (limits : Check.limits) operation left right =
  match (evaluate source variables left, evaluate source variables right) with
  | Whole_value first, Whole_value second ->
      let result =
        match exact operation first second with
        | Ok number -> number
        | Error `Too_big -> Int64.max_int
        | Error `Too_small -> Int64.min_int
      in
      let result =
        match limits.maximum with
        | Some high when result > high -> high
        | _ -> result
      in
      let result =
        match limits.minimum with
        | Some low when result < low -> low
        | _ -> result
      in
      Whole_value result
  | _ -> invalid_arg "Run.saturate: arithmetic on text passed the checker"

(* trace: D88 *)
(* Storing into a variable with limits: `.saturate` at the top sticks at them,
   and anything else outside them is a failed check. *)
and store source variables into name limits (expression : Check.expression) =
  let value =
    match expression.shape with
    | Check.Arithmetic (Check.Saturate operation, left, right, _) ->
        saturate source variables limits operation left right
    | _ -> evaluate source variables expression
  in
  (match value with
  | Whole_value number -> (
      let failed words =
        check_failed
          {
            Token.kind = Token.Word "";
            line = expression.line;
            byte = expression.byte;
            length = expression.length;
          }
          words
          (describe variables (variables_in expression))
          "a number stays within the limits written for its type."
      in
      let text = text_of source expression in
      match limits with
      | { Check.maximum = Some high; _ } when number > high ->
          failed
            (Printf.sprintf "`%s` is above `%s`'s maximum of %Ld" text name high)
      | { Check.minimum = Some low; _ } when number < low ->
          failed
            (Printf.sprintf "`%s` is below `%s`'s minimum of %Ld" text name low)
      | _ -> ())
  | Text_value _ | Bool_value _ | Nothing_value -> ());
  Hashtbl.replace into name value

(* trace: D35 *)
and run_statements source variables statements =
  List.iter
    (function
      | Check.If (branches, otherwise) -> (
          let chosen =
            List.find_opt
              (fun (value, _) ->
                match evaluate source variables value with
                | Bool_value truth -> truth
                | _ ->
                    invalid_arg
                      "Run: an `if` without a condition passed the checker")
              branches
          in
          match (chosen, otherwise) with
          | Some (_, body), _ | None, Some body ->
              run_block source variables body
          | None, None -> ())
      | Check.Show_text (expression, same_line) ->
          show (evaluate source variables expression) same_line
      | Check.Declare (name, expression, limits)
      | Check.Change (name, expression, limits) ->
          store source variables variables name limits expression
      | Check.Expression_statement expression ->
          ignore (evaluate source variables expression)
      | Check.Return (value, _) ->
          raise
            (Returned
               (match value with
               | Some value -> evaluate source variables value
               | None -> Nothing_value)))
    statements

(* trace: D102 *)
(* A block's declarations end with it: each name it declares gets back the
   value it had before, or is gone again. A `return` leaves the whole
   procedure, so nothing needs putting back then. *)
and run_block source variables body =
  let declared =
    List.filter_map
      (function
        | Check.Declare (name, _, _) ->
            Some (name, Hashtbl.find_opt variables name)
        | _ -> None)
      body
  in
  run_statements source variables body;
  List.iter
    (fun (name, before) ->
      match before with
      | Some value -> Hashtbl.replace variables name value
      | None -> Hashtbl.remove variables name)
    declared

let program source (main, named) =
  Hashtbl.reset procedures;
  List.iter
    (fun (name, (parameters : Check.parameter list), body) ->
      Hashtbl.replace procedures name
        ( List.map
            (fun (parameter : Check.parameter) ->
              (parameter.parameter_name, parameter.parameter_limits))
            parameters,
          body ))
    named;
  match run_statements source (Hashtbl.create 16) main with
  | () -> ()
  | exception Returned _ -> ()
