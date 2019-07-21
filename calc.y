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
%type	<inst> expr stmt stmtlist asgn cond while if end for
%token	<sym> NUMBER PRINT VAR BLTIN UNDEF WHILE IF ELSE FOR
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
	| list sep
	| list asgn sep		{ code2((Inst)pop, STOP); return 1; }
	| list stmt sep		{ code(STOP); return 1; }
	| list expr sep		{ code2(print, STOP); return 1; }
	| list error sep	{ yyerrok; }
	;

asgn:	  VAR '=' expr				{ $$ = $3; code3(varpush, (Inst)$1, assign); }
	| VAR ADDEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, addeq); }
	| VAR SUBEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, subeq); }
	| VAR MULEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, muleq); }
	| VAR DIVEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, diveq); }
	| VAR MODEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, modeq); }
	;

stmt:     expr					{ code((Inst)pop); }
	| PRINT expr				{ code(prexpr); $$ = $2; }
	| while '(' cond ')' stmt end {
		($1)[1] = (Inst)$5;
		($1)[2] = (Inst)$6; }
	| for '(' cond ';' cond ';' cond ')' stmt end {
		($1)[1] = (Inst)$5;
		($1)[2] = (Inst)$7;
		($1)[3] = (Inst)$9;
		($1)[4] = (Inst)$10; }
	| if '(' cond ')' stmt end {
		($1)[1] = (Inst)$5;
		($1)[3] = (Inst)$6; }
	| if '(' cond ')' stmt end ELSE stmt end {
		($1)[1] = (Inst)$5;
		($1)[2] = (Inst)$8;
		($1)[3] = (Inst)$9; }
	| '{' stmtlist '}'			{ $$ = $2; }
	;

cond:    expr					{ code(STOP); }
	;

while:   WHILE	{ $$ = code3(whilecode, STOP, STOP); }
	;

for:	 FOR { $$ = code(forcode); code3(STOP, STOP, STOP); code(STOP); }
	;

if:	IF { $$ = code(ifcode); code3(STOP, STOP, STOP); }
	;

end:						{ code(STOP); $$ = progp; }
	;

stmtlist:					{ $$ = progp; }
	| stmtlist sep
	| stmtlist stmt
	;

sep:      '\n' | ';'
	;

expr:	NUMBER					{ $$ = code2(constpush, (Inst)$1); }
	| VAR					{ $$ = code3(varpush, (Inst)$1, eval); }
	| asgn
	| BLTIN '(' expr ')'			{ $$ = $3; code2(bltin, (Inst)$1->u.ptr); }
	| expr '+' expr				{ code(add); }
	| expr '-' expr				{ code(sub); }
	| expr '*' expr				{ code(mul); }
	| expr '/' expr				{ code(div); }
	| expr '%' expr				{ code(mod); }
	| expr '^' expr				{ code(power); }
	| '(' expr ')'				{ $$ = $2; }
	| '[' expr ']'				{ $$ = $2; }
	| '{' expr '}'				{ $$ = $2; }
	| '-' expr %prec UNARYMINUS		{ $$ = $2; code(negate); }
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
	if (c == '#') {					/* comment */
		while ((c = getchar()) != '\n' && c >= 0)
			;
		if (c == '\n')
			lineno++;
		return c;
	}
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
	case '\n':	lineno++; return '\n';
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
#if YYDEBUG > 0
	extern int yydebug;
	yydebug=3;
#endif
	progname = argv[0];
	init();
	setjmp(begin);
	for (initcode(); yyparse(); initcode())
		execute(prog);
	return 0;
}
