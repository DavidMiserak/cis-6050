%option noyywrap nodefault yylineno case-insensitive

%{
#include "pascal.h"
#include "pascal.tab.h"
%}

 /* float exponent */
EXP ([Ee][-+]?[0-9]+)

%%

 /* keywords */
AND        { return AND        ; }
ARRAY      { return ARRAY      ; }
BEGIN      { return BEGIN1     ; }
CASE       { return CASE       ; }
CONST      { return CONST      ; }
DIV        { return DIV        ; }
DO         { return DO         ; }
DOWNTO     { return DOWNTO     ; }
ELSE       { return ELSE       ; }
END        { return END        ; }
FILE       { return FILE1      ; }
FOR        { return FOR        ; }
FORWARD    { return FORWARD    ; }
FUNCTION   { return FUNCTION   ; }
GOTO       { return GOTO       ; }
IF         { return IF         ; }
IN         { return IN         ; }
LABEL      { return LABEL      ; }
MOD        { return MOD        ; }
NIL        { return NIL        ; }
NOT        { return NOT        ; }
OF         { return OF         ; }
OR         { return OR         ; }
PACKED     { return PACKED     ; }
PROCEDURE  { return PROCEDURE  ; }
PROGRAM    { return PROGRAM    ; }
RECORD     { return RECORD     ; }
REPEAT     { return REPEAT     ; }
SET        { return SET        ; }
THEN       { return THEN       ; }
TO         { return TO         ; }
TYPE       { return TYPE       ; }
UNTIL      { return UNTIL      ; }
VAR        { return VAR        ; }
WHILE      { return WHILE      ; }
WITH       { return WITH       ; }

 /* required identifiers */
TRUE       { yylval.d = 1.0; return TRUE       ; }
FALSE      { yylval.d = 0.0; return FALSE      ; }

BOOLEAN    { return BOOLEAN    ; }
CHAR       { return CHAR       ; }
INPUT      { return INPUT      ; }
INTEGER    { return INTEGER    ; }
MAXINT     { return MAXINT     ; }
NEW        { return NEW        ; }
OUTPUT     { return OUTPUT     ; }
REAL       { return REAL       ; }
TEXT       { return TEXT       ; }

 /* Pascal's built-in functions */
ABS        { yylval.fn = B_abs;    return ABS        ; }
ARCTAN     { yylval.fn = B_arctan; return ARCTAN     ; }
CHR        { yylval.fn = B_chr;    return CHR        ; }
COS        { yylval.fn = B_cos;    return COS        ; }
EOF        { yylval.fn = B_eof;    return EOF1       ; }
EOLN       { yylval.fn = B_eoln;   return EOLN       ; }
EXP        { yylval.fn = B_exp;    return EXP        ; }
LN         { yylval.fn = B_ln;     return LN         ; }
ODD        { yylval.fn = B_odd;    return ODD        ; }
ORD        { yylval.fn = B_ord;    return ORD        ; }
PRED       { yylval.fn = B_pred;   return PRED       ; }
ROUND      { yylval.fn = B_round;  return ROUND      ; }
SIN        { yylval.fn = B_sin;    return SIN        ; }
SQR        { yylval.fn = B_sqr;    return SQR        ; }
SQRT       { yylval.fn = B_sqrt;   return SQRT       ; }
SUCC       { yylval.fn = B_succ;   return SUCC       ; }
TRUNC      { yylval.fn = B_trunc;  return TRUNC      ; }

 /* Pascal's built-in procedures */
DISPOSE    { yylval.fn = B_dispose; return DISPOSE    ; }
GET        { yylval.fn = B_get;     return GET        ; }
PACK       { yylval.fn = B_pack;    return PACK       ; }
PAGE       { yylval.fn = B_page;    return PAGE       ; }
PUT        { yylval.fn = B_put;     return PUT        ; }
READ       { yylval.fn = B_read;    return READ       ; }
READLN     { yylval.fn = B_readln;  return READLN     ; }
RESET      { yylval.fn = B_reset;   return RESET      ; }
REWRITE    { yylval.fn = B_rewrite; return REWRITE    ; }
UNPACK     { yylval.fn = B_unpack;  return UNPACK     ; }
WRITE      { yylval.fn = B_write;   return WRITE      ; }
WRITELN    { yylval.fn = B_writeln; return WRITELN    ; }

 /* relational operators */
">"  { yylval.fn = 1; return GT        ; }
"<"  { yylval.fn = 2; return LT        ; }
"<>" { yylval.fn = 3; return NOT_EQUAL ; }
"="  { yylval.fn = 4; return EQUAL     ; }
">=" { yylval.fn = 5; return GT_EQUAL  ; }
"<=" { yylval.fn = 6; return LT_EQUAL  ; }

 /* arithmetic operators */
"+" { yylval.c = '+'; return PLUS ;    }
"-" { yylval.c = '-'; return MINUS ;   }
"*" { yylval.c = '*'; return MULTIPLY; }
"/" { yylval.c = '/'; return DIVIDE ;  }

"("   { return LPAREN ; } 
")"   { return RPAREN ; } 
"["   { return LBRACK ; } 
"]"   { return RBRACK ; } 
"^"   { return CARROT ; }
:=    { return ASSIGN ; }

[0-9]+          { yylval.d = atof( yytext ); return NUM_INT ; }

[0-9]+"."[0-9]*{EXP}? |
"."?[0-9]+{EXP}? { yylval.d = atof( yytext ); return NUM_REAL ; }

[a-z]([a-z0-9]|"_")* { yylval.s = lookup( yytext ); return IDENT ; }

"'"   { return APOSTROPHE ; }
"."   { return DOT        ; }
".."  { return DOTDOT     ; }
";"   { return SEMI       ; }
":"   { return COLON      ; }
","   { return COMMA      ; }

\"([^\\\"]|\\.|\"\")*\" |
\'([^\\\']|\\.|\'\')*\' { 
	yylval.str = strdup(yytext+1);
	yylval.str[yyleng-2] = 0;
	return STRING_LITERAL ; }

"{"[^\\\}]*"}" { /* ignore comments   */ }
[ \t\n]    { /* ignore whitespace */ }
.      { printf("Mystery character %c\n", *yytext); }

<<EOF>>     { yyterminate(); }
%%
