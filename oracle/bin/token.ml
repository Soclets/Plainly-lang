(* The words and symbols a Plainly program is made of. *)

type keyword =
  | Procedure_word
  | Main_word
  | None_word
  | End_word
  | Show_text_word

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
  | "กระบวนการ" -> Some (Procedure_word, Thai)
  | "หลัก" -> Some (Main_word, Thai)
  | "ไม่มี" -> Some (None_word, Thai)
  | "สิ้นสุด" -> Some (End_word, Thai)
  | "แสดงข้อความ" -> Some (Show_text_word, Thai)
  | _ -> None

(* The word a keyword is written as in each table. *)
let spelling keyword table =
  match (keyword, table) with
  | Procedure_word, English -> "procedure"
  | Main_word, English -> "main"
  | None_word, English -> "none"
  | End_word, English -> "end"
  | Show_text_word, English -> "show_text"
  | Procedure_word, Thai -> "กระบวนการ"
  | Main_word, Thai -> "หลัก"
  | None_word, Thai -> "ไม่มี"
  | End_word, Thai -> "สิ้นสุด"
  | Show_text_word, Thai -> "แสดงข้อความ"

(* trace: D75 *)
let language_of_word = function
  | "English" -> Some English
  | "ไทย" -> Some Thai
  | _ -> None
