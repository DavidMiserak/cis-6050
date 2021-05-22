/** @file
 * Functions to aid Pascal compiler
 */

/*
 * -- node types --
 * + - * /
 * 0-7 comparison ops, bit coded 04 equal, 02 less, 01 greater
 * M unary minus
 * L expression of statement list
 * I IF statement
 * W WHILE statement
 * N symbol ref
 * = assignment
 * S list of symbols
 * F build in function call
 * P build in procedure call
 * C user function
 */

extern int yylineno;
extern FILE * yyin;

/**
 * Keep track of source code file.
 */
int fileno();

/**
 * An interface with the lexer.
 */
int yylex();

/**
 * An interface with the parser.
 */
int yyparse();

/**
 * Report parsing errors.
 *
 * @param s A printf style string.
 */
void yyerror( char * s, ... );

/**
 * Emit text via printf style.
 *
 * @param s A printf style string.
 */
void emit( char * s, ... );

/**
 * A symbol record.
 */
struct symbol
{
	char * name;
	double value;
	struct ast * func;
	struct symlist * syms;
};

#define NHASH 9997
extern struct symbol symtab[NHASH];

/**
 * Lookup symbol in the symbol table.
 *
 * @param sym String to search for in symbol table.
 */
struct symbol * lookup( char * sym );

/**
 * A linked list of symbols.
 */
struct symlist
{
	struct symbol * sym;
	struct symlist * next;
};

/**
 * Create a new symbol list.
 *
 * @param sym Symbol
 * @param next Next symbol
 */
struct symlist * newsymlist( struct symbol * sym, struct symlist * next );

/**
 * Free a symbol list.
 *
 * @param sl Symbol List
 */
void symlistfree( struct symlist * sl );

/**
 * Pascal's built-in functions.
 */
enum bifs
{
	B_abs = 1,
	B_arctan,
	B_chr,
	B_cos,
	B_eof,
	B_eoln,
	B_exp,
	B_ln,
	B_odd, /* 8 */
	B_ord,
	B_pred,
	B_round,
	B_sin,
	B_sqr,
	B_sqrt,
	B_succ,
	B_trunc /* 16 */
};

/**
 * Pascal's built-in procedures.
 */
enum bips
{
	B_dispose = 21,
	B_get,
	B_pack,
	B_page,
	B_put,
	B_read, /* 26 */
	B_readln,
	B_reset,
	B_rewrite,
	B_unpack,
	B_write,
	B_writeln /* 32 */
};

/**
 * Abstract Syntax Tree record.
 */
struct ast
{
	int nodetype;
	struct ast * l;
	struct ast * r;
};

/**
 * Built-in function record.
 */
struct fncall
{
	int nodetype; /**< type F */
	struct ast * l;
	enum bifs functype;
};

/**
 * Built-in procedure record.
 */
struct pcall
{
	int nodetype; /**< type P */
	struct ast * l;
	enum bips proctype;
};

/**
 * User defined function record.
 */
struct ufncall /* user function */
{
	int nodetype;      /**< type C */
	struct ast * l;    /**< list of arguments */
	struct symbol * s;
};

/**
 * Control flow record.
 */
struct flow
{
	int nodetype;      /**< type I or W */
	struct ast * cond; /**< condition */
	struct ast * tl;   /**< then branch or do list */
	struct ast * el;   /**< optional else branch */
};

/**
 * Number record.
 */
struct numval
{
	int nodetype; /**< type K */
	double number;
};

/**
 * Symbol reference record.
 */
struct symref
{
	int nodetype; /**< type N */
	struct symbol * s;
};

/**
 * Assignment record.
 */
struct symasgn
{
	int nodetype;     /**< type = */
	struct symbol * s;
	struct ast * v;   /**< value */
};

/**
 * Create a new AST.
 *
 * @param nodetype The type of node.
 * @param l The left AST.
 * @param r The right AST.
 */
struct ast * newast( int nodetype, struct ast * l, struct ast * r );

/**
 * Create a new comparison AST.
 *
 * @param cmptype The type of node.
 * @param l The left AST.
 * @param r The right AST.
 */
struct ast * newcmp( int cmptype, struct ast * l, struct ast * r );

/**
 * Create a new function AST.
 *
 * @param functype The type of node.
 * @param l The left AST.
 */
struct ast * newfunc( int functype, struct ast * l );

/**
 * Create a new procedure AST.
 *
 * @param proctype The type of node.
 * @param l The left AST.
 */
struct ast * newproc( int proctype, struct ast * l );

/**
 * Create a new user defined function AST.
 *
 * @param symbol Symbol.
 * @param l The left AST.
 */
struct ast * newcall( struct symbol * s, struct ast * l );

/**
 * Create an AST that is a reference to a symbol.
 *
 * @param symbol Symbol.
 */
struct ast * newref( struct symbol * s );

/**
 * Create an assignment AST
 *
 * @param symbol Symbol.
 * @param v Value.
 */
struct ast * newasgn( struct symbol * s, struct ast * v );

/**
 * Create an AST the represents a new number.
 *
 * @param d Value.
 */
struct ast * newnum( double d );

/**
 * Create an AST that represents control-flow.
 *
 * @param nodetype The type of node.
 * @param cond     The condition AST to evaluate.
 * @param tl       The then branch.
 * @param tr       The else branch.
 */
struct ast * newflow( int nodetype, struct ast * cond, struct ast * tl,
					  struct ast * el );

/**
 * Define a function.
 *
 * @param name Function name.
 * @param syms Function arguments.
 * @param stmts Function statements.
 */
void dodef( struct symbol * name, struct symlist * syms, struct ast * stmts );

/**
 * Evaluate an arithmetic AST.
 *
 * @param a The AST to evaluate.
 */
double eval( struct ast * a );

/**
 * Delete and free an AST.
 *
 * @param a The AST to delete and free.
 */
void treefree( struct ast * a );

