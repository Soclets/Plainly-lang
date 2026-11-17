(* The words and symbols a Plainly program is made of. *)

type keyword =
  | Procedure_word
  | Main_word
  | None_word
  | End_word
  | Show_text_word
  | Mut_word
  | Change_word

(* trace: D57 *)
(* One grammar, two word tables. *)
type table = English | Thai

type kind =
  | Keyword of keyword * table
  | Word of string
  | Name of string
  | Text of string
  | Symbol of char

(* [byte] is the 1-based byte column where the token starts, and [length] its
   length in bytes. *)
type t = { kind : kind; line : int; byte : int; length : int }

let keyword_of_word = function
  | "procedure" | "proc" -> Some (Procedure_word, English)
  | "main" -> Some (Main_word, English)
  | "none" -> Some (None_word, English)
  | "end" -> Some (End_word, English)
  | "show_text" -> Some (Show_text_word, English)
  | "mut" | "mutable" -> Some (Mut_word, English)
  | "change" -> Some (Change_word, English)
  | "กระบวนการ" -> Some (Procedure_word, Thai)
  | "หลัก" -> Some (Main_word, Thai)
  | "ไม่มี" -> Some (None_word, Thai)
  | "สิ้นสุด" -> Some (End_word, Thai)
  | "แสดงข้อความ" -> Some (Show_text_word, Thai)
  | _ -> None

(* The word a keyword is written as in each table, where one is decided. *)
let spelling keyword table =
  match (keyword, table) with
  | Procedure_word, English -> Some "procedure"
  | Main_word, English -> Some "main"
  | None_word, English -> Some "none"
  | End_word, English -> Some "end"
  | Show_text_word, English -> Some "show_text"
  | Mut_word, English -> Some "mut"
  | Change_word, English -> Some "change"
  | Procedure_word, Thai -> Some "กระบวนการ"
  | Main_word, Thai -> Some "หลัก"
  | None_word, Thai -> Some "ไม่มี"
  | End_word, Thai -> Some "สิ้นสุด"
  | Show_text_word, Thai -> Some "แสดงข้อความ"
  | (Mut_word | Change_word), Thai -> None

(* trace: D75 *)
let language_of_word = function
  | "english" | "eng" -> Some English
  | "ไทย" -> Some Thai
  | _ -> None
