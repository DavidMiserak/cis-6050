/* Pascal parser */
%{
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include "pascal.h"
%}

%union {
        int fn;
        double d;
        char c;
	char * str;
        struct ast * a;
        struct symbol * s;
        struct symbol * sl;
}

%token <s> IDENT 
%token <d> NUM_INT NUM_REAL 
%token <c> PLUS MINUS MULTIPLY DIVIDE /* arithmetic operators */
%token ASSIGN DOTDOT APOSTROPHE
%token <str> STRING_LITERAL
%token DOT SEMI COLON COMMA CARROT
%token LPAREN RPAREN RBRACK LBRACK
%token GT LT NOT_EQUAL EQUAL GT_EQUAL LT_EQUAL /* relational operators */

/* keywords */
%token AND
%token ARRAY
%token BEGIN1
%token CASE
%token CONST
%token DIV
%token DO
%token DOWNTO
%token ELSE
%token END
%token FILE1
%token FOR
%token FORWARD
%token FUNCTION
%token GOTO
%token IF
%token IN
%token LABEL
%token MOD
%token NIL
%token NOT
%token OF
%token OR
%token PACKED
%token PROCEDURE
%token PROGRAM
%token RECORD
%token REPEAT
%token SET
%token THEN
%token TO
%token TYPE
%token UNTIL
%token VAR
%token WHILE
%token WITH

 /* required identifiers */
%token TRUE FALSE
%token BOOLEAN
%token CHAR
%token INPUT
%token INTEGER
%token MAXINT
%token NEW
%token OUTPUT
%token REAL
%token TEXT

 /* Pascal's built-in functions */
%token ABS ARCTAN CHR COS EOF1 EOLN EXP LN ODD ORD PRED ROUND SIN SQR SQRT
%token SUCC TRUNC

 /* Pascal's built-in procedures */
%token DISPOSE GET PACK PAGE PUT READ READLN RESET REWRITE UNPACK 
%token WRITE WRITELN

 /* types */
%type <a> variable_declaration

%type <a> assignment_statement
%type <a> expression simple_expression term factor
%type <a> unsigned_number unsigned_integer unsigned_real
%type <c> adding_operator multiplying_operator
%type <a> unsigned_constant

 /* Association */
%right ASSIGN
%left  PLUS MINUS
%left  MULTIPLY DIVIDE

 /* Entry */
%start program

%%

/* Program */
program
: program_heading SEMI program_block DOT {
	emit( "  return ; terminate main" );
	emit( ".end method ; end main method\n" );
}
;

program_block : block ;

program_heading
: PROGRAM IDENT
| PROGRAM IDENT LPAREN program_parameter_list RPAREN {
	emit( ".source Main.j ; File declaration" );
	emit( ".class Main ; Class declaration" );
	emit( ".super java/lang/Object ;  Super-class declaration\n" );

	emit( "; default constructor" );
	emit( ".method public <init>()V" );
	emit( "  aload_0 ; push this" );
	emit( "  invokespecial java/lang/Object/<init>()V ; call super" );
	emit( "  return" );
	emit( ".end method ; default constructor\n" );

	emit( ".method public static main([Ljava/lang/String;)V" );
	emit( "  ; allocate stack big enough" );
	emit( "  .limit stack 1000\n" );
}
;

program_parameter_list
: program_parameter
| program_parameter_list COMMA program_parameter
;

program_parameter
: IDENT
| INPUT
| OUTPUT
;

 /* identifier and literals*/
identifier_list
: IDENT 
| identifier_list COMMA IDENT
;

directive
: IDENT
| directive IDENT
| directive NUM_INT
;

array_variable : variable_access ;

/* parts */
block
:
label_declaration_part 
constant_definition_part 
type_definition_part
variable_declaration_part
procedure_and_function_declaration_part
statement_part
;

/* parts: label */
label_declaration_part
: %empty /* nothing */
| LABEL label_declaration_part_list SEMI
;

label_declaration_part_list
: label
| label_declaration_part_list COMMA label
;

label : NUM_INT ;

/* parts: constants */
constant_definition_part
: %empty /* nothing */
| CONST constant_definition_part_list SEMI
;

