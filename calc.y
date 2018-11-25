%{
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include "calc.h"

int yylex(void);
void yyerror(char *);

unsigned int lineno = 1;
%}

%union {
	double val;
	Symbol *sym;
}
%token	<val> NUMBER
%token	<sym> VAR BLTIN UNDEF
%type	<val> expr asgn
%right	'='
%left	'+' '-'
%left	'*' '/' '%'
%left	UNARYMINUS UNARYPLUS
%right	'^'

%%

list:	/* empty */
	| list '\n'		{ lineno++; }
	| list asgn '\n'	{ lineno++; }
	| list expr '\n'	{ lineno++; printf("\t%f\n", $2); }
	| list error '\n'	{ yyerrok; }
	;

asgn:	  VAR '=' expr				{ $$=$1->u.val = $3; $1->type = VAR;  }

expr:	NUMBER					{ $$ = $1; }
    	| VAR					{ if ($1->type == UNDEF)
							execerror("undefined variable", $1->name);
						  $$ = $1->u.val; }
	| asgn
	| BLTIN '(' expr ')'			{ $$ = (*($1->u.ptr))($3); }
    	| '-' expr %prec UNARYMINUS		{ $$ = -$2; }
    	| '+' expr %prec UNARYPLUS		{ $$ = +$2; }
	| expr '+' expr				{ $$ = $1 + $3; }
	| expr '-' expr				{ $$ = $1 - $3; }
	| expr '*' expr				{ $$ = $1 * $3; }
	| expr '/' expr				{ $$ = $1 / $3; }
	| expr '%' expr				{ $$ = fmod($1, $3); }
	| expr '^' expr				{ $$ = pow($1, $3); }
	| '(' expr ')'				{ $$ = $2; }
	| '[' expr ']'				{ $$ = $2; }
	| '{' expr '}'				{ $$ = $2; }
	;

%%

char *progname = NULL;

int
yylex(void)
{
	int c;
	while ((c = getchar()) == ' ' || c == '\t')	/* skip white spaces */
		;
	if (c == EOF)					/* the $end */
		return 0;
	if (c == '.' || isdigit(c)) {			/* a number */
		ungetc(c, stdin);
		scanf("%lf", &yylval.val);
		return NUMBER;
	}
	if (isalpha(c)) {
		Symbol *s;
		char  sbuf[100], *p = sbuf;
		do {
			if (p >= sbuf + sizeof(sbuf) - 1) {
				*p = '\0';
				execerror("name too long", sbuf);
			}
			*p++ = c;
		} while((c=getchar()) != EOF && isalnum(c));
		ungetc(c, stdin);
		*p = '\0';
		if ((s=lookup(sbuf)) == 0)
			s = install(sbuf, UNDEF, 0.0);
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
	}
	return c;
}

void
yyerror(char *s)
{
	fprintf(stderr, "%s: %s at line %d\n", progname, s, lineno);
}

void
execerror(char *s, char *t)
{
	fprintf(stderr, "%s: %s ", progname, s);
	if (t)
		fprintf(stderr, " %s", t);
	fprintf(stderr, " at line %d\n", lineno);
}

int
main(int argc, char *argv[])
{
	progname = argv[0];
	return yyparse();
}
