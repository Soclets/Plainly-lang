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
      let statements, refusals, stop, declared =
        Check.program source tokens lexer_stop
      in
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
      let messages = refusals @ Option.to_list stop in
      (* trace: D61 *)
      (* trace: D75 *)
      (* A Thai file's messages are in Thai, and only their labels are decided,
         so its first message stops with NotDesignedYet in its place. *)
      let messages, stop =
        match (declared, messages) with
        | Some Token.Thai, ({ Message.kind = Message.Refused; _ } as first) :: _
          ->
            let thai =
              {
                first with
                Message.kind = Message.Not_designed_yet;
                body =
                  Message.What
                    "the Thai wording of this message isn't decided yet";
                why = None;
              }
            in
            ([ thai ], Some thai)
        | _ -> (messages, stop)
      in
      match messages with
      | [] -> (
          match Run.program source statements with
          | () -> 0
          | exception Message.Stop message ->
              flush stdout;
              prerr_string (Message.render source message);
              Message.exit_status message.kind)
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
