# include <stdio.h>
# include <stdlib.h>
# include <stdarg.h>
# include <string.h>
# include <math.h>
# include "pascal.h"

struct symbol symtab[NHASH];

static unsigned symhash( char * sym )
{
	unsigned int hash = 0;
	unsigned c;

	while( ( c = *sym++ ) )
	{
		hash = hash * 9 ^ c;
	}

	return hash;
}

struct symbol * lookup( char * sym )
{
	struct symbol * sp = &symtab[symhash( sym ) % NHASH];
	int scount = NHASH; /* how many have we looked at */

	while( --scount >= 0 )
	{
		if( sp->name && !strcmp( sp->name, sym ) )
		{
			return sp;
		}

		if( !sp->name ) /* new entry */
		{
			sp->name = strdup( sym );
			sp->value = 0;
			sp->func = NULL;
			sp->syms = NULL;
			return sp;
		}

		if( ++sp >= symtab + NHASH )
		{
			sp = symtab;    /* try the next entry */
		}
	}

	yyerror( "symbol table overflow\n" );
	abort(); /* tried them all, table is full */
}

struct ast * newast( int nodetype, struct ast * l, struct ast * r )
{
	struct ast * a = malloc( sizeof( struct ast ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = nodetype;
	a->l = l;
	a->r = r;
	return a;
}

struct ast * newnum( double d )
{
	struct numval * a = malloc( sizeof( struct numval ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = 'K';
	a->number = d;
	return ( struct ast * ) a;
}

struct ast * newcmp( int cmptype, struct ast * l, struct ast * r )
{
	struct ast * a = malloc( sizeof( struct ast ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = '0' + cmptype;
	a->l = l;
	a->r = r;
	return a;
}

struct ast * newfunc( int functype, struct ast * l )
{
	struct fncall * a = malloc( sizeof( struct fncall ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = 'F';
	a->l = l;
	a->functype = functype;
	return ( struct ast * ) a;
}

struct ast * newproc( int proctype, struct ast * l )
{
	struct pcall * a = malloc( sizeof( struct pcall ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = 'P';
	a->l = l;
	a->proctype = proctype;
	return ( struct ast * ) a;
}

struct ast * newcall( struct symbol * s, struct ast * l )
{
	struct ufncall * a = malloc( sizeof( struct ufncall ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = 'C';
	a->l = l;
	a->s = s;
	return ( struct ast * ) a;
}

struct ast * newref( struct symbol * s )
{
	struct symref * a = malloc( sizeof( struct symref ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = 'N';
	a->s = s;
	return ( struct ast * ) a;
}

struct ast * newasgn( struct symbol * s, struct ast * v )
{
	struct symasgn * a = malloc( sizeof( struct symasgn ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = '=';
	a->s = s;
	a->v = v;
	return ( struct ast * ) a;
}

struct ast * newflow( 
		int nodetype, struct ast * cond, struct ast * tl, struct ast * el )
{
	struct flow * a = malloc( sizeof( struct flow ) );

	if( !a )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	a->nodetype = nodetype;
	a->cond = cond;
	a->tl = tl;
	a->el = el;
	return ( struct ast * )a;
}

void treefree( struct ast * a )
{
	switch( a->nodetype )
	{
		/* two subtrees */
		case '+':
		case '-':
		case '*':
		case '/':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case 'L':
			treefree( a->r );

			/* one subtree */
		case 'M':
		case 'C':
		case 'F':
		case 'P':
			treefree( a->l );

			/* no subtree */
		case 'K':
		case 'N':
			break;

		case '=':
			free( ( ( struct symasgn * )a )->v );
			break;

			/* up to three subtrees */
		case 'I':
		case 'W':
			free( ( ( struct flow * )a )->cond );

			if( ( ( struct flow * )a )->tl )
			{
				treefree( ( ( struct flow * )a )->tl );
			}

			if( ( ( struct flow * )a )->el )
			{
				treefree( ( ( struct flow * )a )->el );
			}

			break;

		default:
			printf( "internal error: free bad node %c\n", a->nodetype );
	}

	free( a );
} /* treefree */

struct symlist * newsymlist( struct symbol * sym, struct symlist * next )
{
	struct symlist * sl = malloc( sizeof( struct symlist ) );

	if( !sl )
	{
		yyerror( "out of space" );
		exit( 0 );
	}

	sl->sym = sym;
	sl->next = next;
	return sl;
}

void symlistfree( struct symlist * sl )
{
	struct symlist * nsl;

	while( sl )
	{
		nsl = sl->next;
		free( sl );
		sl = nsl;
	}
}

static double call_builtin_func ( struct fncall * f );
static void   call_builtin_proc ( struct pcall * p );
static double call_user_func    ( struct ufncall * f );

double eval( struct ast * a )
{
	double v;

	if( !a )
	{
		yyerror( "internal error, null eval" );
		return 0.0;
	}

	switch( a->nodetype )
	{
			/* constant */
		case 'K':
			v = ( ( struct numval * )a )->number;
			break;

			/* name reference */
		case 'N':
			v = ( ( struct symref * )a )->s->value;
			break;

			/* assignment */
		case '=':
			v = ( ( struct symasgn * )a )->s->value = 
				eval( ( ( struct symasgn * )a )->v );
			break;

			/* expressions */
		case '+':
			v = eval( a->l ) + eval( a->r );
			break;

		case '-':
			v = eval( a->l ) - eval( a->r );
			break;

		case '*':
			v = eval( a->l ) * eval( a->r );
			break;

		case '/':
			v = eval( a->l ) / eval( a->r );
			break;

		case 'M':
			v = -eval( a->l );
			break;

			/* comparisons */
		case '1':
			v = ( eval( a->l ) > eval( a->r ) ) ? 1 : 0;
			break;

		case '2':
			v = ( eval( a->l ) < eval( a->r ) ) ? 1 : 0;
			break;

		case '3':
			v = ( eval( a->l ) != eval( a->r ) ) ? 1 : 0;
			break;

		case '4':
			v = ( eval( a->l ) == eval( a->r ) ) ? 1 : 0;
			break;

		case '5':
			v = ( eval( a->l ) >= eval( a->r ) ) ? 1 : 0;
			break;

		case '6':
			v = ( eval( a->l ) >= eval( a->r ) ) ? 1 : 0;
			break;

			/* control flow */
			/* null expressions allowed in the grammar, so check for them */

			/* if/then/else */
		case 'I':
			if( eval( ( ( struct flow * )a )->cond ) != 0 ) /* check the condition */
			{
				if( ( ( struct flow * )a )->tl ) /* the true branch */
				{
					v = eval( ( ( struct flow * )a )->tl );
				}
				else
				{
					v = 0.0; /* a default value */
				}
			}
			else
			{
				if( ( ( struct flow * )a )->el ) /* the false branch */
				{
					v = eval( ( ( struct flow * )a )->el );
				}
				else
				{
					v = 0.0; /* a default value */
				}
			}

			break;

			/* while/do */
		case 'W':
			v = 0.0; /* a default value */

			if( ( ( struct flow * )a )->tl )
			{
				while( eval( ( ( struct flow * )a )->cond ) != 0 )
				{
					v = eval( ( ( struct flow * )a )->tl );
				}
			}

			break; /* value of last statement is value of while/do */

			/* list of statements */
		case 'L':
			eval( a->l );
			v = eval( a->r );
			break;

		case 'F':
			v = call_builtin_func( ( struct fncall * )a );
			break;

		case 'P':
			call_builtin_proc( ( struct pcall * )a );
			break;

		case 'C':
			v = call_user_func( ( struct ufncall * )a );
			break;

		default:
			printf( "internal error: bad node %c\n", a->nodetype );
	}

	return v;
} /* eval */

double call_builtin_func ( struct fncall * f )
{
	enum bifs functype = f->functype;
	double v = eval( f->l );

	switch( functype )
	{
		case B_abs:
			return fabs( v );

		case B_arctan:
			return atan( v );

		case B_chr:
			return v;

		case B_cos:
			return cos( v );

		case B_eof:
			return 0.0; /* unimplemented */

		case B_eoln:
			return 0.0; /* unimplemented */

		case B_exp:
			return exp( v );

		case B_ln:
			return log( v );

		case B_odd:
			if ( (int) fabs(v) % 2 == 0)
			{
				return 0.0;
			}
			return 1.0;

		case B_ord:
			return 0.0; /* unimplemented */

		case B_pred:
			return 0.0; /* unimplemented */

		case B_round:
			return (int) (v + 0.5);

		case B_sin:
			return sin( v );

		case B_sqr:
			return v * v;

		case B_sqrt:
			return sqrt( v );

		case B_succ:
			return 0.0; /* unimplemented */

		case B_trunc:
			return (int) v;

		default:
			yyerror( "Unknown built-in function %d", functype );
			break;
	}

	return 0.0;
}


void call_builtin_proc ( struct pcall * p )
{
	enum bips proctype = p->proctype;

	switch( proctype )
	{
		case B_dispose:
			p->l = p->l->l;
			break;

		case B_get:
			break; /* unimplemented */

		case B_pack:
			break; /* unimplemented */

		case B_page:
			break; /* unimplemented */

		case B_put:
			break; /* unimplemented */

		case B_read:
			break; /* unimplemented */

		case B_readln:
			break; /* unimplemented */

		case B_reset:
			break; /* unimplemented */

		case B_rewrite:
			break; /* unimplemented */

		case B_unpack:
			break; /* unimplemented */

		case B_write:
			break; /* unimplemented */

		case B_writeln:
			break; /* unimplemented */

		default:
			yyerror( "Unknown built-in procedure %d", proctype );
			break;
	}
}

void dodef ( struct symbol * name, struct symlist * syms, struct ast * func )
{
	if( name->syms )
	{
		symlistfree( name->syms );
	}

	if( name->func )
	{
		treefree( name->func );
	}

	name->syms = syms;
	name->func = func;
}

static double call_user_func ( struct ufncall * f )
{
	struct symbol * fn = f->s; /* function name */
	struct symlist * sl ;      /* dummy arguments */
	struct ast * args = f->l;  /* actual arguments */
	double * oldval, *newval;  /* saved arg values */
	double v;
	int nargs;
	int i;

	if( !fn->func )
	{
		yyerror( "call to undefined function %s", fn->name );
		return 0;
	}

	/* count the arguments */
	sl = fn->syms;

	for( nargs = 0; sl; sl = sl->next )
	{
		nargs++;
	}

	/* prepare to save them */
	oldval = ( double * )malloc( nargs * sizeof( double ) );
	newval = ( double * )malloc( nargs * sizeof( double ) );

	if( !oldval || !newval )
	{
		yyerror( "Out of space in %s", fn->name );
		return 0.0;
	}

	/* evaluate the arguments */
	for( i = 0; i < nargs; i++ )
	{
		if( !args )
		{
			yyerror( "too few args in call to %s", fn->name );
			free( oldval );
			free( newval );
			return 0.0;
		}

		if( args->nodetype == 'L' ) /* if this is a list node */
		{
			newval[i] = eval( args->l );
			args = args->r;
		}
		else     /* if it's the end of the list */
		{
			newval[i] = eval( args );
			args = NULL;
		}
	}

	/* save old values of dummies, assign new ones */
	sl = fn->syms;

	for( i = 0; i < nargs; i++ )
	{
		struct symbol * s = sl->sym;

		oldval[i] = s->value;
		s->value = newval[i];
		sl = sl->next;
	}

	free( newval );

	/* evaluate the function */
	v = eval( fn->func );

	/* put the real values of the dummies back */
	sl = fn->syms;

	for( i = 0; i < nargs; i++ )
	{
		struct symbol * s = sl->sym;

		s->value = oldval[i];
		sl = sl->next;
	}

	free( oldval );
	return v;
}

void yyerror( char * s, ... )
{
	va_list ap;
	va_start( ap, s );
	fprintf( stderr, "%04d: error: ", yylineno );
	vfprintf( stderr, s, ap );
	fprintf( stderr, "\n" );
}

void emit(char *s, ...)
{
	extern int yylineno;

	va_list ap;
	va_start(ap, s);

	//printf("jasmine: ");
	vfprintf(stdout, s, ap);
	printf("\n");
}


int main( int argc, char ** argv )
{
	if (argc < 2)
	{
		fprintf(stderr, "usage: %s <file>\n", argv[0]);
		return 1;
	}

	if( !( yyin = fopen( argv[1], "r" ) ) )
	{
		perror( argv[1] );
		return( 1 );
	}

	return yyparse();
}
