(* Running a checked program, one statement after another. PlainOracle's
   answers are `Working`'s answers: every check is made (D19, D66). *)

type value = Whole_value of Int64.t | Text_value of string

let stop_at (token : Token.t) words =
  raise
    (Message.Stop
       {
         Message.kind = Message.Not_designed_yet;
         line = token.line;
         byte = token.byte;
         length = token.length;
         body = Message.What words;
         why = None;
       })

(* trace: D19 *)
(* Overflow is a check that stops the program, but how a failed check is
   reported while running isn't decided yet. *)
let add (token : Token.t) first second =
  let sum = Int64.add first second in
  let overflowed =
    (first >= 0L && second >= 0L && sum < 0L)
    || (first < 0L && second < 0L && sum >= 0L)
  in
  if overflowed then
    stop_at token
      "how a failed check is reported while running isn't decided yet"
  else sum

let rec evaluate variables (expression : Check.expression) =
  match expression.shape with
  | Check.Whole_literal number -> Whole_value number
  | Check.Text_literal words -> Text_value words
  | Check.Variable name -> Hashtbl.find variables name
  | Check.Add (left, right, token) -> (
      match (evaluate variables left, evaluate variables right) with
      | Whole_value first, Whole_value second ->
          Whole_value (add token first second)
      | _ -> invalid_arg "Run.evaluate: `+` on text passed the checker")
  | Check.Join (left, right) -> (
      match (evaluate variables left, evaluate variables right) with
      | Text_value first, Text_value second -> Text_value (first ^ second)
      | _ -> invalid_arg "Run.evaluate: `&` on a number passed the checker")
  (* trace: D6 *)
  | Check.Be_text inner -> (
      match evaluate variables inner with
      | Whole_value number -> Text_value (Int64.to_string number)
      | Text_value words -> Text_value words)
  (* trace: D2 *)
  | Check.Format pieces ->
      Text_value
        (String.concat ""
           (List.map
              (function
                | Check.Words words -> words
                | Check.Fill expression -> (
                    match evaluate variables expression with
                    | Whole_value number -> Int64.to_string number
                    | Text_value words -> words))
              pieces))

let program statements =
  let variables = Hashtbl.create 16 in
  List.iter
    (function
      | Check.Show_text (expression, same_line) -> (
          match evaluate variables expression with
          | Text_value words ->
              print_string words;
              (* trace: D12 *)
              if not same_line then print_char '\n'
          | Whole_value _ ->
              invalid_arg
                "Run.program: show_text of a number passed the checker")
      | Check.Declare (name, expression) | Check.Change (name, expression) ->
          Hashtbl.replace variables name (evaluate variables expression))
    statements