constant_definition_part_list
: constant_definition
| constant_definition_part_list SEMI constant_definition
;

constant_definition : IDENT EQUAL constant ;

constant
: sign unsigned_number
| sign IDENT
| unsigned_number
| IDENT
| STRING_LITERAL
| boolean
;

sign
: PLUS 
| MINUS
;

unsigned_constant
: unsigned_number
| STRING_LITERAL
//| IDENT
//| NIL
;

unsigned_number
: unsigned_integer
| unsigned_real
;

unsigned_integer : NUM_INT {$$ = newnum($1);} ;

unsigned_real : NUM_REAL {$$ = newnum($1);} ;

boolean: TRUE | FALSE ;

/* parts: types */
type_definition_part 
: %empty /* nothing */
| TYPE type_definition_part_list
;

type_definition_part_list
: type_definition SEMI
| type_definition_part_list type_definition SEMI
;

type_definition 
: IDENT EQUAL type_denoter 
;

type_denoter 
: type_identifier 
| new_type 
;

type_identifier
: IDENT
| BOOLEAN
| CHAR
| INTEGER
| REAL
| TEXT
;

new_type 
: new_ordinal_type 
| new_structured_type 
| new_pointer_type
;

tag_type : type_identifier ;

unpacked_structured_type
: array_type
| record_type
| set_type
| file_type
;

array_type : ARRAY LBRACK array_type_parameter_list RBRACK OF component_type ;

component_type : type_denoter ;

array_type_parameter_list
: index_type
| array_type_parameter_list COMMA index_type
;

record_type : RECORD field_list END ;

set_type : SET OF base_type ;

base_type : ordinal_type ;

file_type : FILE1 OF component_type ;

index_type : ordinal_type ;

ordinal_type 
: new_ordinal_type 
| type_identifier
;

new_ordinal_type
: enumerated_type
| subrange_type
;

enumerated_type : LPAREN identifier_list RPAREN ;

subrange_type : constant DOTDOT constant ;

index_type_specification : IDENT DOTDOT IDENT COLON type_identifier ;

index_type_specification_list
: index_type_specification
| index_type_specification_list SEMI index_type_specification
;

domain_type : type_identifier ;

new_pointer_type : CARROT domain_type ;

new_structured_type
: unpacked_structured_type
| PACKED unpacked_structured_type
;

result_type : type_identifier ;

/* parts: variable */
variable_access
: variable_access CARROT
| component_variable 
//| entire_variable
;

variable_access_list
: variable_access COMMA variable_access
| variable_access_list COMMA variable_access
;

variable_conformant_array_specification
: VAR identifier_list COLON conformant_array_schema
;

variable_declaration
: IDENT COLON type_denoter { 
	$$ = newref($1);
	//printf("%04d: var declared. var := %4.4g\n", yylineno, eval($$));
}
//: identifier_list COLON type_denoter
;

variable_declaration_list
: variable_declaration SEMI
| variable_declaration_list variable_declaration SEMI
;

variable_declaration_part
: %empty /* nothing */
| VAR variable_declaration_list
;

variable_parameter_specification
: VAR identifier_list COLON type_identifier
;


/* parts: procedure and function declarations*/
procedure_and_function_declaration_part 
: %empty /* nothing */
| procedure_declaration SEMI
| function_declaration SEMI
| procedure_and_function_declaration_part procedure_declaration SEMI
| procedure_and_function_declaration_part function_declaration SEMI
;

/* parts: pfd: procedure */
procedural_parameter_specification : procedure_heading ;

procedure_block : block ;

procedure_declaration 
: procedure_heading SEMI directive
| procedure_heading SEMI procedure_block
;

procedure_heading
: PROCEDURE procedure_identifier
| PROCEDURE procedure_identifier formal_parameter_list
;

procedure_identifier
: DISPOSE
| GET
| NEW
| PACK
| PAGE
| PUT
| READ
| READLN
| RESET
| REWRITE
| UNPACK
| WRITE
| WRITELN
| IDENT
;

procedure_statement_read
: READ read_parameter_list
| READLN read_parameter_list
;

