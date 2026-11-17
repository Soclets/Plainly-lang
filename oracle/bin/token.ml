(* The words and symbols a Plainly program is made of. *)

type keyword =
  | Procedure_word
  | Main_word
  | None_word
  | End_word
  | Show_text_word
  | Mut_word
  | Change_word
  | Shadow_word
  | Be_word
  | Whole_word
  | Text_word
  | New_line_word
  | Format_word
  | Same_line_word
  | If_word
  | Else_word
  (* trace: D46 *)
  (* trace: D100 *)
  | Returns_word
  | Return_word
  | Nothing_word

(* trace: D57 *)
(* One grammar, two word tables. *)
type table = English | Thai

type kind =
  | Keyword of keyword * table
  | Word of string
  | Name of string
  | Text of string
  | Symbol of char
  (* trace: D34 *)
  | Compare of string
  (* trace: D30 *)
  | Pipe

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
  | "shadow" -> Some (Shadow_word, English)
  | "be" -> Some (Be_word, English)
  | "Whole" -> Some (Whole_word, English)
  | "Text" -> Some (Text_word, English)
  | "new_line" -> Some (New_line_word, English)
  | "format" -> Some (Format_word, English)
  | "same_line" -> Some (Same_line_word, English)
  | "if" -> Some (If_word, English)
  | "else" -> Some (Else_word, English)
  | "returns" -> Some (Returns_word, English)
  | "return" -> Some (Return_word, English)
  | "nothing" -> Some (Nothing_word, English)
  | "กระบวนการ" -> Some (Procedure_word, Thai)
  | "หลัก" -> Some (Main_word, Thai)
  | "ไม่มี" -> Some (None_word, Thai)
  | "สิ้นสุด" -> Some (End_word, Thai)
  | "แสดงข้อความ" -> Some (Show_text_word, Thai)
  | "เปลี่ยนได้" -> Some (Mut_word, Thai)
  | "เปลี่ยน" -> Some (Change_word, Thai)
  | "บัง" -> Some (Shadow_word, Thai)
  | "เป็น" -> Some (Be_word, Thai)
  | "จำนวนเต็ม" -> Some (Whole_word, Thai)
  | "ข้อความ" -> Some (Text_word, Thai)
  | "บรรทัดใหม่" -> Some (New_line_word, Thai)
  | "แทนค่า" -> Some (Format_word, Thai)
  | "บรรทัดเดิม" -> Some (Same_line_word, Thai)
  | "ถ้า" -> Some (If_word, Thai)
  | "ไม่งั้น" -> Some (Else_word, Thai)
  (* Thai verbs don't change form, so `คืน` is both `returns` and `return`;
     where it stands shows which. *)
  | "คืน" -> Some (Return_word, Thai)
  | "ไม่มีอะไร" -> Some (Nothing_word, Thai)
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
  | Shadow_word, English -> Some "shadow"
  | Be_word, English -> Some "be"
  | Whole_word, English -> Some "Whole"
  | Text_word, English -> Some "Text"
  | New_line_word, English -> Some "new_line"
  | Format_word, English -> Some "format"
  | Same_line_word, English -> Some "same_line"
  | If_word, English -> Some "if"
  | Else_word, English -> Some "else"
  | Returns_word, English -> Some "returns"
  | Return_word, English -> Some "return"
  | Nothing_word, English -> Some "nothing"
  | Procedure_word, Thai -> Some "กระบวนการ"
  | Main_word, Thai -> Some "หลัก"
  | None_word, Thai -> Some "ไม่มี"
  | End_word, Thai -> Some "สิ้นสุด"
  | Show_text_word, Thai -> Some "แสดงข้อความ"
  | Mut_word, Thai -> Some "เปลี่ยนได้"
  | Change_word, Thai -> Some "เปลี่ยน"
  | Shadow_word, Thai -> Some "บัง"
  | Be_word, Thai -> Some "เป็น"
  | Whole_word, Thai -> Some "จำนวนเต็ม"
  | Text_word, Thai -> Some "ข้อความ"
  | New_line_word, Thai -> Some "บรรทัดใหม่"
  | Format_word, Thai -> Some "แทนค่า"
  | Same_line_word, Thai -> Some "บรรทัดเดิม"
  | If_word, Thai -> Some "ถ้า"
  | Else_word, Thai -> Some "ไม่งั้น"
  | (Returns_word | Return_word), Thai -> Some "คืน"
  | Nothing_word, Thai -> Some "ไม่มีอะไร"

(* trace: D75 *)
let language_of_word = function
  | "english" | "eng" -> Some English
  | "ไทย" -> Some Thai
  | _ -> None
