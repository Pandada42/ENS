# 4 "lexer.mll"
 
  open Lexing
  open Ast
  open Parser

  exception Lexing_error of string

  let id_or_kwd =
    let h = Hashtbl.create 32 in
    List.iter (fun (s, tok) -> Hashtbl.add h s tok)
      ["def", DEF; "if", IF; "else", ELSE;
       "return", RETURN; "print", PRINT;
       "for", FOR; "in", IN;
       "and", AND; "or", OR; "not", NOT;
       "True", CST (Cbool true);
       "False", CST (Cbool false);
       "None", CST Cnone;];
   fun s -> try Hashtbl.find h s with Not_found -> IDENT s

  let string_buffer = Buffer.create 1024

  let stack = ref [0]  (* indentation stack *)
  let rec unindent n = match !stack with
    | m :: _ when m = n -> []
    | m :: st when m > n -> stack := st; END :: unindent n
    | _ -> raise (Lexing_error "bad indentation")
  let update_stack n =
    match !stack with
    | m :: _ when m < n ->
      stack := n :: !stack;
      [NEWLINE; BEGIN]
    | _ ->
      NEWLINE :: unindent n

# 37 "lexer.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base =
   "\000\000\231\255\232\255\233\255\075\000\235\255\236\255\237\255\
    \238\255\239\255\240\255\002\000\003\000\031\000\033\000\248\255\
    \012\000\250\255\251\255\252\255\085\000\001\000\004\000\255\255\
    \249\255\246\255\245\255\243\255\241\255\199\000\253\255\255\255\
    \002\000\004\000\251\255\252\255\109\000\255\255\253\255\254\255\
    ";
  Lexing.lex_backtrk =
   "\255\255\255\255\255\255\255\255\021\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\013\000\011\000\024\000\008\000\255\255\
    \024\000\255\255\255\255\255\255\002\000\001\000\001\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\001\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\003\000\255\255\255\255\255\255\
    ";
  Lexing.lex_default =
   "\001\000\000\000\000\000\000\000\255\255\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\255\255\255\255\255\255\000\000\
    \255\255\000\000\000\000\000\000\255\255\021\000\255\255\000\000\
    \000\000\000\000\000\000\000\000\000\000\255\255\000\000\000\000\
    \032\000\035\000\000\000\000\000\255\255\000\000\000\000\000\000\
    ";
  Lexing.lex_trans =
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\022\000\023\000\255\255\031\000\022\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \022\000\013\000\003\000\021\000\022\000\015\000\037\000\021\000\
    \010\000\009\000\017\000\019\000\006\000\018\000\000\000\016\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\005\000\024\000\012\000\014\000\011\000\028\000\
    \027\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\008\000\026\000\007\000\025\000\000\000\
    \036\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\038\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \000\000\000\000\000\000\000\000\020\000\000\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \029\000\031\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\039\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\029\000\
    \000\000\000\000\032\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \002\000\255\255\255\255\000\000\034\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\030\000\
    ";
  Lexing.lex_check =
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\021\000\032\000\022\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\000\000\000\000\000\000\022\000\000\000\033\000\022\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\255\255\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\016\000\000\000\000\000\000\000\011\000\
    \012\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\013\000\000\000\014\000\255\255\
    \033\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\036\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \255\255\255\255\255\255\255\255\020\000\255\255\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \029\000\029\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\036\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\029\000\
    \255\255\255\255\029\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\021\000\032\000\255\255\033\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\029\000\
    ";
  Lexing.lex_base_code =
   "";
  Lexing.lex_backtrk_code =
   "";
  Lexing.lex_default_code =
   "";
  Lexing.lex_trans_code =
   "";
  Lexing.lex_check_code =
   "";
  Lexing.lex_code =
   "";
}

let rec next_tokens lexbuf =
   __ocaml_lex_next_tokens_rec lexbuf 0
and __ocaml_lex_next_tokens_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 47 "lexer.mll"
            ( new_line lexbuf; update_stack (indentation lexbuf) )
# 199 "lexer.ml"

  | 1 ->
# 49 "lexer.mll"
            ( next_tokens lexbuf )
# 204 "lexer.ml"

  | 2 ->
let
# 50 "lexer.mll"
             id
# 210 "lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 50 "lexer.mll"
                ( [id_or_kwd id] )
# 214 "lexer.ml"

  | 3 ->
# 51 "lexer.mll"
            ( [PLUS] )
# 219 "lexer.ml"

  | 4 ->
# 52 "lexer.mll"
            ( [MINUS] )
# 224 "lexer.ml"

  | 5 ->