procedure_statement_write
: WRITE   LPAREN STRING_LITERAL RPAREN {

	emit( "  ; push java.lang.System.out (type PrintStream)" );
	emit( "  getstatic java/lang/System/out Ljava/io/PrintStream;\n" );

	emit( "  ldc \"%s\" ; push string", $3 );
	emit( "  invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n" );
}
| WRITELN LPAREN STRING_LITERAL RPAREN {

	emit( "  ; push java.lang.System.out (type PrintStream)" );
	emit( "  getstatic java/lang/System/out Ljava/io/PrintStream;\n" );

	emit( "  ldc \"%s\" ; push string", $3 );
	emit( "  invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n" );
}
| WRITE   LPAREN IDENT RPAREN {

	emit( "  ; push java.lang.System.out (type PrintStream)" );
	emit( "  getstatic java/lang/System/out Ljava/io/PrintStream;\n" );

	emit( "  ldc \"%.4g\" ; push variable value", eval(newref($3)) );
	emit( "  invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n" );
}
| WRITELN LPAREN IDENT RPAREN {

	emit( "  ; push java.lang.System.out (type PrintStream)" );
	emit( "  getstatic java/lang/System/out Ljava/io/PrintStream;\n" );

	emit( "  ldc \"%.4g\" ; push variable value", eval(newref($3)) );
	emit( "  invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n" );
}
;

/* This is the real NT
procedure_statement_write
: WRITELN write_parameter_list
| WRITE write_parameter_list
;
*/

procedure_statement 
: procedure_identifier 
| procedure_identifier actual_parameter_list
| procedure_statement_read
| procedure_statement_write
//| procedure_identifier read_parameter_list
//| procedure_identifier write_parameter_list
;

/* parts: pfd: procedure */
function_block : block ;

function_declaration
: function_heading SEMI directive
| function_heading SEMI function_block
;

function_designator
: function_identifier actual_parameter_list
//| function_identifier
| EOF1
| EOLN
;

function_heading
: FUNCTION function_identifier
| FUNCTION function_identifier COLON result_type
| FUNCTION function_identifier formal_parameter_list COLON result_type
;

function_identifier
: IDENT
| ABS
| ARCTAN
| CHR
| COS
| EOF1
| EOLN
| EXP
| LN
| ODD
| ORD
| PRED
| ROUND
| SIN
| SQR
| SQRT
| SUCC
| TRUNC
;

functional_parameter_specification : function_heading ;

/* expressions */
expression 
: simple_expression 
//| STRING_LITERAL
| expression relational_operator simple_expression
;

simple_expression
: term
//| sign term
//| boolean
| simple_expression adding_operator term { $$ = newast($2, $1, $3); }
;

relational_operator
: EQUAL
| NOT_EQUAL
| LT
| GT
| LT_EQUAL
| GT_EQUAL
| IN
;

adding_operator
: PLUS 
| MINUS 
//| OR
;

term 
: factor
| term multiplying_operator factor { $$ = newast($2, $1, $3); }
;

multiplying_operator
: MULTIPLY
| DIVIDE
//| DIV
//| MOD
//| AND
;

factor
: IDENT { $$ = newref($1); } // TODO: This is a hack, remove
//: variable_access
| unsigned_constant
//| function_designator
//| set_constructor
| LPAREN expression RPAREN { $$ = $2; }
//| NOT factor
;

/* other */
actual_parameter
: expression 
//| variable_access
//| procedure_identifier 
//| function_identifier
| actual_parameter COMMA actual_parameter
;

actual_parameter_list
: LPAREN actual_parameter RPAREN
;

assignment_statement
: IDENT ASSIGN expression { // TODO: This is a Hack, remove
	$$ = newasgn( $1, $3 ); 
	eval($$);
	//printf("%04d: var := %4.4g\n", yylineno, eval($$));
}
//| variable_access ASSIGN expression
//| function_identifier ASSIGN expression
;

boolean_expression : expression ;

case_constant : constant ;

case_constant_list 
: case_constant
| case_constant_list COMMA case_constant
;

case_index : expression ;

case_list_element
: case_constant_list COLON statement SEMI
;

case_list_element_list
: case_list_element
| case_list_element_list case_list_element
;

