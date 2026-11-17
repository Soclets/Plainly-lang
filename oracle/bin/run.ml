(* Running a checked program, one statement after another. PlainOracle's
   answers are `Working`'s answers: every check is made (D19, D66). *)

type value = Whole_value of Int64.t | Text_value of string

(* trace: D19 *)
(* trace: D82 *)
(* Overflow is a check that stops the program, naming the values that broke
   it. *)
let add source variables (expression : Check.expression) (token : Token.t)
    (left : Check.expression) (right : Check.expression) first second =
  let sum = Int64.add first second in
  let overflowed =
    (first >= 0L && second >= 0L && sum < 0L)
    || (first < 0L && second < 0L && sum >= 0L)
  in
  if overflowed then
    let text (part : Check.expression) =
      String.sub (Source.line source part.line) (part.byte - 1) part.length
    in
    let values =
      List.filter_map
        (fun (part : Check.expression) ->
          match part.shape with
          | Check.Variable name -> (
              match Hashtbl.find variables name with
              | Whole_value number ->
                  Some (Printf.sprintf "`%s` is %Ld" name number)
              | Text_value _ -> None)
          | _ -> None)
        [ left; right ]
    in
    let what =
      Printf.sprintf "`%s` is too big for a `Whole`" (text expression)
    in
    raise
      (Message.Stop
         {
           Message.kind = Message.Check_failed;
           line = token.line;
           byte = token.byte;
           length = token.length;
           body =
             (match values with
             | [] -> Message.What what
             | _ -> Message.What_when (what, String.concat ", and " values));
           why =
             Some
               "a `Whole` holds whole numbers from -9223372036854775808 to \
                9223372036854775807.";
         })
  else sum

let rec evaluate source variables (expression : Check.expression) =
  match expression.shape with
  | Check.Whole_literal number -> Whole_value number
  | Check.Text_literal words -> Text_value words
  | Check.Variable name -> Hashtbl.find variables name
  | Check.Add (left, right, token) -> (
      match
        (evaluate source variables left, evaluate source variables right)
      with
      | Whole_value first, Whole_value second ->
          Whole_value
            (add source variables expression token left right first second)
      | _ -> invalid_arg "Run.evaluate: `+` on text passed the checker")
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
      | Text_value words -> Text_value words)
  (* trace: D2 *)
  | Check.Format pieces ->
      Text_value
        (String.concat ""
           (List.map
              (function
                | Check.Words words -> words
                | Check.Fill expression -> (
                    match evaluate source variables expression with
                    | Whole_value number -> Int64.to_string number
                    | Text_value words -> words))
              pieces))

let program source statements =
  let variables = Hashtbl.create 16 in
  List.iter
    (function
      | Check.Show_text (expression, same_line) -> (
          match evaluate source variables expression with
          | Text_value words ->
              print_string words;
              (* trace: D12 *)
              if not same_line then print_char '\n'
          | Whole_value _ ->
              invalid_arg
                "Run.program: show_text of a number passed the checker")
      | Check.Declare (name, expression) | Check.Change (name, expression) ->
          Hashtbl.replace variables name (evaluate source variables expression))
    statements