# 53 "lexer.mll"
            ( [TIMES] )
# 229 "lexer.ml"

  | 6 ->
# 54 "lexer.mll"
            ( [DIV] )
# 234 "lexer.ml"

  | 7 ->
# 55 "lexer.mll"
            ( [MOD] )
# 239 "lexer.ml"

  | 8 ->
# 56 "lexer.mll"
            ( [EQUAL] )
# 244 "lexer.ml"

  | 9 ->
# 57 "lexer.mll"
            ( [CMP Beq] )
# 249 "lexer.ml"

  | 10 ->
# 58 "lexer.mll"
            ( [CMP Bneq] )
# 254 "lexer.ml"

  | 11 ->
# 59 "lexer.mll"
            ( [CMP Blt] )
# 259 "lexer.ml"

  | 12 ->
# 60 "lexer.mll"
            ( [CMP Ble] )
# 264 "lexer.ml"

  | 13 ->
# 61 "lexer.mll"
            ( [CMP Bgt] )
# 269 "lexer.ml"

  | 14 ->
# 62 "lexer.mll"
            ( [CMP Bge] )
# 274 "lexer.ml"

  | 15 ->
# 63 "lexer.mll"
            ( [LP] )
# 279 "lexer.ml"

  | 16 ->
# 64 "lexer.mll"
            ( [RP] )
# 284 "lexer.ml"

  | 17 ->
# 65 "lexer.mll"
            ( [LSQ] )
# 289 "lexer.ml"

  | 18 ->
# 66 "lexer.mll"
            ( [RSQ] )
# 294 "lexer.ml"

  | 19 ->
# 67 "lexer.mll"
            ( [COMMA] )
# 299 "lexer.ml"

  | 20 ->
# 68 "lexer.mll"
            ( [COLON] )
# 304 "lexer.ml"

  | 21 ->
let
# 69 "lexer.mll"
               s
# 310 "lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 70 "lexer.mll"
            ( try [CST (Cint (int_of_string s))]
              with _ -> raise (Lexing_error ("constant too large: " ^ s)) )
# 315 "lexer.ml"

  | 22 ->
# 72 "lexer.mll"
            ( [CST (Cstring (string lexbuf))] )
# 320 "lexer.ml"

  | 23 ->
# 73 "lexer.mll"
            ( NEWLINE :: unindent 0 @ [EOF] )
# 325 "lexer.ml"

  | 24 ->
let
# 74 "lexer.mll"
         c
# 331 "lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 74 "lexer.mll"
            ( raise (Lexing_error ("illegal character: " ^ String.make 1 c)) )
# 335 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_next_tokens_rec lexbuf __ocaml_lex_state

and indentation lexbuf =
   __ocaml_lex_indentation_rec lexbuf 29
and __ocaml_lex_indentation_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 78 "lexer.mll"
      ( new_line lexbuf; indentation lexbuf )
# 347 "lexer.ml"

  | 1 ->
let
# 79 "lexer.mll"
              s
# 353 "lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 80 "lexer.mll"
      ( String.length s )
# 357 "lexer.ml"

  | 2 ->
# 82 "lexer.mll"
      ( 0 )
# 362 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_indentation_rec lexbuf __ocaml_lex_state

and string lexbuf =
   __ocaml_lex_string_rec lexbuf 33
and __ocaml_lex_string_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 86 "lexer.mll"
      ( let s = Buffer.contents string_buffer in
	Buffer.reset string_buffer;
	s )
# 376 "lexer.ml"

  | 1 ->
# 90 "lexer.mll"
      ( Buffer.add_char string_buffer '\n';
	string lexbuf )
# 382 "lexer.ml"

  | 2 ->
# 93 "lexer.mll"
      ( Buffer.add_char string_buffer '"';
	string lexbuf )
# 388 "lexer.ml"

  | 3 ->
let
# 95 "lexer.mll"
         c
# 394 "lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 96 "lexer.mll"
      ( Buffer.add_char string_buffer c;
	string lexbuf )
# 399 "lexer.ml"

  | 4 ->
# 99 "lexer.mll"
      ( raise (Lexing_error "unterminated string") )
# 404 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_string_rec lexbuf __ocaml_lex_state

;;

# 101 "lexer.mll"
 

  let next_token =
    let tokens = Queue.create () in (* prochains lexèmes à renvoyer *)
    fun lb ->
      if Queue.is_empty tokens then begin
	let l = next_tokens lb in
	List.iter (fun t -> Queue.add t tokens) l
      end;
      Queue.pop tokens

# 423 "lexer.ml"