case_statement
: CASE case_index OF case_list_element_list END
;

component_variable 
: indexed_variable
| field_designator
;

compound_statement : BEGIN1 statement_sequence END ;

conditional_statement
: if_statement 
| case_statement ;

conformant_array_parameter_specification 
: value_conformant_array_specification
| variable_conformant_array_specification
;

conformant_array_schema
: packed_conformant_array_schema
| unpacked_conformant_array_schema
;

else_part
: ELSE statement
;

empty_statement : %empty /* nothing */ ;

field_designator
: variable_access DOT IDENT
| field_designator_identifier
;

field_designator_identifier : IDENT ;

field_list
: %empty /* nothing */
| fixed_part
| fixed_part SEMI
| fixed_part variant_part
| fixed_part variant_part SEMI
| fixed_part SEMI variant_part
| fixed_part SEMI variant_part SEMI
;

fixed_part
: record_section
| fixed_part SEMI record_section 
;

for_statement
: FOR IDENT ASSIGN initial_value TO expression DO statement
| FOR IDENT ASSIGN initial_value DOWNTO expression DO statement
;

formal_parameter_list : LPAREN formal_parameter_section RPAREN ;

formal_parameter_section
: value_parameter_specification
| variable_parameter_specification
| procedural_parameter_specification
| functional_parameter_specification
| conformant_array_parameter_specification
| formal_parameter_section SEMI formal_parameter_section
;

goto_statement : GOTO label ;

if_statement
: IF boolean_expression THEN statement
| IF boolean_expression THEN statement else_part
;

index_expression : expression ;

indexed_variable 
: array_variable LBRACK index_expression RBRACK
| array_variable LBRACK indexed_variable_list RBRACK
;

indexed_variable_list
: index_expression COMMA index_expression
| indexed_variable_list COMMA index_expression
;

initial_value : expression ;

member_designator 
: expression
| expression DOTDOT expression
;

packed_conformant_array_schema
: PACKED ARRAY LBRACK index_type_specification RBRACK OF type_identifier
;

read_parameter_list
: LPAREN variable_access RPAREN
| LPAREN variable_access_list RPAREN
;

record_section : identifier_list COLON type_denoter ;

record_variable_list
: variable_access
| record_variable_list COMMA variable_access
;

repeat_statement : REPEAT statement_sequence UNTIL boolean_expression ;

repetitive_statement 
: repeat_statement 
| while_statement 
| for_statement ;


//scale_factor
//: NUM_INT 
//| sign NUM_INT 
//;

set_constructor
: LBRACK RBRACK
| LBRACK set_constructor_list RBRACK
;

set_constructor_list
: member_designator
| set_constructor_list COMMA member_designator
;


simple_statement
: empty_statement
| assignment_statement
| procedure_statement
| goto_statement
;

statement 
: label COLON simple_statement
| label COLON structured_statement
| simple_statement
| structured_statement
;

statement_part : compound_statement ;

statement_sequence
: statement
| statement_sequence SEMI statement
;

structured_statement 
: compound_statement 
| conditional_statement 
| repetitive_statement 
| with_statement 
;

unpacked_conformant_array_schema
: ARRAY LBRACK index_type_specification_list RBRACK OF type_identifier
| ARRAY LBRACK index_type_specification_list RBRACK OF conformant_array_schema
;

value_conformant_array_specification
: identifier_list COLON conformant_array_schema
;

value_parameter_specification
: IDENT COLON type_identifier
| identifier_list COLON type_identifier
;

variant : case_constant_list COLON LPAREN field_list RPAREN ;

variant_list
: variant
| variant_list SEMI variant
;

variant_part
: CASE variant_selector OF variant_list
;

variant_selector
: IDENT COLON tag_type
| tag_type
;

while_statement : WHILE boolean_expression DO statement ;

with_statement : WITH record_variable_list DO statement ;

write_parameter
: actual_parameter
| expression COLON expression
| expression COLON expression COLON expression
| write_parameter COMMA write_parameter
;

write_parameter_list
: LPAREN variable_access COMMA write_parameter RPAREN
| LPAREN write_parameter RPAREN
;

%%
