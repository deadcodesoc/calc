%{
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <setjmp.h>
#include "calc.h"

#define code2(c1,c2)	code(c1); code(c2)
#define code3(c1,c2,c3)	code(c1); code(c2); code(c3)

int yylex(void);
void yyerror(char *);

unsigned int lineno = 1;
%}

%union {
	Symbol	*sym;
	Inst	*inst;
}
%type	<inst> expr stmt stmtlist asgn
%token	<sym> NUMBER PRINT VAR BLTIN UNDEF
%right	'=' ADDEQ SUBEQ MULEQ DIVEQ MODEQ
%left	OR
%left	AND
%left	GT GE LT LE EQ NE
%left	'+' '-'
%left	'*' '/' '%'
%left	UNARYMINUS NOT INC DEC
%right	'^'

%%

list:	/* empty */
	| list '\n'		{ lineno++; }
	| list asgn '\n'	{ lineno++; code2((Inst)pop, STOP); return 1; }
	| list stmt '\n'	{ lineno++; code(STOP); return 1; }
	| list expr '\n'	{ lineno++; code2(print, STOP); return 1; }
	| list error '\n'	{ yyerrok; }
	;

asgn:	  VAR '=' expr				{ code3(varpush, (Inst)$1, assign); }
	| VAR ADDEQ expr			{ code3(varpush, (Inst)$1, addeq); }
	| VAR SUBEQ expr			{ code3(varpush, (Inst)$1, subeq); }
	| VAR MULEQ expr			{ code3(varpush, (Inst)$1, muleq); }
	| VAR DIVEQ expr			{ code3(varpush, (Inst)$1, diveq); }
	| VAR MODEQ expr			{ code3(varpush, (Inst)$1, modeq); }
	;

stmt:     expr					{ code((Inst)pop); }
	| PRINT expr				{ code(prexpr); $$ = $2; }
	| '{' stmtlist '}'			{ $$ = $2; }
	;

stmtlist:					{ $$ = progp; }
	| stmtlist '\n'
	| stmtlist stmt
	;

expr:	NUMBER					{ code2(constpush, (Inst)$1);  }
	| VAR					{ code3(varpush, (Inst)$1, eval); }
	| asgn
	| BLTIN '(' expr ')'			{ code2(bltin, (Inst)$1->u.ptr);  }
	| expr '+' expr				{ code(add); }
	| expr '-' expr				{ code(sub); }
	| expr '*' expr				{ code(mul); }
	| expr '/' expr				{ code(div); }
	| expr '%' expr				{ code(mod); }
	| expr '^' expr				{ code(power); }
	| '(' expr ')'				{ }
	| '[' expr ']'				{ }
	| '{' expr '}'				{ }
	| '-' expr %prec UNARYMINUS		{ code(negate); }
	| expr GT expr				{ code(gt); }
	| expr GE expr				{ code(ge); }
	| expr LT expr				{ code(lt); }
	| expr LE expr				{ code(le); }
	| expr EQ expr				{ code(eq); }
	| expr NE expr				{ code(ne); }
	| expr AND expr				{ code(and); }
	| expr OR expr				{ code(or); }
	| NOT expr				{ $$ = $2; code(not); }
	| INC VAR				{ $$ = code2(preinc, (Inst)$2); }
	| DEC VAR				{ $$ = code2(predec, (Inst)$2); }
	| VAR INC				{ $$ = code2(postinc, (Inst)$1); }
	| VAR DEC				{ $$ = code2(postdec, (Inst)$1); }
	;

%%

char *progname = NULL;
jmp_buf begin;

int
yylex(void)
{
	int c;
	while ((c = getchar()) == ' ' || c == '\t')	/* skip white spaces */
		;
	if (c == EOF)					/* the $end */
		return 0;
	if (c == '.' || isdigit(c)) {			/* a number */
		double d;
		ungetc(c, stdin);
		scanf("%lf", &d);
		yylval.sym = install("", NUMBER, d);
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
		if ((s=lookup(sbuf)) == 0) {
			s = install(sbuf, UNDEF, 0.0);
			if (s == NULL)
				execerror("out of memory", NULL);
		}
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
	}
	switch (c) {
	case '+':	return follow('+', INC, follow('=', ADDEQ, '+'));
	case '-':	return follow('-', DEC, follow('=', SUBEQ, '-'));
	case '*':	return follow('=', MULEQ, '*');
	case '/':	return follow('=', DIVEQ, '/');
	case '%':	return follow('=', MODEQ, '%');
	case '>':	return follow('=', GE, GT);
	case '<':	return follow('=', LE, LT);
	case '=':	return follow('=', EQ, '=');
	case '!':	return follow('=', NE, NOT);
	case '|':	return follow('|', OR, '|');
	case '&':	return follow('&', AND, '&');
	default:	return c;
	}
}

int
follow(int expect, int ifyes, int ifno)
{
	int c = getchar();
	if (c == expect)
		return ifyes;
	ungetc(c, stdin);
	return ifno;
}

void
yyerror(char *s)
{
	warning(s, NULL);
}

void
execerror(char *s, char *t)
{
	warning(s, t);
	longjmp(begin, 0);
}

void
warning(char *s, char *t)
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
	init();
	setjmp(begin);
	for (initcode(); yyparse(); initcode())
		execute(prog);
	return 0;
}
