(* PlainOracle: the slow, obviously correct reference for Plainly (D17). *)

let before (message : Message.t) (limit : Message.t) =
  compare (message.line, message.byte) (limit.line, limit.byte) < 0

let run file =
  match Source.read file with
  | exception Sys_error _ ->
      prerr_endline ("plainoracle: can't read " ^ file);
      2
  | source -> (
      let tokens, lexer_stop = Lexer.tokens source in
      let statements, refusals, stop = Check.program source tokens lexer_stop in
      let refusals = refusals @ Check.indentation source tokens in
      let refusals =
        match stop with
        | Some limit ->
            List.filter (fun message -> before message limit) refusals
        | None -> refusals
      in
      let refusals =
        List.sort
          (fun (first : Message.t) (second : Message.t) ->
            compare (first.line, first.byte) (second.line, second.byte))
          refusals
      in
      match refusals @ Option.to_list stop with
      | [] ->
          List.iter
            (fun (Check.Show_text words) ->
              print_string words;
              print_char '\n')
            statements;
          0
      | messages ->
          prerr_string
            (String.concat "\n" (List.map (Message.render source) messages));
          if Option.is_some stop then 3 else 1)

let () =
  match Sys.argv with
  | [| _; file |] -> exit (run file)
  | _ ->
      prerr_endline "usage: plainoracle <file>";
      exit 2
